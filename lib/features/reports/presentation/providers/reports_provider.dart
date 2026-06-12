import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/sale.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/auth/presentation/providers/shop_provider.dart';

enum ReportPeriod { today, week, month, year, custom }

class ReportSummary extends Equatable {
  const ReportSummary({
    required this.salesTotal,
    required this.salesCount,
    required this.creditTotal,
    required this.creditCount,
    required this.expenseTotal,
    required this.expenseByCategory,
    required this.grossProfit,
    required this.profitItemCount,
  });

  final Decimal salesTotal;
  final int salesCount;
  final Decimal creditTotal;
  final int creditCount;
  final Decimal expenseTotal;
  final Map<String, Decimal> expenseByCategory;
  // Gross profit based only on sale_items that have cost_price_snapshot set
  final Decimal grossProfit;
  // How many line items had cost data (so we can warn if partial)
  final int profitItemCount;

  Decimal get net => salesTotal - expenseTotal;

  @override
  List<Object?> get props => [salesTotal, salesCount, expenseTotal, grossProfit];
}

class _ReportPeriodNotifier extends Notifier<ReportPeriod> {
  @override
  ReportPeriod build() => ReportPeriod.today;
  void set(ReportPeriod p) => state = p;
}

final reportPeriodProvider =
    NotifierProvider<_ReportPeriodNotifier, ReportPeriod>(_ReportPeriodNotifier.new);

// Holds the user-selected custom date range (only used when period == custom).
class _CustomRangeNotifier extends Notifier<DateTimeRange?> {
  @override
  DateTimeRange? build() => null;
  void set(DateTimeRange? r) => state = r;
}

final reportCustomRangeProvider =
    NotifierProvider<_CustomRangeNotifier, DateTimeRange?>(_CustomRangeNotifier.new);

({DateTime start, DateTime end}) _rangeFor(
    ReportPeriod period, DateTimeRange? custom) {
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
    ReportPeriod.year => (
        start: DateTime(now.year, 1, 1),
        end: today.add(const Duration(days: 1)),
      ),
    ReportPeriod.custom => custom != null
        ? (
            start: custom.start,
            end: custom.end.add(const Duration(days: 1)),
          )
        : (start: today, end: today.add(const Duration(days: 1))),
  };
}

// Null = all categories; non-null = filter to that category ID.
class _ReportCategoryNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? id) => state = id;
}

final reportCategoryFilterProvider =
    NotifierProvider<_ReportCategoryNotifier, String?>(_ReportCategoryNotifier.new);

/// The individual completed sales behind the report summary, honouring the
/// same period + category filters. Drives the tappable Transactions/Credits
/// drill-downs. Each row maps to a full [Sale] (with customer/cashier joins),
/// so tapping opens the existing SaleDetailScreen.
final reportSalesProvider = FutureProvider<List<Sale>>((ref) async {
  final period = ref.watch(reportPeriodProvider);
  final customRange = ref.watch(reportCustomRangeProvider);
  final categoryFilter = ref.watch(reportCategoryFilterProvider);
  final branches = await ref.watch(currentShopBranchesProvider.future);
  final branch =
      ref.watch(activeBranchProvider) ?? (branches.isNotEmpty ? branches.first : null);
  if (branch == null) return const [];

  final range = _rangeFor(period, customRange);
  final client = ref.read(supabaseClientProvider);

  final data = await client
      .from('sales')
      .select(
          '*, sale_items(*, products(category_id)), customers(id, name, phone), payment_methods(id, name, code), cashier:profiles!sales_cashier_id_fkey(full_name)')
      .eq('branch_id', branch.id)
      .eq('status', 'completed')
      .gte('created_at', range.start.toUtc().toIso8601String())
      .lt('created_at', range.end.toUtc().toIso8601String())
      .order('created_at', ascending: false)
      // Cap the drill-down list; a shop won't review more than this at once
      // and it keeps the query bounded for long periods (e.g. Year).
      .limit(500);

  final rows = (data as List).cast<Map<String, dynamic>>();
  final filtered = categoryFilter == null
      ? rows
      : rows.where((row) {
          final items = (row['sale_items'] as List? ?? []);
          return items.any((item) =>
              (item['products'] as Map<String, dynamic>?)?['category_id'] ==
              categoryFilter);
        }).toList();

  return filtered.map((e) => Sale.fromJson(e)).toList();
});

