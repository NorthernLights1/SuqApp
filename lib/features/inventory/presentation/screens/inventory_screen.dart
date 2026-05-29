import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/product.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../data/inventory_remote.dart';
import '../providers/inventory_provider.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lowStockCount = ref.watch(lowStockCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            const Tab(text: 'Products'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Stock'),
                  lowStockCount.when(
                    data: (n) => n > 0
                        ? Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('$n',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 11)),
                          )
                        : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (e, st) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _ProductsTab(),
          _StockTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const ProductFormScreen(),
            fullscreenDialog: true,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ─── Products Tab ─────────────────────────────────────────────────────────────

class _ProductsTab extends ConsumerWidget {
  const _ProductsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final stock = ref.watch(stockLevelsProvider);

    // Build a quick lookup: productId → StockEntry
    final stockMap = stock.valueOrNull != null
        ? {for (final e in stock.valueOrNull!) e.productId: e}
        : <String, StockEntry>{};

    return products.when(
      data: (list) => list.isEmpty
          ? _EmptyProducts()
          : ListView.separated(
              itemCount: list.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (ctx, i) =>
                  _ProductTile(product: list[i], stockEntry: stockMap[list[i].id]),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) =>
          Center(child: Text('Error: $e', style: AppTextStyles.bodySmall)),
    );
  }
}

class _ProductTile extends ConsumerWidget {
  const _ProductTile({required this.product, this.stockEntry});
  final Product product;
  final StockEntry? stockEntry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLow = stockEntry?.isLowStock ?? false;
    final isExpired = stockEntry?.isExpired ?? false;
    final isExpiringSoon = stockEntry?.isExpiringSoon ?? false;

    Color avatarColor = AppColors.primaryLight;
    Color avatarTextColor = AppColors.primary;
    if (isExpired) { avatarColor = AppColors.error.withValues(alpha: 0.12); avatarTextColor = AppColors.error; }
    else if (isLow) { avatarColor = AppColors.warning.withValues(alpha: 0.12); avatarTextColor = AppColors.warning; }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: avatarColor,
        child: Text(
          product.name[0].toUpperCase(),
          style: TextStyle(color: avatarTextColor, fontWeight: FontWeight.w700),
        ),
      ),
      title: Text(product.name, style: AppTextStyles.body),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Unit of measurement
          Row(
            children: [
              const Icon(Icons.straighten, size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(product.measurementUnitAbbr, style: AppTextStyles.label),
              if (product.sellingPrice != null) ...[
                const SizedBox(width: 8),
                const Icon(Icons.attach_money, size: 12, color: AppColors.textSecondary),
                Text(
                  'ETB ${product.sellingPrice!.toStringAsFixed(2)}',
                  style: AppTextStyles.label,
                ),
              ],
            ],
          ),
          // Current stock
          if (stockEntry != null)
            Row(
              children: [
                Icon(
                  isExpired ? Icons.warning : isLow ? Icons.warning_amber_outlined : Icons.inventory_outlined,
                  size: 12,
                  color: isExpired ? AppColors.error : isLow ? AppColors.warning : AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Stock: ${stockEntry!.quantity.toStringAsFixed(2)} ${stockEntry!.unitAbbr}',
                  style: AppTextStyles.label.copyWith(
                    color: isExpired ? AppColors.error : isLow ? AppColors.warning : AppColors.textSecondary,
                  ),
                ),
                if (isExpired) ...[
                  const SizedBox(width: 6),
                  const Text('· EXPIRED', style: TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.w700)),
                ] else if (isExpiringSoon) ...[
                  const SizedBox(width: 6),
                  Text(
                    '· Expires ${_formatDate(stockEntry!.expiryDate!)}',
                    style: const TextStyle(color: AppColors.warning, fontSize: 10),
                  ),
                ],
              ],
            )
          else
            Text('No stock recorded', style: AppTextStyles.label.copyWith(color: AppColors.textDisabled)),
        ],
      ),
      isThreeLine: stockEntry != null,
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductFormScreen(product: product),
          fullscreenDialog: true,
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month - 1]} ${d.day}';
  }
}

class _EmptyProducts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textDisabled),
          const SizedBox(height: 12),
          Text('No products yet', style: AppTextStyles.headline3),
          const SizedBox(height: 4),
          Text('Tap + to add your first product', style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

// ─── Stock Tab ────────────────────────────────────────────────────────────────

class _StockTab extends ConsumerWidget {
  const _StockTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stock = ref.watch(stockLevelsProvider);
    return stock.when(
      data: (list) => list.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.scale_outlined, size: 64, color: AppColors.textDisabled),
                  const SizedBox(height: 12),
                  Text('No stock recorded', style: AppTextStyles.headline3),
                  const SizedBox(height: 4),
                  Text('Tap a product → set opening stock', style: AppTextStyles.bodySmall),
                ],
              ),
            )
          : ListView.separated(
              itemCount: list.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (ctx, i) => _StockTile(entry: list[i]),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) =>
          Center(child: Text('Error: $e', style: AppTextStyles.bodySmall)),
    );
  }
}

class _StockTile extends ConsumerWidget {
  const _StockTile({required this.entry});
  final StockEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLow = entry.isLowStock;
    final isExpired = entry.isExpired;
    final isExpiringSoon = entry.isExpiringSoon;

