import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_database.dart';

/// Downloads server state into the local database (the "pull" half of sync).
///
/// **Delta pull** (offline-first v2 Phase B): each replica table keeps a cursor
/// (`LocalSyncState`) = the max server `updated_at` already pulled. A trigger
/// pulls only `where updated_at >= cursor` (>= so rows sharing a boundary
/// timestamp aren't skipped — Postgres `now()` is constant per transaction, so a
/// sale + its items share one `updated_at`; idempotent upsert absorbs the small
/// re-overlap). First pull (null cursor) = a full (windowed) download. Rows whose
/// `deleted_at` is set are hard-removed locally (id-keyed tables).
///
/// Runs on login and on every sync trigger via the SyncScheduler.
///
/// GUARDRAIL: only shop-owned data is replicated. Operator/admin tables —
/// `license_keys`, `shop_controls` — must NEVER be added here. License status is
/// a live, RLS-scoped own-shop read (see licenseStatusProvider) that fails open
/// offline; entitlement stays server-authoritative and is never cached locally.
class SeedService {
  SeedService(this._client, this._db);

  final SupabaseClient _client;
  final AppDatabase _db;

  /// One timestamp shared by every row in a single pull (set at the start of
  /// [seedAll]) so a pull is stamped atomically.
  DateTime _now = DateTime.now();

  Future<void> seedAll({
    required String shopId,
    required String branchId,
  }) async {
    _now = DateTime.now();
    // Shop + branches first: the sales/expenses pulls read local branches to
    // scope their queries, so those rows must exist before they run.
    await Future.wait([
      _guard(() => _seedShops(shopId)),
      _guard(() => _seedBranches(shopId)),
    ]);
    // The rest are independent; each catches its own errors so one failure (or
    // being offline) doesn't abort the others.
    await Future.wait([
      _guard(() => _seedSettings(shopId)),
      _guard(() => _seedPaymentMethods(shopId)),
      _guard(() => _seedCategories(shopId)),
      _guard(_seedUnits),
      _guard(() => _seedProfiles(shopId)),
      _guard(() => _seedProducts(shopId)),
      _guard(() => _seedStock(branchId)),
      _guard(_seedProductBatches),
      _guard(() => _seedCustomers(shopId)),
      _guard(() => _seedExpenseCategories(shopId)),
      _guard(() => _seedSales(shopId)),
      _guard(() => _seedExpenses(shopId)),
      _guard(_seedCreditPayments),
      _guard(_seedSaleItemBatches),
    ]);
  }

  static Decimal _dec(dynamic v) => Decimal.parse((v ?? '0').toString());

  Future<void> _guard(Future<void> Function() op) async {
    try {
      await op();
    } catch (e, st) {
      // Offline or a transient error — keep whatever is already cached. Logged
      // at debug level so a failing table's pull is diagnosable without
      // changing the fail-open behavior.
      debugPrint('SeedService pull failed: $e\n$st');
    }
  }

  /// Core delta-pull loop shared by every table.
  ///
  /// Reads the cursor for [tableKey], lets [fetch] download the changed rows
  /// (it receives the cursor as a UTC ISO string, or null for the first/full
  /// pull), applies live rows via [applyLive], hard-removes soft-deleted rows
  /// (when [deleteFromTable] is given), then advances the cursor to the max
  /// `updated_at` seen.
  Future<void> _deltaPull({
    required String tableKey,
    required Future<List<Map<String, dynamic>>> Function(String? cursorIso)
        fetch,
    required Future<void> Function(List<Map<String, dynamic>> live) applyLive,
    String? deleteFromTable,
  }) async {
    final cursor = await _db.getPullCursor(tableKey);
    // Drift reads DateTime back in local representation; send UTC so the
    // server-side `updated_at >= cursor` comparison is correct.
    final rows = await fetch(cursor?.toUtc().toIso8601String());
    if (rows.isEmpty) return;

    final part = partitionDelta(rows, collectDead: deleteFromTable != null);
    if (part.live.isNotEmpty) await applyLive(part.live);
    if (part.deadIds.isNotEmpty && deleteFromTable != null) {
      await _db.deleteByIds(deleteFromTable, part.deadIds);
    }
    // Advance the cursor over EVERY row seen — including soft-deletes — so a
    // delete on a no-removal table still moves the cursor past it.
    if (part.maxSeen != null) await _db.setPullCursor(tableKey, part.maxSeen!);
  }

