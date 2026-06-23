import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/presentation/providers/permissions_provider.dart';
import '../../../../features/inventory/presentation/providers/inventory_provider.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../providers/reports_provider.dart';
import '../widgets/report_filters.dart';
import 'report_expenses_screen.dart';
import 'report_inventory_screen.dart';
import 'report_revenue_screen.dart';
import 'report_sales_screen.dart';

/// Reports hub: four cards (Sales / Inventory / Expenses / Revenue) showing a
/// snapshot for the selected period. Tapping a card opens its dedicated report.
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
                    style: AppTextStyles.headline3,
                    textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text('Ask the shop owner or a manager for access.',
                    style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }

    final summary = ref.watch(reportSummaryProvider);
    final stock = ref.watch(stockLevelsProvider);

    final lowStockCount = stock.maybeWhen(
      data: (list) => list.where((e) => e.isLowStock).length,
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ReportPeriodSelector(),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: [
              _ReportCard(
                icon: Icons.trending_up,
                color: AppColors.success,
                title: 'Sales',
                value: summary.maybeWhen(
                  data: (s) => formatCurrency(s.salesTotal),
                  orElse: () => '—',
                ),
                subtitle: summary.maybeWhen(
                  data: (s) => '${s.salesCount} transactions',
                  orElse: () => null,
                ),
                onTap: () => _push(context, const ReportSalesScreen()),
              ),
              _ReportCard(
                icon: Icons.inventory_2_outlined,
                color: AppColors.primary,
                title: 'Inventory',
                value: lowStockCount == null
                    ? '—'
                    : '$lowStockCount low',
                subtitle: 'stock health',
                onTap: () => _push(context, const ReportInventoryScreen()),
              ),
              _ReportCard(
                icon: Icons.money_off_outlined,
                color: AppColors.error,
                title: 'Expenses',
                value: summary.maybeWhen(
                  data: (s) => formatCurrency(s.expenseTotal),
                  orElse: () => '—',
                ),
                subtitle: 'this period',
                onTap: () => _push(context, const ReportExpensesScreen()),
              ),
              _ReportCard(
                icon: Icons.account_balance_wallet_outlined,
                color: summary.maybeWhen(
                  data: (s) =>
                      s.net >= Decimal.zero ? AppColors.success : AppColors.error,
                  orElse: () => AppColors.textSecondary,
                ),
                title: 'Revenue',
                value: summary.maybeWhen(
                  data: (s) => formatCurrency(s.net),
                  orElse: () => '—',
                ),
                subtitle: 'net result',
                onTap: () => _push(context, const ReportRevenueScreen()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.onTap,
    this.subtitle,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Icon(icon, color: color, size: 18),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right,
                    size: 18, color: AppColors.textSecondary),
              ],
            ),
            const Spacer(),
            Text(value,
                style: AppTextStyles.headline3.copyWith(color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(title,
                style:
                    AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
            if (subtitle != null)
              Text(subtitle!, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}
