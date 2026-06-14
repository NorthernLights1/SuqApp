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

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('StockRow')
class LocalStock extends Table {
  TextColumn get productId => text()();
  TextColumn get branchId => text()();
  TextColumn get quantity => text().map(const _Dec())();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {productId, branchId};
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
/// display of payment history. Payment *recording* still goes through Supabase.
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
  int get schemaVersion => 7;

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
        },
      );

  // ── Products ───────────────────────────────────────────────────────────────

  Future<void> upsertProducts(List<LocalProductsCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(localProducts, rows));

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
  Future<void> setStockLevel(
          String branchId, String productId, Decimal newQty) =>
      into(localStock).insertOnConflictUpdate(LocalStockCompanion(
        productId: Value(productId),
        branchId: Value(branchId),
        quantity: Value(newQty),
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
        for (final item in items) {
          await into(localSaleItems).insert(item);
        }
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

  /// Hard-remove rows by `id` from an id-keyed local table — used by the delta
  /// pull to apply server soft-deletes (`deleted_at` set). [ids] are bound
  /// parameters; [sqlTable] is interpolated, so — defence-in-depth, even though
  /// callers only ever pass a code constant — it is validated against the real
  /// tables in this schema and rejected otherwise.
  Future<void> deleteByIds(String sqlTable, List<String> ids) async {
    if (ids.isEmpty) return;
    final known = allTables.map((t) => t.actualTableName).toSet();
    if (!known.contains(sqlTable)) {
      throw ArgumentError.value(sqlTable, 'sqlTable', 'not a table in this schema');
    }
    final placeholders = List.filled(ids.length, '?').join(', ');
    await customStatement('DELETE FROM $sqlTable WHERE id IN ($placeholders)', ids);
  }
}
