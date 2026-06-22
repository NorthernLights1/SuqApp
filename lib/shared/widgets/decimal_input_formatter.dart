import 'package:flutter/services.dart';

/// Restricts a text field to a non-negative decimal with a single decimal point
/// and up to 4 fractional digits (e.g. "12", "12.5", "0.0001"). Rejects invalid
/// keystrokes outright (e.g. "1.2.3") rather than relying on later parsing.
/// Shared by money/quantity inputs across the app.
final decimalInputFormatter =
    TextInputFormatter.withFunction((oldValue, newValue) {
  final valid = RegExp(r'^\d*(?:\.\d{0,4})?$').hasMatch(newValue.text);
  return valid ? newValue : oldValue;
});
