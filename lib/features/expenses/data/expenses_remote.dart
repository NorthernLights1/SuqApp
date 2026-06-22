import 'package:decimal/decimal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/expense.dart';

/// Supabase access for expenses. Keeps the feature off the Supabase client
/// directly (per the modules-behind-interfaces rule).
class ExpensesRemote {
  ExpensesRemote(this._client);
  final SupabaseClient _client;

  Future<List<ExpenseCategory>> getCategories(String shopId) async {
    final data = await _client
        .from('expense_categories')
        .select('id, name')
        .or('shop_id.eq.$shopId,shop_id.is.null')
        .order('name');
    return (data as List).map((e) => ExpenseCategory.fromJson(e)).toList();
  }

  Future<List<Expense>> getExpenses(String branchId, DateTime day) async {
    final from = DateTime(day.year, day.month, day.day);
    final to = from.add(const Duration(days: 1));
    final data = await _client
        .from('expenses')
        .select(
            'id, branch_id, category_id, amount, description, recorded_by, date, created_at, expense_categories(name)')
        .eq('branch_id', branchId)
        .gte('date', from.toIso8601String().substring(0, 10))
        .lt('date', to.toIso8601String().substring(0, 10))
        .order('created_at', ascending: false);
    return (data as List).map((e) => Expense.fromJson(e)).toList();
  }

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
    await _client.from('expenses').insert({
      'id': id,
      'branch_id': branchId,
      'category_id': categoryId,
      'amount': amount.toString(),
      'description': description,
      'recorded_by': recordedBy,
      'date': date.toIso8601String().substring(0, 10),
      'created_at': createdAt.toIso8601String(),
    });
  }
}
