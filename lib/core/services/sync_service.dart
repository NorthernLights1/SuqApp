import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/interfaces/sync_service_interface.dart';

class SyncService implements ISyncService {
  SyncService(this._supabase, this._connectivity);
  final SupabaseClient _supabase;
  final Connectivity _connectivity;

  final _statusController = StreamController<SyncStatus>.broadcast();
  SyncStatus _status = SyncStatus.idle;

  @override
  Stream<SyncStatus> get statusStream => _statusController.stream;

  @override
  Future<void> sync() async {
    if (_status == SyncStatus.syncing) return;
    _emit(SyncStatus.syncing);

    try {
      final connections = await _connectivity.checkConnectivity();
      if (connections.contains(ConnectivityResult.none)) {
        _emit(SyncStatus.idle);
        return;
      }

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        _emit(SyncStatus.idle);
        return;
      }

      // TODO(phase1): push pending local Drift records to Supabase here

      await _upsertSyncLog(userId);
      _emit(SyncStatus.success);
    } catch (_) {
      _emit(SyncStatus.failed);
    }
  }

  @override
  Future<DateTime?> lastSyncedAt() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await _supabase
        .from('sync_logs')
        .select('last_synced_at')
        .eq('user_id', userId)
        .eq('status', 'success')
        .order('last_synced_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (data == null) return null;
    return DateTime.tryParse(data['last_synced_at'] as String);
  }

  @override
  Future<bool> isSyncOverdue() async {
    final last = await lastSyncedAt();
    if (last == null) return true;
    final threshold = AppConstants.defaultSyncWarningHours;
    return DateTime.now().difference(last).inHours >= threshold;
  }

  Future<void> _upsertSyncLog(String userId) async {
    await _supabase.from('sync_logs').upsert({
      'user_id': userId,
      'branch_id': '', // TODO(phase1): resolve active branch from session
      'device_id': 'web',
      'last_synced_at': DateTime.now().toIso8601String(),
      'status': 'success',
    });
  }

  void _emit(SyncStatus s) {
    _status = s;
    _statusController.add(s);
  }

  void dispose() => _statusController.close();
}
