/// All known shop_settings keys. Never use raw strings outside this file.
class SettingKeys {
  SettingKeys._();

  static const String inventoryMode = 'inventory_mode';
  static const String syncWarningHours = 'sync_warning_hours';
  static const String lowStockNotify = 'low_stock_notify';
  static const String currencyCode = 'currency_code';
  static const String locale = 'locale';

  static const String shopType = 'shop_type'; // 'retail' | 'wholesale'

  // Notifications
  static const String notificationEmail = 'notification_email';
  static const String overdueCreditDays = 'overdue_credit_days';
}
