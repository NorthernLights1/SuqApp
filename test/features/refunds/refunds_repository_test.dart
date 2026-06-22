import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suq/data/local/app_database.dart';
import 'package:suq/features/refunds/data/refunds_remote.dart';
import 'package:suq/features/refunds/domain/refunds_repository.dart';

// Native repo tests never touch the remote (db != null), so a no-op stub is
// enough. Implements the concrete RefundsRemote as an interface.
class _StubRefundsRemote implements RefundsRemote {
  @override
  Future<Map<String, Decimal>> refundedQtyBySaleItem(String saleId) async => {};

  @override
  Future<void> createRefund({
    required String id,
    required String originalSaleId,
    required String branchId,
    required String refundedBy,
    required String reason,
    required Decimal totalAmount,
    required bool restock,
    required List<({String id, RefundLineInput line})> items,
    required bool useBatches,
  }) async {}
}

AppDatabase _makeDb() => AppDatabase(NativeDatabase.memory());

const branchId = 'b-1';
const userId = 'u-1';
Decimal d(String s) => Decimal.parse(s);

Future<void> _seedSale(AppDatabase db,
    {required String saleId,
    required String itemId,
    required Decimal qty,
    required Decimal total}) async {
  await db.insertSaleWithItems(
    LocalSalesCompanion(
      id: Value(saleId),
      branchId: const Value(branchId),
      cashierId: const Value(userId),
      paymentMethodId: const Value('pm-1'),
      subtotal: Value(total),
      discountAmount: Value(Decimal.zero),
      total: Value(total),
      status: const Value('completed'),
      isCredit: const Value(false),
      createdAt: Value(DateTime.now()),
      isSynced: const Value(true),
    ),
    [
      LocalSaleItemsCompanion(
        id: Value(itemId),
        saleId: Value(saleId),
        productId: const Value('p-1'),
        productNameSnapshot: const Value('Widget'),
        quantity: Value(qty),
        unitPrice: Value(Decimal.zero), // unused by these tests
        discountAmount: Value(Decimal.zero),
        total: Value(total),
        inventoryStatus: const Value('tracked'),
      ),
    ],
  );
}

