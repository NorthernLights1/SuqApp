import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/inventory/presentation/providers/inventory_provider.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../providers/reports_provider.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(reportPeriodProvider);
    final summary = ref.watch(reportSummaryProvider);
    final stock = ref.watch(stockLevelsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Period selector
          SegmentedButton<ReportPeriod>(
            segments: const [
              ButtonSegment(value: ReportPeriod.today, label: Text('Today')),
              ButtonSegment(value: ReportPeriod.week, label: Text('This Week')),
              ButtonSegment(value: ReportPeriod.month, label: Text('This Month')),
            ],
            selected: {period},
            onSelectionChanged: (s) =>
                ref.read(reportPeriodProvider.notifier).state = s.first,
          ),
          const SizedBox(height: 20),

          summary.when(
            data: (s) => _SummaryBody(summary: s),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, st) => Center(
              child: Text('Could not load report: $e',
                  style: AppTextStyles.bodySmall),
            ),
          ),

          const SizedBox(height: 24),
          Text('Low Stock Alert', style: AppTextStyles.headline3),
          const SizedBox(height: 8),

          stock.when(
            data: (list) {
              final low = list.where((e) => e.isLowStock).toList();
              if (low.isEmpty) {
                return Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: AppColors.success, size: 18),
                    const SizedBox(width: 6),
                    Text('All items above threshold',
                        style: AppTextStyles.bodySmall),
                  ],
                );
              }
              return Column(
                children: low
                    .map((e) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.warning_amber_outlined,
                              color: AppColors.warning),
                          title: Text(e.productName, style: AppTextStyles.body),
                          trailing: Text(
                            '${e.quantity.toStringAsFixed(2)} ${e.unitAbbr}',
                            style: AppTextStyles.body.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600),
                          ),
                        ))
                    .toList(),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _SummaryBody extends StatelessWidget {
  const _SummaryBody({required this.summary});
  final ReportSummary summary;

  @override
  Widget build(BuildContext context) {
    final netPositive = summary.net >= Decimal.zero;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sales', style: AppTextStyles.headline3),
        const SizedBox(height: 8),
        _StatRow(
          label: 'Revenue',
          value: 'ETB ${summary.salesTotal.toStringAsFixed(2)}',
          icon: Icons.trending_up,
          color: AppColors.success,
        ),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
            child: _StatRow(
              label: 'Transactions',
              value: '${summary.salesCount}',
              icon: Icons.receipt_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatRow(
              label: 'On Credit',
              value: '${summary.creditCount}',
              icon: Icons.credit_card_outlined,
              color: AppColors.warning,
            ),
          ),
        ]),
        if (summary.creditCount > 0) ...[
          const SizedBox(height: 6),
          _StatRow(
            label: 'Credit Total',
            value: 'ETB ${summary.creditTotal.toStringAsFixed(2)}',
            icon: Icons.account_balance_wallet_outlined,
            color: AppColors.warning,
          ),
        ],
        const SizedBox(height: 20),
        Text('Expenses', style: AppTextStyles.headline3),
        const SizedBox(height: 8),
        _StatRow(
          label: 'Total Expenses',
          value: 'ETB ${summary.expenseTotal.toStringAsFixed(2)}',
          icon: Icons.money_off_outlined,
          color: AppColors.error,
        ),
        if (summary.expenseByCategory.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...summary.expenseByCategory.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 36),
                      child: Text(e.key, style: AppTextStyles.bodySmall),
                    ),
                    Text(
                      'ETB ${e.value.toStringAsFixed(2)}',
                      style: AppTextStyles.bodySmall
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )),
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
              color: netPositive ? AppColors.success : AppColors.error,
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              Icon(
                netPositive ? Icons.trending_up : Icons.trending_down,
                color: netPositive ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Net (Sales − Expenses)',
                    style: AppTextStyles.bodySmall),
              ),
              Text(
                'ETB ${summary.net.toStringAsFixed(2)}',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: netPositive ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: AppTextStyles.bodySmall)),
          Text(value,
              style: AppTextStyles.body
                  .copyWith(fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
