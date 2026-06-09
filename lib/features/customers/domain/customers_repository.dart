import 'dart:async';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';
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
    try {
      final remote = await _remote.getCustomers(shopId);
      // Refresh the mirror, but don't clobber rows with unpushed local edits.
      final pendingIds =
          (await _db.getPendingCustomers()).map((r) => r.id).toSet();
      await _db.upsertCustomers([
        for (final c in remote)
          if (!pendingIds.contains(c.id)) _toCompanion(c, synced: true),
      ]);
      // Surface offline-created customers the server doesn't have yet.
      final remoteIds = remote.map((c) => c.id).toSet();
      final extras = (await _db.getPendingCustomers())
          .where((r) => r.shopId == shopId && !remoteIds.contains(r.id))
          .map(_fromRow);
      final all = [...remote, ...extras]..sort((a, b) => a.name.compareTo(b.name));
      return all;
    } catch (_) {
      final rows = await _db.getCustomersByShop(shopId);
      return rows.map(_fromRow).toList();
    }
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

    unawaited(
      _remote
          .upsertIdentity(
              id: id, shopId: shopId, name: cleanName, phone: cleanPhone)
          .then((_) => _db.markCustomerSynced(id))
          .catchError((_) {}),
    );
    return id;
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
