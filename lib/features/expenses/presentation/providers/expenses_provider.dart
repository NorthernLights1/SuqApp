import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/local/database_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/auth/presentation/providers/shop_provider.dart';
import '../../data/expenses_remote.dart';
import '../../domain/expense.dart';
import '../../domain/expenses_repository.dart';

// Re-export the models so existing screen imports keep resolving.
export '../../domain/expense.dart' show Expense, ExpenseCategory;

// ─── Providers ─────────────────────────────────────────────────────────────

final expensesRepositoryProvider = Provider<IExpensesRepository>((ref) {
  return ExpensesRepository(
    ExpensesRemote(ref.read(supabaseClientProvider)),
    ref.watch(appDatabaseProvider),
  );
});

final expenseCategoriesProvider =
    FutureProvider<List<ExpenseCategory>>((ref) async {
  final shop = await ref.watch(currentShopProvider.future);
  if (shop == null) return [];
  return ref.read(expensesRepositoryProvider).getCategories(shop.id);
});

class _ExpenseDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();
  void set(DateTime d) => state = d;
}

final selectedExpenseDateProvider =
    NotifierProvider<_ExpenseDateNotifier, DateTime>(_ExpenseDateNotifier.new);

final expensesProvider = FutureProvider<List<Expense>>((ref) async {
  final date = ref.watch(selectedExpenseDateProvider);
  final branches = await ref.watch(currentShopBranchesProvider.future);
  final branch = ref.watch(activeBranchProvider) ??
      (branches.isNotEmpty ? branches.first : null);
  if (branch == null) return [];
  return ref.read(expensesRepositoryProvider).getExpenses(branch.id, date);
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
      // Resolve the category name for offline display (no join available
      // when the row is created with no connection).
      final categories = await ref.read(expenseCategoriesProvider.future);
      final categoryName = categories
          .firstWhere(
            (c) => c.id == categoryId,
            orElse: () => const ExpenseCategory(id: '', name: ''),
          )
          .name;

      await ref.read(expensesRepositoryProvider).record(
            branchId: branch.id,
            categoryId: categoryId,
            categoryName: categoryName,
            amount: amount,
            description: description,
            recordedBy: userId,
            date: date,
          );
      ref.invalidate(expensesProvider);
      ref.invalidate(todayExpensesTotalProvider);
    });
    return !state.hasError;
  }
}

final recordExpenseProvider =
    AsyncNotifierProvider<RecordExpenseNotifier, void>(
        RecordExpenseNotifier.new);
