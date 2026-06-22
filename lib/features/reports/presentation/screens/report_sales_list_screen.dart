import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/sale.dart';
import '../../../../features/inventory/presentation/providers/inventory_provider.dart';
import '../../../../features/sales/presentation/screens/sales_screen.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../providers/reports_provider.dart';

/// Drill-down list reached by tapping the Transactions or Credits figure on
/// the report. Shares the report's period + category providers, and exposes
/// the same filters here (a combo of date period and category) so the list is
/// filterable in place. Each row opens the full SaleDetailScreen.
class ReportSalesListScreen extends ConsumerWidget {
  const ReportSalesListScreen({super.key, required this.creditsOnly});

  /// When true, shows outstanding credit sales; otherwise all transactions.
  final bool creditsOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSales = ref.watch(
        creditsOnly ? reportCreditsProvider : reportSalesProvider);
    final period = ref.watch(reportPeriodProvider);
    final categoryFilter = ref.watch(reportCategoryFilterProvider);
    final categories = ref.watch(productCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(creditsOnly ? 'Credits' : 'Transactions')),
      body: Column(
        children: [
          // ── Filters: date period + category (the requested combo) ───────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ReportPeriod>(
                    segments: const [
                      ButtonSegment(value: ReportPeriod.today, label: Text('Day')),
                      ButtonSegment(value: ReportPeriod.week, label: Text('Week')),
                      ButtonSegment(value: ReportPeriod.month, label: Text('Month')),
                      ButtonSegment(value: ReportPeriod.year, label: Text('Year')),
                    ],
                    selected: {
                      if (period != ReportPeriod.custom) period else ReportPeriod.today
                    },
                    showSelectedIcon: false,
                    onSelectionChanged: (s) {
                      ref.read(reportPeriodProvider.notifier).set(s.first);
                      ref.read(reportCustomRangeProvider.notifier).set(null);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                categories.when(
                  data: (cats) {
                    if (cats.isEmpty) return const SizedBox.shrink();
                    return InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Category',
                        isDense: true,
                        prefixIcon:
                            const Icon(Icons.category_outlined, size: 18),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: categoryFilter,
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<String?>(
                                value: null, child: Text('All categories')),
                            ...cats.map((c) => DropdownMenuItem<String?>(
                                value: c.id, child: Text(c.name))),
                          ],
                          onChanged: (id) => ref
                              .read(reportCategoryFilterProvider.notifier)
                              .set(id),
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: asyncSales.when(
              data: (sales) {
                if (sales.isEmpty) {
                  return Center(
                    child: Text(
                      creditsOnly
                          ? 'No outstanding credits for this filter'
                          : 'No transactions for this filter',
                      style: AppTextStyles.bodySmall,
                    ),
                  );
                }
                final total = sales.fold(
                    Decimal.zero, (sum, s) => sum + s.total);
                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      color: AppColors.surfaceLight,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Text(
                        '${sales.length} ${creditsOnly ? "credit" : "transaction"}${sales.length == 1 ? "" : "s"} • ${formatCurrency(total)}',
                        style: AppTextStyles.label,
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: sales.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (ctx, i) =>
                            _SaleRow(sale: sales[i], creditsOnly: creditsOnly),
                      ),
                    ),
                  ],
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Could not load: $e',
                    style: AppTextStyles.bodySmall),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaleRow extends StatelessWidget {
  const _SaleRow({required this.sale, required this.creditsOnly});
  final Sale sale;
  final bool creditsOnly;

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(sale.createdAt).format(context);
    final d = sale.createdAt;
    final subtitleParts = <String>[
      '${d.day}/${d.month}/${d.year} $time',
      if (sale.customerName != null) sale.customerName!,
      if (sale.cashierName != null) sale.cashierName!,
    ];
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: (creditsOnly ? AppColors.warning : AppColors.primary)
            .withValues(alpha: 0.12),
        child: Icon(
          creditsOnly ? Icons.credit_card_outlined : Icons.receipt_outlined,
          color: creditsOnly ? AppColors.warning : AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(formatCurrency(sale.total),
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitleParts.join(' • '), style: AppTextStyles.bodySmall),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SaleDetailScreen(sale: sale)),
      ),
    );
  }
}
