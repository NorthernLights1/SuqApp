abstract interface class INotificationService {
  /// Logs a pending notification entry (picked up by the DB/cron layer).
  Future<void> send({
    required NotificationType type,
    required String shopId,
    required Map<String, dynamic> payload,
  });

  /// Triggers immediate dispatch via the dispatch-notifications Edge Function.
  /// Throws on non-200 responses; otherwise reports whether an email was
  /// actually sent (it isn't, e.g., when nothing is overdue yet).
  Future<DispatchResult> dispatch({
    required NotificationType type,
    required String shopId,
  });
}

/// Outcome of a dispatch call. [sent] is false when the function ran fine but
/// had nothing to send (e.g. no overdue credits) — [reason] explains why.
class DispatchResult {
  const DispatchResult({required this.sent, this.reason});
  final bool sent;
  final String? reason;
}

enum NotificationType {
  lowStock,
  syncWarning,
  debtReminder,
  overdueCredits,
  reconciliationReminder,
}
