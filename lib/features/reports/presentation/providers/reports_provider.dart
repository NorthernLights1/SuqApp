import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/local/app_database.dart';
import '../../../../data/local/database_provider.dart';
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
  List<Object?> get props => [
        salesTotal,
        salesCount,
        creditTotal,
        creditCount,
        expenseTotal,
        expenseByCategory,
        grossProfit,
        profitItemCount,
      ];
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

  try {
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
  } catch (_) {
    // Offline: build the drill-down list from the local cache, enriching with
    // local customer/cashier/payment names.
    final db = ref.read(appDatabaseProvider);
    if (db == null) rethrow;
    final shop = await ref.read(currentShopProvider.future);
    return _localReportSales(db, shop?.id, branch.id, range, categoryFilter);
  }
});

Future<List<Sale>> _localReportSales(
  AppDatabase db,
  String? shopId,
  String branchId,
  ({DateTime start, DateTime end}) range,
  String? categoryFilter,
) async {
  final rows = (await db.getSalesByBranch(branchId, range.start, range.end))
      .where((r) => r.status == 'completed')
      .toList();
  final custNames = {
    if (shopId != null)
      for (final c in await db.getCustomersByShop(shopId)) c.id: c,
  };
  final cashierNames = {
    for (final p in await db.getProfiles()) p.id: p.fullName,
  };
  final payNames = {
    for (final m in await db.getPaymentMethods()) m.id: m.name,
  };
  final prodCat = <String, String?>{
    if (shopId != null)
      for (final p in await db.getProductsByShop(shopId)) p.id: p.categoryId,
  };
  // Batch the items for all sales in one query (avoids N+1 across the period).
  final itemsBySale =
      await db.getSaleItemsForSales(rows.map((r) => r.id).toList());

  final result = <Sale>[];
  for (final r in rows) {
    final items = itemsBySale[r.id] ?? const [];
    if (categoryFilter != null &&
        !items.any((i) => prodCat[i.productId] == categoryFilter)) {
      continue;
    }
    final cust = custNames[r.customerId];
    result.add(Sale(
      id: r.id,
      branchId: r.branchId,
      customerId: r.customerId,
      customerName: cust?.name,
      customerPhone: cust?.phone,
      cashierId: r.cashierId,
      cashierName: cashierNames[r.cashierId],
      paymentMethodId: r.paymentMethodId,
      paymentMethodName: payNames[r.paymentMethodId],
      subtotal: r.subtotal,
      discountAmount: r.discountAmount,
      total: r.total,
      status: saleStatusFromName(r.status),
      voidReason: r.voidReason,
      voidedBy: r.voidedBy,
      voidedAt: r.voidedAt,
      isCredit: r.isCredit,
      creditSettledAt: r.creditSettledAt,
      notes: r.notes,
      createdAt: r.createdAt,
      items: items
          .map((i) => SaleItem(
                id: i.id,
                saleId: i.saleId,
                productId: i.productId,
                productNameSnapshot: i.productNameSnapshot,
                measurementUnitId: i.measurementUnitId,
                quantity: i.quantity,
                unitPrice: i.unitPrice,
                discountAmount: i.discountAmount,
                total: i.total,
                inventoryStatus: inventoryStatusFromName(i.inventoryStatus),
              ))
          .toList(),
    ));
  }
  return result;
}

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
  final shop = await ref.watch(currentShopProvider.future);
  final client = ref.read(supabaseClientProvider);

  try {
  // Sales — include product category info for optional category filter
  final salesData = await client
      .from('sales')
      .select(
          'total, status, is_credit, credit_settled_at, credit_payments(amount), sale_items(quantity, unit_price, discount_amount, cost_price_snapshot, products(category_id))')
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
    final saleAmount = Decimal.parse(row['total'].toString());
    final paid = (row['credit_payments'] as List? ?? []).fold<Decimal>(
      Decimal.zero,
      (sum, payment) =>
          sum + Decimal.parse(payment['amount'].toString()),
    );
    final remainingCredit = saleAmount > paid ? saleAmount - paid : Decimal.zero;
    final isOutstandingCredit =
        row['is_credit'] == true && remainingCredit > Decimal.zero;

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
          grossProfit +=
              ((unitPrice * qty) - disc) - (costPrice * qty);
          profitItemCount++;
        }
      }
      if (!hasCatItem) continue;
      salesTotal += catRevenue;
      salesCount++;
      if (isOutstandingCredit) {
        creditTotal +=
            catRevenue < remainingCredit ? catRevenue : remainingCredit;
        creditCount++;
      }
    } else {
      // All categories: use the stored sale total.
      final amount = saleAmount;
      salesTotal += amount;
      salesCount++;
      if (isOutstandingCredit) {
        creditTotal += remainingCredit;
        creditCount++;
      }
      for (final item in items) {
        if (item['cost_price_snapshot'] == null) continue;
        final qty = Decimal.parse(item['quantity'].toString());
        final unitPrice = Decimal.parse(item['unit_price'].toString());
        final disc =
            Decimal.parse((item['discount_amount'] ?? '0').toString());
        final costPrice = Decimal.parse(item['cost_price_snapshot'].toString());
        grossProfit += ((unitPrice * qty) - disc) - (costPrice * qty);
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
  } catch (_) {
    // Offline: compute the same summary from the local cache.
    final db = ref.read(appDatabaseProvider);
    if (db == null) rethrow;
    return _localReportSummary(db, branch.id, shop?.id, range, categoryFilter);
  }
});

