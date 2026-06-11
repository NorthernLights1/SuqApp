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

// ─── Database ─────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [
  LocalProducts,
  LocalStock,
  LocalSales,
  LocalSaleItems,
  LocalCustomers,
  LocalExpenses,
  LocalInventoryAdjustments,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 4;

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
              t.status.equals('completed') &
              t.createdAt.isBiggerOrEqualValue(from) &
              t.createdAt.isSmallerThanValue(to)))
        .get();
    Decimal total = Decimal.zero;
    for (final r in rows) {
      total += r.total;
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

  Future<List<ExpenseRow>> getExpensesByBranch(
          String branchId, DateTime day) =>
      (select(localExpenses)
            ..where((t) =>
                t.branchId.equals(branchId) &
                t.date.equals(DateTime(day.year, day.month, day.day)))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
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
}
