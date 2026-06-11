import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/customers_provider.dart';
import 'credits_screen.dart' show showCreditSettleSheet;

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
    // Amount owed = sum of what's left on this customer's unsettled bills.
    final owed = ref.watch(customerOutstandingMapProvider).asData?.value[
            customer.id] ??
        Decimal.zero;
    final hasDebt = owed > Decimal.zero;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: hasDebt
            ? AppColors.warning.withValues(alpha: 0.15)
            : AppColors.primaryLight,
        child: Text(
          customer.name[0].toUpperCase(),
          style: TextStyle(
            color: hasDebt ? AppColors.warning : AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: Text(customer.name, style: AppTextStyles.body),
      subtitle: customer.phone != null
          ? Text(customer.phone!, style: AppTextStyles.bodySmall)
          : null,
      trailing: hasDebt
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'ETB ${owed.toStringAsFixed(2)}',
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
    // Re-watch so balance refreshes after settle/payment without requiring back-navigate
    final customerList = ref.watch(customersProvider).asData?.value;
    final freshCustomer = customerList == null
        ? customer
        : customerList.firstWhere(
            (c) => c.id == customer.id,
            orElse: () => customer,
          );
    // Total owed = sum of what's left on this customer's unsettled bills.
    final outstanding = creditSales.asData?.value
            .fold<Decimal>(Decimal.zero, (s, e) => s + e.remaining) ??
        Decimal.zero;

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
          // ── Outstanding summary ────────────────────────────────────────
          if (outstanding > Decimal.zero)
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
                            'ETB ${outstanding.toStringAsFixed(2)}',
                            style: AppTextStyles.amount
                                .copyWith(color: AppColors.warning),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (customer.phone != null) ...[
            const SizedBox(height: 8),
            Material(
              type: MaterialType.transparency,
              child: ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: Text(customer.phone!, style: AppTextStyles.body),
                contentPadding: EdgeInsets.zero,
              ),
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
                      customerName: freshCustomer.name,
                    )).toList(),
                  ),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Could not load credit sales: $e',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.error)),
            ),
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
                : Material(
                    type: MaterialType.transparency,
                    child: Column(
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
                              Flexible(
                                child: Text(
                                  _fmtDate(DateTime.parse(
                                      s['created_at'] as String)),
                                  style: AppTextStyles.bodySmall,
                                ),
                              ),
                              if (isCredit && isSettled) ...[
                                const SizedBox(width: 6),
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
                                const SizedBox(width: 6),
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
  const _CreditSaleTile({
    required this.creditSale,
    required this.customerId,
    required this.customerName,
  });
  final CreditSale creditSale;
  final String customerId;
  final String customerName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(customerFormProvider).isLoading;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.credit_card_outlined,
            color: AppColors.warning),
        title: Text(
          'ETB ${creditSale.remaining.toStringAsFixed(2)}',
          style: AppTextStyles.body
              .copyWith(fontWeight: FontWeight.w600, color: AppColors.warning),
        ),
        subtitle: Text(
          creditSale.paid > Decimal.zero
              ? '${_fmtDate(creditSale.createdAt)} · paid ETB ${creditSale.paid.toStringAsFixed(2)} of ${creditSale.total.toStringAsFixed(2)}'
              : _fmtDate(creditSale.createdAt),
          style: AppTextStyles.bodySmall,
        ),
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
    await showCreditSettleSheet(
      context,
      saleId: creditSale.id,
      saleTotal: creditSale.total,
      salePaid: creditSale.paid,
      saleDate: creditSale.createdAt,
      customerId: customerId,
      customerName: customerName,
    );
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

