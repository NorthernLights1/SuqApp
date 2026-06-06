import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/setting_keys.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/auth/presentation/providers/shop_provider.dart';

// ─── Branch name ───────────────────────────────────────────────────────────

class BranchNameNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> rename(String branchId, String name) async {
    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await client
          .from('branches')
          .update({'name': name.trim()})
          .eq('id', branchId);
      ref.invalidate(currentShopBranchesProvider);
    });
  }
}

final branchNameNotifierProvider =
    AsyncNotifierProvider<BranchNameNotifier, void>(BranchNameNotifier.new);

// ─── Notification settings ─────────────────────────────────────────────────

class NotificationSettings {
  const NotificationSettings({
    this.email = '',
    this.overdueDays = 7,
  });

  final String email;
  final int overdueDays;
}

final notificationSettingsProvider =
    FutureProvider<NotificationSettings>((ref) async {
  final shop = await ref.watch(currentShopProvider.future);
  if (shop == null) return const NotificationSettings();

  final client = ref.read(supabaseClientProvider);
  final rows = await client
      .from('shop_settings')
      .select('key, value')
      .eq('shop_id', shop.id)
      .inFilter('key', [
        SettingKeys.notificationEmail,
        SettingKeys.overdueCreditDays,
      ]);

  final map = {
    for (final r in rows as List) r['key'] as String: r['value'],
  };

  return NotificationSettings(
    email: (map[SettingKeys.notificationEmail] as String?) ?? '',
    overdueDays:
        int.tryParse((map[SettingKeys.overdueCreditDays] as String?) ?? '') ??
            7,
  );
});

final notificationSettingsNotifierProvider =
    AsyncNotifierProvider<NotificationSettingsNotifier, void>(
        NotificationSettingsNotifier.new);

final sendOverdueRemindersProvider =
    AsyncNotifierProvider<SendOverdueRemindersNotifier, void>(
        SendOverdueRemindersNotifier.new);

class NotificationSettingsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> save({
    required String email,
    required int overdueDays,
  }) async {
    final shop = await ref.read(currentShopProvider.future);
    if (shop == null) return;
    final client = ref.read(supabaseClientProvider);
    final userId = ref.read(currentUserIdProvider)!;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final updates = [
        {
          'shop_id': shop.id,
          'key': SettingKeys.notificationEmail,
          'value': email.trim(),
          'updated_by': userId,
        },
        {
          'shop_id': shop.id,
          'key': SettingKeys.overdueCreditDays,
          'value': overdueDays.toString(),
          'updated_by': userId,
        },
      ];

      for (final row in updates) {
        await client.from('shop_settings').upsert(
              row,
              onConflict: 'shop_id,branch_id,key',
            );
      }
      ref.invalidate(notificationSettingsProvider);
    });
  }
}

// ─── Send overdue reminders ────────────────────────────────────────────────

class SendOverdueRemindersNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> send() async {
    final shop = await ref.read(currentShopProvider.future);
    if (shop == null) return;
    final client = ref.read(supabaseClientProvider);

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final response = await client.functions.invoke(
        'dispatch-notifications',
        body: {'shopId': shop.id, 'type': 'overdue_credits'},
      );
      if (response.status != 200) {
        final data = response.data as Map<String, dynamic>?;
        throw Exception(data?['error'] ?? 'Failed (${response.status})');
      }
    });
  }
}
