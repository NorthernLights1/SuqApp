import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/inventory/data/inventory_remote.dart';
import 'app_database.dart';

/// Downloads server state into the local database (the "pull" half of sync).
///
/// Two kinds of data:
///   * Read-cache / reference tables (shop, branches, settings, payment
///     methods, categories, units, profiles) — never written locally, so they
///     are safely overwritten on every pull.
///   * Mirror tables that also accept offline writes (products, stock,
///     customers) — pulled here for the full picture; the push path owns the
///     unsynced local rows.
///
/// Runs on login and on every sync trigger (cold start / reconnect / resume /
/// 15-min backstop) via the SyncScheduler.
class SeedService {
  SeedService(this._client, this._inventoryRemote, this._db);

  final SupabaseClient _client;
  final InventoryRemote _inventoryRemote;
  final AppDatabase _db;

  /// One timestamp shared by every row in a single pull (set at the start of
  /// [seedAll]) so a pull is stamped atomically.
  DateTime _now = DateTime.now();

  Future<void> seedAll({
    required String shopId,
    required String branchId,
  }) async {
    _now = DateTime.now();
    // Independent pulls run together; each catches its own errors so one
    // failure (or being offline) doesn't abort the rest.
    await Future.wait([
      _guard(() => _seedShopAndBranches(shopId)),
      _guard(() => _seedSettings(shopId)),
      _guard(() => _seedPaymentMethods(shopId)),
      _guard(() => _seedCategories(shopId)),
      _guard(() => _seedUnits()),
      _guard(() => _seedProfiles(shopId)),
      _guard(() => _seedProducts(shopId)),
      _guard(() => _seedStock(branchId)),
      _guard(() => _seedCustomers(shopId)),
      _guard(() => _seedExpenseCategories(shopId)),
      _guard(() => _seedSales(shopId)),
      _guard(() => _seedExpenses(shopId)),
      _guard(() => _seedCreditPayments()),
    ]);
  }

  static Decimal _dec(dynamic v) => Decimal.parse((v ?? '0').toString());

  Future<void> _guard(Future<void> Function() op) async {
    try {
      await op();
    } catch (_) {
      // Offline or a transient error — keep whatever is already cached.
    }
  }

  // ── Shop + branches ──────────────────────────────────────────────────────────

  Future<void> _seedShopAndBranches(String shopId) async {
    final shop = await _client
        .from('shops')
        .select('id, name, config, created_at')
        .eq('id', shopId)
        .maybeSingle();
    if (shop != null) {
      await _db.upsertShop(LocalShopsCompanion(
        id: Value(shop['id'] as String),
        name: Value(shop['name'] as String),
        // jsonEncode so the (possibly nested) config round-trips; Map.toString
        // is not valid JSON and can't be parsed back.
        config: Value(jsonEncode(shop['config'] ?? {})),
        createdAt: Value(DateTime.parse(shop['created_at'] as String)),
        syncedAt: Value(_now),
      ));
    }

    final branches = await _client
        .from('branches')
        .select('id, shop_id, name, address, is_active, created_at')
        .eq('shop_id', shopId);
    await _db.upsertBranches((branches as List)
        .map((b) => LocalBranchesCompanion(
              id: Value(b['id'] as String),
              shopId: Value(b['shop_id'] as String),
              name: Value(b['name'] as String),
              address: Value(b['address'] as String?),
              isActive: Value(b['is_active'] as bool? ?? true),
              createdAt: Value(DateTime.parse(b['created_at'] as String)),
              syncedAt: Value(_now),
            ))
        .toList());
  }

  // ── Shop settings ────────────────────────────────────────────────────────────

  Future<void> _seedSettings(String shopId) async {
    final rows = await _client
        .from('shop_settings')
        .select('key, value')
        .eq('shop_id', shopId);
    await _db.upsertSettings((rows as List)
        .map((s) => LocalShopSettingsCompanion(
              shopId: Value(shopId),
              key: Value(s['key'] as String),
              // Store the JSON-encoded value so strings/numbers/bools/objects
              // round-trip to exactly what PostgREST returns for this jsonb
              // column (the local settings reader jsonDecodes it).
              value: Value(jsonEncode(s['value'])),
              syncedAt: Value(_now),
            ))
        .toList());
  }

  // ── Payment methods ──────────────────────────────────────────────────────────

  Future<void> _seedPaymentMethods(String shopId) async {
    final rows = await _client
        .from('payment_methods')
        .select('id, name, code, is_active')
        .or('shop_id.eq.$shopId,shop_id.is.null')
        .eq('is_active', true);
    await _db.upsertPaymentMethods((rows as List)
        .map((m) => LocalPaymentMethodsCompanion(
              id: Value(m['id'] as String),
              name: Value(m['name'] as String),
              code: Value(m['code'] as String),
              isActive: Value(m['is_active'] as bool? ?? true),
              syncedAt: Value(_now),
            ))
        .toList());
  }

  // ── Product categories ───────────────────────────────────────────────────────

