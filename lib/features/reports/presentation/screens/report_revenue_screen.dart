import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../providers/reports_provider.dart';
import '../widgets/report_filters.dart';

/// Revenue report: the bottom line — sales in, expenses out, net result —
/// for the selected period, with optional product-category scoping on sales.
class ReportRevenueScreen extends ConsumerWidget {
  const ReportRevenueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(reportSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Revenue')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ReportPeriodSelector(),
          const SizedBox(height: 12),
          const ReportCategoryDropdown(),
          const SizedBox(height: 16),
          summary.when(
            data: (s) {
              final netPositive = s.net >= Decimal.zero;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReportStatRow(
                    label: 'Sales',
                    value: formatCurrency(s.salesTotal),
                    icon: Icons.trending_up,
                    color: AppColors.success,
                  ),
                  const SizedBox(height: 6),
                  ReportStatRow(
                    label: 'Expenses',
                    value: formatCurrency(s.expenseTotal),
                    icon: Icons.money_off_outlined,
                    color: AppColors.error,
                  ),
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
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: netPositive
                          ? AppColors.success.withValues(alpha: 0.08)
                          : AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: netPositive
                            ? AppColors.success
                            : AppColors.error,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          netPositive
                              ? Icons.trending_up
                              : Icons.trending_down,
                          color:
                              netPositive ? AppColors.success : AppColors.error,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('Net (Sales − Expenses)',
                              style: AppTextStyles.bodySmall),
                        ),
                        Text(
                          formatCurrency(s.net),
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: netPositive
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Center(
              child: Text('Could not load revenue: $e',
                  style: AppTextStyles.bodySmall),
            ),
          ),
        ],
      ),
    );
  }
}
