import 'package:decimal/decimal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../inventory/data/inventory_remote.dart';
import '../domain/refund_restock.dart';

/// A line being returned: which sale_item, how many units, and the money back.
typedef RefundLineInput = ({
  String saleItemId,
  String? productId,
  Decimal quantity,
  Decimal amount,
});

/// Web / no-local-DB path for refunds. Writes the refund + items directly to
/// Supabase, and (when restocking) routes the stock effect through the existing
/// idempotent ledgers — retail via apply_inventory_adjustment (additive
/// 'restock'), wholesale via negative batch_adjustments on the original lots.
class RefundsRemote {
  RefundsRemote(this._client) : _inventory = InventoryRemote(_client);

  final SupabaseClient _client;
  final InventoryRemote _inventory;

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
    await _client.from('refunds').insert({
      'id': id,
      'original_sale_id': originalSaleId,
      'branch_id': branchId,
      'refunded_by': refundedBy,
      'reason': reason,
      'total_amount': totalAmount.toString(),
      'restock': restock,
    });
    await _client.from('refund_items').insert([
      for (final it in items)
        {
          'id': it.id,
          'refund_id': id,
          'sale_item_id': it.line.saleItemId,
          'quantity': it.line.quantity.toString(),
          'amount': it.line.amount.toString(),
        }
    ]);

    if (!restock) return;
    for (final it in items) {
      final line = it.line;
      final productId = line.productId;
      if (productId == null) continue;
      if (useBatches) {
        await _restockBatchesRemote(
            branchId, productId, line, refundedBy);
      } else {
        // Additive restock: pass before=0, after=qty so the server adds the
        // returned units on top of the authoritative quantity.
        await _inventory.applyAdjustment(
          id: const Uuid().v4(),
          type: 'restock',
          branchId: branchId,
          productId: productId,
          quantityBefore: Decimal.zero,
          quantityAfter: line.quantity,
          adjustedBy: refundedBy,
          notes: 'Refund restock',
        );
      }
    }
  }

  Future<void> _restockBatchesRemote(
    String branchId,
    String productId,
    RefundLineInput line,
    String refundedBy,
  ) async {
    final sib = (await _client
        .from('sale_item_batches')
        .select('batch_id, quantity')
        .eq('sale_item_id', line.saleItemId)
        .isFilter('deleted_at', null)
        .timeout(AppConstants.remoteReadTimeout)) as List;
    final draws = [
      for (final s in sib)
        (
          batchId: s['batch_id'] as String,
          depleted:
              Decimal.tryParse(s['quantity'].toString()) ?? Decimal.zero,
        )
    ];
    final returns = allocateRestock(draws, line.quantity);
    for (final r in returns) {
      await _inventory.insertBatchAdjustment(
        id: const Uuid().v4(),
        batchId: r.batchId,
        branchId: branchId,
        productId: productId,
        // Negative delta = add stock back to the lot.
        quantityDelta: -r.quantity,
        reason: 'Refund restock',
        createdBy: refundedBy,
      );
    }
  }
}
