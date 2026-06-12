import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../domain/models/sale.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../providers/sales_provider.dart';

class NewSaleScreen extends ConsumerStatefulWidget {
  const NewSaleScreen({super.key});

  @override
  ConsumerState<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends ConsumerState<NewSaleScreen> {
  final _searchCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final createState = ref.watch(createSaleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Sale'),
        actions: [
          if (cart.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClear(context),
              child: const Text('Clear', style: TextStyle(color: AppColors.error)),
            ),
        ],
      ),
      body: Column(
        children: [
          _ProductSearch(searchCtrl: _searchCtrl),
          const Divider(height: 1),
          Expanded(
            child: cart.isEmpty
                ? _EmptyCart()
                : _CartList(cart: cart),
          ),
          if (cart.isNotEmpty)
            _SaleFooter(
              subtotal: subtotal,
              notesCtrl: _notesCtrl,
              loading: createState.isLoading,
              onSubmit: _submit,
            ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear cart?'),
        content: const Text('All items will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clear();
              Navigator.pop(ctx);
            },
            child: const Text('Clear', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final cart = ref.read(cartProvider);
    final paymentMethod = ref.read(selectedPaymentMethodProvider);
    final isCredit = paymentMethod?.code == 'credit';
    final customer = ref.read(selectedCustomerProvider);

    if (cart.isEmpty) {
      _showSnack('Add at least one item');
      return;
    }
    if (paymentMethod == null) {
      _showSnack('Select a payment method');
      return;
    }
    if (isCredit && customer == null) {
      _showSnack('Select or add a customer for credit sales');
      return;
    }

    final sale = await ref.read(createSaleProvider.notifier).submit(
          paymentMethodId: paymentMethod.id,
          items: cart,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          customerId: customer?.id,
          isCredit: isCredit,
        );

    if (!mounted) return;

    final error = ref.read(createSaleProvider).error;
    if (error != null) {
      _showSnack(error.toString(), isError: true);
      return;
    }

    if (sale != null) {
      _notesCtrl.clear();
      _showSaleSuccess(context, sale);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
    ));
  }

  void _showSaleSuccess(BuildContext context, Sale sale) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: AppColors.success, size: 48),
        title: const Text('Sale Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Total: ETB ${sale.total}', style: AppTextStyles.amount),
            const SizedBox(height: 4),
            Text('${sale.items.length} item(s)', style: AppTextStyles.bodySmall),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            child: const Text('Done'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('New Sale'),
          ),
        ],
      ),
    );
  }
}

// ─── Product Search ───────────────────────────────────────────────────────────

class _ProductSearch extends ConsumerStatefulWidget {
  const _ProductSearch({required this.searchCtrl});
  final TextEditingController searchCtrl;

  @override
  ConsumerState<_ProductSearch> createState() => _ProductSearchState();
}

class _ProductSearchState extends ConsumerState<_ProductSearch> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(productSearchQueryProvider.notifier).set(v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(productSearchProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: widget.searchCtrl,
            decoration: const InputDecoration(
              hintText: 'Search products…',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
            onChanged: _onChanged,
          ),
        ),
        results.when(
          data: (list) => list.isEmpty
              ? const SizedBox.shrink()
              : Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AppColors.divider)),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (ctx, i) => Material(
                      type: MaterialType.transparency,
                      child: ListTile(
                        dense: true,
                        title: Text(list[i].name, style: AppTextStyles.body),
                        subtitle: Text(list[i].measurementUnitAbbr,
                            style: AppTextStyles.bodySmall),
                        trailing: const Icon(Icons.add_circle_outline,
                            color: AppColors.primary),
                        onTap: () => _addToCart(ctx, ref, list[i]),
                      ),
                    ),
                  ),
                ),
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  void _addToCart(BuildContext context, WidgetRef ref, product) {
    _debounce?.cancel();
    widget.searchCtrl.clear();
    ref.read(productSearchQueryProvider.notifier).set('');
    ref.read(cartProvider.notifier).addItem(CartItem(
      productId: product.id,
      productName: product.name,
      measurementUnitId: product.measurementUnitId,
      measurementUnitAbbr: product.measurementUnitAbbr,
      quantity: Decimal.one,
      unitPrice: product.sellingPrice ?? Decimal.zero,
      discountAmount: Decimal.zero,
      costPrice: product.costPrice,
    ));
  }
}

// ─── Cart List ────────────────────────────────────────────────────────────────

