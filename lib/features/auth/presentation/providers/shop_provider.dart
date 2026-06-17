import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/local/database_provider.dart';
import '../../../../domain/models/shop.dart';
import 'auth_provider.dart';

/// The shop owned by (or associated with) the current user.
///
/// Online-resilient: tries Supabase first, and on any network failure falls
/// back to the locally-cached shop (seeded by SeedService) so the app keeps
/// working offline. Returns null only when there's no shop anywhere → onboarding.
final currentShopProvider = FutureProvider<Shop?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final client = ref.read(supabaseClientProvider);
  final db = ref.read(appDatabaseProvider);

  try {
    // Try owned shop first. Bounded so an offline cold start fails fast to the
    // local cache below instead of hanging on a request that never returns.
    final ownedData = await client
        .from('shops')
        .select('id, name, config, created_at')
        .eq('owner_id', userId)
        .maybeSingle()
        .timeout(AppConstants.remoteReadTimeout);

    if (ownedData != null) return Shop.fromJson(ownedData);

    // Fall back to staff membership — join to shops via FK
    final memberData = await client
        .from('shop_users')
        .select('shops(id, name, config, created_at)')
        .eq('user_id', userId)
        .eq('status', 'active')
        .maybeSingle()
        .timeout(AppConstants.remoteReadTimeout);

    if (memberData != null) {
      final shopJson = memberData['shops'] as Map<String, dynamic>?;
      if (shopJson != null) return Shop.fromJson(shopJson);
    }
    // Reached the server and it says "no shop" — trust that (onboarding).
    return null;
  } catch (_) {
    // Offline / transient: use the last-synced shop from the local cache.
    if (db == null) return null;
    final row = await db.getAnyShop();
    if (row == null) return null;
    Map<String, dynamic> config = const {};
    try {
      final decoded = jsonDecode(row.config);
      if (decoded is Map<String, dynamic>) config = decoded;
    } catch (_) {/* keep empty on malformed cache */}
    return Shop(
      id: row.id,
      name: row.name,
      config: config,
      createdAt: row.createdAt,
    );
  }
});

/// The branches for the current shop. Online-resilient (local fallback).
final currentShopBranchesProvider = FutureProvider<List<Branch>>((ref) async {
  final shop = await ref.watch(currentShopProvider.future);
  if (shop == null) return [];

  final client = ref.read(supabaseClientProvider);
  final db = ref.read(appDatabaseProvider);

  try {
    final data = await client
        .from('branches')
        .select('id, shop_id, name, address, is_active, created_at')
        .eq('shop_id', shop.id)
        .eq('is_active', true)
        .timeout(AppConstants.remoteReadTimeout);
    return (data as List).map((e) => Branch.fromJson(e)).toList();
  } catch (_) {
    if (db == null) return [];
    final rows = await db.getBranchesByShop(shop.id);
    return rows
        .map((r) => Branch(
              id: r.id,
              shopId: r.shopId,
              name: r.name,
              address: r.address,
              isActive: r.isActive,
              createdAt: r.createdAt,
            ))
        .toList();
  }
});

/// The active branch for this session (first branch by default).
class _ActiveBranchNotifier extends Notifier<Branch?> {
  @override
  Branch? build() {
    ref.watch(currentUserIdProvider);
    return null;
  }
  void set(Branch? branch) => state = branch;
}

final activeBranchProvider =
    NotifierProvider<_ActiveBranchNotifier, Branch?>(_ActiveBranchNotifier.new);
