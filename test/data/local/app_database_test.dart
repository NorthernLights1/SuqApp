import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suq/data/local/app_database.dart';

AppDatabase _makeDb() => AppDatabase(NativeDatabase.memory());

void main() {
  late AppDatabase db;

  setUp(() => db = _makeDb());
  tearDown(() => db.close());

  // ── Products ──────────────────────────────────────────────────────────────

  group('products', () {
    Future<void> seedProduct({
      String id = 'p-1',
      String shopId = 'shop-1',
      String name = 'Bread',
    }) =>
        db.upsertProducts([
          LocalProductsCompanion(
            id: Value(id),
            shopId: Value(shopId),
            name: Value(name),
            measurementUnitId: const Value('mu-1'),
            measurementUnitAbbr: const Value('pc'),
            lowStockThreshold: Value(Decimal.parse('10')),
            isActive: const Value(true),
            syncedAt: Value(DateTime.now()),
          )
        ]);

    test('upsert and retrieve by shop', () async {
      await seedProduct();
      final rows = await db.getProductsByShop('shop-1');
      expect(rows.length, 1);
      expect(rows.first.name, 'Bread');
    });

    test('search is case-insensitive for ASCII', () async {
      await seedProduct(name: 'Teff Flour');
      final results = await db.searchProducts('shop-1', 'teff');
      expect(results.length, 1);
    });

    test('upsert updates existing row', () async {
      await seedProduct();
      await db.upsertProducts([
        LocalProductsCompanion(
          id: const Value('p-1'),
          shopId: const Value('shop-1'),
          name: const Value('Wheat Bread'),
          measurementUnitId: const Value('mu-1'),
          measurementUnitAbbr: const Value('pc'),
          lowStockThreshold: Value(Decimal.parse('10')),
          isActive: const Value(true),
          syncedAt: Value(DateTime.now()),
        )
      ]);
      final rows = await db.getProductsByShop('shop-1');
      expect(rows.length, 1);
      expect(rows.first.name, 'Wheat Bread');
    });
  });

  // ── Stock ─────────────────────────────────────────────────────────────────

  group('stock', () {
    test('upsert and get stock level', () async {
      await db.upsertStock([
        LocalStockCompanion(
          productId: const Value('p-1'),
          branchId: const Value('b-1'),
          quantity: Value(Decimal.parse('50')),
          syncedAt: Value(DateTime.now()),
        )
      ]);
      final qty = await db.getStockLevel('b-1', 'p-1');
      expect(qty, Decimal.parse('50'));
    });

    test('adjust stock updates quantity', () async {
      await db.upsertStock([
        LocalStockCompanion(
          productId: const Value('p-1'),
          branchId: const Value('b-1'),
          quantity: Value(Decimal.parse('20')),
          syncedAt: Value(DateTime.now()),
        )
      ]);
      await db.adjustStock('b-1', 'p-1', Decimal.parse('15'));
      final qty = await db.getStockLevel('b-1', 'p-1');
      expect(qty, Decimal.parse('15'));
    });

    test('stock expiry date survives the local cache', () async {
      final expiry = DateTime(2026, 7, 1);
      await db.setStockLevel(
        'b-1',
        'p-1',
        Decimal.parse('12'),
        expiryDate: expiry,
      );

      final row = (await db.getStockByBranch('b-1')).single;
      expect(row.expiryDate, expiry);
    });
  });

  // ── Sales ─────────────────────────────────────────────────────────────────

  group('sales', () {
    Future<SaleRow> insertSale({
      String id = 'sale-1',
      String branchId = 'b-1',
      bool isSynced = false,
    }) =>
        db.insertSaleWithItems(
          LocalSalesCompanion(
            id: Value(id),
            branchId: Value(branchId),
            cashierId: const Value('user-1'),
            paymentMethodId: const Value('pm-1'),
            subtotal: Value(Decimal.parse('100')),
            discountAmount: Value(Decimal.zero),
            total: Value(Decimal.parse('100')),
            status: const Value('completed'),
            isCredit: const Value(false),
            createdAt: Value(DateTime.now()),
            isSynced: Value(isSynced),
          ),
          [
            LocalSaleItemsCompanion(
              id: Value('${id}_item-1'),
              saleId: Value(id),
              productNameSnapshot: const Value('Bread'),
              quantity: Value(Decimal.parse('2')),
              unitPrice: Value(Decimal.parse('50')),
              discountAmount: Value(Decimal.zero),
              total: Value(Decimal.parse('100')),
              inventoryStatus: const Value('untracked'),
            ),
          ],
        );

    test('inserts sale and retrieves items', () async {
      final row = await insertSale();
      expect(row.id, 'sale-1');
      final items = await db.getSaleItems('sale-1');
      expect(items.length, 1);
      expect(items.first.productNameSnapshot, 'Bread');
    });

    test('getSale returns the row', () async {
      await insertSale();
      final row = await db.getSale('sale-1');
      expect(row, isNotNull);
      expect(row!.total, Decimal.parse('100'));
    });

    test('getPendingSales returns only unsynced rows', () async {
      await insertSale(id: 'sale-1', isSynced: false);
      await insertSale(id: 'sale-2', isSynced: true);
      final pending = await db.getPendingSales();
      expect(pending.length, 1);
      expect(pending.first.id, 'sale-1');
    });

    test('markSaleSynced clears pending flag', () async {
      await insertSale();
      await db.markSaleSynced('sale-1');
      final pending = await db.getPendingSales();
      expect(pending, isEmpty);
    });

    test('pending tracked sales protect optimistic stock from pulls', () async {
      await db.insertSaleWithItems(
        LocalSalesCompanion(
          id: const Value('sale-tracked'),
          branchId: const Value('b-1'),
          cashierId: const Value('user-1'),
          paymentMethodId: const Value('pm-1'),
          subtotal: Value(Decimal.parse('20')),
          discountAmount: Value(Decimal.zero),
          total: Value(Decimal.parse('20')),
          status: const Value('completed'),
          isCredit: const Value(false),
          createdAt: Value(DateTime.now()),
          isSynced: const Value(false),
        ),
        [
          LocalSaleItemsCompanion(
            id: const Value('item-tracked'),
            saleId: const Value('sale-tracked'),
            productId: const Value('p-tracked'),
            productNameSnapshot: const Value('Tracked product'),
            quantity: Value(Decimal.one),
            unitPrice: Value(Decimal.parse('20')),
            discountAmount: Value(Decimal.zero),
            total: Value(Decimal.parse('20')),
            inventoryStatus: const Value('tracked'),
          ),
        ],
      );

      expect(
        await db.getPendingStockProductIds('b-1'),
        contains('p-tracked'),
      );

      await db.markSaleSynced('sale-tracked');
      expect(
        await db.getPendingStockProductIds('b-1'),
        isNot(contains('p-tracked')),
      );
    });

    test('markSaleVoided updates status', () async {
      await insertSale();
      await db.markSaleVoided('sale-1', 'wrong item', 'user-1');
      final row = await db.getSale('sale-1');
      expect(row!.status, 'voided');
      expect(row.voidReason, 'wrong item');
    });

    test('getTodayTotals sums completed sales', () async {
      await insertSale(id: 'sale-1');
      final totals = await db.getTodayTotals('b-1', DateTime.now());
      expect(totals['total'], Decimal.parse('100'));
      expect(totals['count'], Decimal.parse('1'));
    });
  });

  // ── Customers ─────────────────────────────────────────────────────────────

  group('customers', () {
    test('upsert and search', () async {
      await db.upsertCustomers([
        LocalCustomersCompanion(
          id: const Value('c-1'),
          shopId: const Value('shop-1'),
          name: const Value('Abebe Kebede'),
          creditBalance: Value(Decimal.zero),
          updatedAt: Value(DateTime.now()),
        )
      ]);
      final results = await db.searchCustomers('shop-1', 'abebe');
      expect(results.length, 1);
      expect(results.first.name, 'Abebe Kebede');
    });
  });

  // ── Edge cases ────────────────────────────────────────────────────────────

  group('stock edge cases', () {
    test('getStockLevel returns null when no record exists', () async {
      final qty = await db.getStockLevel('b-1', 'nonexistent-product');
      expect(qty, isNull);
    });

    test('adjustStock is a no-op when row does not exist', () async {
      // Should not throw even when the row is missing
      await db.adjustStock('b-1', 'ghost', Decimal.parse('5'));
      final qty = await db.getStockLevel('b-1', 'ghost');
      expect(qty, isNull);
    });

    test('upsert stock overwrites previous quantity', () async {
      await db.upsertStock([
        LocalStockCompanion(
          productId: const Value('p-1'),
          branchId: const Value('b-1'),
          quantity: Value(Decimal.parse('10')),
          syncedAt: Value(DateTime.now()),
        )
      ]);
      await db.upsertStock([
        LocalStockCompanion(
          productId: const Value('p-1'),
          branchId: const Value('b-1'),
          quantity: Value(Decimal.parse('25')),
          syncedAt: Value(DateTime.now()),
        )
      ]);
      expect(await db.getStockLevel('b-1', 'p-1'), Decimal.parse('25'));
    });
  });

  group('product edge cases', () {
    test('searchProducts returns empty when no match', () async {
      await db.upsertProducts([
        LocalProductsCompanion(
          id: const Value('p-1'),
          shopId: const Value('shop-1'),
          name: const Value('Salt'),
          measurementUnitId: const Value('mu-1'),
          measurementUnitAbbr: const Value('g'),
          lowStockThreshold: Value(Decimal.parse('50')),
          isActive: const Value(true),
          syncedAt: Value(DateTime.now()),
        )
      ]);
      final results = await db.searchProducts('shop-1', 'teff');
      expect(results, isEmpty);
    });

    test('inactive products are excluded from search', () async {
      await db.upsertProducts([
        LocalProductsCompanion(
          id: const Value('p-2'),
          shopId: const Value('shop-1'),
          name: const Value('Old Product'),
          measurementUnitId: const Value('mu-1'),
          measurementUnitAbbr: const Value('pc'),
          lowStockThreshold: Value(Decimal.parse('1')),
          isActive: const Value(false),
          syncedAt: Value(DateTime.now()),
        )
      ]);
      final results = await db.searchProducts('shop-1', 'old');
      expect(results, isEmpty);
    });

    test('multiple products from same shop returned in name order', () async {
      for (final name in ['Zebra', 'Apple', 'Mango']) {
        await db.upsertProducts([
          LocalProductsCompanion(
            id: Value('p-$name'),
            shopId: const Value('shop-1'),
            name: Value(name),
            measurementUnitId: const Value('mu-1'),
            measurementUnitAbbr: const Value('pc'),
            lowStockThreshold: Value(Decimal.parse('5')),
            isActive: const Value(true),
            syncedAt: Value(DateTime.now()),
          )
        ]);
      }
      final rows = await db.getProductsByShop('shop-1');
      expect(rows.map((r) => r.name).toList(), ['Apple', 'Mango', 'Zebra']);
    });
  });

  group('sales edge cases', () {
    test('getSale returns null for nonexistent id', () async {
      final row = await db.getSale('nonexistent');
      expect(row, isNull);
    });

    test('getSalesByBranch respects date range', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final tomorrow = DateTime.now().add(const Duration(days: 1));

      // Sale yesterday — outside range
      await db.insertSaleWithItems(
        LocalSalesCompanion(
          id: const Value('s-old'),
          branchId: const Value('b-1'),
          cashierId: const Value('user-1'),
          paymentMethodId: const Value('pm-1'),
          subtotal: Value(Decimal.parse('50')),
          discountAmount: Value(Decimal.zero),
          total: Value(Decimal.parse('50')),
          status: const Value('completed'),
          isCredit: const Value(false),
          createdAt: Value(yesterday.subtract(const Duration(hours: 1))),
          isSynced: const Value(true),
        ),
        [],
      );

      // Sale today — inside range
      await db.insertSaleWithItems(
        LocalSalesCompanion(
          id: const Value('s-now'),
          branchId: const Value('b-1'),
          cashierId: const Value('user-1'),
          paymentMethodId: const Value('pm-1'),
          subtotal: Value(Decimal.parse('100')),
          discountAmount: Value(Decimal.zero),
          total: Value(Decimal.parse('100')),
          status: const Value('completed'),
          isCredit: const Value(false),
          createdAt: Value(DateTime.now()),
          isSynced: const Value(false),
        ),
        [],
      );

      final rows =
          await db.getSalesByBranch('b-1', yesterday, tomorrow);
      expect(rows.length, 1);
      expect(rows.first.id, 's-now');
    });

    test('getPendingSales excludes already-synced sales', () async {
      for (final synced in [true, false, false]) {
        await db.insertSaleWithItems(
          LocalSalesCompanion(
            id: Value('s-${synced ? 'synced' : 'pending-${DateTime.now().microsecondsSinceEpoch}'}'),
            branchId: const Value('b-1'),
            cashierId: const Value('user-1'),
            paymentMethodId: const Value('pm-1'),
            subtotal: Value(Decimal.zero),
            discountAmount: Value(Decimal.zero),
            total: Value(Decimal.zero),
            status: const Value('completed'),
            isCredit: const Value(false),
            createdAt: Value(DateTime.now()),
            isSynced: Value(synced),
          ),
          [],
        );
      }
      final pending = await db.getPendingSales();
      expect(pending.length, 2);
    });

    test('getTodayTotals excludes voided sales from revenue but still counts them',
        () async {
      // Completed sale
      await db.insertSaleWithItems(
        LocalSalesCompanion(
          id: const Value('s-completed'),
          branchId: const Value('b-1'),
          cashierId: const Value('user-1'),
          paymentMethodId: const Value('pm-1'),
          subtotal: Value(Decimal.parse('100')),
          discountAmount: Value(Decimal.zero),
          total: Value(Decimal.parse('100')),
          status: const Value('completed'),
          isCredit: const Value(false),
          createdAt: Value(DateTime.now()),
          isSynced: const Value(true),
        ),
        [],
      );
      // Voided sale — excluded from revenue, but a voided sale still happened
      // so it stays in the day's transaction tally (see getTodayTotals).
      await db.insertSaleWithItems(
        LocalSalesCompanion(
          id: const Value('s-voided'),
          branchId: const Value('b-1'),
          cashierId: const Value('user-1'),
          paymentMethodId: const Value('pm-1'),
          subtotal: Value(Decimal.parse('200')),
          discountAmount: Value(Decimal.zero),
          total: Value(Decimal.parse('200')),
          status: const Value('voided'),
          isCredit: const Value(false),
          createdAt: Value(DateTime.now()),
          isSynced: const Value(true),
        ),
        [],
      );
      final totals = await db.getTodayTotals('b-1', DateTime.now());
      expect(totals['total'], Decimal.parse('100')); // revenue excludes voided
      expect(totals['count'], Decimal.parse('2')); // tally keeps voided
    });
  });

  // ── Sync state (delta-pull cursors) ─────────────────────────────────────────

  group('sync state cursors', () {
    test('getPullCursor is null before any pull', () async {
      expect(await db.getPullCursor('sales'), isNull);
    });

    test('setPullCursor round-trips and advances per table', () async {
      // Drift stores DateTime as a Unix instant and reads it back in local
      // representation, so compare by moment (isAtSameMomentAs), not ==.
      final t1 = DateTime.utc(2026, 6, 14, 10, 0, 0);
      final t2 = DateTime.utc(2026, 6, 14, 12, 30, 0);

      await db.setPullCursor('sales', t1);
      expect((await db.getPullCursor('sales'))!.isAtSameMomentAs(t1), isTrue);
      // Other tables stay independent (null until set).
      expect(await db.getPullCursor('customers'), isNull);

      // Advancing the same table overwrites, not duplicates.
      await db.setPullCursor('sales', t2);
      expect((await db.getPullCursor('sales'))!.isAtSameMomentAs(t2), isTrue);
    });
  });

  // ── deleteByIds (delta soft-delete removal) ─────────────────────────────────

  group('deleteByIds', () {
    Future<void> seed(String id) => db.upsertProducts([
          LocalProductsCompanion(
            id: Value(id),
            shopId: const Value('s-1'),
            name: Value('P-$id'),
            measurementUnitId: const Value('mu-1'),
            measurementUnitAbbr: const Value('pc'),
            lowStockThreshold: Value(Decimal.zero),
            isActive: const Value(true),
            syncedAt: Value(DateTime.now()),
          )
        ]);

    test('removes only the given ids (and maps the Drift table name)', () async {
      await seed('a');
      await seed('b');
      await db.deleteByIds('local_products', ['a']);
      final rows = await db.getProductsByShop('s-1');
      expect(rows.map((r) => r.id).toList(), ['b']);
    });

    test('empty id list is a no-op', () async {
      await seed('a');
      await db.deleteByIds('local_products', []);
      expect((await db.getProductsByShop('s-1')).length, 1);
    });
  });

  // ── Offline credit settlement ───────────────────────────────────────────────

  group('offline credit settlement', () {
    test('record payments, settle when cleared, queue for push', () async {
      await db.insertSaleWithItems(
        LocalSalesCompanion(
          id: const Value('sale-credit'),
          branchId: const Value('b-1'),
          cashierId: const Value('u-1'),
          paymentMethodId: const Value('pm-1'),
          subtotal: Value(Decimal.parse('100')),
          discountAmount: Value(Decimal.zero),
          total: Value(Decimal.parse('100')),
          status: const Value('completed'),
          isCredit: const Value(true),
          createdAt: Value(DateTime.now()),
          isSynced: const Value(true),
        ),
        [],
      );

      // Partial payment: not settled, queued, summed.
      final settled1 = await db.recordCreditPaymentTxn(
          id: 'pay-1',
          saleId: 'sale-credit',
          customerId: 'c-1',
          saleTotal: Decimal.parse('100'),
          amount: Decimal.parse('40'),
          method: 'cash');
      expect(settled1, isFalse);
      expect((await db.getPaidBySale(['sale-credit']))['sale-credit'],
          Decimal.parse('40'));
      expect((await db.getPendingCreditPayments()).length, 1);
      expect((await db.getSale('sale-credit'))!.creditSettledAt, isNull);

      // Second payment clears it → settles atomically, stamps the uniform method,
      // and flags the sale unsynced so the sale push re-sends the settlement.
      final settled2 = await db.recordCreditPaymentTxn(
          id: 'pay-2',
          saleId: 'sale-credit',
          customerId: 'c-1',
          saleTotal: Decimal.parse('100'),
          amount: Decimal.parse('60'),
          method: 'cash');
      expect(settled2, isTrue);
      final sale = await db.getSale('sale-credit');
      expect(sale!.creditSettledAt, isNotNull);
      expect(sale.creditSettlementMethod, 'cash');
      expect(sale.isSynced, isFalse);
      expect((await db.getPendingCreditPayments()).length, 2);

      // After push, payments drop out of the queue.
      await db.markCreditPaymentSynced('pay-1');
      await db.markCreditPaymentSynced('pay-2');
      expect(await db.getPendingCreditPayments(), isEmpty);
    });
  });
}
