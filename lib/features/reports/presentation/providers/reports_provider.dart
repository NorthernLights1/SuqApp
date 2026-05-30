import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/auth/presentation/providers/shop_provider.dart';

enum ReportPeriod { today, week, month }

class ReportSummary extends Equatable {
  const ReportSummary({
    required this.salesTotal,
    required this.salesCount,
    required this.creditTotal,
    required this.creditCount,
    required this.expenseTotal,
    required this.expenseByCategory,
  });

  final Decimal salesTotal;
  final int salesCount;
  final Decimal creditTotal;
  final int creditCount;
  final Decimal expenseTotal;
  final Map<String, Decimal> expenseByCategory;

  Decimal get net => salesTotal - expenseTotal;

  @override
  List<Object?> get props => [salesTotal, salesCount, expenseTotal];
}

final reportPeriodProvider = StateProvider<ReportPeriod>((ref) => ReportPeriod.today);

({DateTime start, DateTime end}) _rangeFor(ReportPeriod period) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return switch (period) {
    ReportPeriod.today => (start: today, end: today.add(const Duration(days: 1))),
    ReportPeriod.week => (
        start: today.subtract(Duration(days: today.weekday - 1)),
        end: today.add(const Duration(days: 1)),
      ),
    ReportPeriod.month => (
        start: DateTime(now.year, now.month, 1),
        end: today.add(const Duration(days: 1)),
      ),
  };
}

final reportSummaryProvider = FutureProvider<ReportSummary>((ref) async {
  final period = ref.watch(reportPeriodProvider);
  final branches = await ref.watch(currentShopBranchesProvider.future);
  final branch =
      ref.watch(activeBranchProvider) ?? (branches.isNotEmpty ? branches.first : null);

  if (branch == null) {
    return ReportSummary(
      salesTotal: Decimal.zero,
      salesCount: 0,
      creditTotal: Decimal.zero,
      creditCount: 0,
      expenseTotal: Decimal.zero,
      expenseByCategory: const {},
    );
  }

  final range = _rangeFor(period);
  final client = ref.read(supabaseClientProvider);

  // Sales
  final salesData = await client
      .from('sales')
      .select('total, status, is_credit')
      .eq('branch_id', branch.id)
      .gte('created_at', range.start.toIso8601String())
      .lt('created_at', range.end.toIso8601String());

  Decimal salesTotal = Decimal.zero;
  Decimal creditTotal = Decimal.zero;
  int salesCount = 0;
  int creditCount = 0;
  for (final row in salesData as List) {
    if (row['status'] != 'completed') continue;
    final amount = Decimal.parse(row['total'].toString());
    salesTotal += amount;
    salesCount++;
    if (row['is_credit'] == true) {
      creditTotal += amount;
      creditCount++;
    }
  }

  // Expenses
  final expData = await client
      .from('expenses')
      .select('amount, expense_categories(name)')
      .eq('branch_id', branch.id)
      .gte('date', range.start.toIso8601String().substring(0, 10))
      .lt('date', range.end.toIso8601String().substring(0, 10));

  Decimal expenseTotal = Decimal.zero;
  final expByCategory = <String, Decimal>{};
  for (final row in expData as List) {
    final amount = Decimal.parse(row['amount'].toString());
    final catName =
        (row['expense_categories'] as Map<String, dynamic>?)?['name'] as String? ?? 'Other';
    expenseTotal += amount;
    expByCategory[catName] = (expByCategory[catName] ?? Decimal.zero) + amount;
  }

  // Sort categories by amount descending
  final sortedCategories = Map.fromEntries(
    expByCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
  );

  return ReportSummary(
    salesTotal: salesTotal,
    salesCount: salesCount,
    creditTotal: creditTotal,
    creditCount: creditCount,
    expenseTotal: expenseTotal,
    expenseByCategory: sortedCategories,
  );
});
