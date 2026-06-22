import 'package:intl/intl.dart';

/// Shared date formatting for the two recurring display shapes. One-off formats
/// (e.g. 'MMM d' without a year, or 'MMMM d, y' with a full month) stay inlined
/// at their single call site rather than living here.

/// e.g. 'Jun 16, 2026'.
String formatDate(DateTime d) => DateFormat('MMM d, y').format(d);

/// e.g. 'Jun 16, 2026 · 3:05 PM'.
String formatDateTime(DateTime d) => DateFormat('MMM d, y · h:mm a').format(d);
