import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../domain/models/sale.dart';
import '../../../../shared/router/app_routes.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../providers/sales_provider.dart';

class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sales = ref.watch(salesListProvider);
    final date = ref.watch(selectedSalesDateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: () => _pickDate(context, ref, date),
          ),
        ],
      ),
      body: Column(
        children: [
          // Date header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.surfaceLight,
            child: Text(
              _formatDate(date),
              style: AppTextStyles.label,
            ),
          ),
          // Sales summary banner
          _SalesSummaryBanner(),
          const Divider(height: 1),
          // List
          Expanded(
            child: sales.when(
              data: (list) => list.isEmpty
                  ? _EmptySales(date: date)
                  : ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (ctx, i) =>
                          _SaleTile(sale: list[i]),
                    ),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Failed to load sales: $e',
                    style: AppTextStyles.bodySmall),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.newSale),
        icon: const Icon(Icons.add),
        label: const Text('New Sale'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Future<void> _pickDate(
      BuildContext context, WidgetRef ref, DateTime current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      ref.read(selectedSalesDateProvider.notifier).set(picked);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today — ${_monthName(date.month)} ${date.day}, ${date.year}';
    }
    return '${_monthName(date.month)} ${date.day}, ${date.year}';
  }

  String _monthName(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];
}

class _SalesSummaryBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(todaySalesTotalsProvider);
    return totals.when(
      data: (t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: Colors.white,
        child: Row(
          children: [
            _BannerStat(
                label: 'Revenue',
                value: 'ETB ${t['total']?.toStringAsFixed(2) ?? '0.00'}'),
            const SizedBox(width: 24),
            _BannerStat(
                label: 'Transactions',
                value: t['count']?.toStringAsFixed(0) ?? '0'),
          ],
        ),
      ),
      loading: () => const SizedBox(height: 40, child: LinearProgressIndicator()),
      error: (e, _) => const SizedBox.shrink(),
    );
  }
}

class _BannerStat extends StatelessWidget {
  const _BannerStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        Text(value,
            style: AppTextStyles.headline3.copyWith(color: AppColors.primary)),
      ],
    );
  }
}

class _SaleTile extends StatelessWidget {
  const _SaleTile({required this.sale});
  final Sale sale;

  @override
  Widget build(BuildContext context) {
    final isVoided = sale.status == SaleStatus.voided;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            isVoided ? AppColors.error.withValues(alpha: 0.1) : AppColors.primaryLight,
        child: Icon(
          isVoided ? Icons.cancel_outlined : Icons.receipt_outlined,
          color: isVoided ? AppColors.error : AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        'ETB ${sale.total.toStringAsFixed(2)}',
        style: AppTextStyles.body.copyWith(
          fontWeight: FontWeight.w600,
          decoration: isVoided ? TextDecoration.lineThrough : null,
          color: isVoided ? AppColors.textSecondary : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        '${sale.items.length} item(s) • ${_formatTime(sale.createdAt)}',
        style: AppTextStyles.bodySmall,
      ),
      trailing: isVoided
          ? const Chip(
              label: Text('Voided'),
              backgroundColor: Color(0xFFFFEBEE),
              labelStyle: TextStyle(color: AppColors.error, fontSize: 11),
              padding: EdgeInsets.zero,
            )
          : const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: () => _showDetail(context, sale),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  void _showDetail(BuildContext context, Sale sale) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SaleDetailScreen(sale: sale)),
    );
  }
}

class _EmptySales extends StatelessWidget {
  const _EmptySales({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.receipt_long_outlined,
              size: 64, color: AppColors.textDisabled),
          const SizedBox(height: 12),
          Text('No sales recorded', style: AppTextStyles.headline3),
          const SizedBox(height: 4),
          Text('Tap + New Sale to get started',
              style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

// ─── Sale Detail Screen ───────────────────────────────────────────────────────

class SaleDetailScreen extends ConsumerWidget {
  const SaleDetailScreen({super.key, required this.sale});
  final Sale sale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVoided = sale.status == SaleStatus.voided;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sale Details'),
        actions: [
          if (!isVoided)
            TextButton.icon(
              icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
              label: const Text('Void', style: TextStyle(color: AppColors.error)),
              onPressed: () => _confirmVoid(context, ref),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status banner
          if (isVoided)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cancel, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Voided${sale.voidReason != null ? ': ${sale.voidReason}' : ''}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),

          // Summary card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _DetailRow(label: 'Date',
                      value: _formatDateTime(sale.createdAt)),
                  _DetailRow(label: 'Items',
                      value: '${sale.items.length}'),
                  _DetailRow(label: 'Subtotal',
                      value: 'ETB ${sale.subtotal.toStringAsFixed(2)}'),
                  if (sale.discountAmount > Decimal.zero)
                    _DetailRow(
                        label: 'Discount',
                        value: '- ETB ${sale.discountAmount.toStringAsFixed(2)}',
                        valueColor: AppColors.warning),
                  const Divider(),
                  _DetailRow(
                    label: 'Total',
                    value: 'ETB ${sale.total.toStringAsFixed(2)}',
                    bold: true,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          Text('Items', style: AppTextStyles.headline3),
          const SizedBox(height: 8),

          // Items list
          ...sale.items.map((item) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(item.productNameSnapshot,
                      style: AppTextStyles.body),
                  subtitle: Text(
                    '${item.quantity} × ETB ${item.unitPrice.toStringAsFixed(2)}',
                    style: AppTextStyles.bodySmall,
                  ),
                  trailing: Text(
                    'ETB ${item.total.toStringAsFixed(2)}',
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              )),

          if (sale.notes != null) ...[
            const SizedBox(height: 16),
            Text('Notes', style: AppTextStyles.headline3),
            const SizedBox(height: 4),
            Text(sale.notes!, style: AppTextStyles.bodySmall),
          ],
        ],
      ),
    );
  }

  void _confirmVoid(BuildContext context, WidgetRef ref) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Void Sale'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This cannot be undone.', style: AppTextStyles.bodySmall),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Reason (required)',
                isDense: true,
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (reasonCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await ref.read(voidSaleProvider.notifier).voidSale(
                    saleId: sale.id,
                    reason: reasonCtrl.text.trim(),
                  );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Void Sale',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} $h:$m $period';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Text(
            value,
            style: bold
                ? AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)
                : AppTextStyles.body.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }
}
