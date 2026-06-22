import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/local/app_database.dart';
import '../../../domain/models/product.dart';
import '../data/inventory_remote.dart';

/// Offline-first inventory.
///
/// Stock operations (opening / add / manual / correction) are local-first:
/// they update the local stock mirror immediately and queue a delta-aware
/// adjustment that pushes in the background ([SyncService] retries failures).
/// Stock and product reads fall back to the local mirror when offline, and
/// overlay any in-flight optimistic quantity.
///
/// Product create/edit/deactivate remain online (admin actions); making
/// product creation offline-first is a deliberate follow-up (FK ordering).
class InventoryRepository {
  InventoryRepository(this._remote, this._db);

  final InventoryRemote _remote;
  final AppDatabase? _db;

  // ── Reference reads (remote) ─────────────────────────────────────────────────

  Future<List<MeasurementUnit>> getMeasurementUnits(String shopId) async {
    // Local-first: non-empty local is authoritative (seeding complete).
    // Empty local = pre-seed or web → server.
    if (_db != null) {
      final rows = await _db.getUnits();
      if (rows.isNotEmpty) {
        return rows
            .map((r) => MeasurementUnit(
                id: r.id, name: r.name, abbreviation: r.abbreviation))
            .toList();
      }
    }
    return _remote.getMeasurementUnits(shopId);
  }

  Future<MeasurementUnit> createMeasurementUnit({
    required String shopId,
    required String name,
    required String abbreviation,
  }) async {
    // ponytail: custom units are reference data added rarely (usually online at
    // setup). Create is remote-only; the delta pull mirrors it back. We also
    // optimistically upsert into the local cache so the picker shows it at once.
    // Offline support deferred — add a local-first path if shops report needing
    // to add units while disconnected.
    final unit = await _remote.createMeasurementUnit(
      shopId: shopId,
      name: name,
      abbreviation: abbreviation,
    );
    await _db?.upsertUnits([
      LocalMeasurementUnitsCompanion(
        id: Value(unit.id),
        name: Value(unit.name),
        abbreviation: Value(unit.abbreviation),
        syncedAt: Value(DateTime.now()),
      ),
    ]);
    return unit;
  }

  /// A product's live batches (remaining > 0) at a branch, FEFO-ordered
  /// (soonest expiry first). Wholesale display only; empty when there's no local
  /// DB (web) or no batches.
  Future<List<ProductBatchView>> getProductBatches(
      String branchId, String productId) async {
    // Web (no local DB): read the lots straight from Supabase.
    if (_db == null) return _remote.getProductBatches(branchId, productId);
    final batches = await _db.getBatchesForProduct(branchId, productId);
    final ids = batches.map((b) => b.id).toList();
    final depleted = await _db.depletionByBatch(ids);
    final adjusted = await _db.adjustmentByBatch(ids);
    // Resolve "added by" ids to display names from the profiles mirror.
    final names = {
      for (final p in await _db.getProfiles()) p.id: p.fullName,
    };
    return [
      for (final b in batches)
        ProductBatchView(
          id: b.id,
          batchNumber: b.batchNumber,
          expiryDate: b.expiryDate,
          remaining: b.quantity -
              (depleted[b.id] ?? Decimal.zero) -
              (adjusted[b.id] ?? Decimal.zero),
          received: b.quantity,
          receivedAt: b.receivedAt,
          addedByName: b.createdBy == null ? null : names[b.createdBy],
        ),
    ].where((v) => v.remaining > Decimal.zero).toList();
  }

  Future<List<ProductCategory>> getProductCategories(String shopId) async {
    // Local-first: categories can legitimately be empty (a shop may have none),
    // so when the local DB is present we trust it outright — never error offline.
    if (_db != null) {
      final rows = await _db.getCategories(shopId);
      return rows.map((r) => ProductCategory(id: r.id, name: r.name)).toList();
    }
    return _remote.getProductCategories(shopId);
  }

  Future<ProductCategory> createProductCategory({
    required String shopId,
    required String name,
  }) async {
    // Web: remote-only (no local DB).
    if (_db == null) {
      return _remote.createProductCategory(shopId: shopId, name: name);
    }
    // Native: write locally first so the category is visible immediately and
    // works offline. SyncService pushes it when connectivity is available.
    final id = const Uuid().v4();
    final trimmed = name.trim();
    await _db.upsertCategories([
      LocalProductCategoriesCompanion(
        id: Value(id),
        shopId: Value(shopId),
        name: Value(trimmed),
        syncedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ),
    ]);
    return ProductCategory(id: id, name: trimmed);
  }

