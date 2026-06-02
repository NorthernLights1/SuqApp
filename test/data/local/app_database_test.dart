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

    test('getTodayTotals excludes voided sales', () async {
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
      // Voided sale — should not count
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
      expect(totals['total'], Decimal.parse('100'));
      expect(totals['count'], Decimal.parse('1'));
    });
  });
}