class _CartList extends ConsumerWidget {
  const _CartList({required this.cart});
  final List<CartItem> cart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: cart.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (ctx, i) => _CartItemTile(
        item: cart[i],
        index: i,
        onUpdate: (updated) =>
            ref.read(cartProvider.notifier).updateItem(i, updated),
        onRemove: () => ref.read(cartProvider.notifier).removeItem(i),
      ),
    );
  }
}

class _CartItemTile extends StatefulWidget {
  const _CartItemTile({
    required this.item,
    required this.index,
    required this.onUpdate,
    required this.onRemove,
  });
  final CartItem item;
  final int index;
  final ValueChanged<CartItem> onUpdate;
  final VoidCallback onRemove;

  @override
  State<_CartItemTile> createState() => _CartItemTileState();
}

class _CartItemTileState extends State<_CartItemTile> {
  late final _priceCtrl = TextEditingController(
      text: widget.item.unitPrice > Decimal.zero
          ? widget.item.unitPrice.toString()
          : '');
  late final _qtyCtrl =
      TextEditingController(text: widget.item.quantity.toString());

  @override
  void dispose() {
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  void _commit() {
    final qty = Decimal.tryParse(_qtyCtrl.text) ?? Decimal.one;
    final price = Decimal.tryParse(_priceCtrl.text) ?? Decimal.zero;
    widget.onUpdate(widget.item.copyWith(quantity: qty, unitPrice: price));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
            onPressed: widget.onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.item.productName,
                    style: AppTextStyles.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (widget.item.measurementUnitAbbr != null)
                  Text(widget.item.measurementUnitAbbr!, style: AppTextStyles.label),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 52,
            child: TextField(
              controller: _qtyCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                  labelText: 'Qty', isDense: true, contentPadding: EdgeInsets.all(8)),
              onChanged: (_) => _commit(),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: TextField(
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              textAlign: TextAlign.end,
              decoration: const InputDecoration(
                  labelText: 'Price', isDense: true, contentPadding: EdgeInsets.all(8)),
              onChanged: (_) => _commit(),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.item.lineTotal.toStringAsFixed(2),
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty Cart ───────────────────────────────────────────────────────────────

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shopping_cart_outlined,
              size: 64, color: AppColors.textDisabled),
          const SizedBox(height: 12),
          Text('Search for products to add', style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

// ─── Sale Footer ──────────────────────────────────────────────────────────────

class _SaleFooter extends ConsumerWidget {
  const _SaleFooter({
    required this.subtotal,
    required this.notesCtrl,
    required this.loading,
    required this.onSubmit,
  });
  final Decimal subtotal;
  final TextEditingController notesCtrl;
  final bool loading;
  final VoidCallback onSubmit;

  /// The checkout panel may use at most this fraction of the screen so the
  /// cart above it stays visible. Payment/customer/notes scroll within the
  /// cap; the Total + submit row is always pinned at the bottom.
  static const _maxScreenFraction = 0.25;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentMethods = ref.watch(paymentMethodsProvider);
    final selectedMethod = ref.watch(selectedPaymentMethodProvider);
    final isCredit = selectedMethod?.code == 'credit';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * _maxScreenFraction,
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Payment method picker
                  paymentMethods.when(
                    data: (methods) => methods.isEmpty
                        ? const Text('No payment methods configured')
                        : DropdownButton<PaymentMethod>(
                            value: selectedMethod,
                            hint: const Text('Payment method'),
                            isExpanded: true,
                            underline: const Divider(height: 1),
                            items: methods
                                .map((m) => DropdownMenuItem(
                                      value: m,
                                      child: Text(m.name),
                                    ))
                                .toList(),
                            onChanged: (m) => ref
                                .read(selectedPaymentMethodProvider.notifier)
                                .set(m),
                          ),
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) =>
                        const Text('Could not load payment methods'),
                  ),
                  // Customer picker (credit only)
                  if (isCredit) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text('Customer', style: AppTextStyles.label),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const _CustomerPickerSection(),
                  ],
                  const SizedBox(height: 12),
                  // Notes
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Notes (optional)',
                      isDense: true,
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Total + submit (always visible, never scrolled away)
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total', style: AppTextStyles.label),
                  Text(
                    'ETB ${subtotal.toStringAsFixed(2)}',
                    style: AppTextStyles.amount,
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: 160,
                child: AppButton(
                  label: isCredit ? 'Record Credit' : 'Charge',
                  icon: isCredit ? Icons.credit_score : Icons.point_of_sale,
                  loading: loading,
                  fullWidth: false,
                  onPressed: onSubmit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Customer Picker ─────────────────────────────────────────────────────────

/// Compact footer row: shows the chosen customer, or a button that opens a
/// tall bottom sheet to search/add one. The footer itself is capped at 25%
/// of the screen — far too small to search in — so the picking happens in
/// the sheet and only the result lives in the footer.
class _CustomerPickerSection extends ConsumerWidget {
  const _CustomerPickerSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customer = ref.watch(selectedCustomerProvider);

    if (customer != null) {
      return Material(
        type: MaterialType.transparency,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: AppColors.primaryLight,
            child: Text(
              customer.name[0].toUpperCase(),
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
          title: Text(customer.name, style: AppTextStyles.body),
          subtitle: customer.phone != null
              ? Text(customer.phone!, style: AppTextStyles.bodySmall)
              : null,
          trailing: IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
            onPressed: () =>
                ref.read(selectedCustomerProvider.notifier).set(null),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.person_search_outlined, size: 18),
        label: const Text('Select customer'),
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => const _CustomerPickerSheet(),
        ).whenComplete(
          // Reset the search whether a customer was picked or the sheet
          // was dismissed.
          () => ref.read(customerSearchQueryProvider.notifier).set(''),
        ),
      ),
    );
  }
}

class _CustomerPickerSheet extends ConsumerStatefulWidget {
  const _CustomerPickerSheet();

  @override
  ConsumerState<_CustomerPickerSheet> createState() =>
      _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends ConsumerState<_CustomerPickerSheet> {
  final _searchCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _adding = false;
  Timer? _searchDebounce;

  /// Tall enough to search comfortably while keeping the sale visible behind.
  static const _maxScreenFraction = 0.75;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Keep the sheet above the keyboard while typing.
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * _maxScreenFraction,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_adding ? 'New customer' : 'Select customer',
                  style: AppTextStyles.headline3),
              const SizedBox(height: 12),
              if (_adding)
                _AddCustomerForm(
                  nameCtrl: _nameCtrl,
                  phoneCtrl: _phoneCtrl,
                  onCancel: () => setState(() {
                    _adding = false;
                    _nameCtrl.clear();
                    _phoneCtrl.clear();
                  }),
                  onSave: _saveCustomer,
                  saving: ref.watch(createCustomerProvider).isLoading,
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Search by name…',
                          prefixIcon: Icon(Icons.search, size: 18),
                          isDense: true,
                        ),
                        onChanged: (v) {
                          setState(() {});
                          _searchDebounce?.cancel();
                          _searchDebounce = Timer(
                            const Duration(milliseconds: 350),
                            () => ref
                                .read(customerSearchQueryProvider.notifier)
                                .set(v),
                          );
                        },
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _adding = true;
                        _searchCtrl.clear();
                        ref.read(customerSearchQueryProvider.notifier).set('');
                      }),
                      child: const Text('+ New'),
                    ),
                  ],
                ),
                if (_searchCtrl.text.length >= 2)
                  Flexible(
                    child: SingleChildScrollView(
                      child: _CustomerResults(onSelect: _select),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _select(Customer c) {
    ref.read(selectedCustomerProvider.notifier).set(c);
    Navigator.pop(context);
  }

  Future<void> _saveCustomer() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    final customer = await ref.read(createCustomerProvider.notifier).create(
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        );
    if (customer != null && mounted) {
      ref.read(selectedCustomerProvider.notifier).set(customer);
      Navigator.pop(context);
    }
  }
}

