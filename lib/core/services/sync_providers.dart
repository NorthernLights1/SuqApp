import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/database_provider.dart';
import '../../data/local/seed_service.dart';
import '../../domain/interfaces/sync_service_interface.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/providers/shop_provider.dart';
import 'sync_scheduler.dart';
import 'sync_service.dart';

/// The download/pull engine: refreshes the local read-caches from Supabase.
final seedServiceProvider = Provider<SeedService?>((ref) {
  final db = ref.watch(appDatabaseProvider);
  if (db == null) return null; // web — no local DB
  final client = ref.read(supabaseClientProvider);
  return SeedService(client, db);
});

/// Shared connectivity handle (one per app).
final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

/// The sync engine: pushes pending local rows to Supabase and exposes status.
final syncServiceProvider = Provider<ISyncService>((ref) {
  final service = SyncService(
    ref.read(supabaseClientProvider),
    ref.read(connectivityProvider),
    ref.watch(appDatabaseProvider),
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

/// How many local rows are still waiting to upload — for the sync-health view.
/// Recounts after each sync and whenever the pending-work flag flips. 0 on web.
final pendingPushCountProvider = StreamProvider<int>((ref) async* {
  ref.watch(syncStatusProvider); // re-evaluate after a sync run
  final db = ref.watch(appDatabaseProvider);
  if (db == null) {
    yield 0;
    return;
  }
  // Recount on every pending-work change (a write enqueues, a push clears).
  await for (final _ in db.watchHasPendingWork()) {
    yield await db.pendingPushCount();
  }
});

/// Owns the trigger wiring (connectivity / backstop / cold start / login).
/// Instantiate once from the app root so it stays alive for the session.
final syncSchedulerProvider = Provider<SyncScheduler>((ref) {
  final scheduler = SyncScheduler(
    ref.watch(syncServiceProvider),
    ref.read(connectivityProvider),
    // Single post-write nudge: a debounced sync whenever a local write leaves
    // unsynced work (null on web, where there's no local DB / queue).
    pendingStream: ref.watch(appDatabaseProvider)?.watchHasPendingWork(),
    // Pull half: after each push, download server state into the local caches
    // so other devices' changes appear (resolves shop+branch each run).
    onPull: () async {
      final seed = ref.read(seedServiceProvider);
      if (seed == null) return;
      final shop = await ref.read(currentShopProvider.future);
      if (shop == null) return;
      final branches = await ref.read(currentShopBranchesProvider.future);
      if (branches.isEmpty) return;
      final branch = ref.read(activeBranchProvider) ?? branches.first;
      await seed.seedAll(shopId: shop.id, branchId: branch.id);
    },
  );
  scheduler.start();

  // Sync right after sign-in (covers launching while logged out, then in).
  ref.listen<String?>(currentUserIdProvider, (prev, next) {
    if (prev == null && next != null) scheduler.syncNow();
  });

  ref.onDispose(scheduler.dispose);
  return scheduler;
});
