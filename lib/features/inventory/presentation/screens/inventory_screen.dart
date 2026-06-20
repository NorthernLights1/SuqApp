import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../domain/models/product.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/utils/date_formatter.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/auth/presentation/providers/permissions_provider.dart';
import '../../../../features/auth/presentation/providers/shop_provider.dart';
import '../../data/inventory_remote.dart';
import '../providers/inventory_provider.dart';
import '../../../../shared/widgets/decimal_input_formatter.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final stock = ref.watch(stockLevelsProvider);
    final lowCount = ref.watch(lowStockCountProvider);
    final categories = ref.watch(productCategoriesProvider);
    final categoryFilter = ref.watch(inventoryCategoryFilterProvider);

    final stockMap = stock.asData?.value != null
        ? {for (final e in stock.asData!.value) e.productId: e}
        : <String, StockEntry>{};

    final allProducts = products.asData?.value ?? [];
    final visibleProducts = categoryFilter == null
        ? allProducts
        : allProducts.where((p) => p.categoryId == categoryFilter).toList();

    final isLoading = products.isLoading || stock.isLoading;
    final hasError = products.hasError || stock.hasError;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Inventory'),
            lowCount.when(
              data: (n) => n > 0
                  ? Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$n low',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    )
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (e, st) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Category filter chips ──────────────────────────────────────
          categories.when(
            data: (cats) {
              if (cats.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('All'),
                        selected: categoryFilter == null,
                        onSelected: (_) => ref
                            .read(inventoryCategoryFilterProvider.notifier)
                            .set(null),
                        selectedColor: AppColors.primaryLight,
                        checkmarkColor: AppColors.primary,
                      ),
                    ),
                    ...cats.map((c) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(c.name),
                            selected: categoryFilter == c.id,
                            onSelected: (_) => ref
                                .read(inventoryCategoryFilterProvider.notifier)
                                .set(categoryFilter == c.id ? null : c.id),
                            selectedColor: AppColors.primaryLight,
                            checkmarkColor: AppColors.primary,
                          ),
                        )),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          // ── Product list ───────────────────────────────────────────────
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : hasError
                    ? Center(
                        child: Text('Failed to load inventory',
                            style: AppTextStyles.bodySmall),
                      )
                    : visibleProducts.isEmpty
                        ? _EmptyInventory()
                        : ListView.separated(
                            itemCount: visibleProducts.length,
                            separatorBuilder: (ctx, i) =>
                                const Divider(height: 1),
                            itemBuilder: (ctx, i) {
                              final product = visibleProducts[i];
                              return _ProductStockTile(
                                product: product,
                                stockEntry: stockMap[product.id],
                              );
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: hasPermissionSync(ref, 'inventory.edit')
          ? FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ProductFormScreen(),
              fullscreenDialog: true,
            ),
          );
          // Refresh on return so a newly added product/stock shows without an
          // app restart (guaranteed even if the form's own invalidation is
          // missed across the route boundary).
          ref.invalidate(productsProvider);
          ref.invalidate(stockLevelsProvider);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}

// ─── Product + Stock tile ─────────────────────────────────────────────────────

class _ProductStockTile extends ConsumerWidget {
  const _ProductStockTile({required this.product, this.stockEntry});
  final Product product;
  final StockEntry? stockEntry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasStock = stockEntry != null;
    final isLow = stockEntry?.isLowStock ?? false;
    final isExpired = stockEntry?.isExpired ?? false;
    final isExpiringSoon = stockEntry?.isExpiringSoon ?? false;

    Color statusColor;
    if (!hasStock) {
      statusColor = AppColors.error;
    } else if (isExpired) {
      statusColor = AppColors.error;
    } else if (isLow || isExpiringSoon) {
      statusColor = AppColors.warning;
    } else {
      statusColor = AppColors.primary;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: statusColor.withValues(alpha: 0.12),
        child: Text(
          product.name[0].toUpperCase(),
          style: TextStyle(color: statusColor, fontWeight: FontWeight.w700),
        ),
      ),
      title: Text(product.name, style: AppTextStyles.body),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(product.measurementUnitAbbr, style: AppTextStyles.label),
              if (product.sellingPrice != null) ...[
                const SizedBox(width: 8),
                Text(
                  formatCurrency(product.sellingPrice!),
                  style: AppTextStyles.label,
                ),
              ],
            ],
          ),
          if (!hasStock)
            Text(
              'Not in inventory',
              style: AppTextStyles.label.copyWith(color: AppColors.error),
            )
          else ...[
            Text(
              'Stock: ${stockEntry!.quantity.toStringAsFixed(2)} ${stockEntry!.unitAbbr}',
              style: AppTextStyles.label.copyWith(color: statusColor),
            ),
            if (isExpired)
              const Text('EXPIRED',
                  style: TextStyle(
                      color: AppColors.error,
                      fontSize: 10,
                      fontWeight: FontWeight.w700))
            else if (isExpiringSoon)
              Text(
                'Expires ${formatDate(stockEntry!.expiryDate!)}',
                style: const TextStyle(color: AppColors.warning, fontSize: 10),
              ),
          ],
        ],
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: () => _showStockSheet(context, ref, product, stockEntry),
    );
  }
}

