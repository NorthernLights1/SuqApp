import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import 'inventory_provider.dart';

/// An unresolved oversell: a product whose server stock went negative because
/// two offline devices sold the same units. Detected by a DB trigger
/// (migration 021).
class StockConflict extends Equatable {
  const StockConflict({
    required this.id,
    required this.branchId,
    required this.productId,
    required this.productName,
    required this.observedQuantity,
    required this.detectedAt,
  });

  final String id;
  final String branchId;
  final String productId;
  final String productName;
  final Decimal observedQuantity; // negative
  final DateTime detectedAt;

  factory StockConflict.fromJson(Map<String, dynamic> j) => StockConflict(
        id: j['id'] as String,
        branchId: j['branch_id'] as String,
        productId: j['product_id'] as String,
        productName:
            (j['products'] as Map<String, dynamic>?)?['name'] as String? ??
                'Unknown product',
        observedQuantity: Decimal.parse(j['observed_quantity'].toString()),
        detectedAt: DateTime.parse(j['detected_at'] as String).toLocal(),
      );

  @override
  List<Object?> get props =>
      [id, branchId, productId, productName, observedQuantity, detectedAt];
}

/// Open (unresolved) stock conflicts for the current shop. RLS scopes the
/// query to the shop; returns empty offline (conflicts are a sync concern).
final stockConflictsProvider =
    FutureProvider<List<StockConflict>>((ref) async {
  final client = ref.read(supabaseClientProvider);
  try {
    final data = await client
        .from('stock_conflicts')
        .select(
            'id, branch_id, product_id, observed_quantity, detected_at, products(name)')
        .isFilter('resolved_at', null)
        .order('detected_at', ascending: false);
    return (data as List)
        .map((e) => StockConflict.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return const [];
  }
});

/// Resolves a conflict: the owner enters the true physical count, which
/// corrects inventory to that value and closes the conflict.
class ResolveConflictNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> resolve({
    required StockConflict conflict,
    required Decimal trueCount,
    String? note,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return false;
    final client = ref.read(supabaseClientProvider);

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // 1) Claim the conflict by closing it *only if still open*. If another
      //    owner/device resolved it first, this updates 0 rows and we stop
      //    before correcting stock again (prevents a double correction).
      final claimed = await client
          .from('stock_conflicts')
          .update({
            'resolved_at': DateTime.now().toIso8601String(),
            'resolved_by': userId,
            if (note != null && note.isNotEmpty) 'resolution_note': note,
          })
          .eq('id', conflict.id)
          .isFilter('resolved_at', null)
          .select('id');
      if ((claimed as List).isEmpty) {
        ref.invalidate(stockConflictsProvider);
        return; // already resolved elsewhere — nothing to correct.
      }

      // 2) Correct the stock to the owner-confirmed count (absolute 'manual'
      //    adjustment, which also pushes through the normal inventory path).
      await ref.read(inventoryRepositoryProvider).correctStock(
            branchId: conflict.branchId,
            productId: conflict.productId,
            newQuantity: trueCount,
            currentQuantity: conflict.observedQuantity,
            adjustedBy: userId,
            notes: note?.isNotEmpty == true
                ? 'Oversell resolved: $note'
                : 'Oversell conflict resolved',
          );

      ref.invalidate(stockConflictsProvider);
      ref.invalidate(stockLevelsProvider);
    });
    return !state.hasError;
  }
}

final resolveConflictProvider =
    AsyncNotifierProvider<ResolveConflictNotifier, void>(
        ResolveConflictNotifier.new);
