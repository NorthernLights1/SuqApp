import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/app_error.dart';
import '../../domain/interfaces/permission_service_interface.dart';

class PermissionService implements IPermissionService {
  PermissionService(this._supabase);
  final SupabaseClient _supabase;

  // Cache per session to avoid repeated DB hits
  final Map<String, Set<String>> _cache = {};

  @override
  Future<bool> hasPermission(String shopId, String permissionCode) async {
    final perms = await getPermissions(shopId);
    return perms.contains(permissionCode);
  }

  @override
  Future<void> requirePermission(String shopId, String permissionCode) async {
    if (!await hasPermission(shopId, permissionCode)) {
      throw const PermissionError();
    }
  }

  @override
  Future<Set<String>> getPermissions(String shopId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw const AuthError();

    final cacheKey = '$userId:$shopId';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    final data = await _supabase
        .from('shop_users')
        .select('roles(role_permissions(permissions(code)))')
        .eq('shop_id', shopId)
        .eq('user_id', userId)
        .eq('status', 'active')
        .maybeSingle();

    if (data == null) return {};

    final codes = <String>{};
    final rolePerms =
        (data['roles']?['role_permissions'] as List? ?? []);
    for (final rp in rolePerms) {
      final code = rp['permissions']?['code'] as String?;
      if (code != null) codes.add(code);
    }

    _cache[cacheKey] = codes;
    return codes;
  }

  void clearCache() => _cache.clear();
}
