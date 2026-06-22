import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/sales/presentation/providers/sales_provider.dart';
import '../../../../features/sales/presentation/screens/sales_screen.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/utils/date_formatter.dart';
import '../providers/customers_provider.dart';
import '../widgets/payment_history.dart';

// Accepts only a valid decimal: digits with at most one dot (rejects "1.2.3").
final _decimalFormatter = TextInputFormatter.withFunction((oldValue, newValue) {
  if (newValue.text.isEmpty ||
      RegExp(r'^\d*\.?\d*$').hasMatch(newValue.text)) {
    return newValue;
  }
  return oldValue;
});

// Public helper — opens the settle bottom sheet from any screen.
Future<void> showCreditSettleSheet(
  BuildContext context, {
  required String saleId,
  required Decimal saleTotal,
  required Decimal salePaid,
  required DateTime saleDate,
  required String customerId,
  required String customerName,
}) async {
  final sale = CreditSaleWithCustomer(
    id: saleId,
    total: saleTotal,
    paid: salePaid,
    createdAt: saleDate,
    customerId: customerId,
    customerName: customerName,
  );
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Consumer(
      builder: (ctx, ref, _) => _SettleSheet(
        sale: sale,
        customerId: customerId,
        parentRef: ref,
      ),
    ),
  );
}

// ─── Credits Screen ───────────────────────────────────────────────────────────

class CreditsScreen extends ConsumerWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outstanding = ref.watch(outstandingCreditProvider);
    return outstanding.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          Center(child: Text('Error: $e', style: AppTextStyles.bodySmall)),
      data: (sales) {
        if (sales.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 64, color: AppColors.success),
                const SizedBox(height: 12),
                Text('All settled', style: AppTextStyles.headline3),
                const SizedBox(height: 4),
                Text('No outstanding credit', style: AppTextStyles.bodySmall),
              ],
            ),
          );
        }

        // Group by customer, sort by name
        final groups = <String, List<CreditSaleWithCustomer>>{};
        for (final s in sales) {
          groups.putIfAbsent(s.customerId, () => []).add(s);
        }
        final sortedIds = groups.keys.toList()
          ..sort((a, b) =>
              groups[a]![0].customerName.compareTo(groups[b]![0].customerName));

        final grandTotal =
            sales.fold(Decimal.zero, (sum, s) => sum + s.remaining);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // Summary banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined,
                      color: AppColors.warning, size: 22),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(formatCurrency(grandTotal),
                          style: AppTextStyles.body.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w700)),
                      Text(
                          '${sales.length} unsettled bill${sales.length == 1 ? '' : 's'}'
                          ' · ${sortedIds.length} customer${sortedIds.length == 1 ? '' : 's'}',
                          style: AppTextStyles.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            for (final custId in sortedIds) ...[
              _CustomerSection(
                customerId: custId,
                sales: groups[custId]!,
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

// ─── Per-customer section ─────────────────────────────────────────────────────

class _CustomerSection extends StatelessWidget {
  const _CustomerSection({required this.customerId, required this.sales});
  final String customerId;
  final List<CreditSaleWithCustomer> sales;

  @override
  Widget build(BuildContext context) {
    final name = sales[0].customerName;
    final total = sales.fold(Decimal.zero, (s, e) => s + e.remaining);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: AppColors.warning.withValues(alpha: 0.15),
              child: Text(
                name[0].toUpperCase(),
                style: const TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                    fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(name,
                  style:
                      AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
            ),
            Text(
              formatCurrency(total),
              style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.warning, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...sales.map((s) => _SaleBillCard(sale: s, customerId: customerId)),
        const Divider(height: 8),
      ],
    );
  }
}

// ─── Individual bill card ─────────────────────────────────────────────────────

class _SaleBillCard extends ConsumerWidget {
  const _SaleBillCard({required this.sale, required this.customerId});
  final CreditSaleWithCustomer sale;
  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(top: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatCurrency(sale.remaining),
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sale.paid > Decimal.zero
                        ? '${formatDate(sale.createdAt)} · paid ${formatCurrency(sale.paid)} of ${formatCurrency(sale.total)}'
                        : formatDate(sale.createdAt),
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _openDetail(context, ref),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 34),
              ),
              child: const Text('Details'),
            ),
            const SizedBox(width: 4),
            FilledButton(
              onPressed: () => _openSettleSheet(context, ref),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                minimumSize: const Size(0, 34),
              ),
              child: const Text('Settle'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDetail(BuildContext context, WidgetRef ref) async {
    final sale = await ref.read(salesRepositoryProvider).getSale(this.sale.id);
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SaleDetailScreen(sale: sale)),
    );
  }

  Future<void> _openSettleSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SettleSheet(
        sale: sale,
        customerId: customerId,
        parentRef: ref,
      ),
    );
  }
}

