import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import 'app_database.dart';
import 'open_database.dart'
    if (dart.library.io) 'open_database_native.dart';

// Returns null on web — callers must handle the null case by falling back to
// Supabase directly. SQLite is only available on mobile and desktop.
final appDatabaseProvider = Provider<AppDatabase?>((ref) {
  if (kIsWeb) return null;
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  final db = AppDatabase(openDatabase(userId));
  ref.onDispose(db.close);
  return db;
});
