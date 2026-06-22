import 'package:decimal/decimal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/refund_restock.dart';

/// A line being returned: which sale_item, how many units, the money back, and
/// the original sold quantity (used to enforce the remaining-refundable cap at
/// the mutation boundary, not just in the UI).
typedef RefundLineInput = ({
  String saleItemId,
  String? productId,
  Decimal quantity,
  Decimal amount,
  Decimal soldQuantity,
});

/// Web / no-local-DB path for refunds. Routes through the same transactional,
/// idempotent RPC as the native sync (upsert_refund_with_inventory) so the
/// refund record + items + restock commit atomically server-side.
class RefundsRemote {
  RefundsRemote(this._client);

  final SupabaseClient _client;

  /// Units already refunded per sale_item for a sale (web/no-local-DB path), so
  /// the screen + the repository can cap each line at its remaining-refundable.
  /// Excludes soft-deleted refunds/items.
  Future<Map<String, Decimal>> refundedQtyBySaleItem(String saleId) async {
    final refundRows =
        (await _client
                .from('refunds')
                .select('id')
                .eq('original_sale_id', saleId)
                .isFilter('deleted_at', null)
                .timeout(AppConstants.remoteReadTimeout))
            as List;
    final ids = [for (final r in refundRows) r['id'] as String];
    if (ids.isEmpty) return {};
    final itemRows =
        (await _client
                .from('refund_items')
                .select('sale_item_id, quantity')
                .inFilter('refund_id', ids)
                .isFilter('deleted_at', null)
                .timeout(AppConstants.remoteReadTimeout))
            as List;
    final map = <String, Decimal>{};
    for (final i in itemRows) {
      final sid = i['sale_item_id'] as String;
      map[sid] =
          (map[sid] ?? Decimal.zero) +
          (Decimal.tryParse(i['quantity'].toString()) ?? Decimal.zero);
    }
    return map;
  }

  Future<void> createRefund({
    required String id,
    required String originalSaleId,
    required String branchId,
    required String refundedBy,
    required String reason,
    required Decimal totalAmount,
    required bool restock,
    required List<({String id, RefundLineInput line})> items,
    required bool useBatches,
  }) async {
    // Wholesale restock: resolve the lots each line drew from and build negative
    // adjustments (the RPC applies them). Retail leaves this null → the RPC
    // derives the restock from the refunded lines.
    List<Map<String, dynamic>>? batchAdjustments;
    if (restock && useBatches) {
      batchAdjustments = [];
      for (final it in items) {
        final line = it.line;
        final productId = line.productId;
        if (productId == null) continue;
        final sib =
            (await _client
                    .from('sale_item_batches')
                    .select('batch_id, quantity')
                    .eq('sale_item_id', line.saleItemId)
                    .isFilter('deleted_at', null)
                    .timeout(AppConstants.remoteReadTimeout))
                as List;
        final priorRows =
            (await _client
                    .from('batch_adjustments')
                    .select('batch_id, quantity_delta')
                    .eq('sale_item_id', line.saleItemId)
                    .not('refund_id', 'is', null)
                    .isFilter('deleted_at', null)
                    .timeout(AppConstants.remoteReadTimeout))
                as List;
        final priorRestocked = <String, Decimal>{};
        for (final r in priorRows) {
          final delta =
              Decimal.tryParse(r['quantity_delta'].toString()) ?? Decimal.zero;
          if (delta < Decimal.zero) {
            final batchId = r['batch_id'] as String;
            priorRestocked[batchId] =
                (priorRestocked[batchId] ?? Decimal.zero) + (-delta);
          }
        }
        final draws = [
          for (final s in sib)
            (
              batchId: s['batch_id'] as String,
              depleted:
                  (Decimal.tryParse(s['quantity'].toString()) ?? Decimal.zero) -
                  (priorRestocked[s['batch_id'] as String] ?? Decimal.zero),
            ),
        ];
        final returns = allocateRestock(draws, line.quantity);
        final allocated = returns.fold(
          Decimal.zero,
          (sum, r) => sum + r.quantity,
        );
        if (allocated < line.quantity) {
          throw StateError(
            'Cannot restock the returned units to their original lots. '
            'Refund without restock, or correct the stock manually.',
          );
        }
        for (final r in returns) {
          batchAdjustments.add({
            'id': const Uuid().v4(),
            'batch_id': r.batchId,
            'product_id': productId,
            'sale_item_id': line.saleItemId,
            'quantity': r.quantity.toString(),
          });
        }
      }
    }

    await _client.rpc(
      'upsert_refund_with_inventory',
      params: {
        'p_refund': {
          'id': id,
          'original_sale_id': originalSaleId,
          'branch_id': branchId,
          'reason': reason,
          'total_amount': totalAmount.toString(),
          'restock': restock,
        },
        'p_items': [
          for (final it in items)
            {
              'id': it.id,
              'sale_item_id': it.line.saleItemId,
              'quantity': it.line.quantity.toString(),
              'amount': it.line.amount.toString(),
            },
        ],
        'p_batch_adjustments': batchAdjustments,
      },
    );
  }
}