  /// Pure split of a fetched page into rows to upsert (`live`), ids to remove
  /// (`deadIds`, only when [collectDead]), and the max `updated_at` seen
  /// (`maxSeen`, over all rows) = the new cursor. Extracted for unit testing.
  static ({List<Map<String, dynamic>> live, List<String> deadIds, DateTime? maxSeen})
      partitionDelta(List<Map<String, dynamic>> rows,
          {required bool collectDead}) {
    final live = <Map<String, dynamic>>[];
    final deadIds = <String>[];
    DateTime? maxSeen;
    for (final r in rows) {
      if (r['deleted_at'] != null) {
        if (collectDead && r['id'] != null) deadIds.add(r['id'] as String);
      } else {
        live.add(r);
      }
      // tryParse, not parse: a single malformed updated_at must never throw and
      // abort the table's pull — that would leave the cursor unadvanced and
      // re-fetch the bad page forever. Skip it; valid rows still advance it.
      final ua = r['updated_at'];
      if (ua is String) {
        final dt = DateTime.tryParse(ua);
        if (dt != null && (maxSeen == null || dt.isAfter(maxSeen))) {
          maxSeen = dt;
        }
      }
    }
    return (live: live, deadIds: deadIds, maxSeen: maxSeen);
  }

  // ── Shop ─────────────────────────────────────────────────────────────────────

  Future<void> _seedShops(String shopId) => _deltaPull(
        tableKey: 'shops',
        fetch: (cursorIso) async {
          var q = _client
              .from('shops')
              .select('id, name, config, created_at, updated_at, deleted_at')
              .eq('id', shopId);
          if (cursorIso != null) q = q.gte('updated_at', cursorIso);
          return (await q as List).cast<Map<String, dynamic>>();
        },
        applyLive: (rows) async {
          for (final shop in rows) {
            await _db.upsertShop(LocalShopsCompanion(
              id: Value(shop['id'] as String),
              name: Value(shop['name'] as String),
              // jsonEncode so the (possibly nested) config round-trips.
              config: Value(jsonEncode(shop['config'] ?? {})),
              createdAt: Value(DateTime.parse(shop['created_at'] as String)),
              syncedAt: Value(_now),
            ));
          }
        },
      );

  // ── Branches ───────────────────────────────────────────────────────────────

  Future<void> _seedBranches(String shopId) => _deltaPull(
        tableKey: 'branches',
        deleteFromTable: 'local_branches',
        fetch: (cursorIso) async {
          var q = _client
              .from('branches')
              .select(
                  'id, shop_id, name, address, is_active, created_at, updated_at, deleted_at')
              .eq('shop_id', shopId);
          if (cursorIso != null) q = q.gte('updated_at', cursorIso);
          return (await q as List).cast<Map<String, dynamic>>();
        },
        applyLive: (rows) => _db.upsertBranches(rows
            .map((b) => LocalBranchesCompanion(
                  id: Value(b['id'] as String),
                  shopId: Value(b['shop_id'] as String),
                  name: Value(b['name'] as String),
                  address: Value(b['address'] as String?),
                  isActive: Value(b['is_active'] as bool? ?? true),
                  createdAt: Value(DateTime.parse(b['created_at'] as String)),
                  syncedAt: Value(_now),
                ))
            .toList()),
      );

  // ── Shop settings ────────────────────────────────────────────────────────────

  Future<void> _seedSettings(String shopId) => _deltaPull(
        tableKey: 'shop_settings',
        // Composite key (shop, key); settings aren't deleted — skip removal.
        fetch: (cursorIso) async {
          var q = _client
              .from('shop_settings')
              .select('key, value, updated_at, deleted_at')
              .eq('shop_id', shopId);
          if (cursorIso != null) q = q.gte('updated_at', cursorIso);
          return (await q as List).cast<Map<String, dynamic>>();
        },
        applyLive: (rows) => _db.upsertSettings(rows
            .map((s) => LocalShopSettingsCompanion(
                  shopId: Value(shopId),
                  key: Value(s['key'] as String),
                  value: Value(jsonEncode(s['value'])),
                  syncedAt: Value(_now),
                ))
            .toList()),
      );

