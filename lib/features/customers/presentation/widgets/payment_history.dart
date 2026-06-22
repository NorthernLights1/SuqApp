import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/utils/date_formatter.dart';
import '../providers/customers_provider.dart';

/// Timestamped list of payments recorded against one credit sale (the dispute
/// audit trail). Renders nothing while loading or when there are no payments.
/// Shared by the settle sheet (inline) and the sale detail screen (card).
class PaymentHistory extends ConsumerWidget {
  const PaymentHistory({super.key, required this.saleId, this.card = false});
  final String saleId;

  /// Wrap non-empty content in a Card (matches detail-screen sections) while
  /// still collapsing to nothing when there are no payments.
  final bool card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(creditPaymentsProvider(saleId));
    final content = payments.maybeWhen(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text('Payment history', style: AppTextStyles.label),
            const SizedBox(height: 6),
            for (final p in list)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      p.method == 'cash'
                          ? Icons.payments_outlined
                          : Icons.account_balance_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatCurrency(p.amount),
                      style: AppTextStyles.bodySmall
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text(formatDateTime(p.createdAt), style: AppTextStyles.label),
                  ],
                ),
              ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
    if (!card || content is SizedBox) return content;
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: content,
      ),
    );
  }
}