/// Recomputes [ReportSummary] from the local Drift cache (mirrors the remote
/// aggregation) so Reports work offline.
Future<ReportSummary> _localReportSummary(
  AppDatabase db,
  String branchId,
  String? shopId,
  ({DateTime start, DateTime end}) range,
  String? categoryFilter,
) async {
  final sales = await db.getSalesByBranch(branchId, range.start, range.end);
  final prodCat = <String, String?>{
    if (shopId != null)
      for (final p in await db.getProductsByShop(shopId)) p.id: p.categoryId,
  };
  // Batch items + payments for all completed sales (avoids two N+1 loops).
  final completedIds =
      sales.where((s) => s.status == 'completed').map((s) => s.id).toList();
  final itemsBySale = await db.getSaleItemsForSales(completedIds);
  final paidBySale = await db.getPaidBySale(completedIds);

  Decimal salesTotal = Decimal.zero;
  Decimal creditTotal = Decimal.zero;
  Decimal grossProfit = Decimal.zero;
  int salesCount = 0;
  int creditCount = 0;
  int profitItemCount = 0;

  for (final s in sales) {
    if (s.status != 'completed') continue;
    final items = itemsBySale[s.id] ?? const [];
    final paid = paidBySale[s.id] ?? Decimal.zero;
    final remainingCredit = s.total > paid ? s.total - paid : Decimal.zero;
    final isOutstandingCredit = s.isCredit && remainingCredit > Decimal.zero;

    if (categoryFilter != null) {
      Decimal catRevenue = Decimal.zero;
      bool hasCatItem = false;
      for (final item in items) {
        if (prodCat[item.productId] != categoryFilter) continue;
        hasCatItem = true;
        catRevenue += (item.unitPrice * item.quantity) - item.discountAmount;
        if (item.costPriceSnapshot != null) {
          grossProfit +=
              ((item.unitPrice * item.quantity) - item.discountAmount) -
                  (item.costPriceSnapshot! * item.quantity);
          profitItemCount++;
        }
      }
      if (!hasCatItem) continue;
      salesTotal += catRevenue;
      salesCount++;
      if (isOutstandingCredit) {
        creditTotal +=
            catRevenue < remainingCredit ? catRevenue : remainingCredit;
        creditCount++;
      }
    } else {
      salesTotal += s.total;
      salesCount++;
      if (isOutstandingCredit) {
        creditTotal += remainingCredit;
        creditCount++;
      }
      for (final item in items) {
        if (item.costPriceSnapshot == null) continue;
        grossProfit +=
            ((item.unitPrice * item.quantity) - item.discountAmount) -
                (item.costPriceSnapshot! * item.quantity);
        profitItemCount++;
      }
    }
  }

  final expenses =
      await db.getExpensesByBranchRange(branchId, range.start, range.end);
  Decimal expenseTotal = Decimal.zero;
  final expByCategory = <String, Decimal>{};
  for (final e in expenses) {
    expenseTotal += e.amount;
    expByCategory[e.categoryName] =
        (expByCategory[e.categoryName] ?? Decimal.zero) + e.amount;
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
}
