import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suq/data/local/app_database.dart';
import 'package:suq/data/local/seed_service.dart';

void main() {
  group('SeedService.partitionDelta', () {
    Map<String, dynamic> row(String id, String updatedAt, {String? deletedAt}) =>
        {'id': id, 'updated_at': updatedAt, 'deleted_at': deletedAt};

    test('empty page yields nothing and a null cursor', () {
      final p = SeedService.partitionDelta([], collectDead: true);
      expect(p.live, isEmpty);
      expect(p.deadIds, isEmpty);
      expect(p.maxSeen, isNull);
    });

    test('splits live rows from soft-deletes and advances cursor to the max',
        () {
      final rows = [
        row('a', '2026-06-14T10:00:00Z'),
        row('b', '2026-06-14T12:00:00Z', deletedAt: '2026-06-14T12:00:00Z'),
        row('c', '2026-06-14T11:00:00Z'),
      ];
      final p = SeedService.partitionDelta(rows, collectDead: true);
      expect(p.live.map((r) => r['id']), ['a', 'c']);
      expect(p.deadIds, ['b']);
      // maxSeen spans ALL rows, including the deleted one.
      expect(p.maxSeen, DateTime.parse('2026-06-14T12:00:00Z'));
    });

    test('collectDead=false drops dead rows from live but still advances cursor',
        () {
      // A soft-delete on a no-removal table must still move the cursor past it,
      // or the delta pull would re-fetch it forever.
      final rows = [
        row('a', '2026-06-14T10:00:00Z'),
        row('b', '2026-06-14T13:00:00Z', deletedAt: '2026-06-14T13:00:00Z'),
      ];
      final p = SeedService.partitionDelta(rows, collectDead: false);
      expect(p.live.map((r) => r['id']), ['a']);
      expect(p.deadIds, isEmpty);
      expect(p.maxSeen, DateTime.parse('2026-06-14T13:00:00Z'));
    });

    test('a malformed updated_at is skipped, never thrown', () {
      // Guards against a poison row stalling a table's pull forever: the bad
      // timestamp is ignored for the cursor, valid rows still advance it.
      final rows = [
        row('a', 'not-a-timestamp'),
        row('b', '2026-06-14T10:00:00Z'),
      ];
      expect(() => SeedService.partitionDelta(rows, collectDead: true),
          returnsNormally);
      final p = SeedService.partitionDelta(rows, collectDead: true);
      expect(p.live.map((r) => r['id']), ['a', 'b']);
      expect(p.maxSeen, DateTime.parse('2026-06-14T10:00:00Z'));
    });

    test('rows sharing the boundary timestamp resolve to that one cursor', () {
      // Postgres now() is constant per transaction, so a sale + its items share
      // an updated_at; the cursor lands on that shared value (>= overlap then
      // re-fetches them harmlessly).
      final rows = [
        row('a', '2026-06-14T09:30:00Z'),
        row('b', '2026-06-14T09:30:00Z'),
      ];
      final p = SeedService.partitionDelta(rows, collectDead: true);
      expect(p.maxSeen, DateTime.parse('2026-06-14T09:30:00Z'));
      expect(p.live.length, 2);
    });
  });

  test('guardrail: SeedService never pulls operator/admin tables', () {
    // Enforces the documented boundary — license/operator tables must never be
    // replicated. Checks actual table-access calls, not the doc comment.
    // NOTE: lightweight guardrail, not a security boundary — a literal-string
    // scan can be bypassed by dynamic table-name construction. The real wall is
    // server-side RLS (see rls_isolation_test.sql); this just catches the
    // obvious mistake of adding from('license_keys') during a refactor.
    final src =
        File('lib/data/local/seed_service.dart').readAsStringSync();
    expect(src.contains("from('license_keys')"), isFalse,
        reason: 'license_keys must never be pulled into the replica');
    expect(src.contains("from('shop_controls')"), isFalse,
        reason: 'shop_controls must never be pulled into the replica');
  });

  test(
      'stock pull preserves local stock with pending batches, adjustments, and refund restocks',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final now = DateTime(2026, 6, 23);

    Future<void> stock(String productId, String qty) => db.upsertStock([
          LocalStockCompanion(
            productId: Value(productId),
            branchId: const Value('b-1'),
            quantity: Value(Decimal.parse(qty)),
            syncedAt: Value(now),
          ),
        ]);

    await stock('p-batch', '10');
    await stock('p-adjustment', '20');
    await stock('p-refund', '30');
    await stock('p-remote', '40');

    await db.upsertProductBatches([
      LocalProductBatchesCompanion(
        id: const Value('batch-pending'),
        branchId: const Value('b-1'),
        productId: const Value('p-batch'),
        batchNumber: const Value('LOT-1'),
        quantity: Value(Decimal.parse('10')),
        receivedAt: Value(now),
        syncedAt: Value(now),
        isSynced: const Value(false),
      ),
      LocalProductBatchesCompanion(
        id: const Value('batch-adjusted'),
        branchId: const Value('b-1'),
        productId: const Value('p-adjustment'),
        batchNumber: const Value('LOT-2'),
        quantity: Value(Decimal.parse('20')),
        receivedAt: Value(now),
        syncedAt: Value(now),
      ),
    ]);
    await db.upsertBatchAdjustments([
      LocalBatchAdjustmentsCompanion(
        id: const Value('adjustment-pending'),
        batchId: const Value('batch-adjusted'),
        branchId: const Value('b-1'),
        productId: const Value('p-adjustment'),
        quantityDelta: Value(Decimal.one),
        reason: const Value('count'),
        createdAt: Value(now),
        syncedAt: Value(now),
        isSynced: const Value(false),
      ),
    ]);
    await db.insertSaleWithItems(
      LocalSalesCompanion(
        id: const Value('sale-refund'),
        branchId: const Value('b-1'),
        cashierId: const Value('u-1'),
        paymentMethodId: const Value('pm-1'),
        subtotal: Value(Decimal.parse('30')),
        discountAmount: Value(Decimal.zero),
        total: Value(Decimal.parse('30')),
        status: const Value('completed'),
        isCredit: const Value(false),
        createdAt: Value(now),
        isSynced: const Value(true),
      ),
      [
        LocalSaleItemsCompanion(
          id: const Value('sale-item-refund'),
          saleId: const Value('sale-refund'),
          productId: const Value('p-refund'),
          productNameSnapshot: const Value('Refunded product'),
          quantity: Value(Decimal.one),
          unitPrice: Value(Decimal.parse('30')),
          discountAmount: Value(Decimal.zero),
          total: Value(Decimal.parse('30')),
          inventoryStatus: const Value('tracked'),
        ),
      ],
    );
    await db.insertRefundWithItems(
      LocalRefundsCompanion(
        id: const Value('refund-pending'),
        originalSaleId: const Value('sale-refund'),
        branchId: const Value('b-1'),
        refundedBy: const Value('u-1'),
        reason: const Value('returned'),
        totalAmount: Value(Decimal.parse('30')),
        restock: const Value(true),
        createdAt: Value(now),
        syncedAt: Value(now),
        isSynced: const Value(false),
      ),
      [
        LocalRefundItemsCompanion(
          id: const Value('refund-item-pending'),
          refundId: const Value('refund-pending'),
          saleItemId: const Value('sale-item-refund'),
          quantity: Value(Decimal.one),
          amount: Value(Decimal.parse('30')),
          syncedAt: Value(now),
        ),
      ],
    );

    await SeedService.applyStockRowsForTest(
      db,
      'b-1',
      [
        {'product_id': 'p-batch', 'quantity': '1'},
        {'product_id': 'p-adjustment', 'quantity': '2'},
        {'product_id': 'p-refund', 'quantity': '3'},
        {'product_id': 'p-remote', 'quantity': '4'},
      ],
      now,
    );

    expect(await db.getStockLevel('b-1', 'p-batch'), Decimal.parse('10'));
    expect(
      await db.getStockLevel('b-1', 'p-adjustment'),
      Decimal.parse('20'),
    );
    expect(await db.getStockLevel('b-1', 'p-refund'), Decimal.parse('30'));
    expect(await db.getStockLevel('b-1', 'p-remote'), Decimal.parse('4'));
  });
}
