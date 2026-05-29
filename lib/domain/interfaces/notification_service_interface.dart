abstract interface class INotificationService {
  Future<void> send({
    required NotificationType type,
    required String shopId,
    required Map<String, dynamic> payload,
  });
}

enum NotificationType {
  lowStock,
  syncWarning,
  debtReminder,
  reconciliationReminder,
}
