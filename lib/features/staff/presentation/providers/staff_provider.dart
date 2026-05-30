import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/auth/presentation/providers/shop_provider.dart';

class StaffMember extends Equatable {
  const StaffMember({
    required this.id,
    required this.userId,
    required this.roleName,
    required this.roleId,
    required this.status,
    required this.createdAt,
    this.fullName,
    this.phone,
  });

  final String id;
  final String userId;
  final String roleName;
  final String roleId;
  final String status; // 'active', 'invited', 'suspended'
  final DateTime createdAt;
  final String? fullName;
  final String? phone;

  String get displayName => fullName?.isNotEmpty == true ? fullName! : 'Unknown';

  bool get isActive => status == 'active';
  bool get isSuspended => status == 'suspended';

  @override
  List<Object?> get props => [id, userId, status];
}

// ─── Provider ──────────────────────────────────────────────────────────────

final staffListProvider = FutureProvider<List<StaffMember>>((ref) async {
  final shop = await ref.watch(currentShopProvider.future);
  if (shop == null) return [];
  final client = ref.read(supabaseClientProvider);

  // Fetch shop_users with role name
  final staffData = await client
      .from('shop_users')
      .select('id, user_id, role_id, status, created_at, roles(name)')
      .eq('shop_id', shop.id)
      .order('created_at');

  if ((staffData as List).isEmpty) return [];

  final userIds = staffData.map((e) => e['user_id'] as String).toList();

  // Fetch profiles separately (no direct FK from shop_users to profiles)
  final profileData = await client
      .from('profiles')
      .select('id, full_name, phone')
      .inFilter('id', userIds);

  final profileMap = {
    for (final p in profileData as List)
      p['id'] as String: p,
  };

  return staffData.map((e) {
    final profile = profileMap[e['user_id'] as String];
    final roleName =
        (e['roles'] as Map<String, dynamic>?)?['name'] as String? ?? 'Unknown';
    return StaffMember(
      id: e['id'] as String,
      userId: e['user_id'] as String,
      roleName: roleName,
      roleId: e['role_id'] as String,
      status: e['status'] as String? ?? 'active',
      createdAt: DateTime.parse(e['created_at'] as String),
      fullName: profile?['full_name'] as String?,
      phone: profile?['phone'] as String?,
    );
  }).toList();
});

// ─── Status update ─────────────────────────────────────────────────────────

class StaffStatusNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> setStatus(String shopUserId, String status) async {
    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await client
          .from('shop_users')
          .update({'status': status}).eq('id', shopUserId);
      ref.invalidate(staffListProvider);
    });
  }
}

final staffStatusProvider =
    AsyncNotifierProvider<StaffStatusNotifier, void>(StaffStatusNotifier.new);
