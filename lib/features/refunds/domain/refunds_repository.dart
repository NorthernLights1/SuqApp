import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../data/local/app_database.dart';
import '../data/refunds_remote.dart';
import 'refund_restock.dart';

abstract interface class IRefundsRepository {
  /// Units already refunded per sale_item for a sale → drives the
  /// remaining-refundable cap so a line can't be over-refunded.
  Future<Map<String, Decimal>> refundedQtyBySaleItem(String saleId);

  Future<void> createRefund({
    required String originalSaleId,
    required String branchId,
    required String refundedBy,
    required String reason,
    required bool restock,
    required List<RefundLineInput> lines,
    required bool useBatches,
  });
}

class RefundsRepository implements IRefundsRepository {
  RefundsRepository(this._remote, this._db);

  final RefundsRemote _remote;
  final AppDatabase? _db;

  @override
  Future<Map<String, Decimal>> refundedQtyBySaleItem(String saleId) async {
    final db = _db;
    if (db == null) return {};
    return db.refundedQtyBySaleItem(saleId);
  }

  @override
  Future<void> createRefund({
    required String originalSaleId,
    required String branchId,
    required String refundedBy,
    required String reason,
    required bool restock,
    required List<RefundLineInput> lines,
    required bool useBatches,
  }) async {
    final refundId = const Uuid().v4();
    final total =
        lines.fold(Decimal.zero, (sum, l) => sum + l.amount);
    final now = DateTime.now();

    // Web (no local DB): write straight to Supabase.
    final db = _db;
    if (db == null) {
      await _remote.createRefund(
        id: refundId,
        originalSaleId: originalSaleId,
        branchId: branchId,
        refundedBy: refundedBy,
        reason: reason,
        totalAmount: total,
        restock: restock,
        items: [
          for (final l in lines) (id: const Uuid().v4(), line: l),
        ],
        useBatches: useBatches,
      );
      return;
    }

    // Native: one local transaction for the refund + its returned lines + the
    // restock ledger entries. isSynced=false on the refund (and on the restock
    // adjustments) so SyncService is the sole pusher. The caller nudges a sync.
    await db.transaction(() async {
      await db.insertRefundWithItems(
        LocalRefundsCompanion(
          id: Value(refundId),
          originalSaleId: Value(originalSaleId),
          branchId: Value(branchId),
          refundedBy: Value(refundedBy),
          reason: Value(reason),
          totalAmount: Value(total),
          restock: Value(restock),
          createdAt: Value(now),
          syncedAt: Value(now),
          isSynced: const Value(false),
        ),
        [
          for (final l in lines)
            LocalRefundItemsCompanion(
              id: Value(const Uuid().v4()),
              refundId: Value(refundId),
              saleItemId: Value(l.saleItemId),
              quantity: Value(l.quantity),
              amount: Value(l.amount),
              syncedAt: Value(now),
            ),
        ],
      );

      if (!restock) return;
      for (final l in lines) {
        final productId = l.productId;
        if (productId == null) continue;
        if (useBatches) {
          await _restockBatchesLocal(db, branchId, productId, l, refundedBy, now);
        } else {
          await _restockRetailLocal(db, branchId, productId, l, refundedBy, now);
        }
      }
    });
  }

  /// Retail restock = an additive 'restock' inventory adjustment (idempotent by
  /// id, pushed via the existing inventory-work path) + the optimistic local
  /// stock bump.
  Future<void> _restockRetailLocal(
    AppDatabase db,
    String branchId,
    String productId,
    RefundLineInput line,
    String refundedBy,
    DateTime now,
  ) async {
    final before = await db.getStockLevel(branchId, productId) ?? Decimal.zero;
    final after = before + line.quantity;
    await db.setStockLevel(branchId, productId, after);
    await db.insertInventoryAdjustment(LocalInventoryAdjustmentsCompanion(
      id: Value(const Uuid().v4()),
      branchId: Value(branchId),
      productId: Value(productId),
      type: const Value('restock'),
      quantityBefore: Value(before),
      quantityAfter: Value(after),
      adjustedBy: Value(refundedBy),
      notes: const Value('Refund restock'),
      createdAt: Value(now),
      isSynced: const Value(false),
    ));
  }

  /// Wholesale restock = negative batch_adjustments against the lots the line
  /// drew from (so remaining = received − depletions − corrections rises), then
  /// recompute the local rollup. Pushed via the existing batch-adjustment path.
  Future<void> _restockBatchesLocal(
    AppDatabase db,
    String branchId,
    String productId,
    RefundLineInput line,
    String refundedBy,
    DateTime now,
  ) async {
    final sib = await db.getSaleItemBatchesForItems([line.saleItemId]);
    final draws = [
      for (final s in sib) (batchId: s.batchId, depleted: s.quantity),
    ];
    final returns = allocateRestock(draws, line.quantity);
    if (returns.isEmpty) return;
    await db.upsertBatchAdjustments([
      for (final r in returns)
        LocalBatchAdjustmentsCompanion(
          id: Value(const Uuid().v4()),
          batchId: Value(r.batchId),
          branchId: Value(branchId),
          productId: Value(productId),
          // Negative delta = add stock back to the lot.
          quantityDelta: Value(-r.quantity),
          reason: const Value('Refund restock'),
          createdBy: Value(refundedBy),
          createdAt: Value(now),
          syncedAt: Value(now),
          isSynced: const Value(false),
        ),
    ]);
    await db.recomputeStockFromBatches(branchId, productId, now);
  }
}
