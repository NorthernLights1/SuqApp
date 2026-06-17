import 'package:decimal/decimal.dart';
import '../../core/constants/app_constants.dart';

/// Formats a money amount as 'CODE 0.00' (e.g. 'ETB 1234.50'). Deliberately
/// dumb: callers normalize null and sign before calling — null map lookups are
/// converted to Decimal first, and a leading '-' for discounts is rendered by
/// the caller around formatCurrency(amount.abs()).
String formatCurrency(Decimal amount, {String? currencyCode}) =>
    '${currencyCode ?? AppConstants.defaultCurrency} ${amount.toStringAsFixed(2)}';