/// Outstanding credit sales within the report filter (subset of
/// [reportSalesProvider]).
final reportCreditsProvider = FutureProvider<List<Sale>>((ref) async {
  final sales = await ref.watch(reportSalesProvider.future);
  return sales.where((s) => s.isCredit && !s.isCreditSettled).toList();
});

final reportSummaryProvider = FutureProvider<ReportSummary>((ref) async {
  final period = ref.watch(reportPeriodProvider);
  final customRange = ref.watch(reportCustomRangeProvider);
  final categoryFilter = ref.watch(reportCategoryFilterProvider);
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
      grossProfit: Decimal.zero,
      profitItemCount: 0,
    );
  }

  final range = _rangeFor(period, customRange);
  final client = ref.read(supabaseClientProvider);

  // Sales — include product category info for optional category filter
  final salesData = await client
      .from('sales')
      .select(
          'total, status, is_credit, credit_settled_at, sale_items(quantity, unit_price, discount_amount, cost_price_snapshot, products(category_id))')
      .eq('branch_id', branch.id)
      .gte('created_at', range.start.toUtc().toIso8601String())
      .lt('created_at', range.end.toUtc().toIso8601String());

  Decimal salesTotal = Decimal.zero;
  Decimal creditTotal = Decimal.zero;
  Decimal grossProfit = Decimal.zero;
  int salesCount = 0;
  int creditCount = 0;
  int profitItemCount = 0;

  for (final row in salesData as List) {
    if (row['status'] != 'completed') continue;
    final items = (row['sale_items'] as List? ?? []);
    // "On credit" means still outstanding — exclude settled credit sales so
    // the figure matches the credits screen once debts are paid.
    final isOutstandingCredit =
        row['is_credit'] == true && row['credit_settled_at'] == null;

    if (categoryFilter != null) {
      // Category mode: sum only items from the selected category.
      Decimal catRevenue = Decimal.zero;
      bool hasCatItem = false;
      for (final item in items) {
        final catId = (item['products'] as Map<String, dynamic>?)?['category_id'];
        if (catId != categoryFilter) continue;
        hasCatItem = true;
        final qty = Decimal.parse(item['quantity'].toString());
        final unitPrice = Decimal.parse(item['unit_price'].toString());
        final disc = Decimal.parse((item['discount_amount'] ?? '0').toString());
        catRevenue += (unitPrice * qty) - disc;
        if (item['cost_price_snapshot'] != null) {
          final costPrice =
              Decimal.parse(item['cost_price_snapshot'].toString());
          grossProfit += (unitPrice - costPrice) * qty;
          profitItemCount++;
        }
      }
      if (!hasCatItem) continue;
      salesTotal += catRevenue;
      salesCount++;
      if (isOutstandingCredit) {
        creditTotal += catRevenue;
        creditCount++;
      }
    } else {
      // All categories: use the stored sale total.
      final amount = Decimal.parse(row['total'].toString());
      salesTotal += amount;
      salesCount++;
      if (isOutstandingCredit) {
        creditTotal += amount;
        creditCount++;
      }
      for (final item in items) {
        if (item['cost_price_snapshot'] == null) continue;
        final qty = Decimal.parse(item['quantity'].toString());
        final unitPrice = Decimal.parse(item['unit_price'].toString());
        final costPrice = Decimal.parse(item['cost_price_snapshot'].toString());
        grossProfit += (unitPrice - costPrice) * qty;
        profitItemCount++;
      }
    }
  }

  // Expenses (not category-filtered — expense categories are separate from product categories)
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
        (row['expense_categories'] as Map<String, dynamic>?)?['name'] as String? ??
            'Other';
    expenseTotal += amount;
    expByCategory[catName] =
        (expByCategory[catName] ?? Decimal.zero) + amount;
  }

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
    grossProfit: grossProfit,
    profitItemCount: profitItemCount,
  );
});
