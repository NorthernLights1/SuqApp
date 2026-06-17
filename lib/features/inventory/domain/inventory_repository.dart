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
    // Local-first: system units are always seeded, so non-empty local is
    // authoritative; empty = pre-seed or web → server.
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
    final category =
        await _remote.createProductCategory(shopId: shopId, name: name);
    await _db?.upsertCategories([
      LocalProductCategoriesCompanion(
        id: Value(category.id),
        shopId: Value(shopId),
        name: Value(category.name),
        syncedAt: Value(DateTime.now()),
      ),
    ]);
    return category;
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
    final product = await _remote.createProduct(
      shopId: shopId,
      name: name,
      measurementUnitId: measurementUnitId,
      lowStockThreshold: lowStockThreshold,
      sellingPrice: sellingPrice,
      costPrice: costPrice,
      categoryId: categoryId,
      description: description,
    );
    // Mirror locally so local-first reads show it immediately (before sync).
    await _db?.upsertProducts([_toProductCompanion(product)]);
    return product;
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
          .toSet();
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
