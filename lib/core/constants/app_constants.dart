class AppConstants {
  AppConstants._();

  static const String appName = 'Suq';
  static const String defaultLocale = 'en';
  static const String defaultCurrency = 'ETB';
  static const int defaultSyncWarningHours = 12;

  /// Days of device sync-heartbeat rows to keep in `sync_logs`. Older rows are
  /// pruned on each heartbeat so the append-only log stays bounded.
  static const int syncLogRetentionDays = 14;

  /// Days a shop may run unlicensed before the app locks and demands a
  /// 10-digit serial (counted from the shop's creation date).
  static const int licenseTrialDays = 14;

  /// Show the renewal countdown banner when the trial/license has this many
  /// days (or fewer) left.
  static const int licenseWarningDays = 7;
}