  // ── Products ─────────────────────────────────────────────────────────────────

  Future<List<Product>> getProducts(String shopId) async {
    if (_db == null) return _remote.getProducts(shopId);
    // Local-first: the mirror is seeded at login and kept current by sync and by
    // local writes, so it's authoritative for display and works offline. Refresh
    // it in the background. Only an empty mirror falls through to the server.
    final rows = await _db.getProductsByShop(shopId);
    if (rows.isNotEmpty) {
      unawaited(_refreshProducts(shopId));
      return rows.map(_productFromRow).toList();
    }
    try {
      final remote =
          await _remote.getProducts(shopId).timeout(AppConstants.remoteReadTimeout);
      await _db.upsertProducts(remote.map(_toProductCompanion).toList());
      return remote;
    } catch (_) {
      return rows.map(_productFromRow).toList(); // empty cache, offline
    }
  }

  Future<void> _refreshProducts(String shopId) async {
    try {
      final remote =
          await _remote.getProducts(shopId).timeout(AppConstants.remoteReadTimeout);
      await _db!.upsertProducts(remote.map(_toProductCompanion).toList());
    } catch (_) {/* offline / transient — keep the local mirror */}
  }

  Future<Product> createProduct({
    required String shopId,
    required String name,
    required String measurementUnitId,
    required Decimal lowStockThreshold,
    Decimal? sellingPrice,
    Decimal? costPrice,
    String? categoryId,
    String? description,
  }) async {
    // Web: remote-only (no local DB).
    if (_db == null) {
      return _remote.createProduct(
        shopId: shopId,
        name: name,
        measurementUnitId: measurementUnitId,
        lowStockThreshold: lowStockThreshold,
        sellingPrice: sellingPrice,
        costPrice: costPrice,
        categoryId: categoryId,
        description: description,
      );
    }
    // Native: write locally first so the product is visible immediately and
    // works offline. SyncService pushes it when connectivity is available.
    final id = const Uuid().v4();
    final trimmedName = name.trim();
    final trimmedDesc = description?.trim();
    final finalDesc = (trimmedDesc?.isEmpty ?? true) ? null : trimmedDesc;
    // Look up the unit abbreviation from the local cache (always seeded).
    final units = await _db.getUnits();
    final unitAbbr = units
        .where((u) => u.id == measurementUnitId)
        .map((u) => u.abbreviation)
        .firstOrNull ?? '';
    await _db.upsertProducts([
      LocalProductsCompanion(
        id: Value(id),
        shopId: Value(shopId),
        name: Value(trimmedName),
        categoryId: Value(categoryId),
        description: Value(finalDesc),
        measurementUnitId: Value(measurementUnitId),
        measurementUnitAbbr: Value(unitAbbr),
        lowStockThreshold: Value(lowStockThreshold),
        sellingPrice: Value(sellingPrice),
        costPrice: Value(costPrice),
        isActive: const Value(true),
        syncedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ),
    ]);
    return Product(
      id: id,
      shopId: shopId,
      name: trimmedName,
      categoryId: categoryId,
      description: trimmedDesc,
      measurementUnitId: measurementUnitId,
      measurementUnitAbbr: unitAbbr,
      lowStockThreshold: lowStockThreshold,
      sellingPrice: sellingPrice,
      costPrice: costPrice,
      isActive: true,
    );
  }

  Future<Product> updateProduct({
    required String productId,
    required String name,
    required String measurementUnitId,
    required Decimal lowStockThreshold,
    Decimal? sellingPrice,
    Decimal? costPrice,
    String? categoryId,
    String? description,
  }) async {
    final product = await _remote.updateProduct(
      productId: productId,
      name: name,
      measurementUnitId: measurementUnitId,
      lowStockThreshold: lowStockThreshold,
      sellingPrice: sellingPrice,
      costPrice: costPrice,
      categoryId: categoryId,
      description: description,
    );
    await _db?.upsertProducts([_toProductCompanion(product)]);
    return product;
  }

  Future<void> deactivateProduct(String productId) =>
      _remote.deactivateProduct(productId);

  // ── Stock reads ──────────────────────────────────────────────────────────────

