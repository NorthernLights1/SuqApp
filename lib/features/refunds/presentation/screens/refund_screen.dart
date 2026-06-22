import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/sale.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../data/refunds_remote.dart';
import '../../domain/refund_restock.dart';
import '../providers/refunds_provider.dart';

/// Partial refund flow: pick which lines (and how many units) to return from a
/// completed sale, give a reason, choose whether goods go back to stock.
class RefundScreen extends ConsumerStatefulWidget {
  const RefundScreen({super.key, required this.sale});
  final Sale sale;

  @override
  ConsumerState<RefundScreen> createState() => _RefundScreenState();
}

class _RefundScreenState extends ConsumerState<RefundScreen> {
  final _reason = TextEditingController();
  // saleItemId → units to refund (only present when the line is selected).
  final _qty = <String, Decimal>{};
  bool _restock = true;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Decimal _remaining(SaleItem item, Map<String, Decimal> alreadyRefunded) =>
      item.quantity - (alreadyRefunded[item.id] ?? Decimal.zero);

  @override
  Widget build(BuildContext context) {
    final refundedAsync = ref.watch(refundedQtyProvider(widget.sale.id));
    final submitting = ref.watch(createRefundProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Refund')),
      body: refundedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Could not load: $e', style: AppTextStyles.bodySmall)),
        data: (refunded) {
          final refundable = widget.sale.items
              .where((i) => _remaining(i, refunded) > Decimal.zero)
              .toList();

          if (refundable.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Everything on this sale has been refunded.',
                    style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
              ),
            );
          }

          final total = _qty.entries.fold(Decimal.zero, (sum, e) {
            final item =
                widget.sale.items.firstWhere((i) => i.id == e.key);
            return sum + proportionalRefund(item.total, item.quantity, e.value);
          });

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('Select items to return', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    ...refundable.map((item) => _RefundLineTile(
                          item: item,
                          remaining: _remaining(item, refunded),
                          selectedQty: _qty[item.id],
                          onChanged: (qty) => setState(() {
                            if (qty == null) {
                              _qty.remove(item.id);
                            } else {
                              _qty[item.id] = qty;
                            }
                          }),
                        )),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Return goods to stock'),
                      subtitle: Text(
                        'Off if the goods are damaged or kept out.',
                        style: AppTextStyles.bodySmall,
                      ),
                      value: _restock,
                      onChanged: (v) => setState(() => _restock = v),
                    ),
                    TextField(
                      controller: _reason,
                      decoration: const InputDecoration(
                        labelText: 'Reason (required)',
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('Refund total',
                            style: AppTextStyles.body),
                      ),
                      Text(formatCurrency(total),
                          style: AppTextStyles.headline3
                              .copyWith(color: AppColors.error)),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: (submitting || _qty.isEmpty)
                          ? null
                          : () => _submit(refundable),
                      child: submitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Process Refund'),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submit(List<SaleItem> refundable) async {
    final reason = _reason.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reason for the refund.')),
      );
      return;
    }
    final lines = <RefundLineInput>[
      for (final e in _qty.entries)
        () {
          final item = widget.sale.items.firstWhere((i) => i.id == e.key);
          return (
            saleItemId: item.id,
            productId: item.productId,
            quantity: e.value,
            amount: proportionalRefund(item.total, item.quantity, e.value),
          );
        }(),
    ];

    final ok = await ref.read(createRefundProvider.notifier).submit(
          sale: widget.sale,
          lines: lines,
          reason: reason,
          restock: _restock,
        );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refund recorded.')),
      );
      Navigator.of(context).pop();
    } else {
      final err = ref.read(createRefundProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Refund failed: $err')),
      );
    }
  }
}

class _RefundLineTile extends StatefulWidget {
  const _RefundLineTile({
    required this.item,
    required this.remaining,
    required this.selectedQty,
    required this.onChanged,
  });
  final SaleItem item;
  final Decimal remaining;
  final Decimal? selectedQty;
  final ValueChanged<Decimal?> onChanged;

  @override
  State<_RefundLineTile> createState() => _RefundLineTileState();
}

class _RefundLineTileState extends State<_RefundLineTile> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.remaining.toString());

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onQtyText(String text) {
    final qty = Decimal.tryParse(text.trim());
    if (qty == null || qty <= Decimal.zero) {
      widget.onChanged(null);
      return;
    }
    // Cap at remaining-refundable so a line can't be over-refunded.
    final capped = qty > widget.remaining ? widget.remaining : qty;
    if (capped != qty) _ctrl.text = capped.toString();
    widget.onChanged(capped);
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selectedQty != null;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Checkbox(
              value: selected,
              onChanged: (v) {
                if (v == true) {
                  _ctrl.text = widget.remaining.toString();
                  widget.onChanged(widget.remaining);
                } else {
                  widget.onChanged(null);
                }
              },
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.item.productNameSnapshot,
                      style: AppTextStyles.body),
                  Text(
                    'Up to ${widget.remaining} • ${formatCurrency(widget.item.unitPrice)} each',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 72,
              child: TextField(
                controller: _ctrl,
                enabled: selected,
                textAlign: TextAlign.center,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: const InputDecoration(isDense: true),
                onChanged: _onQtyText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
