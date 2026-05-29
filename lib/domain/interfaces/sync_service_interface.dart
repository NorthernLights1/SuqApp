abstract interface class ISyncService {
  /// Triggers a full sync for the current user's branch.
  Future<void> sync();

  /// Returns the last successful sync time, or null if never synced.
  Future<DateTime?> lastSyncedAt();

  /// True if the last sync exceeded the configured warning threshold.
  Future<bool> isSyncOverdue();

  /// Stream that emits sync status changes.
  Stream<SyncStatus> get statusStream;
}

enum SyncStatus { idle, syncing, success, failed }