  Future<List<StockEntry>> getStockLevels(String branchId) async {
    if (_db == null) return _remote.getStockLevels(branchId);
    // Local-first: the local stock mirror already reflects every local write
    // (opening / add / manual / correction) and newly-created products, so it
    // shows the true current quantity instantly and offline. Refresh from the
    // server in the background. Only an empty mirror falls through to the server.
    final local = await _localStockEntries(branchId);
    if (local.isNotEmpty) {
      unawaited(_refreshStock(branchId));
      return local;
    }
    try {
      final remote = await _remote
          .getStockLevels(branchId)
          .timeout(AppConstants.remoteReadTimeout);
      await _db.upsertStock([
        for (final s in remote)
          LocalStockCompanion(
            productId: Value(s.productId),
            branchId: Value(branchId),
            quantity: Value(s.quantity),
            expiryDate: Value(s.expiryDate),
            syncedAt: Value(DateTime.now()),
          ),
      ]);
      return remote;
    } catch (_) {
      return local; // empty cache, offline
    }
  }

  /// Background refresh of the stock mirror from the server, preserving any
  /// optimistic local quantity for products with an in-flight (unpushed)
  /// adjustment so we never clobber a write that hasn't synced yet.
  /// Force-pull fresh stock from the server into the local mirror.
  /// Used after server-side operations that change quantity (e.g. void sale)
  /// so the next local-first read reflects the server state immediately.
  Future<void> refreshStock(String branchId) => _refreshStock(branchId);

  Future<void> _refreshStock(String branchId) async {
    try {
      final remote = await _remote
          .getStockLevels(branchId)
          .timeout(AppConstants.remoteReadTimeout);
      final pendingIds = (await _db!.getPendingInventoryAdjustments())
          .where((a) => a.branchId == branchId)
          .map((a) => a.productId)
          .toSet()
        // Also protect products whose only in-flight change is an unpushed
        // batch (wholesale) — otherwise the refresh clobbers the optimistic
        // rollup before the batch syncs.
        ..addAll(await _db.getPendingBatchProductIds(branchId));
      final toCache = remote.where((s) => !pendingIds.contains(s.productId));
      await _db.upsertStock([
        for (final s in toCache)
          LocalStockCompanion(
            productId: Value(s.productId),
            branchId: Value(branchId),
            quantity: Value(s.quantity),
            expiryDate: Value(s.expiryDate),
            syncedAt: Value(DateTime.now()),
          ),
      ]);
    } catch (_) {/* offline / transient — keep the local mirror */}
  }

  Future<List<StockEntry>> _localStockEntries(String branchId) async {
    final stock = await _db!.getStockByBranch(branchId);
    if (stock.isEmpty) return [];
    final products =
        await _db.getProductsByIds(stock.map((s) => s.productId).toList());
    final byId = {for (final p in products) p.id: p};
    final entries = <StockEntry>[];
    for (final s in stock) {
      final p = byId[s.productId];
      if (p == null) continue;
      entries.add(StockEntry(
        productId: s.productId,
        productName: p.name,
        measurementUnitId: p.measurementUnitId,
        quantity: s.quantity,
        lowStockThreshold: p.lowStockThreshold,
        sellingPrice: p.sellingPrice,
        unitAbbr: p.measurementUnitAbbr,
        expiryDate: s.expiryDate,
        updatedAt: s.syncedAt,
      ));
    }
    entries.sort((a, b) => a.productName.compareTo(b.productName));
    return entries;
  }

  // ── Stock writes (offline-first) ─────────────────────────────────────────────

  Future<void> setOpeningStock({
    required String branchId,
    required String productId,
    required Decimal quantity,
    required String adjustedBy,
    DateTime? expiryDate,
  }) async {
    final before = await _currentQty(branchId, productId);
    await _queueAdjustment(
      type: 'opening_stock',
      branchId: branchId,
      productId: productId,
      before: before,
      after: quantity,
      adjustedBy: adjustedBy,
      expiryDate: expiryDate,
    );
  }

  Future<void> addStock({
    required String branchId,
    required String productId,
    required Decimal quantityToAdd,
    required String adjustedBy,
    DateTime? expiryDate,
  }) async {
    final before = await _currentQty(branchId, productId);
    await _queueAdjustment(
      // 'supply_received' is the DB-allowed type for additive restocks
      // (inventory_adjustments CHECK constraint excludes 'restock').
      type: 'supply_received',
      branchId: branchId,
      productId: productId,
      before: before,
      after: before + quantityToAdd,
      adjustedBy: adjustedBy,
      expiryDate: expiryDate,
    );
  }

