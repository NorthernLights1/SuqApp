class AppConstants {
  AppConstants._();

  static const String appName = 'Suq';
  static const String defaultLocale = 'en';
  static const String defaultCurrency = 'ETB';
  static const int defaultSyncWarningHours = 12;

  /// Days a shop may run unlicensed before the app locks and demands a
  /// 10-digit serial (counted from the shop's creation date).
  static const int licenseTrialDays = 30;
}
