import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../features/inventory/presentation/providers/inventory_provider.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../providers/reports_provider.dart';

/// Period segmented button + custom date range row. Drives the global
/// [reportPeriodProvider] / [reportCustomRangeProvider] state, so every report
/// screen that shows it stays in sync.
class ReportPeriodSelector extends ConsumerWidget {
  const ReportPeriodSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(reportPeriodProvider);
    final customRange = ref.watch(reportCustomRangeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<ReportPeriod>(
          segments: const [
            ButtonSegment(value: ReportPeriod.today, label: Text('Today')),
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
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.date_range_outlined, size: 16),
                label: Text(
                  period == ReportPeriod.custom && customRange != null
                      ? "${DateFormat('MMM d, y').format(customRange.start)} – ${DateFormat('MMM d, y').format(customRange.end)}"
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
      ],
    );
  }
}

/// Product-category combo box. Drives [reportCategoryFilterProvider]. Only
/// shown on reports where category filtering makes sense (Sales / Revenue).
class ReportCategoryDropdown extends ConsumerWidget {
  const ReportCategoryDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryFilter = ref.watch(reportCategoryFilterProvider);
    final categories = ref.watch(productCategoriesProvider);
    return categories.when(
      data: (cats) {
        if (cats.isEmpty) return const SizedBox.shrink();
        return InputDecorator(
          decoration: InputDecoration(
            labelText: 'Category',
            isDense: true,
            prefixIcon: const Icon(Icons.category_outlined, size: 18),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                    value: c.id, child: Text(c.name))),
              ],
              onChanged: (id) =>
                  ref.read(reportCategoryFilterProvider.notifier).set(id),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

/// A single labelled stat card row, optionally tappable (chevron shown).
class ReportStatRow extends StatelessWidget {
  const ReportStatRow({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });
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
