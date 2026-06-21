import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/setting_keys.dart';
import '../../../../data/local/database_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/auth/presentation/providers/shop_provider.dart';

final shopTypeProvider = FutureProvider<String>((ref) async {
  final shop = await ref.watch(currentShopProvider.future);
  if (shop == null) return 'retail';

  final client = ref.read(supabaseClientProvider);
  try {
    final row = await client
        .from('shop_settings')
        .select('value')
        .eq('shop_id', shop.id)
        .eq('key', SettingKeys.shopType)
        .maybeSingle();
    final raw = (row?['value'] as String?) ?? '"retail"';
    return raw.replaceAll('"', '');
  } catch (_) {
    final db = ref.read(appDatabaseProvider);
    if (db == null) return 'retail';
    final cached = await db.getSettings(shop.id);
    final match = cached.where((r) => r.key == SettingKeys.shopType);
    final raw = match.isEmpty ? '"retail"' : match.first.value;
    return raw.replaceAll('"', '');
  }
});

/// Convenience for WIDGETS only (labels, show/hide). During loading/error
/// `asData` is null, so both default to the lenient "retail" reading
/// (isWholesale=false). That is deliberate for cosmetics, but it means an
/// ENFORCEMENT path must NOT use this — it must `await ref.read(
/// shopTypeProvider.future)` so a still-loading wholesale shop can't slip
/// through as retail. (The new-sale customer gate already awaits the future.)
extension ShopTypeX on AsyncValue<String> {
  bool get isWholesale => asData?.value == 'wholesale';
  bool get isRetail => asData?.value != 'wholesale';
}