void main() {
  late AppDatabase db;
  late RefundsRepository repo;

  setUp(() {
    db = _makeDb();
    repo = RefundsRepository(_StubRefundsRemote(), db);
  });
  tearDown(() => db.close());

  test('records a partial refund and exposes refunded qty per line', () async {
    await _seedSale(db, saleId: 's-1', itemId: 'si-1', qty: d('4'), total: d('20'));

    await repo.createRefund(
      originalSaleId: 's-1',
      branchId: branchId,
      refundedBy: userId,
      reason: 'damaged',
      restock: false,
      lines: [
        (
          saleItemId: 'si-1',
          productId: 'p-1',
          quantity: d('2'),
          amount: d('10'),
          soldQuantity: d('4')
        )
      ],
      useBatches: false,
    );

    final refunded = await repo.refundedQtyBySaleItem('s-1');
    expect(refunded['si-1'], d('2'));

    final pending = await db.getPendingRefunds();
    expect(pending.length, 1);
    expect(pending.first.isSynced, false);
    expect(pending.first.totalAmount, d('10'));
  });

  test('refunded qty accumulates across multiple refunds (over-refund cap)',
      () async {
    await _seedSale(db, saleId: 's-1', itemId: 'si-1', qty: d('5'), total: d('25'));

    for (final q in ['2', '1']) {
      await repo.createRefund(
        originalSaleId: 's-1',
        branchId: branchId,
        refundedBy: userId,
        reason: 'r',
        restock: false,
        lines: [
          (
            saleItemId: 'si-1',
            productId: 'p-1',
            quantity: d(q),
            amount: d(q),
            soldQuantity: d('5')
          )
        ],
        useBatches: false,
      );
    }

    final refunded = await repo.refundedQtyBySaleItem('s-1');
    expect(refunded['si-1'], d('3')); // 2 + 1 → remaining-refundable = 5 − 3 = 2
  });

  test('retail restock bumps stock optimistically (RPC applies on push)',
      () async {
    await db.setStockLevel(branchId, 'p-1', d('10'));
    await _seedSale(db, saleId: 's-1', itemId: 'si-1', qty: d('4'), total: d('20'));

    await repo.createRefund(
      originalSaleId: 's-1',
      branchId: branchId,
      refundedBy: userId,
      reason: 'returned',
      restock: true,
      lines: [
        (
          saleItemId: 'si-1',
          productId: 'p-1',
          quantity: d('2'),
          amount: d('10'),
          soldQuantity: d('4')
        )
      ],
      useBatches: false,
    );

    // Local stock reflects the return immediately; the authoritative
    // inventory_adjustment is created server-side by the refund RPC on push, so
    // there is no local adjustment row to push separately.
    expect(await db.getStockLevel(branchId, 'p-1'), d('12'));
    expect(await db.getPendingInventoryAdjustments(), isEmpty);
  });

  test('no restock leaves stock untouched', () async {
    await db.setStockLevel(branchId, 'p-1', d('10'));
    await _seedSale(db, saleId: 's-1', itemId: 'si-1', qty: d('4'), total: d('20'));

    await repo.createRefund(
      originalSaleId: 's-1',
      branchId: branchId,
      refundedBy: userId,
      reason: 'damaged',
      restock: false,
      lines: [
        (
          saleItemId: 'si-1',
          productId: 'p-1',
          quantity: d('2'),
          amount: d('10'),
          soldQuantity: d('4')
        )
      ],
      useBatches: false,
    );

    expect(await db.getStockLevel(branchId, 'p-1'), d('10'));
    expect(await db.getPendingInventoryAdjustments(), isEmpty);
  });

  test('wholesale restock returns units to the drawn lot via a negative adjustment',
      () async {
    // A lot of 10, the sale drew 4 from it.
    await db.upsertProductBatches([
      LocalProductBatchesCompanion(
        id: const Value('lot-1'),
        branchId: const Value(branchId),
        productId: const Value('p-1'),
        quantity: Value(d('10')),
        receivedAt: Value(DateTime.now()),
        syncedAt: Value(DateTime.now()),
        isSynced: const Value(true),
      )
    ]);
    await _seedSale(db, saleId: 's-1', itemId: 'si-1', qty: d('4'), total: d('20'));
    await db.upsertSaleItemBatches([
      LocalSaleItemBatchesCompanion(
        id: const Value('sib-1'),
        saleItemId: const Value('si-1'),
        batchId: const Value('lot-1'),
        quantity: Value(d('4')),
        syncedAt: Value(DateTime.now()),
      )
    ]);
    await db.recomputeStockFromBatches(branchId, 'p-1', DateTime.now());
    expect(await db.getStockLevel(branchId, 'p-1'), d('6')); // 10 − 4

    await repo.createRefund(
      originalSaleId: 's-1',
      branchId: branchId,
      refundedBy: userId,
      reason: 'returned',
      restock: true,
      lines: [
        (
          saleItemId: 'si-1',
          productId: 'p-1',
          quantity: d('2'),
          amount: d('10'),
          soldQuantity: d('4')
        )
      ],
      useBatches: true,
    );

    // Two units returned to lot-1 → rollup back up to 8.
    expect(await db.getStockLevel(branchId, 'p-1'), d('8'));
    final adjusted = await db.adjustmentByBatch(['lot-1']);
    expect(adjusted['lot-1'], d('-2')); // negative delta = added back

    // The restock row is linked to the refund (so the push can gather it) and
    // marked synced so the generic batch-adjustment push skips it.
    final refunds = await db.getPendingRefunds();
    final linked = await db.getRefundRestockAdjustments(refunds.first.id);
    expect(linked.length, 1);
    expect(linked.first.batchId, 'lot-1');
    final genericPending = await db.getPendingBatchAdjustments();
    expect(genericPending, isEmpty);
  });

  test('rejects a refund that exceeds remaining-refundable (domain guard)',
      () async {
    await _seedSale(db, saleId: 's-1', itemId: 'si-1', qty: d('4'), total: d('20'));
    // Already refunded 3 of 4.
    await repo.createRefund(
      originalSaleId: 's-1',
      branchId: branchId,
      refundedBy: userId,
      reason: 'first',
      restock: false,
      lines: [
        (
          saleItemId: 'si-1',
          productId: 'p-1',
          quantity: d('3'),
          amount: d('15'),
          soldQuantity: d('4')
        )
      ],
      useBatches: false,
    );

    // Asking for 2 more (3 + 2 > 4) must be rejected.
    await expectLater(
      () => repo.createRefund(
        originalSaleId: 's-1',
        branchId: branchId,
        refundedBy: userId,
        reason: 'too much',
        restock: false,
        lines: [
          (
            saleItemId: 'si-1',
            productId: 'p-1',
            quantity: d('2'),
            amount: d('10'),
            soldQuantity: d('4')
          )
        ],
        useBatches: false,
      ),
      throwsA(isA<StateError>()),
    );
    // The rejected refund left no trace beyond the first.
    final refunded = await repo.refundedQtyBySaleItem('s-1');
    expect(refunded['si-1'], d('3'));
  });

  test('wholesale restock fails when the depletion ledger is missing', () async {
    // Lot + sale exist, but NO sale_item_batches depletion was recorded.
    await db.upsertProductBatches([
      LocalProductBatchesCompanion(
        id: const Value('lot-1'),
        branchId: const Value(branchId),
        productId: const Value('p-1'),
        quantity: Value(d('10')),
        receivedAt: Value(DateTime.now()),
        syncedAt: Value(DateTime.now()),
        isSynced: const Value(true),
      )
    ]);
    await _seedSale(db, saleId: 's-1', itemId: 'si-1', qty: d('4'), total: d('20'));

    await expectLater(
      () => repo.createRefund(
        originalSaleId: 's-1',
        branchId: branchId,
        refundedBy: userId,
        reason: 'returned',
        restock: true,
        lines: [
          (
            saleItemId: 'si-1',
            productId: 'p-1',
            quantity: d('2'),
            amount: d('10'),
            soldQuantity: d('4')
          )
        ],
        useBatches: true,
      ),
      throwsA(isA<StateError>()),
    );
    // Transaction rolled back: no refund recorded.
    expect(await db.getPendingRefunds(), isEmpty);
  });

  test(
      'two refund lines from the same lot produce two distinct batch_adjustment ids',
      () async {
    // Regression for CodeRabbit B1: if the RPC aggregates p_batch_adjustments
    // by batch_id before inserting, only one of the two client UUIDs survives
    // and the other local row dangles (double-counting the negative adjustment).
    await db.upsertProductBatches([
      LocalProductBatchesCompanion(
        id: const Value('lot-1'),
        branchId: const Value(branchId),
        productId: const Value('p-1'),
        quantity: Value(d('20')),
        receivedAt: Value(DateTime.now()),
        syncedAt: Value(DateTime.now()),
        isSynced: const Value(true),
      )
    ]);
    // Sale with two lines, both drawing from lot-1.
    await db.insertSaleWithItems(
      LocalSalesCompanion(
        id: const Value('s-1'),
        branchId: const Value(branchId),
        cashierId: const Value(userId),
        paymentMethodId: const Value('pm-1'),
        subtotal: Value(d('35')),
        discountAmount: Value(Decimal.zero),
        total: Value(d('35')),
        status: const Value('completed'),
        isCredit: const Value(false),
        createdAt: Value(DateTime.now()),
        isSynced: const Value(true),
      ),
      [
        LocalSaleItemsCompanion(
          id: const Value('si-1'),
          saleId: const Value('s-1'),
          productId: const Value('p-1'),
          productNameSnapshot: const Value('Widget'),
          quantity: Value(d('3')),
          unitPrice: Value(Decimal.zero),
          discountAmount: Value(Decimal.zero),
          total: Value(d('15')),
          inventoryStatus: const Value('tracked'),
        ),
        LocalSaleItemsCompanion(
          id: const Value('si-2'),
          saleId: const Value('s-1'),
          productId: const Value('p-1'),
          productNameSnapshot: const Value('Widget'),
          quantity: Value(d('4')),
          unitPrice: Value(Decimal.zero),
          discountAmount: Value(Decimal.zero),
          total: Value(d('20')),
          inventoryStatus: const Value('tracked'),
        ),
      ],
    );
    await db.upsertSaleItemBatches([
      LocalSaleItemBatchesCompanion(
        id: const Value('sib-1'),
        saleItemId: const Value('si-1'),
        batchId: const Value('lot-1'),
        quantity: Value(d('3')),
        syncedAt: Value(DateTime.now()),
      ),
      LocalSaleItemBatchesCompanion(
        id: const Value('sib-2'),
        saleItemId: const Value('si-2'),
        batchId: const Value('lot-1'),
        quantity: Value(d('4')),
        syncedAt: Value(DateTime.now()),
      ),
    ]);

    await repo.createRefund(
      originalSaleId: 's-1',
      branchId: branchId,
      refundedBy: userId,
      reason: 'returned',
      restock: true,
      lines: [
        (
          saleItemId: 'si-1',
          productId: 'p-1',
          quantity: d('3'),
          amount: d('15'),
          soldQuantity: d('3')
        ),
        (
          saleItemId: 'si-2',
          productId: 'p-1',
          quantity: d('4'),
          amount: d('20'),
          soldQuantity: d('4')
        ),
      ],
      useBatches: true,
    );

    final refunds = await db.getPendingRefunds();
    final linked = await db.getRefundRestockAdjustments(refunds.first.id);

    // Both lines produce their own restock row — same batch_id, distinct ids.
    expect(linked.length, 2);
    expect(linked.every((r) => r.batchId == 'lot-1'), isTrue);
    final ids = linked.map((r) => r.id).toSet();
    expect(ids.length, 2, reason: 'each restock row must have a unique client id');
  });

  test('getRefundTotalByBranchRange sums non-deleted refunds in range', () async {
    await _seedSale(db, saleId: 's-1', itemId: 'si-1', qty: d('4'), total: d('20'));
    await repo.createRefund(
      originalSaleId: 's-1',
      branchId: branchId,
      refundedBy: userId,
      reason: 'r',
      restock: false,
      lines: [
        (
          saleItemId: 'si-1',
          productId: 'p-1',
          quantity: d('2'),
          amount: d('10'),
          soldQuantity: d('4')
        )
      ],
      useBatches: false,
    );

    final from = DateTime.now().subtract(const Duration(days: 1));
    final to = DateTime.now().add(const Duration(days: 1));
    expect(await db.getRefundTotalByBranchRange(branchId, from, to), d('10'));
  });
}