  Future<void> _seedCategories(String shopId) async {
    final rows = await _client
        .from('product_categories')
        .select('id, shop_id, name')
        .eq('shop_id', shopId);
    await _db.upsertCategories((rows as List)
        .map((c) => LocalProductCategoriesCompanion(
              id: Value(c['id'] as String),
              shopId: Value(c['shop_id'] as String),
              name: Value(c['name'] as String),
              syncedAt: Value(_now),
            ))
        .toList());
  }

  // ── Measurement units ────────────────────────────────────────────────────────

  Future<void> _seedUnits() async {
    final rows = await _client
        .from('measurement_units')
        .select('id, name, abbreviation');
    await _db.upsertUnits((rows as List)
        .map((u) => LocalMeasurementUnitsCompanion(
              id: Value(u['id'] as String),
              name: Value(u['name'] as String),
              abbreviation: Value(u['abbreviation'] as String),
              syncedAt: Value(_now),
            ))
        .toList());
  }

  // ── Profiles (cashier names) ─────────────────────────────────────────────────

  Future<void> _seedProfiles(String shopId) async {
    final members = await _client
        .from('shop_users')
        .select('user_id')
        .eq('shop_id', shopId);
    final ids = (members as List).map((m) => m['user_id'] as String).toList();
    if (ids.isEmpty) return;
    final rows = await _client
        .from('profiles')
        .select('id, full_name, phone')
        .inFilter('id', ids);
    await _db.upsertProfiles((rows as List)
        .map((p) => LocalProfilesCompanion(
              id: Value(p['id'] as String),
              fullName: Value(p['full_name'] as String?),
              phone: Value(p['phone'] as String?),
              syncedAt: Value(_now),
            ))
        .toList());
  }

  // ── Products / stock / customers (existing mirrors) ──────────────────────────

  Future<void> _seedProducts(String shopId) async {
    final products = await _inventoryRemote.getProducts(shopId);
    await _db.upsertProducts(products
        .map((p) => LocalProductsCompanion(
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
              syncedAt: Value(_now),
            ))
        .toList());
  }

  Future<void> _seedStock(String branchId) async {
    final stockList = await _inventoryRemote.getStockLevels(branchId);
    await _db.upsertStock(stockList
        .map((s) => LocalStockCompanion(
              productId: Value(s.productId),
              branchId: Value(branchId),
              quantity: Value(s.quantity),
              syncedAt: Value(_now),
            ))
        .toList());
  }

  Future<void> _seedCustomers(String shopId) async {
    // Don't overwrite customers that have unsynced local edits queued for push
    // (would mark them synced and drop them from the queue).
    final pending =
        (await _db.getPendingCustomers()).map((c) => c.id).toSet();
    final data = await _client
        .from('customers')
        .select('id, shop_id, name, phone, credit_balance')
        .eq('shop_id', shopId)
        .order('name');
    await _db.upsertCustomers((data as List)
        .where((e) => !pending.contains(e['id'] as String))
        .map((e) => LocalCustomersCompanion(
              id: Value(e['id'] as String),
              shopId: Value(e['shop_id'] as String),
              name: Value(e['name'] as String),
              phone: Value(e['phone'] as String?),
              creditBalance:
                  Value(Decimal.parse((e['credit_balance'] ?? '0').toString())),
              updatedAt: Value(_now),
              isSynced: const Value(true),
            ))
        .toList());
  }

  // ── Expense categories ───────────────────────────────────────────────────────

  Future<void> _seedExpenseCategories(String shopId) async {
    final rows = await _client
        .from('expense_categories')
        .select('id, shop_id, name')
        .or('shop_id.eq.$shopId,shop_id.is.null');
    await _db.upsertExpenseCategories((rows as List)
        .map((c) => LocalExpenseCategoriesCompanion(
              id: Value(c['id'] as String),
              shopId: Value(c['shop_id'] as String?),
              name: Value(c['name'] as String),
              syncedAt: Value(_now),
            ))
        .toList());
  }

  // ── Sales (recent + all unsettled credits) + their items ─────────────────────

  Future<void> _seedSales(String shopId) async {
    final branches = await _db.getBranchesByShop(shopId);
    final branchIds = branches.map((b) => b.id).toList();
    if (branchIds.isEmpty) return;

    // Don't clobber sales that haven't pushed yet (owned by the push path).
    final pending = (await _db.getPendingSales()).map((s) => s.id).toSet();

    // Recent sales (covers up to a Year report) + ALL unsettled credit sales
    // regardless of age (so the Credits screen is complete offline).
    final since =
        _now.subtract(const Duration(days: 366)).toUtc().toIso8601String();
    final recent = await _client
        .from('sales')
        .select('*, sale_items(*)')
        .inFilter('branch_id', branchIds)
        .gte('created_at', since)
        .order('created_at', ascending: false)
        .limit(2000);
    final credits = await _client
        .from('sales')
        .select('*, sale_items(*)')
        .inFilter('branch_id', branchIds)
        .eq('is_credit', true)
        .filter('credit_settled_at', 'is', null);

    final byId = <String, Map<String, dynamic>>{};
    for (final r in [...recent as List, ...credits as List]) {
      byId[(r as Map<String, dynamic>)['id'] as String] = r;
    }

    for (final row in byId.values) {
      final id = row['id'] as String;
      if (pending.contains(id)) continue;
      final items = (row['sale_items'] as List? ?? [])
          .map((i) => _saleItemCompanion(i as Map<String, dynamic>))
          .toList();
      await _db.upsertDownloadedSale(_saleCompanion(row), items, id);
    }
  }

