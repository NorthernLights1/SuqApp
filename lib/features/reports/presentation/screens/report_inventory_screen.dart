import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/inventory/presentation/providers/inventory_provider.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../widgets/report_filters.dart';

/// Inventory report: current stock health — low-stock items first. Stock is a
/// live snapshot, so this report has no period filter.
class ReportInventoryScreen extends ConsumerWidget {
  const ReportInventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stock = ref.watch(stockLevelsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: stock.when(
        data: (list) {
          final low = list.where((e) => e.isLowStock).toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: ReportStatRow(
                      label: 'Products',
                      value: '${list.length}',
                      icon: Icons.inventory_2_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ReportStatRow(
                      label: 'Low / Out',
                      value: '${low.length}',
                      icon: Icons.warning_amber_outlined,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Low Stock Alert', style: AppTextStyles.headline3),
              const SizedBox(height: 8),
              if (low.isEmpty)
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: AppColors.success, size: 18),
                    const SizedBox(width: 6),
                    Text('All items above threshold',
                        style: AppTextStyles.bodySmall),
                  ],
                )
              else
                ...low.map((e) => ListTile(
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
                    )),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Could not load inventory: $e',
              style: AppTextStyles.bodySmall),
        ),
      ),
    );
  }
}
