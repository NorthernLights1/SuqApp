import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/permission_service.dart';
import 'auth_provider.dart';
import 'shop_provider.dart';

final permissionServiceProvider = Provider<PermissionService>(
  (ref) => PermissionService(ref.read(supabaseClientProvider)),
);

/// The current user's permission codes for the current shop (RBAC source of
/// truth for the UI). Empty while there's no shop, or on error — callers gate
/// on presence of a specific code, so a failed load fails closed.
final permissionsProvider = FutureProvider<Set<String>>((ref) async {
  final shop = await ref.watch(currentShopProvider.future);
  if (shop == null) return const {};
  // Rebuild when the signed-in user changes.
  ref.watch(currentUserIdProvider);
  try {
    return await ref.read(permissionServiceProvider).getPermissions(shop.id);
  } catch (_) {
    return const {};
  }
});

/// Convenience: true when the current user holds [code]. Returns false while
/// permissions are still loading or unavailable.
bool hasPermissionSync(WidgetRef ref, String code) =>
    ref.watch(permissionsProvider).asData?.value.contains(code) ?? false;
