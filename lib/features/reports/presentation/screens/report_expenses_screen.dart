import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../providers/reports_provider.dart';
import '../widgets/report_filters.dart';

/// Expenses report: total spend for the period + a per-category breakdown.
/// (Expense categories are independent of product categories, so no product
/// category filter here.)
class ReportExpensesScreen extends ConsumerWidget {
  const ReportExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(reportSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ReportPeriodSelector(),
          const SizedBox(height: 16),
          summary.when(
            data: (s) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReportStatRow(
                  label: 'Total Expenses',
                  value: formatCurrency(s.expenseTotal),
                  icon: Icons.money_off_outlined,
                  color: AppColors.error,
                ),
                if (s.expenseByCategory.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('By Category', style: AppTextStyles.headline3),
                  const SizedBox(height: 8),
                  ...s.expenseByCategory.entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(e.key, style: AppTextStyles.bodySmall),
                            Text(
                              formatCurrency(e.value),
                              style: AppTextStyles.bodySmall
                                  .copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )),
                ] else ...[
                  const SizedBox(height: 16),
                  Text('No expenses for this period',
                      style: AppTextStyles.bodySmall),
                ],
              ],
            ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Center(
              child: Text('Could not load expenses: $e',
                  style: AppTextStyles.bodySmall),
            ),
          ),
        ],
      ),
    );
  }
}
