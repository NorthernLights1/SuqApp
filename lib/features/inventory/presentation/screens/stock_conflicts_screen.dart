import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/decimal_input_formatter.dart';
import '../providers/conflicts_provider.dart';

/// Lists oversell conflicts and lets the owner resolve each by confirming the
/// true physical count. Plain-language so a non-technical owner understands
/// what happened.
class StockConflictsScreen extends ConsumerWidget {
  const StockConflictsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conflicts = ref.watch(stockConflictsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Stock Conflicts')),
      body: conflicts.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 56, color: AppColors.success),
                    const SizedBox(height: 12),
                    Text('No stock conflicts',
                        style: AppTextStyles.headline3,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    Text('Everything reconciles.',
                        style: AppTextStyles.bodySmall,
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'These products were sold on more than one phone at the same '
                  'time while offline, so more units were sold than were in '
                  'stock. Count what you actually have left and confirm it '
                  'below to fix the count.',
                  style: AppTextStyles.bodySmall,
                ),
              ),
              const SizedBox(height: 12),
              ...list.map((c) => _ConflictCard(conflict: c)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Could not load conflicts: $e',
              style: AppTextStyles.bodySmall),
        ),
      ),
    );
  }
}

class _ConflictCard extends ConsumerStatefulWidget {
  const _ConflictCard({required this.conflict});
  final StockConflict conflict;

  @override
  ConsumerState<_ConflictCard> createState() => _ConflictCardState();
}

class _ConflictCardState extends ConsumerState<_ConflictCard> {
  final _countCtrl = TextEditingController();

  @override
  void dispose() {
    _countCtrl.dispose();
    super.dispose();
  }

  Future<void> _resolve() async {
    final count = Decimal.tryParse(_countCtrl.text.trim());
    if (count == null || count < Decimal.zero) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Enter the actual quantity on hand (0 or more)')));
      return;
    }
    final ok = await ref.read(resolveConflictProvider.notifier).resolve(
          conflict: widget.conflict,
          trueCount: count,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Stock corrected' : 'Could not resolve — try again'),
      backgroundColor: ok ? AppColors.success : AppColors.error,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.conflict;
    final saving = ref.watch(resolveConflictProvider).isLoading;
    final oversoldBy = -c.observedQuantity; // observed is negative

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_outlined,
                    color: AppColors.warning, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(c.productName,
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Oversold by ${oversoldBy.toStringAsFixed(2)} '
              '(system shows ${c.observedQuantity.toStringAsFixed(2)}).',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _countCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [decimalInputFormatter],
                    decoration: const InputDecoration(
                      labelText: 'Actual quantity on hand',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: saving ? null : _resolve,
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary),
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Fix'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
