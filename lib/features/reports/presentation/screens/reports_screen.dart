import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/presentation/providers/permissions_provider.dart';
import '../../../../features/inventory/presentation/providers/inventory_provider.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../providers/reports_provider.dart';
import 'report_sales_list_screen.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Defense-in-depth: even if the entry points are hidden, a cashier must
    // not be able to view reports by any navigation path.
    final perms = ref.watch(permissionsProvider);
    if (perms.hasValue && !perms.requireValue.contains('reports.view')) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reports')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline,
                    size: 56, color: AppColors.textDisabled),
                const SizedBox(height: 12),
                Text('Reports are restricted',
                    style: AppTextStyles.headline3, textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text('Ask the shop owner or a manager for access.',
                    style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }

    final period = ref.watch(reportPeriodProvider);
    final customRange = ref.watch(reportCustomRangeProvider);
    final categoryFilter = ref.watch(reportCategoryFilterProvider);
    final categories = ref.watch(productCategoriesProvider);
    final summary = ref.watch(reportSummaryProvider);
    final stock = ref.watch(stockLevelsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Period selector ────────────────────────────────────────────
          SegmentedButton<ReportPeriod>(
            segments: const [
              ButtonSegment(value: ReportPeriod.today, label: Text('Today')),
              ButtonSegment(value: ReportPeriod.week,  label: Text('Week')),
              ButtonSegment(value: ReportPeriod.month, label: Text('Month')),
              ButtonSegment(value: ReportPeriod.year,  label: Text('Year')),
            ],
            selected: {if (period != ReportPeriod.custom) period else ReportPeriod.today},
            showSelectedIcon: false,
            onSelectionChanged: (s) {
              ref.read(reportPeriodProvider.notifier).set(s.first);
              ref.read(reportCustomRangeProvider.notifier).set(null);
            },
          ),
          const SizedBox(height: 8),

          // ── Custom date range ──────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.date_range_outlined, size: 16),
                  label: Text(
                    period == ReportPeriod.custom && customRange != null
                        ? '${_fmtDate(customRange.start)} – ${_fmtDate(customRange.end)}'
                        : 'Custom Range',
                    style: AppTextStyles.bodySmall,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: period == ReportPeriod.custom
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    side: BorderSide(
                      color: period == ReportPeriod.custom
                          ? AppColors.primary
                          : AppColors.cardBorder,
                    ),
                  ),
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDateRange: customRange,
                    );
                    if (picked == null) return;
                    ref.read(reportCustomRangeProvider.notifier).set(picked);
                    ref.read(reportPeriodProvider.notifier).set(ReportPeriod.custom);
                  },
                ),
              ),
              if (period == ReportPeriod.custom) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Clear custom range',
                  onPressed: () {
                    ref.read(reportPeriodProvider.notifier).set(ReportPeriod.today);
                    ref.read(reportCustomRangeProvider.notifier).set(null);
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // ── Category filter (combo box) ────────────────────────────────
          categories.when(
            data: (cats) {
              if (cats.isEmpty) return const SizedBox.shrink();
              return InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Category',
                  isDense: true,
                  prefixIcon: const Icon(Icons.category_outlined, size: 18),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: categoryFilter,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String?>(
                          value: null, child: Text('All categories')),
                      ...cats.map((c) => DropdownMenuItem<String?>(
                            value: c.id,
                            child: Text(c.name),
                          )),
                    ],
                    onChanged: (id) =>
                        ref.read(reportCategoryFilterProvider.notifier).set(id),
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),

          // ── Summary ────────────────────────────────────────────────────
          if (categoryFilter != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: categories.when(
                data: (cats) {
                  final cat = cats.where((c) => c.id == categoryFilter).firstOrNull;
                  if (cat == null) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.filter_list,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text('Filtered: ${cat.name}',
                            style: AppTextStyles.label
                                .copyWith(color: AppColors.primary)),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ),

          summary.when(
            data: (s) => _SummaryBody(summary: s, isCategoryFiltered: categoryFilter != null),
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

  String _fmtDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month - 1]} ${d.day}';
  }
}

class _SummaryBody extends StatelessWidget {
  const _SummaryBody({required this.summary, this.isCategoryFiltered = false});
  final ReportSummary summary;
  final bool isCategoryFiltered;

  void _openDrillDown(BuildContext context, {required bool creditsOnly}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ReportSalesListScreen(creditsOnly: creditsOnly),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final netPositive = summary.net >= Decimal.zero;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sales', style: AppTextStyles.headline3),
        const SizedBox(height: 8),
        _StatRow(
          label: isCategoryFiltered ? 'Category Revenue' : 'Revenue',
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
              onTap: () => _openDrillDown(context, creditsOnly: false),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatRow(
              label: 'On Credit',
              value: '${summary.creditCount}',
              icon: Icons.credit_card_outlined,
              color: AppColors.warning,
              onTap: () => _openDrillDown(context, creditsOnly: true),
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
        if (summary.profitItemCount > 0) ...[
          const SizedBox(height: 6),
          _StatRow(
            label: 'Gross Profit (costed items)',
            value: 'ETB ${summary.grossProfit.toStringAsFixed(2)}',
            icon: Icons.show_chart,
            color: summary.grossProfit >= Decimal.zero
                ? AppColors.success
                : AppColors.error,
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
      required this.color,
      this.onTap});
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
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
          if (onTap != null) ...[
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textSecondary),
          ],
        ],
      ),
    );
    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: content,
    );
  }
}
