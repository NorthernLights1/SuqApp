abstract interface class INotificationService {
  /// Logs a pending notification entry (picked up by the DB/cron layer).
  Future<void> send({
    required NotificationType type,
    required String shopId,
    required Map<String, dynamic> payload,
  });

  /// Triggers immediate dispatch via the dispatch-notifications Edge Function.
  /// Throws on non-200 responses.
  Future<void> dispatch({
    required NotificationType type,
    required String shopId,
  });
}

enum NotificationType {
  lowStock,
  syncWarning,
  debtReminder,
  overdueCredits,
  reconciliationReminder,
}