  LocalSalesCompanion _saleCompanion(Map<String, dynamic> r) =>
      LocalSalesCompanion(
        id: Value(r['id'] as String),
        branchId: Value(r['branch_id'] as String),
        customerId: Value(r['customer_id'] as String?),
        cashierId: Value(r['cashier_id'] as String),
        paymentMethodId: Value(r['payment_method_id'] as String),
        subtotal: Value(_dec(r['subtotal'])),
        discountAmount: Value(_dec(r['discount_amount'])),
        total: Value(_dec(r['total'])),
        status: Value(r['status'] as String),
        voidReason: Value(r['void_reason'] as String?),
        voidedBy: Value(r['voided_by'] as String?),
        voidedAt: Value(r['voided_at'] != null
            ? DateTime.parse(r['voided_at'] as String)
            : null),
        isCredit: Value(r['is_credit'] as bool? ?? false),
        notes: Value(r['notes'] as String?),
        createdAt: Value(DateTime.parse(r['created_at'] as String)),
        creditSettledAt: Value(r['credit_settled_at'] != null
            ? DateTime.parse(r['credit_settled_at'] as String)
            : null),
        isSynced: const Value(true),
      );

  LocalSaleItemsCompanion _saleItemCompanion(Map<String, dynamic> i) =>
      LocalSaleItemsCompanion(
        id: Value(i['id'] as String),
        saleId: Value(i['sale_id'] as String),
        productId: Value(i['product_id'] as String?),
        productNameSnapshot: Value(i['product_name_snapshot'] as String? ?? ''),
        measurementUnitId: Value(i['measurement_unit_id'] as String?),
        quantity: Value(_dec(i['quantity'])),
        unitPrice: Value(_dec(i['unit_price'])),
        discountAmount: Value(_dec(i['discount_amount'])),
        total: Value(_dec(i['total'])),
        inventoryStatus: Value(i['inventory_status'] as String? ?? 'untracked'),
        costPriceSnapshot: Value(i['cost_price_snapshot'] != null
            ? _dec(i['cost_price_snapshot'])
            : null),
      );

  // ── Expenses ─────────────────────────────────────────────────────────────────

  Future<void> _seedExpenses(String shopId) async {
    final branches = await _db.getBranchesByShop(shopId);
    final branchIds = branches.map((b) => b.id).toList();
    if (branchIds.isEmpty) return;

    final pendingIds =
        (await _db.getPendingExpenses()).map((e) => e.id).toSet();
    final since = _now.subtract(const Duration(days: 366));
    final rows = await _client
        .from('expenses')
        .select('*, expense_categories(name)')
        .inFilter('branch_id', branchIds)
        .gte('date', since.toIso8601String().substring(0, 10));

    for (final e in rows as List) {
      final id = e['id'] as String;
      if (pendingIds.contains(id)) continue;
      await _db.insertOrReplaceExpense(LocalExpensesCompanion(
        id: Value(id),
        branchId: Value(e['branch_id'] as String),
        categoryId: Value(e['category_id'] as String),
        categoryName: Value(
            (e['expense_categories'] as Map<String, dynamic>?)?['name']
                    as String? ??
                'Other'),
        amount: Value(_dec(e['amount'])),
        description: Value(e['description'] as String?),
        recordedBy: Value(e['recorded_by'] as String? ?? ''),
        date: Value(DateTime.parse(e['date'] as String)),
        createdAt: Value(DateTime.parse(e['created_at'] as String)),
        isSynced: const Value(true),
      ));
    }
  }

  // ── Credit payments (offline payment history + remaining balances) ───────────

  Future<void> _seedCreditPayments() async {
    // RLS scopes this to the current shop's sales.
    final rows = await _client
        .from('credit_payments')
        .select('id, sale_id, customer_id, amount, method, notes, created_at');
    await _db.upsertCreditPayments((rows as List)
        .map((p) => LocalCreditPaymentsCompanion(
              id: Value(p['id'] as String),
              saleId: Value(p['sale_id'] as String),
              customerId: Value(p['customer_id'] as String?),
              amount: Value(_dec(p['amount'])),
              method: Value(p['method'] as String),
              notes: Value(p['notes'] as String?),
              createdAt: Value(DateTime.parse(p['created_at'] as String)),
              syncedAt: Value(_now),
            ))
        .toList());
  }
}
