import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';

part 'app_database.g.dart';

// ─── Type converters ──────────────────────────────────────────────────────────

class _Dec extends TypeConverter<Decimal, String> {
  const _Dec();
  @override
  Decimal fromSql(String s) => Decimal.parse(s);
  @override
  String toSql(Decimal v) => v.toString();
}

class _NullDec extends TypeConverter<Decimal?, String?> {
  const _NullDec();
  @override
  Decimal? fromSql(String? s) => s == null ? null : Decimal.parse(s);
  @override
  String? toSql(Decimal? v) => v?.toString();
}

// ─── Tables ───────────────────────────────────────────────────────────────────

@DataClassName('ProductRow')
class LocalProducts extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text()();
  TextColumn get name => text()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get measurementUnitId => text()();
  TextColumn get measurementUnitAbbr => text()();
  TextColumn get lowStockThreshold => text().map(const _Dec())();
  TextColumn get sellingPrice => text().nullable().map(const _NullDec())();
  TextColumn get costPrice => text().nullable().map(const _NullDec())();
  BoolColumn get isActive => boolean()();
  DateTimeColumn get syncedAt => dateTime()();
  // Default true: server-pulled rows are already on the server.
  // Offline-created products set this false so the push queue picks them up.
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('StockRow')
class LocalStock extends Table {
  TextColumn get productId => text()();
  TextColumn get branchId => text()();
  TextColumn get quantity => text().map(const _Dec())();
  DateTimeColumn get expiryDate => dateTime().nullable()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {productId, branchId};
}