  /// Wholesale stock-in: create a BATCH (qty + its own expiry/batch number).
  /// The server rollup trigger maintains `inventory.quantity`; no
  /// inventory_adjustments ledger row — the batch row IS the record. Local-first:
  /// write the batch (isSynced=false) and recompute the local stock rollup;
  /// SyncService pushes the batch (idempotent upsert by UUID).
  ///
  /// NOTE: for a wholesale product, ALL stock-in must go through here — writing
  /// `inventory.quantity` directly (the retail path) would be overwritten by the
  /// rollup trigger on the next batch change. The shop_type gate lives in the
  /// provider/UI layer.
  Future<void> addStockBatch({
    required String branchId,
    required String productId,
    required Decimal quantity,
    required String adjustedBy,
    String? batchNumber,
    DateTime? expiryDate,
    Decimal? costPrice,
  }) async {
    final id = const Uuid().v4();

    // Web (no local DB): insert straight to the server.
    if (_db == null) {
      await _remote.insertBatch(
        id: id,
        branchId: branchId,
        productId: productId,
        batchNumber: batchNumber,
        expiryDate: expiryDate,
        quantity: quantity,
        costPrice: costPrice,
        createdBy: adjustedBy,
      );
      return;
    }

    await _db.upsertProductBatches([
      LocalProductBatchesCompanion(
        id: Value(id),
        branchId: Value(branchId),
        productId: Value(productId),
        batchNumber: Value(batchNumber),
        expiryDate: Value(expiryDate),
        quantity: Value(quantity),
        costPrice: Value(costPrice),
        receivedAt: Value(DateTime.now()),
        syncedAt: Value(DateTime.now()),
        createdBy: Value(adjustedBy),
        isSynced: const Value(false),
      ),
    ]);
    await _recomputeLocalRollup(branchId, productId);
  }

  /// Recompute the local stock rollup from this product's batches (= Σ received
  /// − Σ depletions). Shared with the sale path via the DB helper.
  Future<void> _recomputeLocalRollup(String branchId, String productId) =>
      _db?.recomputeStockFromBatches(branchId, productId, DateTime.now()) ??
      Future.value();

  /// Discard a lot (expired/damaged): soft-delete it + recompute the rollup so
  /// its remaining drops out immediately and offline. SyncService pushes the
  /// soft-delete; the server rollup trigger restates inventory.quantity.
  Future<void> discardBatch(String batchId) async {
    if (_db == null) return;
    final batch = await _db.getBatch(batchId);
    if (batch == null) return;
    await _db.discardBatch(batchId, DateTime.now());
    await _recomputeLocalRollup(batch.branchId, batch.productId);
  }