// ─── Stock action sheet ───────────────────────────────────────────────────────

void _showStockSheet(
    BuildContext context, WidgetRef ref, Product product, StockEntry? entry) {
  final canAdjust = hasPermissionSync(ref, 'inventory.adjust');
  final canCorrect = hasPermissionSync(ref, 'settings.manage');
  final canEdit = hasPermissionSync(ref, 'inventory.edit');
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetCtx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.name, style: AppTextStyles.headline3),
            const SizedBox(height: 4),
            Text(
              entry != null
                  ? 'Current stock: ${entry.quantity.toStringAsFixed(2)} ${entry.unitAbbr}'
                  : 'Not in inventory',
              style: AppTextStyles.bodySmall.copyWith(
                color: entry == null ? AppColors.error : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            if (canAdjust)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Stock'),
                  onPressed: () {
                    Navigator.pop(sheetCtx);
                    showDialog(
                      context: context,
                      builder: (_) =>
                          _AddStockDialog(product: product, currentEntry: entry),
                    );
                  },
                ),
              ),
            if (entry != null && canCorrect) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Correct Stock'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary),
                  onPressed: () {
                    Navigator.pop(sheetCtx);
                    showDialog(
                      context: context,
                      builder: (_) =>
                          _CorrectStockDialog(product: product, entry: entry),
                    );
                  },
                ),
              ),
            ],
            if (canEdit) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(sheetCtx);
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ProductFormScreen(product: product),
                      fullscreenDialog: true,
                    ));
                  },
                  child: const Text('Edit Product Details'),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

// ─── Add Stock dialog (additive) ──────────────────────────────────────────────

class _AddStockDialog extends ConsumerStatefulWidget {
  const _AddStockDialog({required this.product, this.currentEntry});
  final Product product;
  final StockEntry? currentEntry;

  @override
  ConsumerState<_AddStockDialog> createState() => _AddStockDialogState();
}