class _AddCustomerForm extends StatelessWidget {
  const _AddCustomerForm({
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.onCancel,
    required this.onSave,
    required this.saving,
  });
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Full name *', isDense: true),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: phoneCtrl,
          decoration: const InputDecoration(labelText: 'Phone (optional)', isDense: true),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton(onPressed: onCancel, child: const Text('Cancel')),
            const Spacer(),
            saving
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : FilledButton(onPressed: onSave, child: const Text('Add Customer')),
          ],
        ),
      ],
    );
  }
}

class _CustomerResults extends ConsumerWidget {
  const _CustomerResults({required this.onSelect});
  final ValueChanged<Customer> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(customerSearchProvider);
    return results.when(
      data: (list) {
        if (list.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('No customers found — tap + New to add',
                style: AppTextStyles.bodySmall),
          );
        }
        return Column(
          children: list
              .map((c) => Material(
                    type: MaterialType.transparency,
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(c.name[0].toUpperCase(),
                            style: const TextStyle(
                                color: AppColors.primary, fontSize: 12)),
                      ),
                      title: Text(c.name, style: AppTextStyles.body),
                      subtitle: c.phone != null
                          ? Text(c.phone!, style: AppTextStyles.bodySmall)
                          : null,
                      onTap: () => onSelect(c),
                    ),
                  ))
              .toList(),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => const SizedBox.shrink(),
    );
  }
}
