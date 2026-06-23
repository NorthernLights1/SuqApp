// Tests for the stock correction flow.
//
// The correction path is: StockAdjustmentNotifier.correctStock →
//   InventoryRemote.correctStock (Supabase, not testable here) and,
//   for the local enforcement pre-check, AppDatabase.adjustStock (Drift).
//
// These tests cover:
//   1. DB layer — adjustStock as an absolute-quantity setter
//   2. SalesRepository enforcement after a correction is applied to Drift
//   3. Edge cases: correction to zero, correction when no row exists, correction
//      then full-deduction sale, same-product correction + sale
//
// History: previously, InventoryRemote.correctStock inserted 'type':'correction'
// into inventory_adjustments but the DB check constraint only permits
// ('opening_stock','sale','refund','manual','supply_received','void').
// That caused every correction to fail silently with "Correction failed."
// The type was changed to 'manual' to fix it.

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suq/data/local/app_database.dart';
import 'package:suq/domain/models/product.dart';
import 'package:suq/domain/models/sale.dart';
import 'package:suq/features/sales/data/sales_remote.dart';
import 'package:suq/features/sales/domain/sales_repository.dart';

// ── Minimal stub remote ───────────────────────────────────────────────────────

class _StubRemote implements SalesRemote {
  @override
  Future<List<Product>> searchProducts(String s, String q) async => [];
  @override
  Future<List<PaymentMethod>> getPaymentMethods(String s) async => [];
  @override
  Future<List<Customer>> searchCustomers(String s, String q) async => [];
  @override
  Future<Customer> createCustomer(
          {required String shopId, required String name, String? phone}) async =>
      Customer(id: 'c-stub', name: name, creditBalance: Decimal.zero);
  @override
  Future<String> getInventoryMode(String s) async => 'strict';
  @override
  Future<Decimal?> getStockLevel(String b, String p) async => null;
  @override
  Future<Sale> createSale({
    required String id,
    required String branchId,
    required String shopId,
    required String cashierId,
    required String paymentMethodId,
    required List<CartItem> items,
    String? customerId,
    bool isCredit = false,
    String? notes,
    String? discountReason,
    bool useBatches = false,
  }) async =>
      throw Exception('stub');
  @override
  Future<void> voidSale(
          {required String saleId,
          required String voidedBy,
          required String reason,
          required String branchId}) async {}
  @override
  Future<Sale> getSale(String id) async => _fakeSale(id);
  @override
  Future<List<Sale>> getSalesForBranch(
          {required String branchId,
          required DateTime from,
          required DateTime to}) async =>
      [];
  @override
  Future<Map<String, Decimal>> getTodayTotals(String b) async =>
      {'total': Decimal.zero, 'count': Decimal.zero};
}

Sale _fakeSale(String id) => Sale(
      id: id,
      branchId: 'b-1',
      cashierId: 'user-1',
      paymentMethodId: 'pm-1',
      subtotal: Decimal.zero,
      discountAmount: Decimal.zero,
      total: Decimal.zero,
      status: SaleStatus.completed,
      isCredit: false,
      createdAt: DateTime.now(),
    );

// ── Fixtures ──────────────────────────────────────────────────────────────────

AppDatabase _makeDb() => AppDatabase(NativeDatabase.memory());

Future<void> _seedProduct(AppDatabase db, {String id = 'p-1'}) =>
    db.upsertProducts([
      LocalProductsCompanion(
        id: Value(id),
        shopId: const Value('shop-1'),
        name: Value('Product $id'),
        measurementUnitId: const Value('mu-1'),
        measurementUnitAbbr: const Value('pc'),
        lowStockThreshold: Value(Decimal.parse('5')),
        isActive: const Value(true),
        syncedAt: Value(DateTime.now()),
      )
    ]);

Future<void> _seedStock(AppDatabase db,
        {String productId = 'p-1',
        String branchId = 'b-1',
        required Decimal qty}) =>
    db.upsertStock([
      LocalStockCompanion(
        productId: Value(productId),
        branchId: Value(branchId),
        quantity: Value(qty),
        syncedAt: Value(DateTime.now()),
      )
    ]);

