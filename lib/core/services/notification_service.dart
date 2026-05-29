import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/interfaces/notification_service_interface.dart';

class NotificationService implements INotificationService {
  NotificationService(this._supabase);
  final SupabaseClient _supabase;

  static const _typeCodeMap = {
    NotificationType.lowStock: 'low_stock',
    NotificationType.syncWarning: 'sync_warning',
    NotificationType.debtReminder: 'debt_reminder',
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
        .select('id, channel_id, notification_types!inner(code), notification_channels(code, is_active)')
        .eq('shop_id', shopId)
        .eq('notification_types.code', typeCode)
        .eq('is_enabled', true);

    for (final config in configs as List) {
      final channel = config['notification_channels'];
      if (channel == null || channel['is_active'] != true) continue;

      // Log the attempt — actual dispatch handled by Supabase Edge Functions
      await _supabase.from('notification_logs').insert({
        'shop_id': shopId,
        'notification_config_id': config['id'],
        'recipient': shopId, // Edge Function resolves actual recipient
        'status': 'pending',
        'payload': payload,
      });
    }
  }
}
