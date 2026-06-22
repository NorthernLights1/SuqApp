import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../domain/interfaces/sync_service_interface.dart';

/// Decides *when* to sync. The heavy lifting (pushing pending rows, retry
/// idempotency, status) lives in [ISyncService]; this only wires real-world
/// events to it:
///   1. Connectivity regained (offline → online transition)
///   2. A periodic backstop (covers "looks connected but isn't" Wi-Fi)
///   3. Cold start ([start] runs an initial sync)
/// App-resume and post-login triggers are driven from outside (see
/// sync_providers / app root) and also funnel through [syncNow].
class SyncScheduler {
  SyncScheduler(this._service, this._connectivity,
      {this.onPull, this.pendingStream});

  final ISyncService _service;
  final Connectivity _connectivity;

  /// Downloads server state into the local DB (the "pull" half). Runs after the
  /// push on every trigger so other devices' changes land locally. Optional so
  /// the scheduler stays usable without a pull wired in.
  final Future<void> Function()? onPull;

  /// Emits true whenever a local write leaves unsynced work (see
  /// [AppDatabase.watchHasPendingWork]). A debounced sync drains it promptly —
  /// the single post-write nudge for every offline write. Null on web.
  final Stream<bool>? pendingStream;

  StreamSubscription<List<ConnectivityResult>>? _connSub;
  StreamSubscription<bool>? _pendingSub;
  Timer? _timer;
  Timer? _debounce;
  bool _wasOnline = true;

  /// Foreground backstop. Timers on mobile don't fire while backgrounded, so
  /// this is effectively foreground-only. 15 min keeps it nearly free.
  static const _backstopInterval = Duration(minutes: 15);

  /// Coalesce a burst of writes (e.g. a multi-line sale) into one sync.
  static const _writeDebounce = Duration(seconds: 2);

  /// Begins listening and runs an initial sync (cold start).
  void start() {
    syncNow();
    _connSub = _connectivity.onConnectivityChanged.listen(_onConnectivity);
    _timer = Timer.periodic(_backstopInterval, (_) => syncNow());
    _pendingSub = pendingStream?.listen((hasPending) {
      if (!hasPending) return;
      _debounce?.cancel();
      _debounce = Timer(_writeDebounce, () => syncNow());
    });
  }

  void _onConnectivity(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    // Only fire on the offline → online edge, not on every network change.
    if (online && !_wasOnline) syncNow();
    _wasOnline = online;
  }

  /// Triggers a sync now. Safe to call repeatedly — the service ignores
  /// overlapping calls. [force] bypasses the heartbeat throttle (manual sync).
  /// Pushes pending local writes first, then pulls server state down.
  Future<void> syncNow({bool force = false}) async {
    await _service.sync(force: force);
    final pull = onPull;
    if (pull != null) {
      try {
        await pull();
      } catch (_) {
        // Pull is best-effort; offline or transient errors keep the cache.
      }
    }
  }

  void dispose() {
    _connSub?.cancel();
    _pendingSub?.cancel();
    _timer?.cancel();
    _debounce?.cancel();
  }
}
