import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/customers_provider.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _fmtDate(DateTime dt) =>
    '${_months[dt.month - 1]} ${dt.day}, ${dt.year}';

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customers = ref.watch(customersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      body: customers.when(
        data: (list) => list.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_outline,
                        size: 64, color: AppColors.textDisabled),
                    const SizedBox(height: 12),
                    Text('No customers yet', style: AppTextStyles.headline3),
                    const SizedBox(height: 4),
                    Text('Tap + to add one', style: AppTextStyles.bodySmall),
                  ],
                ),
              )
            : ListView.separated(
                itemCount: list.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1),
                itemBuilder: (ctx, i) => _CustomerTile(customer: list[i]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) =>
            Center(child: Text('Error: $e', style: AppTextStyles.bodySmall)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.person_add_outlined),
      ),
    );
  }

  void _showForm(BuildContext context, [Customer? customer]) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CustomerFormScreen(customer: customer),
      fullscreenDialog: true,
    ));
  }
}

class _CustomerTile extends ConsumerWidget {
  const _CustomerTile({required this.customer});
  final Customer customer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: customer.hasDebt
            ? AppColors.warning.withValues(alpha: 0.15)
            : AppColors.primaryLight,
        child: Text(
          customer.name[0].toUpperCase(),
          style: TextStyle(
            color: customer.hasDebt ? AppColors.warning : AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: Text(customer.name, style: AppTextStyles.body),
      subtitle: customer.phone != null
          ? Text(customer.phone!, style: AppTextStyles.bodySmall)
          : null,
      trailing: customer.hasDebt
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'ETB ${customer.creditBalance.toStringAsFixed(2)}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.warning, fontWeight: FontWeight.w600),
                ),
                Text('owes', style: AppTextStyles.label),
              ],
            )
          : const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => CustomerDetailScreen(customer: customer),
      )),
    );
  }
}

// ─── Customer Detail ──────────────────────────────────────────────────────────

class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({super.key, required this.customer});
  final Customer customer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sales = ref.watch(customerSalesProvider(customer.id));
    final creditSales = ref.watch(customerCreditSalesProvider(customer.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => CustomerFormScreen(customer: customer),
              fullscreenDialog: true,
            )),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Credit balance summary ─────────────────────────────────────
          if (customer.hasDebt)
            Card(
              color: AppColors.warning.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined,
                        color: AppColors.warning, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Outstanding', style: AppTextStyles.label),
                          Text(
                            'ETB ${customer.creditBalance.toStringAsFixed(2)}',
                            style: AppTextStyles.amount
                                .copyWith(color: AppColors.warning),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) =>
                            _ReceivePaymentDialog(customer: customer),
                      ),
                      child: const Text('Receive\nPayment',
                          textAlign: TextAlign.center),
                    ),
                  ],
                ),
              ),
            ),

          if (customer.phone != null) ...[
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: Text(customer.phone!, style: AppTextStyles.body),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
          ],

          // ── Unsettled credit sales ─────────────────────────────────────
          const SizedBox(height: 16),
          Text('Outstanding Credit Sales', style: AppTextStyles.headline3),
          const SizedBox(height: 4),
          Text(
            'Settle individual sales when the customer pays for them.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 8),
          creditSales.when(
            data: (list) => list.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            color: AppColors.success, size: 18),
                        const SizedBox(width: 6),
                        Text('No unsettled credit sales',
                            style: AppTextStyles.bodySmall),
                      ],
                    ),
                  )
                : Column(
                    children: list.map((s) => _CreditSaleTile(
                      creditSale: s,
                      customerId: customer.id,
                    )).toList(),
                  ),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => const SizedBox.shrink(),
          ),

          // ── All sales history ──────────────────────────────────────────
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Text('All Sales', style: AppTextStyles.headline3),
          const SizedBox(height: 8),
          sales.when(
            data: (list) => list.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text('No sales recorded',
                        style: AppTextStyles.bodySmall),
                  )
                : Column(
                    children: list.map((s) {
                      final isVoided = s['status'] == 'voided';
                      final isCredit = s['is_credit'] == true;
                      final isSettled = s['credit_settled_at'] != null;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          isVoided
                              ? Icons.cancel_outlined
                              : isCredit
                                  ? Icons.credit_card_outlined
                                  : Icons.receipt_outlined,
                          color: isVoided
                              ? AppColors.error
                              : isCredit && !isSettled
                                  ? AppColors.warning
                                  : AppColors.primary,
                        ),
                        title: Text(
                          'ETB ${Decimal.parse(s['total'].toString()).toStringAsFixed(2)}',
                          style: AppTextStyles.body,
                        ),
                        subtitle: Row(
                          children: [
                            Text(
                              _fmtDate(DateTime.parse(
                                  s['created_at'] as String)),
                              style: AppTextStyles.bodySmall,
                            ),
                            if (isCredit && isSettled) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.success
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('Settled',
                                    style: AppTextStyles.label.copyWith(
                                        color: AppColors.success)),
                              ),
                            ] else if (isCredit && !isSettled) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.warning
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('Credit',
                                    style: AppTextStyles.label.copyWith(
                                        color: AppColors.warning)),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
            loading: () => const LinearProgressIndicator(),
            error: (e, st) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// Per-sale settle tile
class _CreditSaleTile extends ConsumerWidget {
  const _CreditSaleTile({required this.creditSale, required this.customerId});
  final CreditSale creditSale;
  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(customerFormProvider).isLoading;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.credit_card_outlined,
            color: AppColors.warning),
        title: Text(
          'ETB ${creditSale.total.toStringAsFixed(2)}',
          style: AppTextStyles.body
              .copyWith(fontWeight: FontWeight.w600, color: AppColors.warning),
        ),
        subtitle:
            Text(_fmtDate(creditSale.createdAt), style: AppTextStyles.bodySmall),
        trailing: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
            : FilledButton(
                onPressed: () => _settle(context, ref),
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 0),
                    minimumSize: const Size(0, 32)),
                child: const Text('Settle'),
              ),
      ),
    );
  }

  Future<void> _settle(BuildContext context, WidgetRef ref) async {
    final ok = await ref.read(customerFormProvider.notifier).settleCreditSale(
          customerId: customerId,
          saleId: creditSale.id,
          saleTotal: creditSale.total,
        );
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to settle. Try again.'),
        backgroundColor: AppColors.error,
      ));
    }
  }
}