// ─── Settlement bottom sheet ──────────────────────────────────────────────────

class _SettleSheet extends ConsumerStatefulWidget {
  const _SettleSheet({
    required this.sale,
    required this.customerId,
    required this.parentRef,
  });
  final CreditSaleWithCustomer sale;
  final String customerId;
  final WidgetRef parentRef;

  @override
  ConsumerState<_SettleSheet> createState() => _SettleSheetState();
}

class _SettleSheetState extends ConsumerState<_SettleSheet> {
  String? _method; // 'cash' | 'bank_transfer'
  final _notesCtrl = TextEditingController();
  late final _amountCtrl =
      TextEditingController(text: widget.sale.remaining.toStringAsFixed(2));

  @override
  void dispose() {
    _notesCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final amount = Decimal.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= Decimal.zero) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter a valid amount'),
      ));
      return;
    }
    if (amount > widget.sale.remaining) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Only ${formatCurrency(widget.sale.remaining)} is left on this bill'),
      ));
      return;
    }
    final ok = await ref.read(customerFormProvider.notifier).recordCreditPayment(
          customerId: widget.customerId,
          saleId: widget.sale.id,
          saleTotal: widget.sale.total,
          amount: amount,
          method: _method!,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Payment of ${formatCurrency(amount)} recorded'),
        backgroundColor: AppColors.success,
      ));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not record the payment. Try again.'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(customerFormProvider).isLoading;
    final isBankTransfer = _method == 'bank_transfer';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Text('Record Payment', style: AppTextStyles.headline3),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(widget.sale.customerName,
                  style: AppTextStyles.bodySmall
                      .copyWith(fontWeight: FontWeight.w600)),
              const Text(' · ', style: TextStyle(color: AppColors.textSecondary)),
              Text(formatDate(widget.sale.createdAt),
                  style: AppTextStyles.bodySmall),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${formatCurrency(widget.sale.remaining)} remaining',
            style: AppTextStyles.amount.copyWith(color: AppColors.warning),
          ),
          if (widget.sale.paid > Decimal.zero)
            Text(
              'Paid ${formatCurrency(widget.sale.paid)} of ${formatCurrency(widget.sale.total)}',
              style: AppTextStyles.bodySmall,
            ),
          const SizedBox(height: 16),

          // Amount — defaults to the full remaining; lower it for a partial payment.
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [_decimalFormatter],
            decoration: const InputDecoration(
              labelText: 'Amount paid (${AppConstants.defaultCurrency})',
              helperText: 'Lower this to record a partial payment',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 20),

          // Method selection
          Text('How was this paid?', style: AppTextStyles.label),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _MethodButton(
                icon: Icons.payments_outlined,
                label: 'Cash',
                selected: _method == 'cash',
                onTap: () => setState(() => _method = 'cash'),
              )),
              const SizedBox(width: 12),
              Expanded(child: _MethodButton(
                icon: Icons.account_balance_outlined,
                label: 'Bank Transfer',
                selected: _method == 'bank_transfer',
                onTap: () => setState(() => _method = 'bank_transfer'),
              )),
            ],
          ),

          // Notes field — only for bank transfer
          if (isBankTransfer) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Reference ID, sender name, etc.',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 2,
              textInputAction: TextInputAction.done,
              autofocus: true,
            ),
          ],

          // Payment history (the dispute trail)
          PaymentHistory(saleId: widget.sale.id),

          const SizedBox(height: 24),

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (_method == null || loading) ? null : _confirm,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                disabledBackgroundColor:
                    AppColors.success.withValues(alpha: 0.3),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Record Payment', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodButton extends StatelessWidget {
  const _MethodButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: selected ? AppColors.primary : AppColors.textSecondary,
                size: 26),
            const SizedBox(height: 6),
            Text(label,
                style: AppTextStyles.body.copyWith(
                    color:
                        selected ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