CartItem _item({
  String? productId = 'p-1',
  Decimal? quantity,
  Decimal? unitPrice,
}) =>
    CartItem(
      productId: productId,
      productName: 'Product ${productId ?? "custom"}',
      quantity: quantity ?? Decimal.one,
      unitPrice: unitPrice ?? Decimal.parse('50'),
      discountAmount: Decimal.zero,
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  const branchId = 'b-1';
  const shopId = 'shop-1';
  const cashierId = 'user-1';
  const pmId = 'pm-1';

  late AppDatabase db;
  late SalesRepository repo;

  setUp(() {
    db = _makeDb();
    repo = SalesRepository(_StubRemote(), db);
  });

  tearDown(() => db.close());

  // ── 1. DB layer: adjustStock as absolute setter ───────────────────────────

  group('adjustStock — absolute quantity setter', () {
    test('corrects high quantity down to lower value', () async {
      await _seedStock(db, qty: Decimal.parse('100'));
      await db.adjustStock(branchId, 'p-1', Decimal.parse('12'));
      expect(await db.getStockLevel(branchId, 'p-1'), Decimal.parse('12'));
    });

    test('corrects low quantity up to higher value', () async {
      await _seedStock(db, qty: Decimal.parse('3'));
      await db.adjustStock(branchId, 'p-1', Decimal.parse('75'));
      expect(await db.getStockLevel(branchId, 'p-1'), Decimal.parse('75'));
    });

    test('corrects quantity to exactly zero', () async {
      await _seedStock(db, qty: Decimal.parse('30'));
      await db.adjustStock(branchId, 'p-1', Decimal.zero);
      expect(await db.getStockLevel(branchId, 'p-1'), Decimal.zero);
    });

    test('correction is idempotent when value unchanged', () async {
      await _seedStock(db, qty: Decimal.parse('20'));
      await db.adjustStock(branchId, 'p-1', Decimal.parse('20'));
      expect(await db.getStockLevel(branchId, 'p-1'), Decimal.parse('20'));
    });

    test('no-op when product row does not exist', () async {
      // Row has never been seeded — adjustStock must not create a row
      await db.adjustStock(branchId, 'p-ghost', Decimal.parse('50'));
      expect(await db.getStockLevel(branchId, 'p-ghost'), isNull);
    });

    test('correction on one branch does not affect another branch', () async {
      await _seedStock(db, productId: 'p-1', branchId: 'b-1', qty: Decimal.parse('40'));
      await _seedStock(db, productId: 'p-1', branchId: 'b-2', qty: Decimal.parse('40'));

      await db.adjustStock('b-1', 'p-1', Decimal.parse('10'));

      expect(await db.getStockLevel('b-1', 'p-1'), Decimal.parse('10'));
      expect(await db.getStockLevel('b-2', 'p-1'), Decimal.parse('40'));
    });

    test('decimal precision preserved (fractional correction)', () async {
      await _seedStock(db, qty: Decimal.parse('10'));
      await db.adjustStock(branchId, 'p-1', Decimal.parse('3.75'));
      expect(await db.getStockLevel(branchId, 'p-1'), Decimal.parse('3.75'));
    });
  });

  // ── 2. Sale enforcement after correction ─────────────────────────────────

  group('sale enforcement after stock correction', () {
    test('sale blocked when corrected stock is less than sale quantity', () async {
      await _seedProduct(db);
      await _seedStock(db, qty: Decimal.parse('50'));

      // Owner corrects stock down to 5
      await db.adjustStock(branchId, 'p-1', Decimal.parse('5'));

      // Try to sell 20 — must be blocked
      await expectLater(
        repo.createSale(
          branchId: branchId,
          shopId: shopId,
          cashierId: cashierId,
          paymentMethodId: pmId,
          items: [_item(quantity: Decimal.parse('20'))],
        ),
        throwsA(predicate<Exception>((e) =>
            e.toString().contains('Not enough stock') ||
            e.toString().contains('not in inventory'))),
      );
    });

    test('sale allowed when corrected stock exactly equals sale quantity', () async {
      await _seedProduct(db);
      await _seedStock(db, qty: Decimal.parse('50'));

      // Correct down to exactly 8
      await db.adjustStock(branchId, 'p-1', Decimal.parse('8'));

      final sale = await repo.createSale(
        branchId: branchId,
        shopId: shopId,
        cashierId: cashierId,
        paymentMethodId: pmId,
        items: [_item(quantity: Decimal.parse('8'))],
      );
      expect(sale.status, SaleStatus.completed);
    });

    test('stock is zero after correction and any sale is blocked', () async {
      await _seedProduct(db);
      await _seedStock(db, qty: Decimal.parse('50'));

      // Correct to zero (e.g. owner found all stock was damaged)
      await db.adjustStock(branchId, 'p-1', Decimal.zero);

      await expectLater(
        repo.createSale(
          branchId: branchId,
          shopId: shopId,
          cashierId: cashierId,
          paymentMethodId: pmId,
          items: [_item(quantity: Decimal.one)],
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('stock deducted correctly from corrected quantity', () async {
      await _seedProduct(db);
      await _seedStock(db, qty: Decimal.parse('50'));

      // Correct down to 15
      await db.adjustStock(branchId, 'p-1', Decimal.parse('15'));

      // Sell 6 — remaining should be 9
      await repo.createSale(
        branchId: branchId,
        shopId: shopId,
        cashierId: cashierId,
        paymentMethodId: pmId,
        items: [_item(quantity: Decimal.parse('6'))],
      );
      expect(await db.getStockLevel(branchId, 'p-1'), Decimal.parse('9'));
    });

    test('correction up then sale from new higher stock works', () async {
      await _seedProduct(db);
      await _seedStock(db, qty: Decimal.parse('2'));

      // Restock correction: correct up to 100
      await db.adjustStock(branchId, 'p-1', Decimal.parse('100'));

      // Sell 50 — should succeed
      final sale = await repo.createSale(
        branchId: branchId,
        shopId: shopId,
        cashierId: cashierId,
        paymentMethodId: pmId,
        items: [_item(quantity: Decimal.parse('50'))],
      );
      expect(sale.status, SaleStatus.completed);
      expect(await db.getStockLevel(branchId, 'p-1'), Decimal.parse('50'));
    });
  });

  // ── 3. Multiple corrections ───────────────────────────────────────────────

  group('multiple sequential corrections', () {
    test('final correction is the value the sale check uses', () async {
      await _seedProduct(db);
      await _seedStock(db, qty: Decimal.parse('50'));

      // First correction
      await db.adjustStock(branchId, 'p-1', Decimal.parse('20'));
      // Second correction overrides the first
      await db.adjustStock(branchId, 'p-1', Decimal.parse('7'));

      // Sale for 10 must be blocked (stock=7)
      await expectLater(
        repo.createSale(
          branchId: branchId,
          shopId: shopId,
          cashierId: cashierId,
          paymentMethodId: pmId,
          items: [_item(quantity: Decimal.parse('10'))],
        ),
        throwsA(isA<Exception>()),
      );

      // Sale for 7 must succeed
      final sale = await repo.createSale(
        branchId: branchId,
        shopId: shopId,
        cashierId: cashierId,
        paymentMethodId: pmId,
        items: [_item(quantity: Decimal.parse('7'))],
      );
      expect(sale.status, SaleStatus.completed);
      expect(await db.getStockLevel(branchId, 'p-1'), Decimal.zero);
    });
  });

  // ── 4. Correction + same-product multi-item sale ──────────────────────────

  group('correction then multi-item sale for same product', () {
    test('blocks when combined sale qty exceeds corrected stock', () async {
      await _seedProduct(db);
      await _seedStock(db, qty: Decimal.parse('50'));

      // Correct to 8
      await db.adjustStock(branchId, 'p-1', Decimal.parse('8'));

      // Two items for same product: 5 + 5 = 10 > 8 → must block
      await expectLater(
        repo.createSale(
          branchId: branchId,
          shopId: shopId,
          cashierId: cashierId,
          paymentMethodId: pmId,
          items: [
            _item(quantity: Decimal.parse('5')),
            _item(quantity: Decimal.parse('5')),
          ],
        ),
        throwsA(isA<Exception>()),
      );
      // Stock must remain at 8
      expect(await db.getStockLevel(branchId, 'p-1'), Decimal.parse('8'));
    });

    test('allows and deducts correctly when combined qty fits corrected stock', () async {
      await _seedProduct(db);
      await _seedStock(db, qty: Decimal.parse('50'));

      // Correct to 10
      await db.adjustStock(branchId, 'p-1', Decimal.parse('10'));

      // Two items: 3 + 4 = 7 ≤ 10 → must succeed, stock = 3
      final sale = await repo.createSale(
        branchId: branchId,
        shopId: shopId,
        cashierId: cashierId,
        paymentMethodId: pmId,
        items: [
          _item(quantity: Decimal.parse('3')),
          _item(quantity: Decimal.parse('4')),
        ],
      );
      expect(sale.status, SaleStatus.completed);
      expect(await db.getStockLevel(branchId, 'p-1'), Decimal.parse('3'));
    });
  });
}
