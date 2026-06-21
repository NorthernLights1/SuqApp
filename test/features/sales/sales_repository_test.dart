import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suq/data/local/app_database.dart';
import 'package:suq/domain/models/product.dart';
import 'package:suq/domain/models/sale.dart';
import 'package:suq/features/sales/data/sales_remote.dart';
import 'package:suq/features/sales/domain/sales_repository.dart';

// ── Stub remote ───────────────────────────────────────────────────────────────
//
// Implements SalesRemote without a SupabaseClient.
// createSale throws by default so the fire-and-forget unawaited chain in the
// repo never calls markSaleSynced — keeping isSynced=false deterministic.
// Tests that exercise the no-DB path (direct remote) use _SuccessStubRemote.

class _StubSalesRemote implements SalesRemote {
  @override
  Future<List<Product>> searchProducts(String shopId, String query) async => [];

  @override
  Future<List<PaymentMethod>> getPaymentMethods(String shopId) async => [];

  @override
  Future<List<Customer>> searchCustomers(String shopId, String query) async => [];

  @override
  Future<Customer> createCustomer({
    required String shopId,
    required String name,
    String? phone,
  }) async =>
      Customer(id: 'c-stub', name: name, creditBalance: Decimal.zero);

  @override
  Future<String> getInventoryMode(String shopId) async => 'strict';

  @override
  Future<Decimal?> getStockLevel(String branchId, String productId) async =>
      null;

  // Throws so the unawaited().catchError() path swallows the error and
  // markSaleSynced is never called — leaves isSynced=false in local DB.
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
  }) async =>
      throw Exception('stub: remote not available');

  @override
  Future<void> voidSale({
    required String saleId,
    required String voidedBy,
    required String reason,
    required String branchId,
  }) async {}

  @override
  Future<Sale> getSale(String saleId) async => _stubSale(saleId);

  @override
  Future<List<Sale>> getSalesForBranch({
    required String branchId,
    required DateTime from,
    required DateTime to,
  }) async =>
      [];

  @override
  Future<Map<String, Decimal>> getTodayTotals(String branchId) async =>
      {'total': Decimal.zero, 'count': Decimal.zero};
}

// Returns a valid stub Sale — used in the null-DB path test.
class _SuccessStubRemote extends _StubSalesRemote {
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
  }) async =>
      _stubSale(id, branchId: branchId, cashierId: cashierId,
          paymentMethodId: paymentMethodId, isCredit: isCredit);
}

Sale _stubSale(
  String id, {
  String branchId = 'b-1',
  String cashierId = 'user-1',
  String paymentMethodId = 'pm-1',
  bool isCredit = false,
}) =>
    Sale(
      id: id,
      branchId: branchId,
      cashierId: cashierId,
      paymentMethodId: paymentMethodId,
      subtotal: Decimal.zero,
      discountAmount: Decimal.zero,
      total: Decimal.zero,
      status: SaleStatus.completed,
      isCredit: isCredit,
      createdAt: DateTime.now(),
    );

// ── Helpers ───────────────────────────────────────────────────────────────────

AppDatabase _makeDb() => AppDatabase(NativeDatabase.memory());