/// One batch/lot of a product at a branch — its own qty, expiry, batch number.
/// Wholesale-only (retail shops have no batches). The server keeps
/// `inventory.quantity` as the rollup of these; the device mirrors them for FEFO
/// depletion + expiry display. Offline-created batches (add-stock) set
/// isSynced=false so the push queue picks them up.
@DataClassName('ProductBatchRow')
class LocalProductBatches extends Table {
  TextColumn get id => text()();
  TextColumn get branchId => text()();
  TextColumn get productId => text()();
  TextColumn get batchNumber => text().nullable()();
  DateTimeColumn get expiryDate => dateTime().nullable()();
  TextColumn get quantity => text().map(const _Dec())();
  TextColumn get costPrice => text().nullable().map(const _NullDec())();
  DateTimeColumn get receivedAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime()();
  // Discard (expired/damaged lot): set locally, pushed up, then the pull
  // hard-removes the row once the server soft-delete comes back.
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// The depletion ledger (wholesale): how much of each sale line was drawn from
/// each batch. Append-only; a void soft-deletes (sets deletedAt). Mirrors
/// `sale_item_batches`. No isSynced — these ride the sale's push (the sale RPC
/// inserts them via p_item_batches), and are pulled back for cross-device
/// per-batch remaining accuracy.
@DataClassName('SaleItemBatchRow')
class LocalSaleItemBatches extends Table {
  TextColumn get id => text()();
  TextColumn get saleItemId => text()();
  TextColumn get batchId => text()();
  TextColumn get quantity => text().map(const _Dec())();
  DateTimeColumn get syncedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SaleRow')
class LocalSales extends Table {
  TextColumn get id => text()();
  TextColumn get branchId => text()();
  TextColumn get customerId => text().nullable()();
  TextColumn get cashierId => text()();
  TextColumn get paymentMethodId => text()();
  TextColumn get subtotal => text().map(const _Dec())();
  TextColumn get discountAmount => text().map(const _Dec())();
  TextColumn get total => text().map(const _Dec())();
  TextColumn get status => text()();
  TextColumn get voidReason => text().nullable()();
  TextColumn get voidedBy => text().nullable()();
  DateTimeColumn get voidedAt => dateTime().nullable()();
  BoolColumn get isCredit => boolean()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get creditSettledAt => dateTime().nullable()();
  // Single settlement method when every payment used the same one (parity with
  // the online path); null for mixed/unknown.
  TextColumn get creditSettlementMethod => text().nullable()();
  // Denormalized names captured at write/pull time so offline detail screens
  // (Sales/Credits) can show them without a Supabase join. Null on rows written
  // before v7 / before they are populated.
  TextColumn get customerName => text().nullable()();
  TextColumn get cashierName => text().nullable()();
  TextColumn get paymentMethodName => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SaleItemRow')
class LocalSaleItems extends Table {
  TextColumn get id => text()();
  TextColumn get saleId => text()();
  TextColumn get productId => text().nullable()();
  TextColumn get productNameSnapshot => text()();
  TextColumn get measurementUnitId => text().nullable()();
  TextColumn get quantity => text().map(const _Dec())();
  TextColumn get unitPrice => text().map(const _Dec())();
  TextColumn get discountAmount => text().map(const _Dec())();
  TextColumn get total => text().map(const _Dec())();
  TextColumn get inventoryStatus => text()();
  TextColumn get costPriceSnapshot => text().nullable().map(const _NullDec())();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CustomerRow')
class LocalCustomers extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get creditBalance => text().map(const _Dec())();
  DateTimeColumn get updatedAt => dateTime()();
  // Default true: downloaded rows are already on the server. Offline-created
  // customers set this false (see customers_repository) so the push queue picks
  // them up. Keep the default true so server-pulled rows (seed) and the column
  // retrofit mark themselves synced without each call site repeating it.
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Pending stock operations (add / opening / manual / correction) waiting to
/// reach Supabase. Each row also carries the locally-computed before/after so
/// the push can apply the right effect (additive delta vs absolute override).
@DataClassName('InventoryAdjustmentRow')
class LocalInventoryAdjustments extends Table {
  TextColumn get id => text()();
  TextColumn get branchId => text()();
  TextColumn get productId => text()();
  TextColumn get type => text()(); // opening_stock | restock | manual
  TextColumn get quantityBefore => text().map(const _Dec())();
  TextColumn get quantityAfter => text().map(const _Dec())();
  TextColumn get adjustedBy => text()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get expiryDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ExpenseRow')
class LocalExpenses extends Table {
  TextColumn get id => text()();
  TextColumn get branchId => text()();
  TextColumn get categoryId => text()();
  TextColumn get categoryName => text()(); // denormalized for offline display
  TextColumn get amount => text().map(const _Dec())();
  TextColumn get description => text().nullable()();
  TextColumn get recordedBy => text()();
  DateTimeColumn get date => dateTime()(); // calendar date (midnight)
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Reference / read-cache tables (download-sync only, never queued) ─────────

@DataClassName('ShopRow')
class LocalShops extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get config => text().withDefault(const Constant('{}'))(); // json
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('BranchRow')
class LocalBranches extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text()();
  TextColumn get name => text()();
  TextColumn get address => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Shop-level settings (branch-level not used yet). Keyed by (shopId, key).
@DataClassName('SettingRow')
class LocalShopSettings extends Table {
  TextColumn get shopId => text()();
  TextColumn get key => text()();
  TextColumn get value => text()(); // raw json-encoded value, as stored remotely
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {shopId, key};
}

@DataClassName('PaymentMethodRow')
class LocalPaymentMethods extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get code => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ProductCategoryRow')
class LocalProductCategories extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text()();
  TextColumn get name => text()();
  DateTimeColumn get syncedAt => dateTime()();
  // Default true: server-pulled rows are already on the server.
  // Offline-created categories set this false so the push queue picks them up.
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MeasurementUnitRow')
class LocalMeasurementUnits extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get abbreviation => text()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Shop members' display names (for "Sold by" on sales). Downloaded only.
@DataClassName('ProfileRow')
class LocalProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get fullName => text().nullable()();
  TextColumn get phone => text().nullable()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ExpenseCategoryRow')
class LocalExpenseCategories extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text().nullable()();
  TextColumn get name => text()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Recorded credit payments (the dispute audit trail), downloaded for offline
/// display AND offline recording (the push queue picks up unsynced rows).
@DataClassName('CreditPaymentRow')
class LocalCreditPayments extends Table {
  TextColumn get id => text()();
  TextColumn get saleId => text()();
  TextColumn get customerId => text().nullable()();
  TextColumn get amount => text().map(const _Dec())();
  TextColumn get method => text()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime()();
  // Default true: downloaded rows are already on the server. Offline-recorded
  // payments set this false so the push queue picks them up.
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Per-table delta-pull cursor: the max server `updated_at` already pulled for
/// a replica table. The delta pull fetches `where updated_at >= lastPulledAt`
/// (>= not >, so rows sharing the boundary timestamp aren't skipped — Postgres
/// `now()` is constant within a transaction, so a sale + its items share one
/// `updated_at`; idempotent upsert makes the small re-overlap harmless).
/// No row = never pulled = do a full first download.
///
/// Single-shop by design: the device replicates one shop per session, so the
/// cursor is keyed by table only, not by shop.
@DataClassName('SyncStateRow')
class LocalSyncState extends Table {
  TextColumn get tableKey => text()();
  DateTimeColumn get lastPulledAt => dateTime()();