// ─── Customer Form ────────────────────────────────────────────────────────────

class CustomerFormScreen extends ConsumerStatefulWidget {
  const CustomerFormScreen({super.key, this.customer});
  final Customer? customer;

  @override
  ConsumerState<CustomerFormScreen> createState() =>
      _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl =
      TextEditingController(text: widget.customer?.name ?? '');
  late final _phoneCtrl =
      TextEditingController(text: widget.customer?.phone ?? '');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(customerFormProvider.notifier).save(
          customerId: widget.customer?.id,
          name: _nameCtrl.text,
          phone: _phoneCtrl.text,
        );
    if (mounted && ok) Navigator.pop(context);
    if (mounted && !ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(customerFormProvider).error?.toString() ??
              'Failed to save'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(customerFormProvider).isLoading;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer == null ? 'New Customer' : 'Edit Customer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                controller: _nameCtrl,
                label: 'Full Name',
                autofocus: true,
                prefixIcon: const Icon(Icons.person_outlined),
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _phoneCtrl,
                label: 'Phone (optional)',
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone_outlined),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 32),
              AppButton(
                label: widget.customer == null ? 'Add Customer' : 'Save',
                loading: loading,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Receive Payment Dialog ───────────────────────────────────────────────────

class _ReceivePaymentDialog extends ConsumerStatefulWidget {
  const _ReceivePaymentDialog({required this.customer});
  final Customer customer;

  @override
  ConsumerState<_ReceivePaymentDialog> createState() =>
      _ReceivePaymentDialogState();
}

class _ReceivePaymentDialogState extends ConsumerState<_ReceivePaymentDialog> {
  late final _amountCtrl = TextEditingController(
      text: widget.customer.creditBalance.toStringAsFixed(2));

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final amount = Decimal.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= Decimal.zero) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }
    final ok = await ref
        .read(customerFormProvider.notifier)
        .receivePayment(widget.customer.id, amount);
    if (mounted && ok) Navigator.pop(context);
    if (mounted && !ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to record payment'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(customerFormProvider).isLoading;
    return AlertDialog(
      title: const Text('Receive Payment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Outstanding: ETB ${widget.customer.creditBalance.toStringAsFixed(2)}',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Pre-filled with full balance. Change to record a partial payment.',
            style: AppTextStyles.label,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
            ],
            decoration: const InputDecoration(
              labelText: 'Amount paid (ETB)',
              isDense: true,
            ),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: loading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : FilledButton(
                onPressed: _apply,
                child: const Text('Apply'),
              ),
      ],
    );
  }
}
