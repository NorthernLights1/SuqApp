import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suq/data/local/app_database.dart';
import 'package:suq/features/customers/data/customers_remote.dart';
import 'package:suq/features/customers/domain/customer.dart';
import 'package:suq/features/customers/domain/customers_repository.dart';

AppDatabase _makeDb() => AppDatabase(NativeDatabase.memory());

// upsertIdentity throws by default so the fire-and-forget push leaves the
// local row deterministically pending.
class _ThrowingRemote implements CustomersRemote {
  @override
  Future<List<Customer>> getCustomers(String shopId) async =>
      throw Exception('offline');
  @override
  Future<void> upsertIdentity({
    required String id,
    required String shopId,
    required String name,
    String? phone,
  }) async =>
      throw Exception('offline');
  @override
  Future<bool> recordCreditPayment({
    required String saleId,
    required String customerId,
    required Decimal amount,
    required String method,
    String? notes,
  }) async =>
      throw Exception('offline');
}

class _CapturingRemote implements CustomersRemote {
  List<Customer> remoteRows = [];
  final List<String> upsertedIds = [];

  @override
  Future<List<Customer>> getCustomers(String shopId) async => remoteRows;
  @override
  Future<void> upsertIdentity({
    required String id,
    required String shopId,
    required String name,
    String? phone,
  }) async {
    upsertedIds.add(id);
  }

  @override
  Future<bool> recordCreditPayment({
    required String saleId,
    required String customerId,
    required Decimal amount,
    required String method,
    String? notes,
  }) async =>
      false;
}

Customer _cust(String id, String name, {Decimal? balance}) => Customer(
      id: id,
      shopId: 'shop-1',
      name: name,
      creditBalance: balance ?? Decimal.zero,
      createdAt: DateTime(2026, 6, 9),
    );

void main() {
  late AppDatabase db;
  setUp(() => db = _makeDb());
  tearDown(() => db.close());

  group('save — offline', () {
    test('create writes a pending local customer when the push fails',
        () async {
      final repo = CustomersRepository(_ThrowingRemote(), db);
      final id = await repo.save(shopId: 'shop-1', name: 'Abebe', phone: '0911');

      final pending = await db.getPendingCustomers();
      expect(pending.length, 1);
      expect(pending.first.id, id);
      expect(pending.first.name, 'Abebe');
      expect(pending.first.phone, '0911');
      expect(pending.first.isSynced, false);
      expect(pending.first.creditBalance, Decimal.zero);
    });

    test('edit flags an existing customer pending without touching balance',
        () async {
      // Seed a synced customer that owes money.
      await db.upsertCustomer(LocalCustomersCompanion(
        id: const Value('c-1'),
        shopId: const Value('shop-1'),
        name: const Value('Old Name'),
        creditBalance: Value(Decimal.parse('120')),
        updatedAt: Value(DateTime(2026, 6, 1)),
        isSynced: const Value(true),
      ));

      final repo = CustomersRepository(_ThrowingRemote(), db);
      await repo.save(customerId: 'c-1', shopId: 'shop-1', name: 'New Name');

      final pending = await db.getPendingCustomers();
      expect(pending.length, 1);
      expect(pending.first.name, 'New Name');
      expect(pending.first.creditBalance, Decimal.parse('120')); // preserved
    });

    test('empty phone is stored as null', () async {
      final repo = CustomersRepository(_ThrowingRemote(), db);
      await repo.save(shopId: 'shop-1', name: 'Sara', phone: '   ');
      final pending = await db.getPendingCustomers();
      expect(pending.first.phone, isNull);
    });
  });

  group('getCustomers', () {
    test('offline falls back to the local mirror', () async {
      await db.upsertCustomer(LocalCustomersCompanion(
        id: const Value('c-1'),
        shopId: const Value('shop-1'),
        name: const Value('Abebe'),
        creditBalance: Value(Decimal.parse('50')),
        updatedAt: Value(DateTime(2026, 6, 1)),
        isSynced: const Value(true),
      ));
      final repo = CustomersRepository(_ThrowingRemote(), db);
      final list = await repo.getCustomers('shop-1');
      expect(list.length, 1);
      expect(list.first.name, 'Abebe');
      expect(list.first.creditBalance, Decimal.parse('50'));
    });

    test('local-first read returns synced and offline-created customers alike',
        () async {
      // Local-first: the mirror is the source of truth. A prior sync put the
      // server customer here (isSynced=true); an offline-created one is pending
      // (isSynced=false). getCustomers returns both from the mirror; the server
      // list is merged in via a background refresh, not at read time.
      final remote = _CapturingRemote()..remoteRows = [];
      await db.upsertCustomer(LocalCustomersCompanion(
        id: const Value('server-1'),
        shopId: const Value('shop-1'),
        name: const Value('Server Cust'),
        creditBalance: Value(Decimal.zero),
        updatedAt: Value(DateTime(2026, 6, 1)),
        isSynced: const Value(true),
      ));
      await db.upsertCustomer(LocalCustomersCompanion(
        id: const Value('local-1'),
        shopId: const Value('shop-1'),
        name: const Value('Local Cust'),
        creditBalance: Value(Decimal.zero),
        updatedAt: Value(DateTime(2026, 6, 9)),
        isSynced: const Value(false),
      ));
      final repo = CustomersRepository(remote, db);
      final list = await repo.getCustomers('shop-1');
      expect(list.map((c) => c.id), containsAll(['server-1', 'local-1']));
      expect(list.length, 2);
    });

    test('refreshing the mirror does not clobber an unpushed local edit',
        () async {
      // Local pending edit says "Edited", server still says "Original".
      await db.upsertCustomer(LocalCustomersCompanion(
        id: const Value('c-1'),
        shopId: const Value('shop-1'),
        name: const Value('Edited'),
        creditBalance: Value(Decimal.zero),
        updatedAt: Value(DateTime(2026, 6, 9)),
        isSynced: const Value(false),
      ));
      final remote = _CapturingRemote()
        ..remoteRows = [_cust('c-1', 'Original')];
      final repo = CustomersRepository(remote, db);
      await repo.getCustomers('shop-1');

      final pending = await db.getPendingCustomers();
      expect(pending.length, 1);
      expect(pending.first.name, 'Edited'); // not overwritten by server
    });
  });

  group('save — web (no DB)', () {
    test('delegates straight to remote upsert', () async {
      final remote = _CapturingRemote();
      final repo = CustomersRepository(remote, null);
      final id = await repo.save(shopId: 'shop-1', name: 'Web Cust');
      expect(remote.upsertedIds, [id]);
    });
  });
}
