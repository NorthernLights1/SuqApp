// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Suq';

  @override
  String get login => 'Log In';

  @override
  String get signup => 'Sign Up';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get fullName => 'Full Name';

  @override
  String get phone => 'Phone Number';

  @override
  String get continueButton => 'Continue';

  @override
  String get skip => 'Skip';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get sales => 'Sales';

  @override
  String get inventory => 'Inventory';

  @override
  String get customers => 'Customers';

  @override
  String get expenses => 'Expenses';

  @override
  String get reports => 'Reports';

  @override
  String get settings => 'Settings';

  @override
  String get staff => 'Staff';

  @override
  String get newSale => 'New Sale';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get confirm => 'Confirm';

  @override
  String get loading => 'Loading…';

  @override
  String get errorOccurred => 'Something went wrong. Please try again.';

  @override
  String get noInternetConnection => 'No internet connection.';

  @override
  String get permissionDenied =>
      'You do not have permission to perform this action.';

  @override
  String get syncOverdueWarning =>
      'Data has not synced in a while. Connect to the internet to sync.';

  @override
  String lowStockAlert(String product, String quantity, String unit) {
    return '$product is running low ($quantity $unit remaining).';
  }

  @override
  String get createShop => 'Create Your Shop';

  @override
  String get shopName => 'Shop Name';

  @override
  String get branchName => 'Branch Name';

  @override
  String get openingStock => 'Opening Stock';

  @override
  String get inviteStaff => 'Invite Staff';

  @override
  String get getStarted => 'Get Started';
}
