import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/interfaces/notification_service_interface.dart';

class NotificationService implements INotificationService {
  NotificationService(this._supabase);
  final SupabaseClient _supabase;

  static const _typeCodeMap = {
    NotificationType.lowStock: 'low_stock',
    NotificationType.syncWarning: 'sync_warning',
    NotificationType.debtReminder: 'debt_reminder',
    NotificationType.overdueCredits: 'overdue_credits',
    NotificationType.reconciliationReminder: 'reconciliation_reminder',
  };

  @override
  Future<void> send({
    required NotificationType type,
    required String shopId,
    required Map<String, dynamic> payload,
  }) async {
    final typeCode = _typeCodeMap[type]!;

    // Load enabled configs for this shop + type
    final configs = await _supabase
        .from('notification_configs')
        .select(
            'id, channel_id, notification_types!inner(code), notification_channels(code, is_active)')
        .eq('shop_id', shopId)
        .eq('notification_types.code', typeCode)
        .eq('is_enabled', true);

    for (final config in configs as List) {
      final channel = config['notification_channels'];
      if (channel == null || channel['is_active'] != true) continue;

      await _supabase.from('notification_logs').insert({
        'shop_id': shopId,
        'notification_config_id': config['id'],
        'recipient': shopId,
        'status': 'pending',
        'payload': payload,
      });
    }
  }

  @override
  Future<DispatchResult> dispatch({
    required NotificationType type,
    required String shopId,
  }) async {
    final typeCode = _typeCodeMap[type]!;
    final response = await _supabase.functions.invoke(
      'dispatch-notifications',
      body: {'shopId': shopId, 'type': typeCode},
    );
    final data = response.data;
    if (response.status != 200) {
      final message =
          data is Map<String, dynamic> ? data['error'] as String? : null;
      throw Exception(message ?? 'Failed (${response.status})');
    }
    // 200 can still mean "nothing to send" (e.g. no overdue credits). Report
    // that honestly so the UI doesn't claim an email went out.
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    return DispatchResult(
      sent: map['sent'] == true,
      reason: map['reason'] as String?,
    );
  }
}
