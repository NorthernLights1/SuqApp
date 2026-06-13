import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/setting_keys.dart';
import '../../../../data/local/database_provider.dart';
import '../../../../domain/interfaces/notification_service_interface.dart';
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
  try {
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
  } catch (_) {
    // Offline: read from the local settings cache (values are JSON-encoded).
    final db = ref.read(appDatabaseProvider);
    if (db == null) return const NotificationSettings();
    final cached = {
      for (final r in await db.getSettings(shop.id)) r.key: r.value,
    };
    String decode(String? raw) {
      if (raw == null) return '';
      try {
        return jsonDecode(raw)?.toString() ?? '';
      } catch (_) {
        return raw;
      }
    }

    return NotificationSettings(
      email: decode(cached[SettingKeys.notificationEmail]),
      overdueDays:
          int.tryParse(decode(cached[SettingKeys.overdueCreditDays])) ?? 7,
    );
  }
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
    // All guards are inside the guard so early-exit sets state to AsyncError,
    // preventing a false-success snackbar.
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final shop = await ref.read(currentShopProvider.future);
      if (shop == null) throw StateError('No active shop');
      final client = ref.read(supabaseClientProvider);
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) throw StateError('Not authenticated');

      // Single upsert call with both rows — avoids a half-written state if one
      // row commits and the second fails.
      await client.from('shop_settings').upsert(
        [
          {
            'shop_id': shop.id,
            'branch_id': null,
            'key': SettingKeys.notificationEmail,
            'value': email.trim(),
            'updated_by': userId,
          },
          {
            'shop_id': shop.id,
            'branch_id': null,
            'key': SettingKeys.overdueCreditDays,
            'value': overdueDays.toString(),
            'updated_by': userId,
          },
        ],
        onConflict: 'shop_id,branch_id,key',
      );
      ref.invalidate(notificationSettingsProvider);
    });
  }
}

// ─── Send overdue reminders ────────────────────────────────────────────────

class SendOverdueRemindersNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Returns the dispatch outcome (whether an email actually went out and why
  /// not), or null on error (state carries the error).
  Future<DispatchResult?> send() async {
    state = const AsyncLoading();
    DispatchResult? result;
    state = await AsyncValue.guard(() async {
      final shop = await ref.read(currentShopProvider.future);
      if (shop == null) throw StateError('No active shop');
      result = await ref.read(notificationServiceProvider).dispatch(
            type: NotificationType.overdueCredits,
            shopId: shop.id,
          );
    });
    return state.hasError ? null : result;
  }
}