  // ── Payment methods ──────────────────────────────────────────────────────────

  Future<void> _seedPaymentMethods(String shopId) => _deltaPull(
        tableKey: 'payment_methods',
        deleteFromTable: 'local_payment_methods',
        fetch: (cursorIso) async {
          // No is_active filter: a deactivated method flows through with
          // isActive=false (local reads filter it); delta then propagates it.
          var q = _client
              .from('payment_methods')
              .select('id, name, code, is_active, updated_at, deleted_at')
              .or('shop_id.eq.$shopId,shop_id.is.null');
          if (cursorIso != null) q = q.gte('updated_at', cursorIso);
          return (await q as List).cast<Map<String, dynamic>>();
        },
        applyLive: (rows) => _db.upsertPaymentMethods(rows
            .map((m) => LocalPaymentMethodsCompanion(
                  id: Value(m['id'] as String),
                  name: Value(m['name'] as String),
                  code: Value(m['code'] as String),
                  isActive: Value(m['is_active'] as bool? ?? true),
                  syncedAt: Value(_now),
                ))
            .toList()),
      );

  // ── Product categories ───────────────────────────────────────────────────────

  Future<void> _seedCategories(String shopId) => _deltaPull(
        tableKey: 'product_categories',
        deleteFromTable: 'local_product_categories',
        fetch: (cursorIso) async {
          var q = _client
              .from('product_categories')
              .select('id, shop_id, name, updated_at, deleted_at')
              .eq('shop_id', shopId);
          if (cursorIso != null) q = q.gte('updated_at', cursorIso);
          return (await q as List).cast<Map<String, dynamic>>();
        },
        applyLive: (rows) => _db.upsertCategories(rows
            .map((c) => LocalProductCategoriesCompanion(
                  id: Value(c['id'] as String),
                  shopId: Value(c['shop_id'] as String),
                  name: Value(c['name'] as String),
                  syncedAt: Value(_now),
                ))
            .toList()),
      );

  // ── Measurement units ────────────────────────────────────────────────────────

  Future<void> _seedUnits() => _deltaPull(
        tableKey: 'measurement_units',
        deleteFromTable: 'local_measurement_units',
        fetch: (cursorIso) async {
          // No shop filter: RLS returns system + own-shop units.
          var q = _client
              .from('measurement_units')
              .select('id, name, abbreviation, updated_at, deleted_at');
          if (cursorIso != null) q = q.gte('updated_at', cursorIso);
          return (await q as List).cast<Map<String, dynamic>>();
        },
        applyLive: (rows) => _db.upsertUnits(rows
            .map((u) => LocalMeasurementUnitsCompanion(
                  id: Value(u['id'] as String),
                  name: Value(u['name'] as String),
                  abbreviation: Value(u['abbreviation'] as String),
                  syncedAt: Value(_now),
                ))
            .toList()),
      );

  // ── Product batches (wholesale: qty/expiry per batch) ────────────────────────

  Future<void> _seedProductBatches() => _deltaPull(
        tableKey: 'product_batches',
        deleteFromTable: 'local_product_batches',
        fetch: (cursorIso) async {
          // No shop filter: RLS returns only this shop's batches.
          var q = _client.from('product_batches').select(
              'id, branch_id, product_id, batch_number, expiry_date, quantity, cost_price, received_at, created_by, updated_at, deleted_at');
          if (cursorIso != null) q = q.gte('updated_at', cursorIso);
          return (await q as List).cast<Map<String, dynamic>>();
        },
        applyLive: (rows) => _db.upsertProductBatches(rows
            .map((b) => LocalProductBatchesCompanion(
                  id: Value(b['id'] as String),
                  branchId: Value(b['branch_id'] as String),
                  productId: Value(b['product_id'] as String),
                  batchNumber: Value(b['batch_number'] as String?),
                  expiryDate: Value(b['expiry_date'] != null
                      ? DateTime.tryParse(b['expiry_date'] as String)
                      : null),
                  quantity: Value(_dec(b['quantity'])),
                  costPrice: Value(b['cost_price'] != null
                      ? Decimal.tryParse(b['cost_price'].toString())
                      : null),
                  // tryParse + fallback: a malformed received_at must never throw
                  // and stall this table's pull (it would leave the cursor
                  // unadvanced and re-fetch the bad page forever).
                  receivedAt: Value(
                      DateTime.tryParse(b['received_at']?.toString() ?? '') ??
                          _now),
                  createdBy: Value(b['created_by'] as String?),
                  syncedAt: Value(_now),
                  isSynced: const Value(true),
                ))
            .toList()),
      );

