import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

QueryExecutor openDatabase(String userId) => LazyDatabase(() async {
  final dir = await getApplicationDocumentsDirectory();
  final safeUserId = userId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  final userFile = File(p.join(dir.path, 'suq_$safeUserId.db'));
  final legacyFile = File(p.join(dir.path, 'suq.db'));

  // Claim the pre-v2 single-user database once, preserving pending offline
  // writes during upgrade. Every later account gets its own empty file.
  if (!await userFile.exists() && await legacyFile.exists()) {
    await legacyFile.rename(userFile.path);
  }
  return NativeDatabase(userFile);
});
