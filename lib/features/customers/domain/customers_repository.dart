import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/local/app_database.dart';
import '../data/customers_remote.dart';
import 'customer.dart';

/// Offline-first customer identity (name/phone).
///
/// Create/edit are local-first: they update the local mirror (which doubles as
/// the pending queue via `isSynced`) and push identity fields in the
/// background; [SyncService] retries failures. Reads prefer the server and fall
/// back to the mirror offline, always surfacing not-yet-synced rows.
///
/// Credit-balance settlement is intentionally NOT handled here — it is a
/// read-modify-write on a running debt balance and per-sale settlement flags,
/// and stays online (see CustomerFormNotifier). Safe offline settlement needs a
/// server-side credit_payments ledger + idempotent RPC (a follow-up).
class CustomersRepository {
  CustomersRepository(this._remote, this._db);

  final CustomersRemote _remote;
  final AppDatabase? _db;

  Future<List<Customer>> getCustomers(String shopId) async {
    if (_db == null) return _remote.getCustomers(shopId);
    // Local-first: the mirror holds all customers — synced and offline-created
    // (isSynced=false) alike — so it's authoritative for display and works
    // offline. Refresh in the background. Only an empty mirror hits the server.
    final rows = await _db.getCustomersByShop(shopId);
    if (rows.isNotEmpty) {
      unawaited(_refreshCustomers(shopId));
      return rows.map(_fromRow).toList();
    }
    try {
      final remote =
          await _remote.getCustomers(shopId).timeout(AppConstants.remoteReadTimeout);
      await _db.upsertCustomers(
          [for (final c in remote) _toCompanion(c, synced: true)]);
      return remote;
    } catch (_) {
      return rows.map(_fromRow).toList(); // empty cache, offline
    }
  }

  Future<void> _refreshCustomers(String shopId) async {
    try {
      final remote =
          await _remote.getCustomers(shopId).timeout(AppConstants.remoteReadTimeout);
      // Don't clobber rows with unpushed local edits.
      final pendingIds =
          (await _db!.getPendingCustomers()).map((r) => r.id).toSet();
      await _db.upsertCustomers([
        for (final c in remote)
          if (!pendingIds.contains(c.id)) _toCompanion(c, synced: true),
      ]);
    } catch (_) {/* offline / transient — keep the local mirror */}
  }

  /// Create (when [customerId] is null) or edit a customer. Returns the id.
  Future<String> save({
    String? customerId,
    required String shopId,
    required String name,
    String? phone,
  }) async {
    final id = customerId ?? const Uuid().v4();
    final cleanName = name.trim();
    final cleanPhone =
        (phone == null || phone.trim().isEmpty) ? null : phone.trim();

    // Web (no local DB): straight to Supabase.
    if (_db == null) {
      await _remote.upsertIdentity(
          id: id, shopId: shopId, name: cleanName, phone: cleanPhone);
      return id;
    }

    if (customerId == null) {
      await _db.upsertCustomer(LocalCustomersCompanion(
        id: Value(id),
        shopId: Value(shopId),
        name: Value(cleanName),
        phone: Value(cleanPhone),
        creditBalance: Value(Decimal.zero),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ));
    } else {
      await _db.updateCustomerIdentity(id, cleanName, cleanPhone);
    }

    // No inline push (single boundary): the row stays isSynced=false and
    // SyncService is the sole pusher; the pending-work watcher nudges a sync.
    return id;
  }

  /// Record a credit payment against a bill. Native: local-first + atomic settle
  /// (queued for push). Web: straight to Supabase. Returns true if it settled.
  Future<bool> recordCreditPayment({
    required String saleId,
    required String customerId,
    required Decimal saleTotal,
    required Decimal amount,
    required String method,
    String? notes,
  }) {
    if (_db == null) {
      return _remote.recordCreditPayment(
        saleId: saleId,
        customerId: customerId,
        amount: amount,
        method: method,
        notes: notes,
      );
    }
    return _db.recordCreditPaymentTxn(
      id: const Uuid().v4(),
      saleId: saleId,
      customerId: customerId,
      saleTotal: saleTotal,
      amount: amount,
      method: method,
      notes: (notes != null && notes.isNotEmpty) ? notes : null,
    );
  }

  LocalCustomersCompanion _toCompanion(Customer c, {required bool synced}) =>
      LocalCustomersCompanion(
        id: Value(c.id),
        shopId: Value(c.shopId),
        name: Value(c.name),
        phone: Value(c.phone),
        creditBalance: Value(c.creditBalance),
        updatedAt: Value(DateTime.now()),
        isSynced: Value(synced),
      );

  Customer _fromRow(CustomerRow r) => Customer(
        id: r.id,
        shopId: r.shopId,
        name: r.name,
        phone: r.phone,
        creditBalance: r.creditBalance,
        createdAt: r.updatedAt, // mirror has no separate createdAt
      );
}