  @override
  Set<Column> get primaryKey => {tableKey};
}

// ─── Database ─────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [
  LocalProducts,
  LocalStock,
  LocalProductBatches,
  LocalSaleItemBatches,
  LocalSales,
  LocalSaleItems,
  LocalCustomers,
  LocalExpenses,
  LocalInventoryAdjustments,
  LocalShops,
  LocalBranches,
  LocalShopSettings,
  LocalPaymentMethods,
  LocalProductCategories,
  LocalMeasurementUnits,
  LocalProfiles,
  LocalExpenseCategories,
  LocalCreditPayments,
  LocalSyncState,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 14;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // v1 -> v2: offline-first expenses queue.
          if (from < 2) await m.createTable(localExpenses);
          // v2 -> v3: offline-first inventory adjustments queue.
          if (from < 3) await m.createTable(localInventoryAdjustments);
          // v3 -> v4: credit settlement state on the local sales mirror.
          if (from < 4) {
            await m.addColumn(localSales, localSales.creditSettledAt);
          }
          // v4 -> v5: offline-first read caches (shop/branches/settings/payment
          // methods/categories/units/profiles/credit payments).
          if (from < 5) {
            await m.createTable(localShops);
            await m.createTable(localBranches);
            await m.createTable(localShopSettings);
            await m.createTable(localPaymentMethods);
            await m.createTable(localProductCategories);
            await m.createTable(localMeasurementUnits);
            await m.createTable(localProfiles);
            await m.createTable(localCreditPayments);
          }
          // v5 -> v6: expense categories read cache.
          if (from < 6) await m.createTable(localExpenseCategories);
          // v6 -> v7: offline-first v2 — per-table delta-pull cursors +
          // denormalized customer/cashier/payment names on the local sales
          // mirror (so offline detail screens render without a Supabase join).
          if (from < 7) {
            await m.createTable(localSyncState);
            await m.addColumn(localSales, localSales.customerName);
            await m.addColumn(localSales, localSales.cashierName);
            await m.addColumn(localSales, localSales.paymentMethodName);
          }
          // v7 -> v8: offline credit settlement — credit payments can be
          // recorded offline and queued for push.
          // Lower bound matters: localCreditPayments is created (createTable) in
          // the v5 step, which always builds the *current* schema — so a DB at
          // from < 5 already gets isSynced from createTable and must NOT addColumn
          // it again (that would be a duplicate-column error). Only DBs created at
          // v5–v7 (before isSynced was added) need the retrofit.
          if (from >= 5 && from < 8) {
            await m.addColumn(localCreditPayments, localCreditPayments.isSynced);
          }
          // v8 -> v9: store the sale-level settlement method locally so an
          // offline settlement matches the online path.
          if (from < 9) {
            await m.addColumn(
                localSales, localSales.creditSettlementMethod);
          }
          // v9 -> v10: retain stock expiry dates in the offline mirror.
          if (from < 10) {
            await m.addColumn(localStock, localStock.expiryDate);
          }
          // v10 -> v11: offline-first product and category creation.
          // localProducts exists since v1 — all existing DBs need addColumn.
          // localProductCategories was created in the v5 step via createTable,
          // which picks up the current schema at compile time. DBs that upgraded
          // through v5 already have isSynced from that createTable call; only
          // DBs that were already at v5+ before this change need addColumn.
          if (from < 11) {
            await m.addColumn(localProducts, localProducts.isSynced);
            if (from >= 5) {
              await m.addColumn(
                  localProductCategories, localProductCategories.isSynced);
            }
          }
          // v11 -> v12: wholesale batch/expiry mirror (FEFO depletion + expiry).
          if (from < 12) await m.createTable(localProductBatches);
          // v12 -> v13: wholesale depletion ledger (sale_item_batches mirror).
          if (from < 13) await m.createTable(localSaleItemBatches);
          // v13 -> v14: lot discard (soft-delete) on the batch mirror.
          // localProductBatches is created (createTable) in the v12 step, which
          // always builds the *current* schema — so a DB at from < 12 already
          // gets deletedAt there and must NOT addColumn it again (duplicate-
          // column error). Only DBs that were already at v12/v13 (table created
          // before deletedAt existed) need the retrofit.
          if (from >= 12 && from < 14) {
            await m.addColumn(localProductBatches, localProductBatches.deletedAt);
          }
        },
      );

  // ── Products ───────────────────────────────────────────────────────────────

  Future<void> upsertProducts(List<LocalProductsCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(localProducts, rows));

  Future<List<ProductRow>> getPendingProducts() =>
      (select(localProducts)..where((t) => t.isSynced.equals(false))).get();

  Future<void> markProductSynced(String id) =>
      (update(localProducts)..where((t) => t.id.equals(id)))
          .write(const LocalProductsCompanion(isSynced: Value(true)));