Future<void> _seedProduct(
  AppDatabase db, {
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

Future<void> _seedStock(
  AppDatabase db, {
  String productId = 'p-1',
  String branchId = 'b-1',
  required Decimal quantity,
}) =>
    db.upsertStock([
      LocalStockCompanion(
        productId: Value(productId),
        branchId: Value(branchId),
        quantity: Value(quantity),
        syncedAt: Value(DateTime.now()),
      )
    ]);

CartItem _item({
  String? productId = 'p-1',
  String name = 'Bread',
  String? unitAbbr,
  Decimal? quantity,
  Decimal? unitPrice,
  Decimal? discount,
}) =>
    CartItem(
      productId: productId,
      productName: name,
      measurementUnitAbbr: unitAbbr,
      quantity: quantity ?? Decimal.one,
      unitPrice: unitPrice ?? Decimal.parse('50'),
      discountAmount: discount ?? Decimal.zero,
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late AppDatabase db;
  late SalesRepository repo;

  const branchId = 'b-1';
  const shopId = 'shop-1';
  const cashierId = 'user-1';
  const pmId = 'pm-1';

  setUp(() {
    db = _makeDb();
    repo = SalesRepository(_StubSalesRemote(), db);
  });

  tearDown(() => db.close());

  // ── Inventory enforcement ─────────────────────────────────────────────────

  group('Inventory enforcement — no stock record', () {
    test('blocks sale and message mentions product name', () async {
      await _seedProduct(db, id: 'p-1', name: 'Teff');
      // No stock row — inventory table is empty

      await expectLater(
        repo.createSale(
          branchId: branchId,
          shopId: shopId,
          cashierId: cashierId,
          paymentMethodId: pmId,
          items: [_item(productId: 'p-1', name: 'Teff')],
        ),
        throwsA(predicate((e) =>
            e.toString().contains('not in inventory') &&
            e.toString().contains('Teff'))),
      );
    });

    test('no sale row is written to DB when pre-check fails', () async {
      await _seedProduct(db);

      try {
        await repo.createSale(
          branchId: branchId,
          shopId: shopId,
          cashierId: cashierId,
          paymentMethodId: pmId,
          items: [_item()],
        );
      } catch (_) {}

      expect(await db.getPendingSales(), isEmpty);
    });
  });

  group('Inventory enforcement — insufficient stock', () {
    test('blocks when quantity ordered exceeds stock', () async {
      await _seedProduct(db, id: 'p-1', name: 'Butter');
      await _seedStock(db, productId: 'p-1', quantity: Decimal.parse('3'));

      await expectLater(
        repo.createSale(
          branchId: branchId,
          shopId: shopId,
          cashierId: cashierId,
          paymentMethodId: pmId,
          items: [_item(productId: 'p-1', name: 'Butter',
              quantity: Decimal.parse('5'))],
        ),
        throwsA(predicate((e) =>
            e.toString().contains('Not enough stock') &&
            e.toString().contains('Butter'))),
      );
    });

    test('blocks when stock is exactly 0', () async {
      await _seedProduct(db);
      await _seedStock(db, productId: 'p-1', quantity: Decimal.zero);

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

    test('stock unchanged when sale is blocked', () async {
      await _seedProduct(db);
      await _seedStock(db, productId: 'p-1', quantity: Decimal.parse('3'));

      try {
        await repo.createSale(
          branchId: branchId,
          shopId: shopId,
          cashierId: cashierId,
          paymentMethodId: pmId,
          items: [_item(quantity: Decimal.parse('10'))],
        );
      } catch (_) {}

      expect(await db.getStockLevel(branchId, 'p-1'), Decimal.parse('3'));
    });
  });

  group('Inventory enforcement — sufficient stock', () {
    test('allows sale when stock exactly matches quantity', () async {
      await _seedProduct(db);
      await _seedStock(db, productId: 'p-1', quantity: Decimal.parse('5'));

      final sale = await repo.createSale(
        branchId: branchId,
        shopId: shopId,
        cashierId: cashierId,
        paymentMethodId: pmId,
        items: [_item(quantity: Decimal.parse('5'))],
      );
      expect(sale.status, SaleStatus.completed);
    });

    test('allows sale when stock exceeds quantity', () async {
      await _seedProduct(db);
      await _seedStock(db, productId: 'p-1', quantity: Decimal.parse('20'));

      final sale = await repo.createSale(
        branchId: branchId,
        shopId: shopId,
        cashierId: cashierId,
        paymentMethodId: pmId,
        items: [_item(quantity: Decimal.parse('3'))],
      );
      expect(sale.status, SaleStatus.completed);
    });
  });

  group('Inventory enforcement — untracked items', () {
    test('item with null productId bypasses stock check', () async {
      // No products or stock seeded — should still succeed
      final sale = await repo.createSale(
        branchId: branchId,
        shopId: shopId,
        cashierId: cashierId,
        paymentMethodId: pmId,
        items: [_item(productId: null, name: 'Custom')],
      );
      expect(sale.status, SaleStatus.completed);
    });

    test('mixed cart: tracked item ok, second tracked item has no stock → blocks', () async {
      await _seedProduct(db, id: 'p-1', name: 'Bread');
      await _seedStock(db, productId: 'p-1', quantity: Decimal.parse('10'));
      await _seedProduct(db, id: 'p-2', name: 'Butter');
      // No stock for p-2

      await expectLater(
        repo.createSale(
          branchId: branchId,
          shopId: shopId,
          cashierId: cashierId,
          paymentMethodId: pmId,
          items: [
            _item(productId: 'p-1', name: 'Bread',
                quantity: Decimal.parse('2')),
            _item(productId: 'p-2', name: 'Butter',
                quantity: Decimal.one),
          ],
        ),
        throwsA(predicate((e) =>
            e.toString().contains('Butter') &&
            e.toString().contains('not in inventory'))),
      );
    });

    test('mixed cart: untracked item does not affect tracked item check', () async {
      await _seedProduct(db, id: 'p-1', name: 'Bread');
      await _seedStock(db, productId: 'p-1', quantity: Decimal.parse('5'));

      final sale = await repo.createSale(
        branchId: branchId,
        shopId: shopId,
        cashierId: cashierId,
        paymentMethodId: pmId,
        items: [
          _item(productId: null, name: 'Custom'), // untracked
          _item(productId: 'p-1', name: 'Bread',
              quantity: Decimal.parse('2')), // tracked
        ],
      );
      expect(sale.status, SaleStatus.completed);
    });
  });

  // ── Same-product-twice bug ─────────────────────────────────────────────────
  //
  // Before the fix, two cart items for the same product each passed the
  // per-item stock check, then the deduction loop re-read the post-deduction
  // value and could produce negative stock.

  group('Same product in multiple cart items', () {
    test('blocks when combined quantity exceeds stock', () async {
      await _seedProduct(db, id: 'p-1', name: 'Rice');
      await _seedStock(db, productId: 'p-1', quantity: Decimal.parse('8'));

      // 5 + 5 = 10 > 8 — should be blocked
      await expectLater(
        repo.createSale(
          branchId: branchId,
          shopId: shopId,
          cashierId: cashierId,
          paymentMethodId: pmId,
          items: [
            _item(productId: 'p-1', name: 'Rice',
                quantity: Decimal.parse('5')),
            _item(productId: 'p-1', name: 'Rice',
                quantity: Decimal.parse('5')),
          ],
        ),
        throwsA(isA<Exception>()),
      );

      // Stock must remain untouched
      expect(await db.getStockLevel(branchId, 'p-1'), Decimal.parse('8'));
    });

    test('allows and correctly deducts combined quantity within stock', () async {
      await _seedProduct(db, id: 'p-1', name: 'Rice');
      await _seedStock(db, productId: 'p-1', quantity: Decimal.parse('10'));

      // 3 + 4 = 7 ≤ 10 — should succeed, stock = 3
      final sale = await repo.createSale(
        branchId: branchId,
        shopId: shopId,
        cashierId: cashierId,
        paymentMethodId: pmId,
        items: [
          _item(productId: 'p-1', name: 'Rice',
              quantity: Decimal.parse('3')),
          _item(productId: 'p-1', name: 'Rice',
              quantity: Decimal.parse('4')),
        ],
      );
      expect(sale.status, SaleStatus.completed);
      expect(await db.getStockLevel(branchId, 'p-1'), Decimal.parse('3'));
    });
  });

  // ── Sale creation ──────────────────────────────────────────────────────────

  group('createSale — totals', () {
    test('single item, no discount', () async {
      await _seedProduct(db);
      await _seedStock(db, productId: 'p-1', quantity: Decimal.parse('20'));

      final sale = await repo.createSale(
        branchId: branchId,
        shopId: shopId,
        cashierId: cashierId,
        paymentMethodId: pmId,
        items: [_item(quantity: Decimal.parse('3'), unitPrice: Decimal.parse('50'))],
      );
      expect(sale.subtotal, Decimal.parse('150'));
      expect(sale.discountAmount, Decimal.zero);
      expect(sale.total, Decimal.parse('150'));
    });

    test('single item with discount', () async {
      await _seedProduct(db);
      await _seedStock(db, productId: 'p-1', quantity: Decimal.parse('20'));

      final sale = await repo.createSale(
        branchId: branchId,
        shopId: shopId,
        cashierId: cashierId,
        paymentMethodId: pmId,
        items: [
          _item(
            quantity: Decimal.parse('3'),
            unitPrice: Decimal.parse('50'),
            discount: Decimal.parse('10'),
          )
        ],
      );
      // subtotal = 50×3 = 150; discount = 10; total = 140
      expect(sale.subtotal, Decimal.parse('150'));
      expect(sale.discountAmount, Decimal.parse('10'));
      expect(sale.total, Decimal.parse('140'));
    });

    test('multi-item aggregated totals', () async {
      await _seedProduct(db, id: 'p-1', name: 'Bread');
      await _seedProduct(db, id: 'p-2', name: 'Butter');
      await _seedStock(db, productId: 'p-1', quantity: Decimal.parse('20'));
      await _seedStock(db, productId: 'p-2', quantity: Decimal.parse('10'));

      final sale = await repo.createSale(
        branchId: branchId,
        shopId: shopId,
        cashierId: cashierId,
        paymentMethodId: pmId,
        items: [
          CartItem(
            productId: 'p-1',
            productName: 'Bread',
            quantity: Decimal.parse('2'),
            unitPrice: Decimal.parse('50'),
            discountAmount: Decimal.zero,
          ),
          CartItem(
            productId: 'p-2',
            productName: 'Butter',
            quantity: Decimal.parse('1'),
            unitPrice: Decimal.parse('80'),
            discountAmount: Decimal.parse('5'),
          ),
        ],
      );
      // subtotal = 100 + 80 = 180; discount = 5; total = 175
      expect(sale.subtotal, Decimal.parse('180'));
      expect(sale.discountAmount, Decimal.parse('5'));
      expect(sale.total, Decimal.parse('175'));
    });
  });

  group('createSale — DB writes', () {
    test('sale is stored in local DB', () async {
      await _seedProduct(db);
      await _seedStock(db, productId: 'p-1', quantity: Decimal.parse('10'));

      final sale = await repo.createSale(
        branchId: branchId,
        shopId: shopId,
        cashierId: cashierId,
        paymentMethodId: pmId,
        items: [_item()],
      );

      final row = await db.getSale(sale.id);
      expect(row, isNotNull);
      expect(row!.branchId, branchId);
    });

    test('sale is written with isSynced=false (remote stub throws)', () async {
      await _seedProduct(db);
      await _seedStock(db, productId: 'p-1', quantity: Decimal.parse('10'));

      final sale = await repo.createSale(
        branchId: branchId,
        shopId: shopId,
        cashierId: cashierId,
        paymentMethodId: pmId,
        items: [_item()],
      );

      // Give pending microtasks a chance to settle
      await Future.microtask(() {});

      final pending = await db.getPendingSales();
      expect(pending.any((r) => r.id == sale.id), isTrue);
    });

    test('stock is deducted after sale', () async {
      await _seedProduct(db);
      await _seedStock(db, productId: 'p-1', quantity: Decimal.parse('15'));

      await repo.createSale(
        branchId: branchId,
        shopId: shopId,
        cashierId: cashierId,
        paymentMethodId: pmId,
        items: [_item(quantity: Decimal.parse('4'))],
      );

      expect(await db.getStockLevel(branchId, 'p-1'), Decimal.parse('11'));
    });

    test('stock reaches exactly 0 after full-quantity sale', () async {
      await _seedProduct(db);
      await _seedStock(db, productId: 'p-1', quantity: Decimal.parse('5'));

      await repo.createSale(
        branchId: branchId,
        shopId: shopId,
        cashierId: cashierId,
        paymentMethodId: pmId,
        items: [_item(quantity: Decimal.parse('5'))],
      );

      expect(await db.getStockLevel(branchId, 'p-1'), Decimal.zero);
    });

    test('tracked item is stored with tracked inventory status', () async {
      await _seedProduct(db);
      await _seedStock(db, productId: 'p-1', quantity: Decimal.parse('10'));

      final sale = await repo.createSale(
        branchId: branchId,
        shopId: shopId,
        cashierId: cashierId,
        paymentMethodId: pmId,
        items: [_item()],
      );

      expect(sale.items.first.inventoryStatus, InventoryStatus.tracked);
    });

    test('untracked item is stored with untracked status', () async {
      final sale = await repo.createSale(
        branchId: branchId,
        shopId: shopId,
        cashierId: cashierId,
        paymentMethodId: pmId,
        items: [_item(productId: null, name: 'Special')],
      );
      expect(sale.items.first.inventoryStatus, InventoryStatus.untracked);
    });

    test('credit sale flag is preserved', () async {
      final sale = await repo.createSale(
        branchId: branchId,
        shopId: shopId,
        cashierId: cashierId,
        paymentMethodId: pmId,
        items: [_item(productId: null)],
        isCredit: true,
      );
      final row = await db.getSale(sale.id);
      expect(row!.isCredit, isTrue);
    });
  });

  group('createSale — null DB path (web)', () {
    test('delegates directly to remote and returns its result', () async {
      final repoNoDb = SalesRepository(_SuccessStubRemote(), null);

      final sale = await repoNoDb.createSale(
        branchId: branchId,
        shopId: shopId,
        cashierId: cashierId,
        paymentMethodId: pmId,
        items: [_item(productId: null, name: 'Item')],
      );
      expect(sale.status, SaleStatus.completed);
    });

    test('no pre-check runs when DB is null (untracked item passes)', () async {
      final repoNoDb = SalesRepository(_SuccessStubRemote(), null);

      // Would fail pre-check if DB were present, but DB is null
      final sale = await repoNoDb.createSale(
        branchId: branchId,
        shopId: shopId,
        cashierId: cashierId,
        paymentMethodId: pmId,
        items: [_item(productId: 'p-does-not-exist', name: 'Ghost')],
      );
      expect(sale.status, SaleStatus.completed);
    });
  });

  // ── Search ────────────────────────────────────────────────────────────────

  group('searchProducts', () {
    test('returns empty for query shorter than 2 chars', () async {
      expect(await repo.searchProducts(shopId, 'a'), isEmpty);
      expect(await repo.searchProducts(shopId, ''), isEmpty);
      expect(await repo.searchProducts(shopId, ' '), isEmpty);
    });

    test('returns local DB results when available', () async {
      await _seedProduct(db, shopId: shopId, name: 'Teff Flour');
      final results = await repo.searchProducts(shopId, 'Teff');
      expect(results.length, 1);
      expect(results.first.name, 'Teff Flour');
    });

    test('search is case-insensitive', () async {
      await _seedProduct(db, shopId: shopId, name: 'Teff Flour');
      final results = await repo.searchProducts(shopId, 'teff');
      expect(results.length, 1);
    });

    test('falls through to stub remote when no local match (returns empty)', () async {
      await _seedProduct(db, shopId: shopId, name: 'Salt');
      final results = await repo.searchProducts(shopId, 'Teff');
      // No local match → stub remote returns []
      expect(results, isEmpty);
    });

    test('falls through to remote when DB is null', () async {
      final repoNoDb = SalesRepository(_StubSalesRemote(), null);
      final results = await repoNoDb.searchProducts(shopId, 'Teff');
      expect(results, isEmpty); // stub returns []
    });
  });

  group('searchCustomers', () {
    test('returns empty for single-char query', () async {
      expect(await repo.searchCustomers(shopId, 'A'), isEmpty);
      expect(await repo.searchCustomers(shopId, ''), isEmpty);
    });

    test('returns local DB match', () async {
      await db.upsertCustomers([
        LocalCustomersCompanion(
          id: const Value('c-1'),
          shopId: const Value('shop-1'),
          name: const Value('Abebe Kebede'),
          creditBalance: Value(Decimal.zero),
          updatedAt: Value(DateTime.now()),
        )
      ]);
      final results = await repo.searchCustomers(shopId, 'Ab');
      expect(results.length, 1);
      expect(results.first.name, 'Abebe Kebede');
    });

    test('falls through to stub remote when no local match', () async {
      final results = await repo.searchCustomers(shopId, 'Unknown');
      expect(results, isEmpty);
    });
  });

  // ── Wholesale batch depletion (useBatches) ──────────────────────────────────

  group('createSale — wholesale FEFO depletion', () {
    Future<void> seedBatch(String id, Decimal qty, DateTime? expiry) =>
        db.upsertProductBatches([
          LocalProductBatchesCompanion(
            id: Value(id),
            branchId: const Value(branchId),
            productId: const Value('p-1'),
            quantity: Value(qty),
            expiryDate: Value(expiry),
            receivedAt: Value(DateTime.now()),
            syncedAt: Value(DateTime.now()),
            isSynced: const Value(true),
          )
        ]);

    test('depletes the soonest-expiry lot first and records the ledger',
        () async {
      await _seedProduct(db);
      await seedBatch('late', Decimal.parse('10'), DateTime(2027, 1, 1));
      await seedBatch('soon', Decimal.parse('3'), DateTime(2026, 9, 1));
      await db.recomputeStockFromBatches(branchId, 'p-1', DateTime.now());
      expect(await db.getStockLevel(branchId, 'p-1'), Decimal.parse('13'));

      await repo.createSale(
        branchId: branchId,
        shopId: shopId,
        cashierId: cashierId,
        paymentMethodId: pmId,
        items: [_item(quantity: Decimal.parse('5'))],
        useBatches: true,
      );

      // Rollup dropped by 5.
      expect(await db.getStockLevel(branchId, 'p-1'), Decimal.parse('8'));
      // FEFO: soon (3) fully drawn, late drawn by 2.
      final depl = await db.depletionByBatch(['soon', 'late']);
      expect(depl['soon'], Decimal.parse('3'));
      expect(depl['late'], Decimal.parse('2'));
    });

    test('void reverses the depletion and restores the rollup', () async {
      await _seedProduct(db);
      await seedBatch('b1', Decimal.parse('10'), DateTime(2027, 1, 1));
      await db.recomputeStockFromBatches(branchId, 'p-1', DateTime.now());

      final sale = await repo.createSale(
        branchId: branchId,
        shopId: shopId,
        cashierId: cashierId,
        paymentMethodId: pmId,
        items: [_item(quantity: Decimal.parse('4'))],
        useBatches: true,
      );
      expect(await db.getStockLevel(branchId, 'p-1'), Decimal.parse('6'));

      await repo.voidSale(
        saleId: sale.id,
        voidedBy: cashierId,
        reason: 'mistake',
        branchId: branchId,
      );
      expect(await db.getStockLevel(branchId, 'p-1'), Decimal.parse('10'));
    });

    test('wouldUseExpiredBatch flags a draw from an expired lot', () async {
      await _seedProduct(db);
      await seedBatch('exp', Decimal.parse('10'), DateTime(2020, 1, 1));
      await db.recomputeStockFromBatches(branchId, 'p-1', DateTime.now());

      expect(
        await repo.wouldUseExpiredBatch(
            branchId: branchId, items: [_item(quantity: Decimal.one)]),
        isTrue,
      );
    });

    test('wouldUseExpiredBatch is false when the drawn lot is fresh', () async {
      await _seedProduct(db);
      await seedBatch('fresh', Decimal.parse('10'), DateTime(2030, 1, 1));
      await db.recomputeStockFromBatches(branchId, 'p-1', DateTime.now());

      expect(
        await repo.wouldUseExpiredBatch(
            branchId: branchId, items: [_item(quantity: Decimal.one)]),
        isFalse,
      );
    });
  });
}
