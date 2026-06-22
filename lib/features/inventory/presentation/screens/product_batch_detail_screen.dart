import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/utils/date_formatter.dart';
import '../../data/inventory_remote.dart';
import '../providers/inventory_provider.dart';

/// Full per-lot view for a wholesale product: each batch's number, expiry,
/// received vs remaining quantity, who added it and when. Read-only for now;
/// per-batch correction + add-batch actions land here next (feature #3).
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
    return Scaffold(
      appBar: AppBar(
        title: Text(productName),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(20),
          child: Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Batch details'),
          ),
        ),
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
            itemBuilder: (_, i) =>
                _BatchDetailCard(batch: list[i], unitAbbr: unitAbbr),
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
  const _BatchDetailCard({required this.batch, required this.unitAbbr});

  final ProductBatchView batch;
  final String unitAbbr;

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
          _row('Expiry', batch.expiryDate != null
              ? formatDate(batch.expiryDate!)
              : 'No expiry'),
          _row('Remaining',
              '${batch.remaining.toStringAsFixed(2)} $unitAbbr', emphasize: true),
          _row('Received', '${batch.received.toStringAsFixed(2)} $unitAbbr'),
          _row('Added on', formatDate(batch.receivedAt)),
          _row('Added by', batch.addedByName ?? 'Unknown'),
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
              child: Text(
                value,
                style: emphasize
                    ? AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)
                    : AppTextStyles.body,
              ),
            ),
          ],
        ),
      );
}
