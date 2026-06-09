import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/database_provider.dart';
import '../../domain/interfaces/sync_service_interface.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import 'sync_scheduler.dart';
import 'sync_service.dart';

/// Shared connectivity handle (one per app).
final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

/// The sync engine: pushes pending local rows to Supabase and exposes status.
final syncServiceProvider = Provider<ISyncService>((ref) {
  final service = SyncService(
    ref.read(supabaseClientProvider),
    ref.read(connectivityProvider),
    ref.read(appDatabaseProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

/// Live sync status (idle / syncing / success / failed) for the UI.
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  return ref.watch(syncServiceProvider).statusStream;
});

/// Last successful sync time. Re-fetches whenever a sync completes.
final lastSyncedAtProvider = FutureProvider<DateTime?>((ref) {
  ref.watch(syncStatusProvider); // refresh on status change
  return ref.read(syncServiceProvider).lastSyncedAt();
});

/// Owns the trigger wiring (connectivity / backstop / cold start / login).
/// Instantiate once from the app root so it stays alive for the session.
final syncSchedulerProvider = Provider<SyncScheduler>((ref) {
  final scheduler = SyncScheduler(
    ref.read(syncServiceProvider),
    ref.read(connectivityProvider),
  );
  scheduler.start();

  // Sync right after sign-in (covers launching while logged out, then in).
  ref.listen<String?>(currentUserIdProvider, (prev, next) {
    if (prev == null && next != null) scheduler.syncNow();
  });

  ref.onDispose(scheduler.dispose);
  return scheduler;
});
