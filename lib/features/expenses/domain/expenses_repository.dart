import 'dart:async';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';
import '../../../data/local/app_database.dart';
import '../data/expenses_remote.dart';
import 'expense.dart';

abstract interface class IExpensesRepository {
  Future<List<ExpenseCategory>> getCategories(String shopId);
  Future<List<Expense>> getExpenses(String branchId, DateTime day);
  Future<Expense> record({
    required String branchId,
    required String categoryId,
    required String categoryName,
    required Decimal amount,
    String? description,
    required String recordedBy,
    required DateTime date,
  });
}

/// Offline-first expenses. Writes go to the local Drift queue first (so they
/// survive with no connection) and push to Supabase in the background;
/// [SyncService] retries any that fail. Reads prefer the server but fall back
/// to local when offline, always surfacing not-yet-synced rows.
class ExpensesRepository implements IExpensesRepository {
  ExpensesRepository(this._remote, this._db);

  final ExpensesRemote _remote;
  final AppDatabase? _db;

  @override
  Future<List<ExpenseCategory>> getCategories(String shopId) async {
    if (_db == null) return _remote.getCategories(shopId);
    try {
      return await _remote.getCategories(shopId);
    } catch (_) {
      // Offline: serve the downloaded categories so the expense form still works.
      final rows = await _db.getExpenseCategories(shopId);
      return rows.map((r) => ExpenseCategory(id: r.id, name: r.name)).toList();
    }
  }

  @override
  Future<List<Expense>> getExpenses(String branchId, DateTime day) async {
    if (_db == null) return _remote.getExpenses(branchId, day);
    try {
      final remote = await _remote.getExpenses(branchId, day);
      // Surface any local rows the server hasn't received yet (offline-created
      // or push still in flight) so they show immediately. Dedupe by id.
      final pending = await _db.getPendingExpensesByBranch(branchId, day);
      final remoteIds = remote.map((e) => e.id).toSet();
      final extras =
          pending.where((r) => !remoteIds.contains(r.id)).map(_fromRow);
      return [...extras, ...remote];
    } catch (_) {
      // Offline: serve whatever we have locally.
      final rows = await _db.getExpensesByBranch(branchId, day);
      return rows.map(_fromRow).toList();
    }
  }

  @override
  Future<Expense> record({
    required String branchId,
    required String categoryId,
    required String categoryName,
    required Decimal amount,
    String? description,
    required String recordedBy,
    required DateTime date,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    final desc = (description == null || description.trim().isEmpty)
        ? null
        : description.trim();
    final day = DateTime(date.year, date.month, date.day);

    final expense = Expense(
      id: id,
      branchId: branchId,
      categoryId: categoryId,
      categoryName: categoryName,
      amount: amount,
      description: desc,
      recordedBy: recordedBy,
      date: day,
      createdAt: now,
    );

    // Web (no local DB): write straight to Supabase.
    if (_db == null) {
      await _remote.insertExpense(
        id: id,
        branchId: branchId,
        categoryId: categoryId,
        amount: amount,
        description: desc,
        recordedBy: recordedBy,
        date: day,
        createdAt: now,
      );
      return expense;
    }

    // Native: local-first, then background push (SyncService handles retries).
    await _db.insertExpense(LocalExpensesCompanion(
      id: Value(id),
      branchId: Value(branchId),
      categoryId: Value(categoryId),
      categoryName: Value(categoryName),
      amount: Value(amount),
      description: Value(desc),
      recordedBy: Value(recordedBy),
      date: Value(day),
      createdAt: Value(now),
      isSynced: const Value(false),
    ));

    unawaited(
      _remote
          .insertExpense(
            id: id,
            branchId: branchId,
            categoryId: categoryId,
            amount: amount,
            description: desc,
            recordedBy: recordedBy,
            date: day,
            createdAt: now,
          )
          .then((_) => _db.markExpenseSynced(id))
          .catchError((_) {}),
    );

    return expense;
  }

  Expense _fromRow(ExpenseRow r) => Expense(
        id: r.id,
        branchId: r.branchId,
        categoryId: r.categoryId,
        categoryName: r.categoryName,
        amount: r.amount,
        description: r.description,
        recordedBy: r.recordedBy,
        date: r.date,
        createdAt: r.createdAt,
      );
}
