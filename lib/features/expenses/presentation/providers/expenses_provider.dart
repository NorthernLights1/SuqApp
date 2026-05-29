import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/auth/presentation/providers/shop_provider.dart';

class ExpenseCategory extends Equatable {
  const ExpenseCategory({required this.id, required this.name});
  final String id;
  final String name;
  factory ExpenseCategory.fromJson(Map<String, dynamic> json) =>
      ExpenseCategory(id: json['id'] as String, name: json['name'] as String);
  @override
  List<Object?> get props => [id, name];
}

class Expense extends Equatable {
  const Expense({
    required this.id,
    required this.branchId,
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    this.description,
    required this.recordedBy,
    required this.date,
    required this.createdAt,
  });

  final String id;
  final String branchId;
  final String categoryId;
  final String categoryName;
  final Decimal amount;
  final String? description;
  final String recordedBy;
  final DateTime date;
  final DateTime createdAt;

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String,
        branchId: json['branch_id'] as String,
        categoryId: json['category_id'] as String,
        categoryName:
            (json['expense_categories'] as Map<String, dynamic>?)?['name']
                as String? ?? '',
        amount: Decimal.parse(json['amount'].toString()),
        description: json['description'] as String?,
        recordedBy: json['recorded_by'] as String,
        date: DateTime.parse(json['date'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  @override
  List<Object?> get props => [id, amount, date];
}

// ─── Providers ─────────────────────────────────────────────────────────────

final expenseCategoriesProvider =
    FutureProvider<List<ExpenseCategory>>((ref) async {
  final shop = await ref.watch(currentShopProvider.future);
  if (shop == null) return [];
  final client = ref.read(supabaseClientProvider);
  final data = await client
      .from('expense_categories')
      .select('id, name')
      .or('shop_id.eq.${shop.id},shop_id.is.null')
      .order('name');
  return (data as List).map((e) => ExpenseCategory.fromJson(e)).toList();
});

final selectedExpenseDateProvider =
    StateProvider<DateTime>((ref) => DateTime.now());

final expensesProvider = FutureProvider<List<Expense>>((ref) async {
  final date = ref.watch(selectedExpenseDateProvider);
  final branches = await ref.watch(currentShopBranchesProvider.future);
  final branch = ref.watch(activeBranchProvider) ??
      (branches.isNotEmpty ? branches.first : null);
  if (branch == null) return [];

  final from = DateTime(date.year, date.month, date.day);
  final to = from.add(const Duration(days: 1));
  final client = ref.read(supabaseClientProvider);

  final data = await client
      .from('expenses')
      .select('id, branch_id, category_id, amount, description, recorded_by, date, created_at, expense_categories(name)')
      .eq('branch_id', branch.id)
      .gte('date', from.toIso8601String().substring(0, 10))
      .lt('date', to.toIso8601String().substring(0, 10))
      .order('created_at', ascending: false);

  return (data as List).map((e) => Expense.fromJson(e)).toList();
});

final todayExpensesTotalProvider = FutureProvider<Decimal>((ref) async {
  final expenses = await ref.watch(expensesProvider.future);
  Decimal total = Decimal.zero;
  for (final e in expenses) {
    total += e.amount;
  }
  return total;
});

class RecordExpenseNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> record({
    required String categoryId,
    required Decimal amount,
    String? description,
    required DateTime date,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    final branches = await ref.read(currentShopBranchesProvider.future);
    final branch = ref.read(activeBranchProvider) ??
        (branches.isNotEmpty ? branches.first : null);
    if (userId == null || branch == null) return false;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(supabaseClientProvider).from('expenses').insert({
        'branch_id': branch.id,
        'category_id': categoryId,
        'amount': amount.toString(),
        'description': description?.trim().isEmpty == true
            ? null
            : description?.trim(),
        'recorded_by': userId,
        'date': date.toIso8601String().substring(0, 10),
      });
      ref.invalidate(expensesProvider);
      ref.invalidate(todayExpensesTotalProvider);
    });
    return !state.hasError;
  }
}

final recordExpenseProvider =
    AsyncNotifierProvider<RecordExpenseNotifier, void>(
        RecordExpenseNotifier.new);
