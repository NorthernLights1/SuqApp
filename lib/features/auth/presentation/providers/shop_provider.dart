import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/shop.dart';
import 'auth_provider.dart';

/// Fetches the shop owned by (or associated with) the current user.
/// Returns null if the user has no shop yet → triggers onboarding.
final currentShopProvider = FutureProvider<Shop?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final client = ref.read(supabaseClientProvider);

  final data = await client
      .from('shops')
      .select('id, name, config, created_at')
      .eq('owner_id', userId)
      .maybeSingle();

  if (data == null) return null;
  return Shop.fromJson(data);
});

/// Fetches the branches for the current shop.
final currentShopBranchesProvider = FutureProvider<List<Branch>>((ref) async {
  final shop = await ref.watch(currentShopProvider.future);
  if (shop == null) return [];

  final client = ref.read(supabaseClientProvider);
  final data = await client
      .from('branches')
      .select('id, shop_id, name, address, is_active, created_at')
      .eq('shop_id', shop.id)
      .eq('is_active', true);

  return (data as List).map((e) => Branch.fromJson(e)).toList();
});

/// The active branch for this session (first branch by default).
final activeBranchProvider = StateProvider<Branch?>((ref) => null);
