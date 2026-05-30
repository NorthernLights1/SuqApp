import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/setting_keys.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/auth/presentation/providers/shop_provider.dart';

// ─── Inventory mode ────────────────────────────────────────────────────────

final inventoryModeProvider = FutureProvider<String>((ref) async {
  final shop = await ref.watch(currentShopProvider.future);
  if (shop == null) return 'flexible';
  final client = ref.read(supabaseClientProvider);
  final data = await client
      .from('shop_settings')
      .select('value')
      .eq('shop_id', shop.id)
      .eq('key', SettingKeys.inventoryMode)
      .maybeSingle();
  if (data == null) return 'flexible';
  final raw = data['value'];
  return (raw is String ? raw : raw.toString()).replaceAll('"', '');
});

class InventoryModeNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> setMode(String mode) async {
    final shop = await ref.read(currentShopProvider.future);
    if (shop == null) return;
    final userId = ref.read(currentUserIdProvider);
    final client = ref.read(supabaseClientProvider);

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await client.from('shop_settings').upsert(
        {
          'shop_id': shop.id,
          'key': SettingKeys.inventoryMode,
          'value': mode,
          'updated_by': userId,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'shop_id, key',
      );
      ref.invalidate(inventoryModeProvider);
    });
  }
}

final inventoryModeNotifierProvider =
    AsyncNotifierProvider<InventoryModeNotifier, void>(InventoryModeNotifier.new);
