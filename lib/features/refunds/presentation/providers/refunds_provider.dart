import 'dart:async';
import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/setting_keys.dart';
import '../../../../core/services/sync_providers.dart';
import '../../../../data/local/database_provider.dart';
import '../../../../domain/models/sale.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/inventory/presentation/providers/inventory_provider.dart';
import '../../../../features/reports/presentation/providers/reports_provider.dart';
import '../../../../features/sales/presentation/providers/sales_provider.dart';
import '../../../../features/settings/presentation/providers/shop_type_provider.dart';
import '../../data/refunds_remote.dart';
import '../../domain/refunds_repository.dart';

final refundsRepositoryProvider = Provider<RefundsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final db = ref.watch(appDatabaseProvider);
  return RefundsRepository(RefundsRemote(client), db);
});

/// Units already refunded per sale_item for a sale — used to cap each line's
/// remaining-refundable quantity (original qty − this).
final refundedQtyProvider =
    FutureProvider.family<Map<String, Decimal>, String>((ref, saleId) async {
  return ref.watch(refundsRepositoryProvider).refundedQtyBySaleItem(saleId);
});

class CreateRefundNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Records a (partial) refund against [sale]. Returns true on success.
  Future<bool> submit({
    required Sale sale,
    required List<RefundLineInput> lines,
    required String reason,
    required bool restock,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      throw Exception('Missing user context');
    }
    // Authoritative (awaited) so a still-loading wholesale shop can't take the
    // retail restock path.
    final useBatches =
        await ref.read(shopTypeProvider.future) == ShopType.wholesale;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(refundsRepositoryProvider).createRefund(
            originalSaleId: sale.id,
            branchId: sale.branchId,
            refundedBy: userId,
            reason: reason,
            restock: restock,
            lines: lines,
            useBatches: useBatches,
          );
      // Refresh the surfaces a refund touches; don't block on refetch.
      ref.invalidate(refundedQtyProvider(sale.id));
      if (restock) {
        ref.invalidate(stockLevelsProvider);
        if (useBatches) ref.invalidate(productBatchesProvider);
      }
      ref.invalidate(reportSummaryProvider);
      ref.invalidate(salesListProvider);
      // Single-boundary sync nudge (offline → no-op, pushed on reconnect).
      unawaited(ref.read(syncSchedulerProvider).syncNow());
    });
    return !state.hasError;
  }
}

final createRefundProvider =
    AsyncNotifierProvider<CreateRefundNotifier, void>(CreateRefundNotifier.new);