  /// Correct ONE lot's remaining to a counted quantity. Records the difference
  /// as an append-only adjustment (positive delta = removed, negative = added
  /// back) with a reason, then recomputes the rollup. Offline-first; the server
  /// trigger restates inventory.quantity on push.
  Future<void> correctBatch({
    required String batchId,
    required String branchId,
    required String productId,
    required Decimal countedRemaining,
    required String reason,
    required String adjustedBy,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();

    if (_db == null) {
      // Web: derive the current remaining from the server, then post the delta.
      final views = await _remote.getProductBatches(branchId, productId);
      Decimal? current;
      for (final v in views) {
        if (v.id == batchId) {
          current = v.remaining;
          break;
        }
      }
      if (current == null) return;
      final delta = current - countedRemaining;
      if (delta == Decimal.zero) return;
      await _remote.insertBatchAdjustment(
        id: id,
        batchId: batchId,
        branchId: branchId,
        productId: productId,
        quantityDelta: delta,
        reason: reason,
        createdBy: adjustedBy,
      );
      return;
    }

    final batch = await _db.getBatch(batchId);
    if (batch == null) return;
    final depleted =
        (await _db.depletionByBatch([batchId]))[batchId] ?? Decimal.zero;
    final adjusted =
        (await _db.adjustmentByBatch([batchId]))[batchId] ?? Decimal.zero;
    final current = batch.quantity - depleted - adjusted;
    final delta = current - countedRemaining;
    if (delta == Decimal.zero) return;
    await _db.upsertBatchAdjustments([
      LocalBatchAdjustmentsCompanion(
        id: Value(id),
        batchId: Value(batchId),
        branchId: Value(branchId),
        productId: Value(productId),
        quantityDelta: Value(delta),
        reason: Value(reason),
        createdBy: Value(adjustedBy),
        createdAt: Value(now),
        syncedAt: Value(now),
        isSynced: const Value(false),
      ),
    ]);
    await _recomputeLocalRollup(branchId, productId);
  }

  Future<void> manualAdjustment({
    required String branchId,
    required String productId,
    required Decimal newQuantity,
    required Decimal currentQuantity,
    required String adjustedBy,
    required String notes,
    DateTime? expiryDate,
  }) =>
      _queueAdjustment(
        type: 'manual',
        branchId: branchId,
        productId: productId,
        before: currentQuantity,
        after: newQuantity,
        adjustedBy: adjustedBy,
        notes: notes,
        expiryDate: expiryDate,
      );

  Future<void> correctStock({
    required String branchId,
    required String productId,
    required Decimal newQuantity,
    required Decimal currentQuantity,
    required String adjustedBy,
    required String notes,
    DateTime? expiryDate,
  }) =>
      _queueAdjustment(
        type: 'manual',
        branchId: branchId,
        productId: productId,
        before: currentQuantity,
        after: newQuantity,
        adjustedBy: adjustedBy,
        notes: notes,
        expiryDate: expiryDate,
      );

  Future<Decimal> _currentQty(String branchId, String productId) async {
    if (_db == null) return Decimal.zero;
    return await _db.getStockLevel(branchId, productId) ?? Decimal.zero;
  }

  Future<void> _queueAdjustment({
    required String type,
    required String branchId,
    required String productId,
    required Decimal before,
    required Decimal after,
    required String adjustedBy,
    String? notes,
    DateTime? expiryDate,
  }) async {
    final id = const Uuid().v4();

    // Web (no local DB): apply straight to the server.
    if (_db == null) {
      await _remote.applyAdjustment(
        id: id,
        type: type,
        branchId: branchId,
        productId: productId,
        quantityBefore: before,
        quantityAfter: after,
        adjustedBy: adjustedBy,
        notes: notes,
        expiryDate: expiryDate,
      );
      return;
    }

    // Native: optimistic mirror update + queue. No inline push (single
    // boundary): the adjustment stays isSynced=false and SyncService is the
    // sole pusher; the pending-work watcher nudges a sync.
    await _db.setStockLevel(
      branchId,
      productId,
      after,
      expiryDate: expiryDate,
    );
    await _db.insertInventoryAdjustment(LocalInventoryAdjustmentsCompanion(
      id: Value(id),
      branchId: Value(branchId),
      productId: Value(productId),
      type: Value(type),
      quantityBefore: Value(before),
      quantityAfter: Value(after),
      adjustedBy: Value(adjustedBy),
      notes: Value(notes),
      expiryDate: Value(expiryDate),
      createdAt: Value(DateTime.now()),
      isSynced: const Value(false),
    ));
  }

  // ── Mappers ──────────────────────────────────────────────────────────────────

  LocalProductsCompanion _toProductCompanion(Product p) =>
      LocalProductsCompanion(
        id: Value(p.id),
        shopId: Value(p.shopId),
        name: Value(p.name),
        categoryId: Value(p.categoryId),
        description: Value(p.description),
        measurementUnitId: Value(p.measurementUnitId),
        measurementUnitAbbr: Value(p.measurementUnitAbbr),
        lowStockThreshold: Value(p.lowStockThreshold),
        sellingPrice: Value(p.sellingPrice),
        costPrice: Value(p.costPrice),
        isActive: Value(p.isActive),
        syncedAt: Value(DateTime.now()),
      );

  Product _productFromRow(ProductRow r) => Product(
        id: r.id,
        shopId: r.shopId,
        name: r.name,
        categoryId: r.categoryId,
        description: r.description,
        measurementUnitId: r.measurementUnitId,
        measurementUnitAbbr: r.measurementUnitAbbr,
        lowStockThreshold: r.lowStockThreshold,
        sellingPrice: r.sellingPrice,
        costPrice: r.costPrice,
        isActive: r.isActive,
      );
}