  // ── Sale-item batches (wholesale depletion ledger) ───────────────────────────

  Future<void> _seedSaleItemBatches() => _deltaPull(
        tableKey: 'sale_item_batches',
        // Soft-deleted (voided) depletions are hard-removed locally → they stop
        // counting against the rollup, restoring stock.
        deleteFromTable: 'local_sale_item_batches',
        fetch: (cursorIso) async {
          var q = _client.from('sale_item_batches').select(
              'id, sale_item_id, batch_id, quantity, updated_at, deleted_at');
          if (cursorIso != null) q = q.gte('updated_at', cursorIso);
          return (await q as List).cast<Map<String, dynamic>>();
        },
        applyLive: (rows) => _db.upsertSaleItemBatches(rows
            .map((s) => LocalSaleItemBatchesCompanion(
                  id: Value(s['id'] as String),
                  saleItemId: Value(s['sale_item_id'] as String),
                  batchId: Value(s['batch_id'] as String),
                  quantity: Value(_dec(s['quantity'])),
                  syncedAt: Value(_now),
                ))
            .toList()),
      );

  // ── Profiles (cashier names) ─────────────────────────────────────────────────

  Future<void> _seedProfiles(String shopId) => _deltaPull(
        tableKey: 'profiles',
        fetch: (cursorIso) async {
          final members = await _client
              .from('shop_users')
              .select('user_id')
              .eq('shop_id', shopId);
          final ids =
              (members as List).map((m) => m['user_id'] as String).toList();
          if (ids.isEmpty) return [];
          var q = _client
              .from('profiles')
              .select('id, full_name, phone, updated_at, deleted_at')
              .inFilter('id', ids);
          if (cursorIso != null) q = q.gte('updated_at', cursorIso);
          return (await q as List).cast<Map<String, dynamic>>();
        },
        applyLive: (rows) => _db.upsertProfiles(rows
            .map((p) => LocalProfilesCompanion(
                  id: Value(p['id'] as String),
                  fullName: Value(p['full_name'] as String?),
                  phone: Value(p['phone'] as String?),
                  syncedAt: Value(_now),
                ))
            .toList()),
      );

  // ── Products ─────────────────────────────────────────────────────────────────

  Future<void> _seedProducts(String shopId) => _deltaPull(
        tableKey: 'products',
        deleteFromTable: 'local_products',
        fetch: (cursorIso) async {
          // No is_active filter: deactivation propagates (local reads filter
          // isActive). measurement_units join supplies the unit abbreviation.
          var q = _client.from('products').select(
              'id, shop_id, name, description, category_id, measurement_unit_id, low_stock_threshold, selling_price, cost_price, is_active, updated_at, deleted_at, measurement_units(abbreviation)')
              .eq('shop_id', shopId);
          if (cursorIso != null) q = q.gte('updated_at', cursorIso);
          return (await q as List).cast<Map<String, dynamic>>();
        },
        applyLive: (rows) => _db.upsertProducts(rows
            .map((p) => LocalProductsCompanion(
                  id: Value(p['id'] as String),
                  shopId: Value(p['shop_id'] as String),
                  name: Value(p['name'] as String),
                  categoryId: Value(p['category_id'] as String?),
                  description: Value(p['description'] as String?),
                  measurementUnitId: Value(p['measurement_unit_id'] as String),
                  measurementUnitAbbr: Value(
                      (p['measurement_units'] as Map<String, dynamic>?)?[
                              'abbreviation'] as String? ??
                          ''),
                  lowStockThreshold: Value(_dec(p['low_stock_threshold'])),
                  sellingPrice: Value(p['selling_price'] != null
                      ? _dec(p['selling_price'])
                      : null),
                  costPrice: Value(
                      p['cost_price'] != null ? _dec(p['cost_price']) : null),
                  isActive: Value(p['is_active'] as bool? ?? true),
                  syncedAt: Value(_now),
                ))
            .toList()),
      );

