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
    // Web (no local DB): aggregate from the server so the remaining-refundable
    // cap is real, not an empty map (which would let web over-refund).
    if (db == null) return _remote.refundedQtyBySaleItem(saleId);
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
    final total = lines.fold(Decimal.zero, (sum, l) => sum + l.amount);
    final now = DateTime.now();

    // Over-refund guard at the mutation boundary (not just the UI): re-read the
    // already-refunded totals and reject if existing + requested exceeds what
    // was sold. Catches stale UI, double-submit, and direct calls. (Offline this
    // is the only gate; on push the server is the final authority.)
    final alreadyRefunded = await refundedQtyBySaleItem(originalSaleId);
    final requestedBySaleItem = <String, Decimal>{};
    final soldQuantityBySaleItem = <String, Decimal>{};
    for (final l in lines) {
      requestedBySaleItem[l.saleItemId] =
          (requestedBySaleItem[l.saleItemId] ?? Decimal.zero) + l.quantity;
      soldQuantityBySaleItem[l.saleItemId] = l.soldQuantity;
    }
    for (final entry in requestedBySaleItem.entries) {
      final prior = alreadyRefunded[entry.key] ?? Decimal.zero;
      final soldQuantity = soldQuantityBySaleItem[entry.key] ?? Decimal.zero;
      if (prior + entry.value > soldQuantity) {
        throw StateError(
          'Cannot refund more than was sold for this item '
          '(sold $soldQuantity, already refunded $prior).',
        );
      }
    }

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
        items: [for (final l in lines) (id: const Uuid().v4(), line: l)],
        useBatches: useBatches,
      );
      return;
    }

    // Native: one local transaction for the refund + its returned lines + the
    // restock ledger entries. isSynced=false on the refund (and on the restock
    // adjustments) so SyncService is the sole pusher. The caller nudges a sync.
    await db.transaction(() async {
      final sale = await db.getSale(originalSaleId);
      if (sale == null || sale.status != 'completed') {
        throw StateError('Only completed sales can be refunded.');
      }

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
          await _restockBatchesLocal(
            db,
            branchId,
            productId,
            l,
            refundId,
            refundedBy,
            now,
          );
        } else {
          await _restockRetailLocal(db, branchId, productId, l);
        }
      }
    });
  }

  /// Retail restock: optimistic local stock bump only. The authoritative effect
  /// (an inventory_adjustments row of type 'refund' + the inventory increment)
  /// is applied server-side by upsert_refund_with_inventory on push, derived
  /// from the refunded lines — so there's no separate local row to push.
  Future<void> _restockRetailLocal(
    AppDatabase db,
    String branchId,
    String productId,
    RefundLineInput line,
  ) async {
    final before = await db.getStockLevel(branchId, productId) ?? Decimal.zero;
    await db.setStockLevel(branchId, productId, before + line.quantity);
  }

  /// Wholesale restock: negative batch_adjustments against the lots the line
  /// drew from (remaining = received − depletions − corrections rises), then
  /// recompute the local rollup. Marked isSynced=true + linked to the refund so
  /// the generic batch-adjustment push skips them — they ride the refund RPC
  /// (which inserts server rows with these same ids, reconciling on pull).
  Future<void> _restockBatchesLocal(
    AppDatabase db,
    String branchId,
    String productId,
    RefundLineInput line,
    String refundId,
    String refundedBy,
    DateTime now,
  ) async {
    final sib = await db.getSaleItemBatchesForItems([line.saleItemId]);
    final priorRestocked = await db.refundRestockedQtyByBatchForSaleItem(
      line.saleItemId,
    );
    final draws = [
      for (final s in sib)
        (
          batchId: s.batchId,
          depleted: s.quantity - (priorRestocked[s.batchId] ?? Decimal.zero),
        ),
    ];
    final returns = allocateRestock(draws, line.quantity);
    final allocated = returns.fold(Decimal.zero, (sum, r) => sum + r.quantity);
    if (allocated < line.quantity) {
      // The lots this line drew from can't absorb the return (missing/short
      // depletion ledger). Fail the whole refund transaction rather than record
      // restock=true while leaving stock unrestored.
      throw StateError(
        'Cannot restock the returned units to their original lots. '
        'Refund without restock, or correct the stock manually.',
      );
    }
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
          // Synced=true: the generic push skips it; the refund RPC carries it.
          isSynced: const Value(true),
          refundId: Value(refundId),
          saleItemId: Value(line.saleItemId),
        ),
    ]);
    await db.recomputeStockFromBatches(branchId, productId, now);
  }
}
