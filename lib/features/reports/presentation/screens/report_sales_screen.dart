import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../providers/reports_provider.dart';
import '../widgets/report_filters.dart';
import 'report_sales_list_screen.dart';

/// Sales report: top-line revenue, transaction counts (drill-down), credit,
/// and gross profit — filtered by period + product category.
class ReportSalesScreen extends ConsumerWidget {
  const ReportSalesScreen({super.key});

  void _openDrillDown(BuildContext context, {required bool creditsOnly}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ReportSalesListScreen(creditsOnly: creditsOnly),
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(reportSummaryProvider);
    final categoryFiltered = ref.watch(reportCategoryFilterProvider) != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Sales')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ReportPeriodSelector(),
          const SizedBox(height: 12),
          const ReportCategoryDropdown(),
          const SizedBox(height: 16),
          summary.when(
            data: (s) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReportStatRow(
                  label: categoryFiltered ? 'Category Revenue' : 'Revenue',
                  value: formatCurrency(s.salesTotal),
                  icon: Icons.trending_up,
                  color: AppColors.success,
                ),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(
                    child: ReportStatRow(
                      label: 'Transactions',
                      value: '${s.salesCount}',
                      icon: Icons.receipt_outlined,
                      color: AppColors.primary,
                      onTap: () => _openDrillDown(context, creditsOnly: false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ReportStatRow(
                      label: 'On Credit',
                      value: '${s.creditCount}',
                      icon: Icons.credit_card_outlined,
                      color: AppColors.warning,
                      onTap: () => _openDrillDown(context, creditsOnly: true),
                    ),
                  ),
                ]),
                if (s.creditCount > 0) ...[
                  const SizedBox(height: 6),
                  ReportStatRow(
                    label: 'Credit Total',
                    value: formatCurrency(s.creditTotal),
                    icon: Icons.account_balance_wallet_outlined,
                    color: AppColors.warning,
                  ),
                ],
                if (s.profitItemCount > 0) ...[
                  const SizedBox(height: 6),
                  ReportStatRow(
                    label: 'Gross Profit (costed items)',
                    value: formatCurrency(s.grossProfit),
                    icon: Icons.show_chart,
                    color: s.grossProfit >= Decimal.zero
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ],
              ],
            ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Center(
              child: Text('Could not load sales: $e',
                  style: AppTextStyles.bodySmall),
            ),
          ),
        ],
      ),
    );
  }
}