  // ── Stock (inventory) ────────────────────────────────────────────────────────

  Future<void> _seedStock(String branchId) => _deltaPull(
        tableKey: 'inventory',
        // Composite key (branch, product); stock goes to 0, isn't deleted.
        fetch: (cursorIso) async {
          var q = _client
              .from('inventory')
              .select(
                  'product_id, quantity, expiry_date, updated_at, deleted_at')
              .eq('branch_id', branchId);
          if (cursorIso != null) q = q.gte('updated_at', cursorIso);
          return (await q as List).cast<Map<String, dynamic>>();
        },
        applyLive: (rows) async {
          final pendingProductIds =
              await _db.getPendingStockProductIds(branchId);
          await _db.upsertStock(rows
              .where((s) =>
                  !pendingProductIds.contains(s['product_id'] as String))
              .map((s) => LocalStockCompanion(
                    productId: Value(s['product_id'] as String),
                    branchId: Value(branchId),
                    quantity: Value(_dec(s['quantity'])),
                    expiryDate: Value(s['expiry_date'] == null
                        ? null
                        : DateTime.parse(s['expiry_date'] as String)),
                    syncedAt: Value(_now),
                  ))
              .toList());
        },
      );

  // ── Customers ────────────────────────────────────────────────────────────────

  Future<void> _seedCustomers(String shopId) => _deltaPull(
        tableKey: 'customers',
        deleteFromTable: 'local_customers',
        fetch: (cursorIso) async {
          var q = _client
              .from('customers')
              .select(
                  'id, shop_id, name, phone, credit_balance, updated_at, deleted_at')
              .eq('shop_id', shopId);
          if (cursorIso != null) q = q.gte('updated_at', cursorIso);
          return (await q as List).cast<Map<String, dynamic>>();
        },
        applyLive: (rows) async {
          // Don't overwrite customers with unsynced local edits (owned by push).
          final pending =
              (await _db.getPendingCustomers()).map((c) => c.id).toSet();
          await _db.upsertCustomers(rows
              .where((e) => !pending.contains(e['id'] as String))
              .map((e) => LocalCustomersCompanion(
                    id: Value(e['id'] as String),
                    shopId: Value(e['shop_id'] as String),
                    name: Value(e['name'] as String),
                    phone: Value(e['phone'] as String?),
                    creditBalance: Value(_dec(e['credit_balance'])),
                    updatedAt: Value(_now),
                    isSynced: const Value(true),
                  ))
              .toList());
        },
      );

  // ── Expense categories ───────────────────────────────────────────────────────

  Future<void> _seedExpenseCategories(String shopId) => _deltaPull(
        tableKey: 'expense_categories',
        deleteFromTable: 'local_expense_categories',
        fetch: (cursorIso) async {
          var q = _client
              .from('expense_categories')
              .select('id, shop_id, name, updated_at, deleted_at')
              .or('shop_id.eq.$shopId,shop_id.is.null');
          if (cursorIso != null) q = q.gte('updated_at', cursorIso);
          return (await q as List).cast<Map<String, dynamic>>();
        },
        applyLive: (rows) => _db.upsertExpenseCategories(rows
            .map((c) => LocalExpenseCategoriesCompanion(
                  id: Value(c['id'] as String),
                  shopId: Value(c['shop_id'] as String?),
                  name: Value(c['name'] as String),
                  syncedAt: Value(_now),
                ))
            .toList()),
      );

  // ── Sales (+ items, + denormalized names) ────────────────────────────────────

  static const _salesSelect =
      '*, sale_items(*), customers(id, name, phone), payment_methods(id, name, code), cashier:profiles!sales_cashier_id_fkey(full_name)';

