import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/app_error.dart';
import '../../domain/interfaces/permission_service_interface.dart';

class PermissionService implements IPermissionService {
  PermissionService(this._supabase);
  final SupabaseClient _supabase;

  // Cache per session to avoid repeated DB hits
  final Map<String, Set<String>> _cache = {};

  // Offline survives a restart: permissions fetched online are persisted so the
  // UI (menus, action buttons) stays usable with no network. Key is per
  // user+shop so accounts never see each other's permissions.
  static const _prefsPrefix = 'perms:';

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

    try {
      // Bound the call: offline this would otherwise hang, leaving the UI with
      // no permissions (every gated menu/button hidden) until it times out.
      final data = await _supabase
          .from('shop_users')
          .select('roles(role_permissions(permissions(code)))')
          .eq('shop_id', shopId)
          .eq('user_id', userId)
          .eq('status', 'active')
          .maybeSingle()
          .timeout(const Duration(seconds: 5));

      final codes = <String>{};
      final rolePerms = (data?['roles']?['role_permissions'] as List? ?? []);
      for (final rp in rolePerms) {
        final code = rp['permissions']?['code'] as String?;
        if (code != null) codes.add(code);
      }

      // Only cache a NON-empty result. Every active member holds >=1 permission,
      // so an empty set never means "this user legitimately has no access" — it
      // means the role embed hadn't resolved yet (race right after onboarding) or
      // the read half-failed. Caching/persisting that empty set with no TTL would
      // make it stick forever (an owner stuck at cashier-level access). Leaving it
      // uncached lets the very next call retry and self-heal.
      if (codes.isNotEmpty) {
        _cache[cacheKey] = codes;
        await _persist(cacheKey, codes);
      }
      return codes;
    } catch (_) {
      // Offline / timeout: fall back to the permissions saved on the last
      // online session so the app stays usable. Only a user who has never been
      // online has no cache → fails closed (caller treats absence as no perms).
      final cached = await _readPersisted(cacheKey);
      if (cached != null) {
        _cache[cacheKey] = cached;
        return cached;
      }
      rethrow;
    }
  }

  Future<void> _persist(String key, Set<String> codes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefsPrefix$key', jsonEncode(codes.toList()));
  }

  Future<Set<String>?> _readPersisted(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefsPrefix$key');
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List).cast<String>().toSet();
    } catch (_) {
      return null; // malformed cache — treat as absent
    }
  }

  void clearCache() => _cache.clear();
}