    Color statusColor = isExpired
        ? AppColors.error
        : isLow
            ? AppColors.warning
            : AppColors.primary;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: statusColor.withValues(alpha: 0.12),
        child: Icon(
          isExpired
              ? Icons.warning
              : isLow
                  ? Icons.warning_amber_outlined
                  : Icons.inventory_outlined,
          color: statusColor,
          size: 20,
        ),
      ),
      title: Text(entry.productName, style: AppTextStyles.body),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Unit
          Text(
            'Unit: ${entry.unitAbbr}',
            style: AppTextStyles.label,
          ),
          // Expiry
          if (entry.expiryDate != null)
            Text(
              isExpired
                  ? 'EXPIRED: ${_formatDate(entry.expiryDate!)}'
                  : isExpiringSoon
                      ? 'Expires soon: ${_formatDate(entry.expiryDate!)}'
                      : 'Expires: ${_formatDate(entry.expiryDate!)}',
              style: AppTextStyles.label.copyWith(
                color: isExpired
                    ? AppColors.error
                    : isExpiringSoon
                        ? AppColors.warning
                        : AppColors.textSecondary,
              ),
            ),
          if (isLow && !isExpired)
            Text(
              'Low — threshold: ${entry.lowStockThreshold} ${entry.unitAbbr}',
              style: AppTextStyles.label.copyWith(color: AppColors.warning),
            ),
        ],
      ),
      isThreeLine: entry.expiryDate != null || isLow,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            entry.quantity.toStringAsFixed(2),
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
          Text(entry.unitAbbr, style: AppTextStyles.label),
        ],
      ),
      onTap: () => _showAdjustDialog(context, ref),
    );
  }

  void _showAdjustDialog(BuildContext context, WidgetRef ref) {
    final qtyCtrl = TextEditingController(text: entry.quantity.toStringAsFixed(2));
    final notesCtrl = TextEditingController();
    DateTime? expiryDate = entry.expiryDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Adjust Stock: ${entry.productName}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current: ${entry.quantity} ${entry.unitAbbr}',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'New quantity (${entry.unitAbbr})',
                    isDense: true,
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Reason (required)',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                // Expiry date
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: expiryDate ?? DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) setDialogState(() => expiryDate = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Expiry Date (optional)',
                      isDense: true,
                      suffixIcon: Icon(Icons.calendar_today_outlined, size: 16),
                    ),
                    child: Text(
                      expiryDate != null ? _formatDate(expiryDate!) : 'Not set',
                      style: AppTextStyles.body,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (notesCtrl.text.trim().isEmpty) return;
                final newQty = Decimal.tryParse(qtyCtrl.text) ?? entry.quantity;
                Navigator.pop(ctx);
                final ok = await ref
                    .read(stockAdjustmentProvider.notifier)
                    .manualAdjust(
                      productId: entry.productId,
                      newQuantity: newQty,
                      currentQuantity: entry.quantity,
                      notes: notesCtrl.text.trim(),
                      expiryDate: expiryDate,
                    );
                if (context.mounted && !ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Adjustment failed'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
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
  late final _priceCtrl = TextEditingController(
      text: widget.product?.sellingPrice?.toString() ?? '');
  late final _thresholdCtrl = TextEditingController(
      text: widget.product?.lowStockThreshold.toString() ?? '0');
  MeasurementUnit? _selectedUnit;
  bool _unitsLoaded = false;

  bool get _isEdit => widget.product != null;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _thresholdCtrl.dispose();
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

    final ok = await ref.read(productFormProvider.notifier).save(
          productId: widget.product?.id,
          name: _nameCtrl.text,
          measurementUnitId: _selectedUnit!.id,
          lowStockThreshold:
              Decimal.tryParse(_thresholdCtrl.text) ?? Decimal.zero,
          sellingPrice: _priceCtrl.text.trim().isEmpty
              ? null
              : Decimal.tryParse(_priceCtrl.text),
        );

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      final err = ref.read(productFormProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err?.toString() ?? 'Failed to save'),
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
            child: const Text('Remove',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final ok = await ref
        .read(productFormProvider.notifier)
        .deactivate(widget.product!.id);
    if (mounted && ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final units = ref.watch(measurementUnitsProvider);
    final loading = ref.watch(productFormProvider).isLoading;

    // Pre-select unit when editing — do this once when units finish loading
    units.whenData((list) {
      if (!_unitsLoaded && widget.product != null) {
        _unitsLoaded = true;
        final match = list.where(
            (u) => u.id == widget.product!.measurementUnitId);
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
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Name is required'
                    : null,
              ),
              const SizedBox(height: 16),

              // Unit of measurement — use value: for reactive display
              units.when(
                data: (list) => InputDecorator(
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
                                child: Text('${u.name} (${u.abbreviation})'),
                              ))
                          .toList(),
                      onChanged: (u) => setState(() => _selectedUnit = u),
                    ),
                  ),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, st) => Text(
                  'Could not load units — try again',
                  style: AppTextStyles.label.copyWith(color: AppColors.error),
                ),
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _priceCtrl,
                label: 'Selling Price (ETB) — optional',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.attach_money),
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _thresholdCtrl,
                label: 'Low Stock Alert Threshold',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                prefixIcon: const Icon(Icons.warning_amber_outlined),
              ),
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