  Future<List<ProductRow>> getProductsByShop(String shopId) =>
      (select(localProducts)
            ..where((t) => t.shopId.equals(shopId) & t.isActive.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();

  Future<List<ProductRow>> searchProducts(String shopId, String query) =>
      (select(localProducts)
            ..where((t) =>
                t.shopId.equals(shopId) &
                t.isActive.equals(true) &
                t.name.like('%$query%'))
            ..limit(20))
          .get();

  // ── Stock ──────────────────────────────────────────────────────────────────

  Future<void> upsertStock(List<LocalStockCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(localStock, rows));

  // ── Product batches (wholesale) ──────────────────────────────────────────────

  Future<void> upsertProductBatches(List<LocalProductBatchesCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(localProductBatches, rows));

  /// A product's batches at a branch in FEFO order: soonest expiry first, nulls
  /// (non-perishable) last. Empty/zero batches are kept out of depletion by the
  /// caller. Used by Phase 3 (depletion) and Phase 4 (expiry display).
  Future<List<ProductBatchRow>> getBatchesForProduct(
          String branchId, String productId) =>
      (select(localProductBatches)
            ..where((t) =>
                t.branchId.equals(branchId) &
                t.productId.equals(productId) &
                t.deletedAt.isNull()) // discarded lots are excluded everywhere
            ..orderBy([
              (t) => OrderingTerm.asc(t.expiryDate, nulls: NullsOrder.last),
            ]))
          .get();

  Future<ProductBatchRow?> getBatch(String id) =>
      (select(localProductBatches)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  /// Discard a lot (expired/damaged): soft-delete locally + queue the push. The
  /// caller recomputes the product rollup afterwards.
  Future<void> discardBatch(String id, DateTime when) =>
      (update(localProductBatches)..where((t) => t.id.equals(id))).write(
        LocalProductBatchesCompanion(
          deletedAt: Value(when),
          isSynced: const Value(false),
        ),
      );

  Future<List<ProductBatchRow>> getPendingProductBatches() =>
      (select(localProductBatches)..where((t) => t.isSynced.equals(false)))
          .get();

  Future<void> markProductBatchSynced(String id) =>
      (update(localProductBatches)..where((t) => t.id.equals(id)))
          .write(const LocalProductBatchesCompanion(isSynced: Value(true)));

  /// Product ids at [branchId] with an unpushed batch — so a background stock
  /// refresh won't clobber the optimistic rollup before the batch syncs.
  Future<Set<String>> getPendingBatchProductIds(String branchId) async {
    final rows = await (select(localProductBatches)
          ..where((t) => t.branchId.equals(branchId) & t.isSynced.equals(false)))
        .get();
    return rows.map((r) => r.productId).toSet();
  }

  // ── Sale-item batches (depletion ledger, wholesale) ──────────────────────────

  Future<void> upsertSaleItemBatches(
          List<LocalSaleItemBatchesCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(localSaleItemBatches, rows));

  /// Non-deleted depletion summed per batch, for the given batch ids. Used to
  /// compute FEFO `remaining(batch) = received − depleted`.
  Future<Map<String, Decimal>> depletionByBatch(List<String> batchIds) async {
    if (batchIds.isEmpty) return {};
    final rows = await (select(localSaleItemBatches)
          ..where((t) => t.batchId.isIn(batchIds) & t.deletedAt.isNull()))
        .get();
    final map = <String, Decimal>{};
    for (final r in rows) {
      map[r.batchId] = (map[r.batchId] ?? Decimal.zero) + r.quantity;
    }
    return map;
  }

  /// The active depletions for a sale's items — used to build the sale RPC's
  /// `p_item_batches` payload on push.
  Future<List<SaleItemBatchRow>> getSaleItemBatchesForItems(
      List<String> saleItemIds) {
    if (saleItemIds.isEmpty) return Future.value(const []);
    return (select(localSaleItemBatches)
          ..where((t) => t.saleItemId.isIn(saleItemIds) & t.deletedAt.isNull()))
        .get();
  }

  /// Void: soft-delete a sale's depletions so the local rollup restores.
  Future<void> softDeleteSaleItemBatches(
      List<String> saleItemIds, DateTime when) async {
    if (saleItemIds.isEmpty) return;
    await (update(localSaleItemBatches)
          ..where((t) => t.saleItemId.isIn(saleItemIds)))
        .write(LocalSaleItemBatchesCompanion(deletedAt: Value(when)));
  }

  /// Recompute the local stock rollup for a wholesale product from its batches:
  /// `LocalStock.quantity = Σ(received) − Σ(non-deleted depletions)` — the same
  /// derivation as the server rollup trigger (029). The stock row's expiry = the
  /// soonest expiry among lots that still have remaining stock.
  Future<void> recomputeStockFromBatches(
      String branchId, String productId, DateTime now) async {
    final batches = await getBatchesForProduct(branchId, productId);
    final depleted = await depletionByBatch(batches.map((b) => b.id).toList());
    var total = Decimal.zero;
    DateTime? soonest;
    for (final b in batches) {
      final remaining = b.quantity - (depleted[b.id] ?? Decimal.zero);
      total += remaining;
      if (remaining <= Decimal.zero) continue; // exhausted lot — ignore expiry
      final e = b.expiryDate;
      if (e != null && (soonest == null || e.isBefore(soonest))) soonest = e;
    }
    await setStockLevel(branchId, productId, total,
        expiryDate: soonest, overwriteExpiry: true);
  }

  Future<List<StockRow>> getStockByBranch(String branchId) =>
      (select(localStock)..where((t) => t.branchId.equals(branchId))).get();

  Future<Decimal?> getStockLevel(String branchId, String productId) async {
    final row = await (select(localStock)
          ..where((t) =>
              t.branchId.equals(branchId) & t.productId.equals(productId)))
        .getSingleOrNull();
    return row?.quantity;
  }

  Future<void> adjustStock(
          String branchId, String productId, Decimal newQty) =>
      (update(localStock)
            ..where((t) =>
                t.branchId.equals(branchId) & t.productId.equals(productId)))
          .write(LocalStockCompanion(
              quantity: Value(newQty), syncedAt: Value(DateTime.now())));

  /// Upsert a single stock level (used by stock ops, which may target a
  /// product that has no local row yet — e.g. opening stock).
  /// Upsert a single stock level. By default a null [expiryDate] leaves any
  /// existing expiry untouched (callers that only set quantity). The batch
  /// rollup is the authoritative projection of expiry, so it passes
  /// [overwriteExpiry] to push null through and CLEAR a stale date once the
  /// expiring lot is sold out or discarded.
  Future<void> setStockLevel(
          String branchId, String productId, Decimal newQty,
          {DateTime? expiryDate, bool overwriteExpiry = false}) =>
      into(localStock).insertOnConflictUpdate(LocalStockCompanion(
        productId: Value(productId),
        branchId: Value(branchId),
        quantity: Value(newQty),
        expiryDate: overwriteExpiry || expiryDate != null
            ? Value(expiryDate)
            : const Value.absent(),
        syncedAt: Value(DateTime.now()),
      ));

  Future<List<ProductRow>> getProductsByIds(List<String> ids) =>
      (select(localProducts)..where((t) => t.id.isIn(ids))).get();

  // ── Sales ──────────────────────────────────────────────────────────────────

  Future<SaleRow> insertSaleWithItems(
    LocalSalesCompanion sale,
    List<LocalSaleItemsCompanion> items,
  ) =>
      transaction(() async {
        final row = await into(localSales).insertReturning(sale);
        for (final item in items) {
          await into(localSaleItems).insert(item);
        }
        return row;
      });

  Future<SaleRow?> getSale(String id) =>
      (select(localSales)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<SaleRow>> getSalesByBranch(
          String branchId, DateTime from, DateTime to) =>
      (select(localSales)
            ..where((t) =>
                t.branchId.equals(branchId) &
                t.createdAt.isBiggerOrEqualValue(from) &
                t.createdAt.isSmallerThanValue(to))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<List<SaleItemRow>> getSaleItems(String saleId) =>
      (select(localSaleItems)..where((t) => t.saleId.equals(saleId))).get();

  Future<List<SaleRow>> getSalesByCustomer(String customerId,
          {int limit = 20}) =>
      (select(localSales)
            ..where((t) => t.customerId.equals(customerId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(limit))
          .get();

  Future<List<SaleRow>> getPendingSales() =>
      (select(localSales)..where((t) => t.isSynced.equals(false))).get();

  /// Products whose optimistic stock must not be overwritten by a server pull.
  /// This includes both explicit stock operations and tracked items in sales
  /// that have not reached the transactional sale RPC yet.
  Future<Set<String>> getPendingStockProductIds(String branchId) async {
    final rows = await customSelect(
      'SELECT DISTINCT si.product_id AS product_id '
      'FROM local_sale_items si '
      'JOIN local_sales s ON s.id = si.sale_id '
      'WHERE s.branch_id = ? AND s.is_synced = 0 '
      'AND si.product_id IS NOT NULL '
      'AND si.inventory_status != ? '
      'UNION '
      'SELECT product_id FROM local_inventory_adjustments '
      'WHERE branch_id = ? AND is_synced = 0',
      variables: [
        Variable<String>(branchId),
        const Variable<String>('untracked'),
        Variable<String>(branchId),
      ],
      readsFrom: {
        localSales,
        localSaleItems,
        localInventoryAdjustments,
      },
    ).get();
    return rows.map((row) => row.read<String>('product_id')).toSet();
  }

  Future<void> markSaleSynced(String saleId) =>
      (update(localSales)..where((t) => t.id.equals(saleId)))
          .write(const LocalSalesCompanion(isSynced: Value(true)));

  /// Mark a single local credit sale settled (mirrors a server-side settlement
  /// so the offline sales list stops showing it as outstanding).
  Future<void> markSaleCreditSettled(String saleId) =>
      (update(localSales)..where((t) => t.id.equals(saleId))).write(
        LocalSalesCompanion(creditSettledAt: Value(DateTime.now())),
      );

  Future<void> markSaleVoided(
          String saleId, String reason, String voidedBy) =>
      (update(localSales)..where((t) => t.id.equals(saleId))).write(
        LocalSalesCompanion(
          status: const Value('voided'),
          voidReason: Value(reason),
          voidedBy: Value(voidedBy),
          voidedAt: Value(DateTime.now()),
          isSynced: const Value(true),
        ),
      );

  Future<Map<String, Decimal>> getTodayTotals(
      String branchId, DateTime date) async {
    final from = DateTime(date.year, date.month, date.day);
    final to = from.add(const Duration(days: 1));
    final rows = await (select(localSales)
          ..where((t) =>
              t.branchId.equals(branchId) &
              t.createdAt.isBiggerOrEqualValue(from) &
              t.createdAt.isSmallerThanValue(to)))
        .get();
    // Revenue excludes voided sales, but the transaction count keeps them:
    // a voided sale still happened, so the day's transaction tally must not
    // shrink when one is voided.
    Decimal total = Decimal.zero;
    for (final r in rows) {
      if (r.status == 'completed') total += r.total;
    }
    return {'total': total, 'count': Decimal.fromInt(rows.length)};
  }

  // ── Customers ─────────────────────────────────────────────────────────────

  Future<void> upsertCustomers(List<LocalCustomersCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(localCustomers, rows));

  Future<void> upsertCustomer(LocalCustomersCompanion row) =>
      into(localCustomers).insertOnConflictUpdate(row);

  Future<List<CustomerRow>> getCustomersByShop(String shopId) =>
      (select(localCustomers)
            ..where((t) => t.shopId.equals(shopId))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();

  Future<List<CustomerRow>> getPendingCustomers() =>
      (select(localCustomers)..where((t) => t.isSynced.equals(false))).get();

  /// Update identity fields offline and flag the row for re-push. Leaves the
  /// locally-mirrored credit balance untouched.
  Future<void> updateCustomerIdentity(
          String id, String name, String? phone) =>
      (update(localCustomers)..where((t) => t.id.equals(id))).write(
        LocalCustomersCompanion(
          name: Value(name),
          phone: Value(phone),
          updatedAt: Value(DateTime.now()),
          isSynced: const Value(false),
        ),
      );

  Future<void> markCustomerSynced(String id) =>
      (update(localCustomers)..where((t) => t.id.equals(id)))
          .write(const LocalCustomersCompanion(isSynced: Value(true)));

  Future<List<CustomerRow>> searchCustomers(String shopId, String query) =>
      (select(localCustomers)
            ..where((t) =>
                t.shopId.equals(shopId) & t.name.like('%$query%'))
            ..orderBy([(t) => OrderingTerm.asc(t.name)])
            ..limit(10))
          .get();

  // ── Expenses ────────────────────────────────────────────────────────────────

  Future<void> insertExpense(LocalExpensesCompanion row) =>
      into(localExpenses).insert(row);

  /// Upsert a downloaded expense (pull path).
  Future<void> insertOrReplaceExpense(LocalExpensesCompanion row) =>
      into(localExpenses).insertOnConflictUpdate(row);

  Future<List<ExpenseRow>> getExpensesByBranch(
          String branchId, DateTime day) =>
      (select(localExpenses)
            ..where((t) =>
                t.branchId.equals(branchId) &
                t.date.equals(DateTime(day.year, day.month, day.day)))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<List<ExpenseRow>> getExpensesByBranchRange(
          String branchId, DateTime from, DateTime to) =>
      (select(localExpenses)
            ..where((t) =>
                t.branchId.equals(branchId) &
                t.date.isBiggerOrEqualValue(from) &
                t.date.isSmallerThanValue(to)))
          .get();

  Future<List<ExpenseRow>> getPendingExpenses() =>
      (select(localExpenses)..where((t) => t.isSynced.equals(false))).get();

  Future<List<ExpenseRow>> getPendingExpensesByBranch(
          String branchId, DateTime day) =>
      (select(localExpenses)
            ..where((t) =>
                t.branchId.equals(branchId) &
                t.isSynced.equals(false) &
                t.date.equals(DateTime(day.year, day.month, day.day)))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<void> markExpenseSynced(String id) =>
      (update(localExpenses)..where((t) => t.id.equals(id)))
          .write(const LocalExpensesCompanion(isSynced: Value(true)));

  // ── Inventory adjustments queue ──────────────────────────────────────────────

  Future<void> insertInventoryAdjustment(
          LocalInventoryAdjustmentsCompanion row) =>
      into(localInventoryAdjustments).insert(row);

  Future<List<InventoryAdjustmentRow>> getPendingInventoryAdjustments() =>
      (select(localInventoryAdjustments)
            ..where((t) => t.isSynced.equals(false))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

  Future<void> markInventoryAdjustmentSynced(String id) =>
      (update(localInventoryAdjustments)..where((t) => t.id.equals(id)))
          .write(const LocalInventoryAdjustmentsCompanion(isSynced: Value(true)));

  // ── Shop / branches (download-sync read caches) ──────────────────────────────

  Future<void> upsertShop(LocalShopsCompanion row) =>
      into(localShops).insertOnConflictUpdate(row);

  Future<ShopRow?> getShopById(String id) =>
      (select(localShops)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<ShopRow?> getAnyShop() =>
      (select(localShops)..limit(1)).getSingleOrNull();

  Future<void> upsertBranches(List<LocalBranchesCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(localBranches, rows));

  Future<List<BranchRow>> getBranchesByShop(String shopId) =>
      (select(localBranches)
            ..where((t) => t.shopId.equals(shopId) & t.isActive.equals(true)))
          .get();

  /// Any local branch (for the device-level sync heartbeat, which needs a valid
  /// branch_id but isn't branch-specific). Null before the first seed.
  Future<BranchRow?> getAnyBranch() =>
      (select(localBranches)..limit(1)).getSingleOrNull();

  // ── Shop settings ────────────────────────────────────────────────────────────

  Future<void> upsertSettings(List<LocalShopSettingsCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(localShopSettings, rows));

  Future<List<SettingRow>> getSettings(String shopId) =>
      (select(localShopSettings)..where((t) => t.shopId.equals(shopId))).get();

  // ── Payment methods ──────────────────────────────────────────────────────────

  Future<void> upsertPaymentMethods(List<LocalPaymentMethodsCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(localPaymentMethods, rows));

  Future<List<PaymentMethodRow>> getPaymentMethods() =>
      (select(localPaymentMethods)..where((t) => t.isActive.equals(true))).get();

  // ── Product categories ───────────────────────────────────────────────────────

  Future<void> upsertCategories(List<LocalProductCategoriesCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(localProductCategories, rows));

  Future<List<ProductCategoryRow>> getCategories(String shopId) =>
      (select(localProductCategories)..where((t) => t.shopId.equals(shopId)))
          .get();

  Future<List<ProductCategoryRow>> getPendingCategories() =>
      (select(localProductCategories)..where((t) => t.isSynced.equals(false)))
          .get();

  Future<void> markCategorySynced(String id) =>
      (update(localProductCategories)..where((t) => t.id.equals(id)))
          .write(const LocalProductCategoriesCompanion(isSynced: Value(true)));

  // ── Measurement units ────────────────────────────────────────────────────────

  Future<void> upsertUnits(List<LocalMeasurementUnitsCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(localMeasurementUnits, rows));

  Future<List<MeasurementUnitRow>> getUnits() =>
      (select(localMeasurementUnits)).get();

  // ── Profiles (cashier names) ─────────────────────────────────────────────────

  Future<void> upsertProfiles(List<LocalProfilesCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(localProfiles, rows));

  Future<List<ProfileRow>> getProfiles() => (select(localProfiles)).get();

  // ── Expense categories ───────────────────────────────────────────────────────

  Future<void> upsertExpenseCategories(
          List<LocalExpenseCategoriesCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(localExpenseCategories, rows));

  Future<List<ExpenseCategoryRow>> getExpenseCategories(String shopId) =>
      (select(localExpenseCategories)
            ..where((t) => t.shopId.equals(shopId) | t.shopId.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();

  // ── Downloaded sales (replace a synced sale + its items atomically) ──────────

  /// Upsert a server sale and atomically replace its items. Callers are
  /// responsible for skipping sales with an unsynced local version (those are
  /// owned by the push path) — see SeedService._seedSales.
  Future<void> upsertDownloadedSale(
    LocalSalesCompanion sale,
    List<LocalSaleItemsCompanion> items,
    String saleId,
  ) =>
      transaction(() async {
        await into(localSales).insertOnConflictUpdate(sale);
        await (delete(localSaleItems)..where((t) => t.saleId.equals(saleId)))
            .go();
        await batch((b) => b.insertAll(localSaleItems, items));
      });

  // ── Credit payments (offline payment history) ────────────────────────────────

  Future<void> upsertCreditPayments(List<LocalCreditPaymentsCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(localCreditPayments, rows));

  /// All unsettled credit sales (completed, not voided, not yet settled) in the
  /// local DB (single-shop), newest first — drives the offline Credits views.
  Future<List<SaleRow>> getUnsettledCreditSales() =>
      (select(localSales)
            ..where((t) =>
                t.isCredit.equals(true) &
                t.status.equals('completed') &
                t.creditSettledAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<List<CreditPaymentRow>> getCreditPaymentsForSale(String saleId) =>
      (select(localCreditPayments)
            ..where((t) => t.saleId.equals(saleId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  /// Sum of recorded payments per sale, across the given sale ids — used to
  /// compute remaining balances offline.
  Future<Map<String, Decimal>> getPaidBySale(List<String> saleIds) async {
    if (saleIds.isEmpty) return {};
    final rows = await (select(localCreditPayments)
          ..where((t) => t.saleId.isIn(saleIds)))
        .get();
    final map = <String, Decimal>{};
    for (final r in rows) {
      map[r.saleId] = (map[r.saleId] ?? Decimal.zero) + r.amount;
    }
    return map;
  }

  /// Record a credit payment locally (offline-first). Flagged unsynced so the
  /// push queue sends it; `getPaidBySale` already sums it for the running total.
  Future<void> recordLocalCreditPayment({
    required String id,
    required String saleId,
    String? customerId,
    required Decimal amount,
    required String method,
    String? notes,
  }) =>
      into(localCreditPayments).insert(LocalCreditPaymentsCompanion(
        id: Value(id),
        saleId: Value(saleId),
        customerId: Value(customerId),
        amount: Value(amount),
        method: Value(method),
        notes: Value(notes),
        createdAt: Value(DateTime.now()),
        syncedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ));

  Future<List<CreditPaymentRow>> getPendingCreditPayments() =>
      (select(localCreditPayments)..where((t) => t.isSynced.equals(false)))
          .get();

  Future<void> markCreditPaymentSynced(String id) =>
      (update(localCreditPayments)..where((t) => t.id.equals(id)))
          .write(const LocalCreditPaymentsCompanion(isSynced: Value(true)));

  /// Stamp a credit sale settled locally AND flag it unsynced, so the sale push
  /// re-sends it carrying `credit_settled_at` (+ method). [method] is the single
  /// settlement method when every payment used the same one, else null.
  Future<void> markSaleSettledLocal(String saleId, {String? method}) =>
      (update(localSales)..where((t) => t.id.equals(saleId))).write(
        LocalSalesCompanion(
          creditSettledAt: Value(DateTime.now()),
          creditSettlementMethod: Value(method),
          isSynced: const Value(false),
        ),
      );

  /// Atomically record an offline credit payment and settle the sale when the
  /// recorded payments cover its total. Returns true if it settled. Wrapped in a
  /// transaction so a crash can't leave a payment recorded but the bill unsettled.
  Future<bool> recordCreditPaymentTxn({
    required String id,
    required String saleId,
    String? customerId,
    required Decimal saleTotal,
    required Decimal amount,
    required String method,
    String? notes,
  }) =>
      transaction(() async {
        await recordLocalCreditPayment(
          id: id,
          saleId: saleId,
          customerId: customerId,
          amount: amount,
          method: method,
          notes: notes,
        );
        final paid = (await getPaidBySale([saleId]))[saleId] ?? Decimal.zero;
        if (paid < saleTotal) return false;
        // Settled: claim a single method only when every payment used the same.
        final methods =
            (await getCreditPaymentsForSale(saleId)).map((p) => p.method).toSet();
        await markSaleSettledLocal(saleId,
            method: methods.length == 1 ? methods.first : null);
        return true;
      });

  /// Sale items for many sales in one query, grouped by saleId (avoids N+1 when
  /// building a sales list).
  Future<Map<String, List<SaleItemRow>>> getSaleItemsForSales(
      List<String> saleIds) async {
    if (saleIds.isEmpty) return {};
    final rows = await (select(localSaleItems)
          ..where((t) => t.saleId.isIn(saleIds)))
        .get();
    final map = <String, List<SaleItemRow>>{};
    for (final r in rows) {
      (map[r.saleId] ??= []).add(r);
    }
    return map;
  }

  // ── Sync state (per-table delta-pull cursors) ────────────────────────────────

  /// The max server `updated_at` already pulled for [tableName], or null if the
  /// table has never been pulled (→ the delta pull does a full first download).
  Future<DateTime?> getPullCursor(String tableName) async {
    final row = await (select(localSyncState)
          ..where((t) => t.tableKey.equals(tableName)))
        .getSingleOrNull();
    return row?.lastPulledAt;
  }

  /// Advance (or set) the delta cursor for [tableName] to [lastPulledAt].
  Future<void> setPullCursor(String tableName, DateTime lastPulledAt) =>
      into(localSyncState).insertOnConflictUpdate(LocalSyncStateCompanion(
        tableKey: Value(tableName),
        lastPulledAt: Value(lastPulledAt),
      ));

  /// Emits whether any local write is waiting to push. Drives a debounced sync
  /// nudge after offline writes. Loop-safe: pulled rows are `is_synced = 1`, so a
  /// pull never re-arms this — only genuine pending work flips it true.
  Stream<bool> watchHasPendingWork() {
    return customSelect(
      'SELECT ('
      'EXISTS(SELECT 1 FROM local_product_categories WHERE is_synced = 0) OR '
      'EXISTS(SELECT 1 FROM local_products WHERE is_synced = 0) OR '
      'EXISTS(SELECT 1 FROM local_product_batches WHERE is_synced = 0) OR '
      'EXISTS(SELECT 1 FROM local_sales WHERE is_synced = 0) OR '
      'EXISTS(SELECT 1 FROM local_expenses WHERE is_synced = 0) OR '
      'EXISTS(SELECT 1 FROM local_inventory_adjustments WHERE is_synced = 0) OR '
      'EXISTS(SELECT 1 FROM local_customers WHERE is_synced = 0) OR '
      'EXISTS(SELECT 1 FROM local_credit_payments WHERE is_synced = 0)'
      ') AS has_pending',
      readsFrom: {
        localProductCategories,
        localProducts,
        localProductBatches,
        localSales,
        localExpenses,
        localInventoryAdjustments,
        localCustomers,
        localCreditPayments,
      },
    ).watch().map((rows) => rows.first.read<int>('has_pending') == 1);
  }

  /// Tables the delta pull may hard-remove rows from by `id` (server
  /// soft-deletes). Explicit allowlist — not merely "is a real table": every
  /// entry is single-column `id`-keyed, so a composite-key table (local_stock,
  /// local_shop_settings, local_sync_state) can never be passed here by mistake,
  /// and the interpolated table name is bound to a constant set (SQL-injection
  /// defence in depth). Keep in sync with the `deleteFromTable:` args in
  /// SeedService.
  static const _deletableByIdTables = {
    'local_branches',
    'local_payment_methods',
    'local_product_categories',
    'local_measurement_units',
    'local_products',
    'local_product_batches',
    'local_sale_item_batches',
    'local_customers',
    'local_expense_categories',
    'local_expenses',
    'local_credit_payments',
  };

  /// Hard-remove rows by `id` from an id-keyed replica table — used by the delta
  /// pull to apply server soft-deletes. [ids] are bound parameters; [sqlTable]
  /// is interpolated but validated against [_deletableByIdTables] first.
  Future<void> deleteByIds(String sqlTable, List<String> ids) async {
    if (ids.isEmpty) return;
    if (!_deletableByIdTables.contains(sqlTable)) {
      throw ArgumentError.value(
          sqlTable, 'sqlTable', 'not an id-keyed delta-replica table');
    }
    final placeholders = List.filled(ids.length, '?').join(', ');
    await customStatement('DELETE FROM $sqlTable WHERE id IN ($placeholders)', ids);
  }
}
