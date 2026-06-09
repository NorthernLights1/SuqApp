import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suq/data/local/app_database.dart';
import 'package:suq/features/expenses/data/expenses_remote.dart';
import 'package:suq/features/expenses/domain/expense.dart';
import 'package:suq/features/expenses/domain/expenses_repository.dart';

AppDatabase _makeDb() => AppDatabase(NativeDatabase.memory());

// ── Stub remotes ────────────────────────────────────────────────────────────
//
// insertExpense throws by default so the fire-and-forget push never flips
// isSynced — keeping the local row deterministically pending.

class _ThrowingRemote implements ExpensesRemote {
  @override
  Future<List<ExpenseCategory>> getCategories(String shopId) async => [];

  @override
  Future<List<Expense>> getExpenses(String branchId, DateTime day) async =>
      throw Exception('offline');

  @override
  Future<void> insertExpense({
    required String id,
    required String branchId,
    required String categoryId,
    required Decimal amount,
    String? description,
    required String recordedBy,
    required DateTime date,
    required DateTime createdAt,
  }) async =>
      throw Exception('offline');
}

class _CapturingRemote implements ExpensesRemote {
  final List<String> insertedIds = [];
  List<Expense> remoteRows = [];

  @override
  Future<List<ExpenseCategory>> getCategories(String shopId) async => [];

  @override
  Future<List<Expense>> getExpenses(String branchId, DateTime day) async =>
      remoteRows;

  @override
  Future<void> insertExpense({
    required String id,
    required String branchId,
    required String categoryId,
    required Decimal amount,
    String? description,
    required String recordedBy,
    required DateTime date,
    required DateTime createdAt,
  }) async {
    insertedIds.add(id);
  }
}

void main() {
  group('ExpensesRepository — DB path (offline)', () {
    late AppDatabase db;
    setUp(() => db = _makeDb());
    tearDown(() => db.close());

    test('record writes a pending local row when the push fails', () async {
      final repo = ExpensesRepository(_ThrowingRemote(), db);
      await repo.record(
        branchId: 'b-1',
        categoryId: 'cat-1',
        categoryName: 'Rent',
        amount: Decimal.parse('250'),
        recordedBy: 'u-1',
        date: DateTime(2026, 6, 9),
      );

      final pending = await db.getPendingExpenses();
      expect(pending.length, 1);
      expect(pending.first.categoryName, 'Rent');
      expect(pending.first.amount, Decimal.parse('250'));
      expect(pending.first.isSynced, false);
    });

    test('getExpenses falls back to local rows when offline', () async {
      final repo = ExpensesRepository(_ThrowingRemote(), db);
      await repo.record(
        branchId: 'b-1',
        categoryId: 'cat-1',
        categoryName: 'Rent',
        amount: Decimal.parse('250'),
        recordedBy: 'u-1',
        date: DateTime(2026, 6, 9),
      );

      final list = await repo.getExpenses('b-1', DateTime(2026, 6, 9));
      expect(list.length, 1);
      expect(list.first.categoryName, 'Rent');
    });
  });

  group('ExpensesRepository — online reads', () {
    late AppDatabase db;
    setUp(() => db = _makeDb());
    tearDown(() => db.close());

    test('unions a not-yet-synced local row with the server list', () async {
      final remote = _CapturingRemote();
      remote.remoteRows = [
        Expense(
          id: 'server-1',
          branchId: 'b-1',
          categoryId: 'cat-1',
          categoryName: 'Utilities',
          amount: Decimal.parse('40'),
          recordedBy: 'u-1',
          date: DateTime(2026, 6, 9),
          createdAt: DateTime(2026, 6, 9, 8),
        ),
      ];
      // A local pending row the server hasn't received yet.
      await db.insertExpense(LocalExpensesCompanion(
        id: const Value('local-1'),
        branchId: const Value('b-1'),
        categoryId: const Value('cat-2'),
        categoryName: const Value('Transport'),
        amount: Value(Decimal.parse('15')),
        recordedBy: const Value('u-1'),
        date: Value(DateTime(2026, 6, 9)),
        createdAt: Value(DateTime(2026, 6, 9, 9)),
        isSynced: const Value(false),
      ));

      final repo = ExpensesRepository(remote, db);
      final list = await repo.getExpenses('b-1', DateTime(2026, 6, 9));
      final ids = list.map((e) => e.id).toList();
      expect(ids, containsAll(['local-1', 'server-1']));
      expect(list.length, 2);
    });
  });

  group('ExpensesRepository — web path (no DB)', () {
    test('record delegates straight to remote', () async {
      final remote = _CapturingRemote();
      final repo = ExpensesRepository(remote, null);
      final e = await repo.record(
        branchId: 'b-1',
        categoryId: 'cat-1',
        categoryName: 'Rent',
        amount: Decimal.parse('250'),
        recordedBy: 'u-1',
        date: DateTime(2026, 6, 9),
      );
      expect(remote.insertedIds, [e.id]);
    });
  });

  group('expense DB queries', () {
    late AppDatabase db;
    setUp(() => db = _makeDb());
    tearDown(() => db.close());

    Future<void> insert(String id, {bool synced = false}) =>
        db.insertExpense(LocalExpensesCompanion(
          id: Value(id),
          branchId: const Value('b-1'),
          categoryId: const Value('cat-1'),
          categoryName: const Value('Rent'),
          amount: Value(Decimal.parse('10')),
          recordedBy: const Value('u-1'),
          date: Value(DateTime(2026, 6, 9)),
          createdAt: Value(DateTime(2026, 6, 9, 8)),
          isSynced: Value(synced),
        ));

    test('getPendingExpenses returns only unsynced rows', () async {
      await insert('e-1', synced: false);
      await insert('e-2', synced: true);
      final pending = await db.getPendingExpenses();
      expect(pending.map((e) => e.id), ['e-1']);
    });

    test('markExpenseSynced flips the flag', () async {
      await insert('e-1', synced: false);
      await db.markExpenseSynced('e-1');
      final pending = await db.getPendingExpenses();
      expect(pending, isEmpty);
    });
  });
}