class _AddStockDialogState extends ConsumerState<_AddStockDialog> {
  final _qtyCtrl = TextEditingController();
  final _sellPriceCtrl = TextEditingController();
  final _costPriceCtrl = TextEditingController();
  final _thresholdCtrl = TextEditingController();
  DateTime? _expiryDate;
  bool _loading = false;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _sellPriceCtrl.dispose();
    _costPriceCtrl.dispose();
    _thresholdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final p = widget.product;
    final qty = Decimal.tryParse(_qtyCtrl.text.trim());
    if (qty == null || qty <= Decimal.zero) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a quantity greater than zero')),
      );
      return;
    }

    // Optional fields — empty means "keep the current value".
    final newSell = _sellPriceCtrl.text.trim().isEmpty
        ? null
        : Decimal.tryParse(_sellPriceCtrl.text.trim());
    final newCost = _costPriceCtrl.text.trim().isEmpty
        ? null
        : Decimal.tryParse(_costPriceCtrl.text.trim());
    final newThreshold = _thresholdCtrl.text.trim().isEmpty
        ? null
        : Decimal.tryParse(_thresholdCtrl.text.trim());

    setState(() => _loading = true);

    // 1) If any price/threshold actually changed, update the product first.
    final detailsChanged = (newSell != null && newSell != p.sellingPrice) ||
        (newCost != null && newCost != p.costPrice) ||
        (newThreshold != null && newThreshold != p.lowStockThreshold);
    if (detailsChanged) {
      final updated = await ref.read(productFormProvider.notifier).save(
            productId: p.id,
            name: p.name,
            measurementUnitId: p.measurementUnitId,
            lowStockThreshold: newThreshold ?? p.lowStockThreshold,
            sellingPrice: newSell ?? p.sellingPrice,
            costPrice: newCost ?? p.costPrice,
            categoryId: p.categoryId,
            description: p.description,
          );
      if (!updated) {
        if (!mounted) return;
        // Price/threshold update failed (likely offline). Still proceed to
        // queue the stock adjustment — it is offline-safe and independent.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product details could not be saved — will retry when online'),
          ),
        );
      }
    }

    // 2) Add the received quantity.
    final ok = await ref.read(stockAdjustmentProvider.notifier).addStock(
          productId: p.id,
          quantityToAdd: qty,
          expiryDate: _expiryDate,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stock added'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add stock'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _priceHint(Decimal? v) => v != null ? v.toStringAsFixed(2) : 'Not set';

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final unitAbbr = widget.currentEntry?.unitAbbr ?? p.measurementUnitAbbr;
    return AlertDialog(
      title: Text('Add Stock: ${p.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.currentEntry != null)
              Text(
                'Current: ${widget.currentEntry!.quantity.toStringAsFixed(2)} $unitAbbr',
                style: AppTextStyles.bodySmall,
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _qtyCtrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [decimalInputFormatter],
              decoration: InputDecoration(
                labelText: 'Quantity received ($unitAbbr)',
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            // Optional: update sale price for this product (blank = keep current)
            TextField(
              controller: _sellPriceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [decimalInputFormatter],
              decoration: InputDecoration(
                labelText: 'Sale price (optional)',
                hintText: _priceHint(p.sellingPrice),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            // Optional: update purchase (cost) price
            TextField(
              controller: _costPriceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [decimalInputFormatter],
              decoration: InputDecoration(
                labelText: 'Purchase price (optional)',
                hintText: _priceHint(p.costPrice),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            // Optional: update low-stock threshold
            TextField(
              controller: _thresholdCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [decimalInputFormatter],
              decoration: InputDecoration(
                labelText: 'Low stock threshold (optional)',
                hintText: _priceHint(p.lowStockThreshold),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate:
                      _expiryDate ?? DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (picked != null && mounted) {
                  setState(() => _expiryDate = picked);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Expiry Date (optional)',
                  isDense: true,
                  suffixIcon: Icon(Icons.calendar_today_outlined, size: 16),
                ),
                child: Text(
                  _expiryDate != null ? formatDate(_expiryDate!) : 'Not set',
                  style: AppTextStyles.body.copyWith(
                    color:
                        _expiryDate == null ? AppColors.textDisabled : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Add'),
        ),
      ],
    );
  }
}

// ─── Correct Stock dialog (absolute, owner password required) ─────────────────

class _CorrectStockDialog extends ConsumerStatefulWidget {
  const _CorrectStockDialog({required this.product, required this.entry});
  final Product product;
  final StockEntry entry;

  @override
  ConsumerState<_CorrectStockDialog> createState() =>
      _CorrectStockDialogState();
}

class _CorrectStockDialogState extends ConsumerState<_CorrectStockDialog> {
  final _qtyCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _reasonCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final qty = Decimal.tryParse(_qtyCtrl.text.trim());
    if (qty == null || qty < Decimal.zero) {
      setState(() => _error = 'Enter a valid quantity');
      return;
    }
    if (_reasonCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Reason is required');
      return;
    }
    if (_pwCtrl.text.isEmpty) {
      setState(() => _error = 'Password is required');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    // Verify owner password before applying correction.
    // signInWithPassword re-authenticates against Supabase Auth.
    // Supabase may rate-limit attempts — we show the real error so the owner
    // knows whether to wait or recheck their credentials.
    try {
      final client = ref.read(supabaseClientProvider);
      final email = client.auth.currentUser?.email ?? '';
      await client.auth.signInWithPassword(
          email: email, password: _pwCtrl.text.trim());
    } on AuthException catch (e) {
      if (!mounted) return;
      final msg = e.message.toLowerCase();
      final isRateLimit = e.statusCode == '429' ||
          msg.contains('rate') ||
          msg.contains('after');
      setState(() {
        _loading = false;
        _error = isRateLimit
            ? 'Too many attempts — wait a minute then try again'
            : 'Incorrect password';
      });
      return;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Verification failed: ${e.toString().replaceFirst('Exception: ', '')}';
      });
      return;
    }

    final ok = await ref.read(stockAdjustmentProvider.notifier).correctStock(
          productId: widget.product.id,
          newQuantity: qty,
          currentQuantity: widget.entry.quantity,
          notes: _reasonCtrl.text.trim(),
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stock corrected'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      setState(() => _error = 'Correction failed. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final unitAbbr = widget.entry.unitAbbr;
    return AlertDialog(
      title: Text('Correct Stock: ${widget.product.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current: ${widget.entry.quantity.toStringAsFixed(2)} $unitAbbr',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _qtyCtrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [decimalInputFormatter],
              decoration: InputDecoration(
                labelText: 'Correct quantity ($unitAbbr)',
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Reason for correction',
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pwCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Your password (to confirm)',
                isDense: true,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Correct'),
        ),
      ],
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyInventory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inventory_2_outlined,
              size: 64, color: AppColors.textDisabled),
          const SizedBox(height: 12),
          Text('No products yet', style: AppTextStyles.headline3),
          const SizedBox(height: 4),
          Text('Tap + to add your first product',
              style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

// ─── Product Form Screen ──────────────────────────────────────────────────────

class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.product});
  final Product? product;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(text: widget.product?.name ?? '');
  late final _descriptionCtrl =
      TextEditingController(text: widget.product?.description ?? '');
  late final _priceCtrl = TextEditingController(
      text: widget.product?.sellingPrice?.toString() ?? '');
  late final _costPriceCtrl = TextEditingController(
      text: widget.product?.costPrice?.toString() ?? '');
  late final _thresholdCtrl = TextEditingController(
      text: widget.product?.lowStockThreshold.toString() ?? '0');
  late final _openingQtyCtrl = TextEditingController();
  MeasurementUnit? _selectedUnit;
  String? _selectedCategoryId;
  DateTime? _expiryDate;
  bool _unitsLoaded = false;

  bool get _isEdit => widget.product != null;
  bool get _hasOpeningQty {
    final v = Decimal.tryParse(_openingQtyCtrl.text.trim());
    return v != null && v > Decimal.zero;
  }

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.product?.categoryId;
    _openingQtyCtrl.addListener(_rebuildForQty);
  }

  void _rebuildForQty() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _priceCtrl.dispose();
    _costPriceCtrl.dispose();
    _thresholdCtrl.dispose();
    _openingQtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a unit of measurement')),
      );
      return;
    }

    final rawQty = _openingQtyCtrl.text.trim();
    Decimal? initialQty;
    if (!_isEdit) {
      initialQty = Decimal.tryParse(rawQty);
      if (initialQty == null || initialQty <= Decimal.zero) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enter a quantity greater than 0'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    if (!_isEdit && _expiryDate != null) {
      final today = DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day);
      if (!_expiryDate!.isAfter(today)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expiry date must be at least tomorrow'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    final ok = await ref.read(productFormProvider.notifier).save(
          productId: widget.product?.id,
          name: _nameCtrl.text,
          measurementUnitId: _selectedUnit!.id,
          lowStockThreshold:
              Decimal.tryParse(_thresholdCtrl.text) ?? Decimal.zero,
          sellingPrice: _priceCtrl.text.trim().isEmpty
              ? null
              : Decimal.tryParse(_priceCtrl.text),
          costPrice: _costPriceCtrl.text.trim().isEmpty
              ? null
              : Decimal.tryParse(_costPriceCtrl.text),
          categoryId: _selectedCategoryId,
          description: _descriptionCtrl.text.trim().isEmpty
              ? null
              : _descriptionCtrl.text.trim(),
          initialQuantity: initialQty,
          expiryDate: !_isEdit ? _expiryDate : null,
        );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Product updated' : 'Product added'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      final err = ref.read(productFormProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err?.toString() ?? 'Failed to save product'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _deactivate() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove product?'),
        content: const Text(
            'The product will be hidden. Historical records are kept.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Remove', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final ok =
        await ref.read(productFormProvider.notifier).deactivate(widget.product!.id);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to remove product'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _createCategory() async {
    final shop = await ref.read(currentShopProvider.future);
    if (shop == null || !mounted) return;

    final nameCtrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
          decoration: const InputDecoration(
            labelText: 'Category name',
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, nameCtrl.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    nameCtrl.dispose();

    if (name == null || name.isEmpty || !mounted) return;
    try {
      final cat = await ref
          .read(inventoryRepositoryProvider)
          .createProductCategory(shopId: shop.id, name: name);
      ref.invalidate(productCategoriesProvider);
      if (mounted) setState(() => _selectedCategoryId = cat.id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create category'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _createUnit() async {
    final shop = await ref.read(currentShopProvider.future);
    if (shop == null || !mounted) return;

    final nameCtrl = TextEditingController();
    final abbrCtrl = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Unit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Name (e.g. Carton)',
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: abbrCtrl,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => Navigator.pop(ctx, true),
              decoration: const InputDecoration(
                labelText: 'Abbreviation (e.g. ctn)',
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    final name = nameCtrl.text.trim();
    final abbr = abbrCtrl.text.trim();
    nameCtrl.dispose();
    abbrCtrl.dispose();

    if (created != true || name.isEmpty || abbr.isEmpty || !mounted) return;
    try {
      final unit = await ref.read(inventoryRepositoryProvider).createMeasurementUnit(
            shopId: shop.id,
            name: name,
            abbreviation: abbr,
          );
      ref.invalidate(measurementUnitsProvider);
      if (mounted) setState(() => _selectedUnit = unit);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create unit — you may be offline'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final units = ref.watch(measurementUnitsProvider);
    final categories = ref.watch(productCategoriesProvider);
    final loading = ref.watch(productFormProvider).isLoading;

    units.whenData((list) {
      if (!_unitsLoaded && widget.product != null) {
        _unitsLoaded = true;
        final match =
            list.where((u) => u.id == widget.product!.measurementUnitId);
        if (match.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedUnit = match.first);
          });
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Product' : 'New Product'),
        actions: [
          if (_isEdit)
            TextButton(
              onPressed: _deactivate,
              child: const Text('Remove',
                  style: TextStyle(color: AppColors.error)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                controller: _nameCtrl,
                label: 'Product Name',
                autofocus: !_isEdit,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _descriptionCtrl,
                label: 'Description (optional)',
                textInputAction: TextInputAction.next,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              units.when(
                data: (list) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Unit of Measurement *',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<MeasurementUnit>(
                          value: _selectedUnit,
                          hint: const Text('Select unit'),
                          isExpanded: true,
                          items: list
                              .map((u) => DropdownMenuItem(
                                    value: u,
                                    child:
                                        Text('${u.name} (${u.abbreviation})'),
                                  ))
                              .toList(),
                          onChanged: (u) => setState(() => _selectedUnit = u),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _createUnit,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('New unit'),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      ),
                    ),
                  ],
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, st) => Text(
                  'Could not load units — try again',
                  style: AppTextStyles.label.copyWith(color: AppColors.error),
                ),
              ),
              const SizedBox(height: 16),
              categories.when(
                data: (list) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Category (optional)',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: list.any((c) => c.id == _selectedCategoryId)
                              ? _selectedCategoryId
                              : null,
                          hint: const Text('No category'),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('No category'),
                            ),
                            ...list.map(
                              (c) => DropdownMenuItem<String?>(
                                value: c.id,
                                child: Text(c.name),
                              ),
                            ),
                          ],
                          onChanged: (id) =>
                              setState(() => _selectedCategoryId = id),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _createCategory,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('New category'),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      ),
                    ),
                  ],
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, st) => Text(
                  'Could not load categories',
                  style: AppTextStyles.label.copyWith(color: AppColors.error),
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _priceCtrl,
                label: 'Selling Price — optional',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [decimalInputFormatter],
                textInputAction: TextInputAction.next,
                prefixText: '${AppConstants.defaultCurrency} ',
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _costPriceCtrl,
                label: 'Cost / Purchase Price — optional',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [decimalInputFormatter],
                textInputAction: TextInputAction.next,
                prefixText: '${AppConstants.defaultCurrency} ',
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _thresholdCtrl,
                label: 'Low Stock Alert Threshold',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [decimalInputFormatter],
                textInputAction: TextInputAction.done,
                prefixIcon: const Icon(Icons.warning_amber_outlined),
              ),
              if (!_isEdit) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Opening Stock',
                        style: AppTextStyles.label
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _openingQtyCtrl,
                  label: 'Quantity',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [decimalInputFormatter],
                  textInputAction: TextInputAction.done,
                  prefixIcon: const Icon(Icons.inventory_outlined),
                ),
                if (_hasOpeningQty) ...[
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      final tomorrow = DateTime(DateTime.now().year,
                          DateTime.now().month, DateTime.now().day + 1);
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _expiryDate ??
                            DateTime.now().add(const Duration(days: 30)),
                        firstDate: tomorrow,
                        lastDate:
                            DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (picked != null && mounted) {
                        setState(() => _expiryDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Expiry Date (optional)',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        suffixIcon: _expiryDate != null
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () =>
                                        setState(() => _expiryDate = null),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  const Icon(Icons.calendar_today_outlined,
                                      size: 18),
                                ],
                              )
                            : const Icon(Icons.calendar_today_outlined,
                                size: 18),
                      ),
                      child: Text(
                        _expiryDate != null
                            ? formatDate(_expiryDate!)
                            : 'Not set',
                        style: AppTextStyles.body.copyWith(
                          color: _expiryDate == null
                              ? AppColors.textDisabled
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 32),
              AppButton(
                label: _isEdit ? 'Save Changes' : 'Add Product',
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