  Future<void> _seedSales(String shopId) => _deltaPull(
        tableKey: 'sales',
        // Sales are voided, never hard-deleted — no local removal.
        fetch: (cursorIso) async {
          final branches = await _db.getBranchesByShop(shopId);
          final branchIds = branches.map((b) => b.id).toList();
          if (branchIds.isEmpty) return [];

          if (cursorIso == null) {
            // First pull: recent window (up to a Year report) + ALL unsettled
            // credit sales regardless of age, so Credits is complete offline.
            final since = _now
                .subtract(const Duration(days: 366))
                .toUtc()
                .toIso8601String();
            // Cap the first bulk download for sync performance. A shop with
            // >2000 sales in the last year keeps the most recent 2000 here;
            // older ones are pulled on demand / by the delta cursor as they
            // change. Unsettled credit sales are fetched separately below with
            // NO limit, so credit management is always complete offline.
            final recent = await _client
                .from('sales')
                .select(_salesSelect)
                .inFilter('branch_id', branchIds)
                .gte('created_at', since)
                .order('created_at', ascending: false)
                .limit(2000);
            final credits = await _client
                .from('sales')
                .select(_salesSelect)
                .inFilter('branch_id', branchIds)
                .eq('is_credit', true)
                .isFilter('credit_settled_at', null);
            final byId = <String, Map<String, dynamic>>{};
            for (final r in [...recent as List, ...credits as List]) {
              byId[(r as Map<String, dynamic>)['id'] as String] = r;
            }
            return byId.values.toList();
          }

          // Delta: any sale changed since the cursor (new, settled, voided),
          // by updated_at only (no created_at window — catches old settlements).
          final rows = await _client
              .from('sales')
              .select(_salesSelect)
              .inFilter('branch_id', branchIds)
              .gte('updated_at', cursorIso)
              .order('updated_at');
          return (rows as List).cast<Map<String, dynamic>>();
        },
        applyLive: (rows) async {
          // Don't clobber sales that haven't pushed yet (owned by the push).
          final pending =
              (await _db.getPendingSales()).map((s) => s.id).toSet();
          for (final row in rows) {
            final id = row['id'] as String;
            if (pending.contains(id)) continue;
            final items = (row['sale_items'] as List? ?? [])
                .map((i) => _saleItemCompanion(i as Map<String, dynamic>))
                .toList();
            await _db.upsertDownloadedSale(_saleCompanion(row), items, id);
          }
        },
      );

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
        creditSettlementMethod: Value(r['credit_settlement_method'] as String?),
        // Denormalized names from the joins, so offline detail screens render
        // without a Supabase round-trip (consumed in Phase C).
        customerName:
            Value((r['customers'] as Map<String, dynamic>?)?['name'] as String?),
        paymentMethodName: Value(
            (r['payment_methods'] as Map<String, dynamic>?)?['name'] as String?),
        cashierName: Value(
            (r['cashier'] as Map<String, dynamic>?)?['full_name'] as String?),
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

  Future<void> _seedExpenses(String shopId) => _deltaPull(
        tableKey: 'expenses',
        deleteFromTable: 'local_expenses',
        fetch: (cursorIso) async {
          final branches = await _db.getBranchesByShop(shopId);
          final branchIds = branches.map((b) => b.id).toList();
          if (branchIds.isEmpty) return [];
          var q = _client
              .from('expenses')
              .select('*, expense_categories(name)')
              .inFilter('branch_id', branchIds);
          if (cursorIso == null) {
            final since = _now
                .subtract(const Duration(days: 366))
                .toIso8601String()
                .substring(0, 10);
            q = q.gte('date', since);
          } else {
            q = q.gte('updated_at', cursorIso);
          }
          return (await q as List).cast<Map<String, dynamic>>();
        },
        applyLive: (rows) async {
          final pendingIds =
              (await _db.getPendingExpenses()).map((e) => e.id).toSet();
          for (final e in rows) {
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
        },
      );

  // ── Credit payments ──────────────────────────────────────────────────────────

  Future<void> _seedCreditPayments() => _deltaPull(
        tableKey: 'credit_payments',
        deleteFromTable: 'local_credit_payments',
        fetch: (cursorIso) async {
          // RLS scopes this to the current shop's sales. Intentionally NO time
          // window on the first pull (unlike sales/expenses): payment volume is
          // low, and the full history backs both the dispute audit trail and the
          // remaining-balance math for unsettled credits of any age.
          var q = _client.from('credit_payments').select(
              'id, sale_id, customer_id, amount, method, notes, created_at, updated_at, deleted_at');
          if (cursorIso != null) q = q.gte('updated_at', cursorIso);
          return (await q as List).cast<Map<String, dynamic>>();
        },
        applyLive: (rows) => _db.upsertCreditPayments(rows
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
            .toList()),
      );
}
