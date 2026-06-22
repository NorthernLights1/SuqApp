// Tests for offline-first inventory: the local adjustments queue + mirror.
//
// Stock ops update the local mirror immediately and queue a delta-aware
// adjustment. The background push (InventoryRemote.applyAdjustment) is stubbed
// to throw so the queued row stays deterministically pending.

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suq/data/local/app_database.dart';
import 'package:suq/domain/models/product.dart';
import 'package:suq/features/inventory/data/inventory_remote.dart';
import 'package:suq/features/inventory/domain/inventory_repository.dart';

// ── Stub remote ───────────────────────────────────────────────────────────────

class _StubInventoryRemote implements InventoryRemote {
  bool stockThrows = false;

  @override
  Future<void> applyAdjustment({
    required String id,
    required String type,
    required String branchId,
    required String productId,
    required Decimal quantityBefore,
    required Decimal quantityAfter,
    required String adjustedBy,
    String? notes,
    DateTime? expiryDate,
    DateTime? createdAt,
  }) async =>
      throw Exception('offline'); // keep the queued row pending

  @override
  Future<List<StockEntry>> getStockLevels(String branchId) async {
    if (stockThrows) throw Exception('offline');
    return [];
  }

  @override
  Future<List<Product>> getProducts(String shopId) async => [];

