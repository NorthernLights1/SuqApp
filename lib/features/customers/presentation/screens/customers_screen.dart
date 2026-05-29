import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/customers_provider.dart';

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
          // Credit card
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
                          Text('Outstanding Credit',
                              style: AppTextStyles.label),
                          Text(
                            'ETB ${customer.creditBalance.toStringAsFixed(2)}',
                            style: AppTextStyles.amount
                                .copyWith(color: AppColors.warning),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _settleDebt(context, ref),
                      child: const Text('Mark Settled'),
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

          const SizedBox(height: 8),
          Text('Recent Sales', style: AppTextStyles.headline3),
          const SizedBox(height: 8),

          sales.when(
            data: (list) => list.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text('No sales recorded',
                        style: AppTextStyles.bodySmall),
                  )
                : Column(
                    children: list
                        .map((s) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                s['status'] == 'voided'
                                    ? Icons.cancel_outlined
                                    : s['is_credit'] == true
                                        ? Icons.credit_card_outlined
                                        : Icons.receipt_outlined,
                                color: s['status'] == 'voided'
                                    ? AppColors.error
                                    : AppColors.primary,
                              ),
                              title: Text(
                                'ETB ${Decimal.parse(s['total'].toString()).toStringAsFixed(2)}',
                                style: AppTextStyles.body,
                              ),
                              subtitle: Text(
                                _formatDate(
                                    DateTime.parse(s['created_at'] as String)),
                                style: AppTextStyles.bodySmall,
                              ),
                            ))
                        .toList(),
                  ),
            loading: () => const LinearProgressIndicator(),
            error: (e, st) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  void _settleDebt(BuildContext context, WidgetRef ref) async {
    final ok = await ref
        .read(customerFormProvider.notifier)
        .settleDebt(customer.id);
    if (context.mounted && ok) Navigator.pop(context);
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
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
