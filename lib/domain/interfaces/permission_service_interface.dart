abstract interface class IPermissionService {
  /// Returns true if the current user has [permissionCode] in [shopId].
  Future<bool> hasPermission(String shopId, String permissionCode);

  /// Throws [PermissionError] if the current user lacks [permissionCode].
  Future<void> requirePermission(String shopId, String permissionCode);

  /// Returns all permission codes the current user holds in [shopId].
  Future<Set<String>> getPermissions(String shopId);
}
