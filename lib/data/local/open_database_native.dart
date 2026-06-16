import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

QueryExecutor openDatabase(String userId) => LazyDatabase(() async {
  final dir = await getApplicationDocumentsDirectory();
  // userId is always a Supabase auth UUID (e.g. "69c021a0-e5a5-4aef-..."), whose
  // characters are already filesystem-safe — the sanitize is purely defensive.
  // Because real ids are UUIDs they cannot collide, and the derivation is kept
  // stable on purpose so an existing per-user DB file is never orphaned.
  final safeUserId = userId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  final userFile = File(p.join(dir.path, 'suq_$safeUserId.db'));
  final legacyFile = File(p.join(dir.path, 'suq.db'));

  // Claim the pre-v2 single-user database once, preserving pending offline
  // writes during upgrade. Every later account gets its own empty file. If the
  // rename fails (file locked / permissions), fall back to a fresh per-user DB
  // rather than blocking startup — the legacy file stays for a later retry and
  // its data re-pulls from the server.
  if (!await userFile.exists() && await legacyFile.exists()) {
    try {
      await legacyFile.rename(userFile.path);
    } catch (e, st) {
      // Proceed with an empty per-user database rather than blocking startup,
      // but surface the failure: any unsynced writes left in the legacy file
      // are lost (synced data re-pulls), so this must be visible for recovery.
      debugPrint('Legacy DB migration failed; unsynced writes may be lost: $e\n$st');
    }
  }
  return NativeDatabase(userFile);
});
