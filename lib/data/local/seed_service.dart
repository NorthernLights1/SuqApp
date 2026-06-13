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
    ]);
  }

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
}