  // Unused by these tests.
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

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

Future<void> _seedStock(AppDatabase db, Decimal qty,
        {String productId = 'p-1', String branchId = 'b-1'}) =>
    db.upsertStock([
      LocalStockCompanion(
        productId: Value(productId),
        branchId: Value(branchId),
        quantity: Value(qty),
        syncedAt: Value(DateTime.now()),
      )
    ]);

void main() {
  const branchId = 'b-1';
  late AppDatabase db;
  late _StubInventoryRemote remote;
  late InventoryRepository repo;

  setUp(() {
    db = _makeDb();
    remote = _StubInventoryRemote();
    repo = InventoryRepository(remote, db);
  });
  tearDown(() => db.close());

  group('addStock', () {
    test('updates the mirror additively and queues a restock adjustment',
        () async {
      await _seedStock(db, Decimal.parse('10'));
      await repo.addStock(
        branchId: branchId,
        productId: 'p-1',
        quantityToAdd: Decimal.parse('5'),
        adjustedBy: 'u-1',
      );

      expect(await db.getStockLevel(branchId, 'p-1'), Decimal.parse('15'));
      final pending = await db.getPendingInventoryAdjustments();
      expect(pending.length, 1);
      expect(pending.first.type, 'supply_received');
      expect(pending.first.quantityBefore, Decimal.parse('10'));
      expect(pending.first.quantityAfter, Decimal.parse('15'));
    });

    test('creates a mirror row when the product had none (before = 0)',
        () async {
      await repo.addStock(
        branchId: branchId,
        productId: 'p-new',
        quantityToAdd: Decimal.parse('7'),
        adjustedBy: 'u-1',
      );
      expect(await db.getStockLevel(branchId, 'p-new'), Decimal.parse('7'));
      final pending = await db.getPendingInventoryAdjustments();
      expect(pending.first.quantityBefore, Decimal.zero);
    });
  });

  group('setOpeningStock', () {
    test('sets absolute mirror qty and queues an opening_stock adjustment',
        () async {
      await repo.setOpeningStock(
        branchId: branchId,
        productId: 'p-1',
        quantity: Decimal.parse('40'),
        adjustedBy: 'u-1',
      );
      expect(await db.getStockLevel(branchId, 'p-1'), Decimal.parse('40'));
      final pending = await db.getPendingInventoryAdjustments();
      expect(pending.first.type, 'opening_stock');
      expect(pending.first.quantityAfter, Decimal.parse('40'));
    });
  });

  group('manualAdjustment', () {
    test('queues a manual (absolute) adjustment with before/after', () async {
      await _seedStock(db, Decimal.parse('30'));
      await repo.manualAdjustment(
        branchId: branchId,
        productId: 'p-1',
        newQuantity: Decimal.parse('12'),
        currentQuantity: Decimal.parse('30'),
        adjustedBy: 'u-1',
        notes: 'recount',
      );
      expect(await db.getStockLevel(branchId, 'p-1'), Decimal.parse('12'));
      final pending = await db.getPendingInventoryAdjustments();
      expect(pending.first.type, 'manual');
      expect(pending.first.quantityBefore, Decimal.parse('30'));
      expect(pending.first.quantityAfter, Decimal.parse('12'));
      expect(pending.first.notes, 'recount');
    });
  });

  group('getStockLevels — offline fallback', () {
    test('serves local mirror entries when the server is unreachable',
        () async {
      await _seedProduct(db);
      await _seedStock(db, Decimal.parse('22'));
      remote.stockThrows = true;

      final entries = await repo.getStockLevels(branchId);
      expect(entries.length, 1);
      expect(entries.first.productId, 'p-1');
      expect(entries.first.quantity, Decimal.parse('22'));
      expect(entries.first.unitAbbr, 'pc');
    });
  });

  group('adjustment queue DB methods', () {
    test('markInventoryAdjustmentSynced removes a row from pending', () async {
      await repo.addStock(
        branchId: branchId,
        productId: 'p-1',
        quantityToAdd: Decimal.one,
        adjustedBy: 'u-1',
      );
      final pending = await db.getPendingInventoryAdjustments();
      expect(pending.length, 1);
      await db.markInventoryAdjustmentSynced(pending.first.id);
      expect(await db.getPendingInventoryAdjustments(), isEmpty);
    });
  });

  group('addStockBatch (wholesale)', () {
    test('creates a pending batch and rolls up LocalStock to its quantity',
        () async {
      await repo.addStockBatch(
        branchId: branchId,
        productId: 'p-1',
        quantity: Decimal.parse('12'),
        adjustedBy: 'u-1',
        batchNumber: 'LOT-A',
        expiryDate: DateTime(2027, 1, 1),
      );

      expect(await db.getStockLevel(branchId, 'p-1'), Decimal.parse('12'));
      final batches = await db.getBatchesForProduct(branchId, 'p-1');
      expect(batches.length, 1);
      expect(batches.first.batchNumber, 'LOT-A');
      expect(batches.first.isSynced, isFalse); // queued for push
    });

    test('a second batch sums into the rollup; stock expiry = soonest',
        () async {
      await repo.addStockBatch(
        branchId: branchId,
        productId: 'p-1',
        quantity: Decimal.parse('10'),
        adjustedBy: 'u-1',
        expiryDate: DateTime(2027, 6, 1),
      );
      await repo.addStockBatch(
        branchId: branchId,
        productId: 'p-1',
        quantity: Decimal.parse('5'),
        adjustedBy: 'u-1',
        expiryDate: DateTime(2026, 12, 1), // sooner
      );

      expect(await db.getStockLevel(branchId, 'p-1'), Decimal.parse('15'));
      // FEFO order: soonest-expiry batch first.
      final batches = await db.getBatchesForProduct(branchId, 'p-1');
      expect(batches.length, 2);
      expect(batches.first.expiryDate, DateTime(2026, 12, 1));
      // Stock row carries the soonest expiry (drives the "expiring" badge).
      final stock = await db.getStockByBranch(branchId);
      expect(stock.first.expiryDate, DateTime(2026, 12, 1));
    });

    test('flags the product as having pending batch work', () async {
      await repo.addStockBatch(
        branchId: branchId,
        productId: 'p-1',
        quantity: Decimal.one,
        adjustedBy: 'u-1',
      );
      expect(await db.getPendingBatchProductIds(branchId), contains('p-1'));
    });

    test('discardBatch drops the lot remaining from the rollup and hides it',
        () async {
      await repo.addStockBatch(
        branchId: branchId,
        productId: 'p-1',
        quantity: Decimal.parse('10'),
        adjustedBy: 'u-1',
        batchNumber: 'L1',
      );
      final batches = await db.getBatchesForProduct(branchId, 'p-1');
      expect(await db.getStockLevel(branchId, 'p-1'), Decimal.parse('10'));

      await repo.discardBatch(batches.first.id);

      // Discarded lot is excluded everywhere: rollup back to 0, lot hidden.
      expect(await db.getStockLevel(branchId, 'p-1'), Decimal.zero);
      expect(await db.getBatchesForProduct(branchId, 'p-1'), isEmpty);
    });

    test('records the adder and resolves "added by" to a profile name',
        () async {
      await db.upsertProfiles([
        LocalProfilesCompanion(
          id: const Value('u-1'),
          fullName: const Value('Sara T.'),
          syncedAt: Value(DateTime.now()),
        ),
      ]);
      await repo.addStockBatch(
        branchId: branchId,
        productId: 'p-1',
        quantity: Decimal.parse('5'),
        adjustedBy: 'u-1',
        batchNumber: 'L1',
      );

      final views = await repo.getProductBatches(branchId, 'p-1');
      expect(views.single.addedByName, 'Sara T.');
    });
  });

  group('correctBatch (wholesale)', () {
    test('down-correction lowers the lot remaining and the rollup', () async {
      await repo.addStockBatch(
        branchId: branchId,
        productId: 'p-1',
        quantity: Decimal.parse('10'),
        adjustedBy: 'u-1',
        batchNumber: 'L1',
      );
      final batch = (await repo.getProductBatches(branchId, 'p-1')).single;
      expect(batch.remaining, Decimal.parse('10'));

      // Physically counted only 7 in the lot.
      await repo.correctBatch(
        batchId: batch.id,
        branchId: branchId,
        productId: 'p-1',
        countedRemaining: Decimal.parse('7'),
        reason: 'miscount',
        adjustedBy: 'u-1',
      );

      final after = (await repo.getProductBatches(branchId, 'p-1')).single;
      expect(after.remaining, Decimal.parse('7'));
      expect(await db.getStockLevel(branchId, 'p-1'), Decimal.parse('7'));
    });

    test('up-correction adds remaining back; correction is queued for push',
        () async {
      await repo.addStockBatch(
        branchId: branchId,
        productId: 'p-1',
        quantity: Decimal.parse('5'),
        adjustedBy: 'u-1',
        batchNumber: 'L1',
      );
      final batch = (await repo.getProductBatches(branchId, 'p-1')).single;

      await repo.correctBatch(
        batchId: batch.id,
        branchId: branchId,
        productId: 'p-1',
        countedRemaining: Decimal.parse('8'),
        reason: 'found more',
        adjustedBy: 'u-1',
      );

      expect((await repo.getProductBatches(branchId, 'p-1')).single.remaining,
          Decimal.parse('8'));
      expect(await db.getStockLevel(branchId, 'p-1'), Decimal.parse('8'));
      // The adjustment is pending sync (offline-first).
      expect(await db.getPendingBatchAdjustments(), isNotEmpty);
    });
  });
}
