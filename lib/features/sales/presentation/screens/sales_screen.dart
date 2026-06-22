import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../domain/models/sale.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/auth/presentation/providers/permissions_provider.dart';
import '../../../../features/refunds/presentation/screens/refund_screen.dart';
import '../../../../features/customers/presentation/widgets/payment_history.dart';
import '../../../../shared/router/app_routes.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/utils/date_formatter.dart';
import '../providers/sales_provider.dart';

class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sales = ref.watch(salesListProvider);
    final date = ref.watch(selectedSalesDateProvider);
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

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
              isToday ? 'Today — ${formatDate(date)}' : formatDate(date),
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
                value: formatCurrency(t['total'] ?? Decimal.zero)),
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
    final isUnsettledCredit = sale.isCredit && !sale.isCreditSettled;
    final isSettledCredit = sale.isCredit && sale.isCreditSettled;

    final Color iconColor;
    final Color iconBg;
    final IconData iconData;
    final Widget trailing;

    if (isVoided) {
      iconColor = AppColors.error;
      iconBg = AppColors.error.withValues(alpha: 0.1);
      iconData = Icons.cancel_outlined;
      trailing = const Chip(
        label: Text('Voided'),
        backgroundColor: Color(0xFFFFEBEE),
        labelStyle: TextStyle(color: AppColors.error, fontSize: 11),
        padding: EdgeInsets.zero,
      );
    } else if (isUnsettledCredit) {
      iconColor = AppColors.warning;
      iconBg = AppColors.warning.withValues(alpha: 0.1);
      iconData = Icons.credit_card_outlined;
      trailing = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('Credit', style: AppTextStyles.label.copyWith(color: AppColors.warning)),
      );
    } else if (isSettledCredit) {
      iconColor = AppColors.success;
      iconBg = AppColors.success.withValues(alpha: 0.1);
      iconData = Icons.credit_score;
      trailing = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('Paid', style: AppTextStyles.label.copyWith(color: AppColors.success)),
      );
    } else {
      iconColor = AppColors.primary;
      iconBg = AppColors.primaryLight;
      iconData = Icons.receipt_outlined;
      trailing = const Icon(Icons.chevron_right, color: AppColors.textSecondary);
    }

    final who = sale.cashierName != null ? ' • ${sale.cashierName}' : '';
    final subtitle = isUnsettledCredit && sale.customerName != null
        ? '${sale.customerName} • ${_formatTime(sale.createdAt)}$who'
        : '${sale.items.length} item(s) • ${_formatTime(sale.createdAt)}$who';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconBg,
        child: Icon(iconData, color: iconColor, size: 20),
      ),
      title: Text(
        formatCurrency(sale.total),
        style: AppTextStyles.body.copyWith(
          fontWeight: FontWeight.w600,
          decoration: isVoided ? TextDecoration.lineThrough : null,
          color: isVoided ? AppColors.textSecondary : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
      trailing: trailing,
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
    final isUnsettledCredit = sale.isCredit && !sale.isCreditSettled;
    final isSettledCredit = sale.isCredit && sale.isCreditSettled;
    final txRef = '#${sale.id.split('-').last.toUpperCase()}';

    String paymentLabel;
    Color paymentColor;
    if (isUnsettledCredit) {
      paymentLabel = 'Credit — Outstanding';
      paymentColor = AppColors.warning;
    } else if (isSettledCredit) {
      // A bill paid with mixed methods (or via the payment history) has no
      // single method — don't claim one.
      final method = switch (sale.creditSettlementMethod) {
        'bank_transfer' => 'Bank Transfer',
        'cash' => 'Cash',
        _ => null,
      };
      paymentLabel =
          method != null ? 'Credit — Settled ($method)' : 'Credit — Settled';
      paymentColor = AppColors.success;
    } else {
      paymentLabel = sale.paymentMethodName ?? 'Cash';
      paymentColor = AppColors.textPrimary;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sale Details'),
        actions: [
          if (!isVoided && _canRefund(ref))
            TextButton.icon(
              icon: const Icon(Icons.assignment_return_outlined,
                  color: AppColors.warning),
              label: const Text('Refund',
                  style: TextStyle(color: AppColors.warning)),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => RefundScreen(sale: sale)),
              ),
            ),
          if (!isVoided && hasPermissionSync(ref, 'sales.void'))
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
          // Voided banner
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
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),

          // Outstanding credit banner
          if (isUnsettledCredit)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.credit_card_outlined, color: AppColors.warning, size: 20),
                  const SizedBox(width: 8),
                  Text('Credit not yet settled',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning)),
                ],
              ),
            ),

          // Summary card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _DetailRow(label: 'Ref', value: txRef),
                  _DetailRow(label: 'Date', value: formatDateTime(sale.createdAt)),
                  if (sale.cashierName != null)
                    _DetailRow(label: 'Sold by', value: sale.cashierName!),
                  _DetailRow(
                    label: 'Payment',
                    value: paymentLabel,
                    valueColor: paymentColor,
                  ),
                  _DetailRow(label: 'Items', value: '${sale.items.length}'),
                  _DetailRow(label: 'Subtotal',
                      value: formatCurrency(sale.subtotal)),
                  if (sale.discountAmount > Decimal.zero)
                    _DetailRow(
                        label: 'Discount',
                        value: '- ${formatCurrency(sale.discountAmount.abs())}',
                        valueColor: AppColors.warning),
                  const Divider(),
                  _DetailRow(
                    label: 'Total',
                    value: formatCurrency(sale.total),
                    bold: true,
                  ),
                ],
              ),
            ),
          ),

          // Customer info (credit sales)
          if (sale.isCredit && (sale.customerName != null || sale.customerId != null)) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text('Customer', style: AppTextStyles.label),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (sale.customerName != null)
                      _DetailRow(label: 'Name', value: sale.customerName!),
                    if (sale.customerPhone != null)
                      _DetailRow(label: 'Phone', value: sale.customerPhone!),
                  ],
                ),
              ),
            ),
          ],

          // Payment history (credit sales) — every recorded installment with
          // its timestamp, whether the bill is partially or fully settled.
          // Collapses to nothing when no payments have been recorded yet.
          if (sale.isCredit) PaymentHistory(saleId: sale.id, card: true),

          // Settlement notes (bank transfer)
          if (isSettledCredit &&
              sale.creditSettlementMethod == 'bank_transfer' &&
              sale.creditSettlementNotes != null) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_balance_outlined,
                            size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text('Settlement Notes', style: AppTextStyles.label),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(sale.creditSettlementNotes!, style: AppTextStyles.body),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),
          Text('Items', style: AppTextStyles.headline3),
          const SizedBox(height: 8),

          // Items list
          ...sale.items.map((item) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(item.productNameSnapshot, style: AppTextStyles.body),
                  subtitle: Text(
                    '${item.quantity} × ${formatCurrency(item.unitPrice)}',
                    style: AppTextStyles.bodySmall,
                  ),
                  trailing: Text(
                    formatCurrency(item.total),
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
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

  /// Owners/managers can refund any sale; a cashier with refund_own can refund
  /// only the sales they rang up.
  bool _canRefund(WidgetRef ref) {
    if (hasPermissionSync(ref, 'sales.refund_any')) return true;
    final userId = ref.read(currentUserIdProvider);
    return hasPermissionSync(ref, 'sales.refund_own') &&
        userId != null &&
        sale.cashierId == userId;
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
