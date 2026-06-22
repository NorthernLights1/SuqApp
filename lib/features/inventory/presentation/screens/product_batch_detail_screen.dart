import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/presentation/providers/permissions_provider.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/utils/date_formatter.dart';
import '../../../../shared/widgets/decimal_input_formatter.dart';
import '../../data/inventory_remote.dart';
import '../providers/inventory_provider.dart';

/// Full per-lot view for a wholesale product: each batch's number, expiry,
/// received vs remaining quantity, who added it and when — plus per-lot
/// correction and an add-batch action.
class ProductBatchDetailScreen extends ConsumerWidget {
  const ProductBatchDetailScreen({
    super.key,
    required this.productId,
    required this.productName,
    required this.unitAbbr,
  });

  final String productId;
  final String productName;
  final String unitAbbr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batches = ref.watch(productBatchesProvider(productId));
    final canAdjust = hasPermissionSync(ref, 'inventory.adjust');
    final canCorrect = hasPermissionSync(ref, 'settings.manage');

    return Scaffold(
      appBar: AppBar(
        title: Text(productName),
        actions: [
          if (canAdjust)
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add batch'),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => _AddBatchDialog(
                    productId: productId, unitAbbr: unitAbbr),
              ),
            ),
        ],
      ),
      body: batches.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Text('No active batches',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _BatchDetailCard(
              batch: list[i],
              productId: productId,
              unitAbbr: unitAbbr,
              canCorrect: canCorrect,
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Text('Could not load batches',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
        ),
      ),
    );
  }
}

class _BatchDetailCard extends StatelessWidget {
  const _BatchDetailCard({
    required this.batch,
    required this.productId,
    required this.unitAbbr,
    required this.canCorrect,
  });

  final ProductBatchView batch;
  final String productId;
  final String unitAbbr;
  final bool canCorrect;

  @override
  Widget build(BuildContext context) {
    final (Color color, String? tag) = batch.isExpired
        ? (AppColors.error, 'Expired')
        : batch.isExpiringSoon
            ? (Colors.orange.shade700, 'Expiring soon')
            : (AppColors.textSecondary, null);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  batch.batchNumber?.isNotEmpty == true
                      ? batch.batchNumber!
                      : 'No batch number',
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (tag != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(tag,
                      style: AppTextStyles.label.copyWith(color: color)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _row('Expiry',
              batch.expiryDate != null ? formatDate(batch.expiryDate!) : 'No expiry'),
          _row('Remaining', '${batch.remaining.toStringAsFixed(2)} $unitAbbr',
              emphasize: true),
          _row('Received', '${batch.received.toStringAsFixed(2)} $unitAbbr'),
          _row('Added on', formatDate(batch.receivedAt)),
          _row('Added by', batch.addedByName ?? 'Unknown'),
          if (canCorrect) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.tune, size: 16),
                label: const Text('Correct'),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => _CorrectBatchDialog(
                      batch: batch, productId: productId, unitAbbr: unitAbbr),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool emphasize = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              child: Text(label,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            ),
            Expanded(
              child: Text(value,
                  style: emphasize
                      ? AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)
                      : AppTextStyles.body),
            ),
          ],
        ),
      );
}

/// Correct a single lot's remaining to a counted figure. The difference is
/// recorded as an adjustment with a reason (audit trail).
class _CorrectBatchDialog extends ConsumerStatefulWidget {
  const _CorrectBatchDialog({
    required this.batch,
    required this.productId,
    required this.unitAbbr,
  });

  final ProductBatchView batch;
  final String productId;
  final String unitAbbr;

  @override
  ConsumerState<_CorrectBatchDialog> createState() =>
      _CorrectBatchDialogState();
}

class _CorrectBatchDialogState extends ConsumerState<_CorrectBatchDialog> {
  late final _qtyCtrl =
      TextEditingController(text: widget.batch.remaining.toStringAsFixed(2));
  final _reasonCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final counted = Decimal.tryParse(_qtyCtrl.text.trim());
    if (counted == null || counted < Decimal.zero) {
      _snack('Enter a valid counted quantity');
      return;
    }
    if (_reasonCtrl.text.trim().isEmpty) {
      _snack('Enter a reason for the correction');
      return;
    }
    setState(() => _saving = true);
    final ok = await ref.read(stockAdjustmentProvider.notifier).correctBatch(
          batchId: widget.batch.id,
          productId: widget.productId,
          countedRemaining: counted,
          reason: _reasonCtrl.text.trim(),
        );
    if (!mounted) return;
    Navigator.pop(context);
    _snack(ok ? 'Lot corrected' : 'Failed to correct lot', error: !ok);
  }

  void _snack(String msg, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.error : null,
      ));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Correct lot'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current remaining: '
            '${widget.batch.remaining.toStringAsFixed(2)} ${widget.unitAbbr}',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _qtyCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [decimalInputFormatter],
            decoration: InputDecoration(
              labelText: 'Counted quantity (${widget.unitAbbr})',
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonCtrl,
            decoration: const InputDecoration(
              labelText: 'Reason (e.g. miscount, damage)',
              isDense: true,
            ),
            maxLines: 1,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}

/// Add a new lot for this product (batch number required for wholesale).
class _AddBatchDialog extends ConsumerStatefulWidget {
  const _AddBatchDialog({required this.productId, required this.unitAbbr});

  final String productId;
  final String unitAbbr;

  @override
  ConsumerState<_AddBatchDialog> createState() => _AddBatchDialogState();
}

class _AddBatchDialogState extends ConsumerState<_AddBatchDialog> {
  final _qtyCtrl = TextEditingController();
  final _batchCtrl = TextEditingController();
  DateTime? _expiry;
  bool _saving = false;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _batchCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final qty = Decimal.tryParse(_qtyCtrl.text.trim());
    if (qty == null || qty <= Decimal.zero) {
      _snack('Enter a quantity greater than 0');
      return;
    }
    if (_batchCtrl.text.trim().isEmpty) {
      _snack('Enter a batch / lot number');
      return;
    }
    setState(() => _saving = true);
    final ok = await ref.read(stockAdjustmentProvider.notifier).addStockBatch(
          productId: widget.productId,
          quantity: qty,
          batchNumber: _batchCtrl.text.trim(),
          expiryDate: _expiry,
        );
    if (!mounted) return;
    Navigator.pop(context);
    _snack(ok ? 'Batch added' : 'Failed to add batch', error: !ok);
  }

  void _snack(String msg, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.error : null,
      ));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add batch'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _batchCtrl,
            decoration:
                const InputDecoration(labelText: 'Batch / Lot Number', isDense: true),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _qtyCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [decimalInputFormatter],
            decoration: InputDecoration(
                labelText: 'Quantity (${widget.unitAbbr})', isDense: true),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  _expiry != null
                      ? 'Expiry: ${formatDate(_expiry!)}'
                      : 'No expiry',
                  style: AppTextStyles.bodySmall,
                ),
              ),
              TextButton(
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _expiry ?? now.add(const Duration(days: 30)),
                    firstDate: DateTime(now.year, now.month, now.day + 1),
                    lastDate: now.add(const Duration(days: 3650)),
                  );
                  if (picked != null) setState(() => _expiry = picked);
                },
                child: Text(_expiry == null ? 'Set expiry' : 'Change'),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Add'),
        ),
      ],
    );
  }
}
