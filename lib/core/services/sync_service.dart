import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../data/local/app_database.dart';
import '../../domain/interfaces/sync_service_interface.dart';
import '../../features/inventory/data/inventory_remote.dart';

class SyncService implements ISyncService {
  SyncService(this._supabase, this._connectivity, this._db);

  final SupabaseClient _supabase;
  final Connectivity _connectivity;
  final AppDatabase? _db;

  final _statusController = StreamController<SyncStatus>.broadcast();
  SyncStatus _status = SyncStatus.idle;

  /// Last time we wrote the sync_logs heartbeat (in-memory, per session).
  DateTime? _lastLogAt;

  /// How stale the heartbeat must be before an empty sync re-writes it.
  /// Bursts of triggers (connectivity flaps, resumes) inside this window are
  /// collapsed to a single write so frequent syncs don't spam the backend.
  static const _logHeartbeatInterval = Duration(minutes: 10);

  @override
  Stream<SyncStatus> get statusStream => _statusController.stream;

  @override
  Future<void> sync({bool force = false}) async {
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

      var pushed = 0;
      if (_db != null) {
        pushed += await _pushPendingCustomers();
        pushed += await _pushPendingSales();
        pushed += await _pushPendingCreditPayments();
        pushed += await _pushPendingExpenses();
        pushed += await _pushPendingAdjustments();
      }

      // The sync_logs heartbeat records "this device reached the server" for
      // overdue detection. We skip the write when nothing was pushed and we
      // logged recently — that's what keeps frequent triggers cheap on the
      // backend. `force` (manual sync) and actual pushes always write.
      final now = DateTime.now();
      if (force ||
          pushed > 0 ||
          _lastLogAt == null ||
          now.difference(_lastLogAt!) >= _logHeartbeatInterval) {
        if (await _writeSyncLog(userId)) _lastLogAt = now;
      }
      _emit(SyncStatus.success);
    } catch (_) {
      _emit(SyncStatus.failed);
    }
  }

  /// Pushes all pending local sales (+ their items) in two bulk upserts,
  /// idempotent by id. All-or-nothing per batch: on any failure the rows stay
  /// `isSynced=false` and the next sync retries. (A single invalid row blocks
  /// its batch — acceptable for the pilot; revisit with per-row fallback if it
  /// bites.)
  Future<int> _pushPendingSales() async {
    final db = _db!;
    final pending = await db.getPendingSales();
    if (pending.isEmpty) return 0;
    try {
      await _supabase
          .from('sales')
          .upsert(pending.map(_saleJson).toList(), onConflict: 'id');

      final items = <Map<String, dynamic>>[];
      for (final sale in pending) {
        items.addAll((await db.getSaleItems(sale.id)).map(_saleItemJson));
      }
      if (items.isNotEmpty) {
        await _supabase.from('sale_items').upsert(items, onConflict: 'id');
      }

      for (final sale in pending) {
        await db.markSaleSynced(sale.id);
      }
      return pending.length;
    } catch (_) {
      return 0; // leave isSynced=false; next sync retries
    }
  }

  Map<String, dynamic> _saleJson(SaleRow sale) => {
        'id': sale.id,
        'branch_id': sale.branchId,
        'customer_id': sale.customerId,
        'cashier_id': sale.cashierId,
        'payment_method_id': sale.paymentMethodId,
        'subtotal': sale.subtotal.toString(),
        'discount_amount': sale.discountAmount.toString(),
        'total': sale.total.toString(),
        'status': sale.status,
        'void_reason': sale.voidReason,
        'voided_by': sale.voidedBy,
        'voided_at': sale.voidedAt?.toIso8601String(),
        'is_credit': sale.isCredit,
        'notes': sale.notes,
        'created_at': sale.createdAt.toIso8601String(),
        // Carries an offline settlement up: a bill settled offline re-pushes the
        // sale with these stamped (null otherwise, which is a no-op).
        'credit_settled_at': sale.creditSettledAt?.toIso8601String(),
        'credit_settlement_method': sale.creditSettlementMethod,
      };

  Map<String, dynamic> _saleItemJson(SaleItemRow item) => {
        'id': item.id,
        'sale_id': item.saleId,
        'product_id': item.productId,
        'product_name_snapshot': item.productNameSnapshot,
        'measurement_unit_id': item.measurementUnitId,
        'quantity': item.quantity.toString(),
        'unit_price': item.unitPrice.toString(),
        'discount_amount': item.discountAmount.toString(),
        'total': item.total.toString(),
        'inventory_status': item.inventoryStatus,
        'cost_price_snapshot': item.costPriceSnapshot?.toString(),
      };

  /// Pushes all pending local expenses in one bulk upsert (idempotent by id).
  Future<int> _pushPendingExpenses() async {
    final db = _db!;
    final pending = await db.getPendingExpenses();
    if (pending.isEmpty) return 0;
    try {
      await _supabase.from('expenses').upsert(
        pending
            .map((e) => {
                  'id': e.id,
                  'branch_id': e.branchId,
                  'category_id': e.categoryId,
                  'amount': e.amount.toString(),
                  'description': e.description,
                  'recorded_by': e.recordedBy,
                  'date': e.date.toIso8601String().substring(0, 10),
                  'created_at': e.createdAt.toIso8601String(),
                })
            .toList(),
        onConflict: 'id',
      );
      for (final e in pending) {
        await db.markExpenseSynced(e.id);
      }
      return pending.length;
    } catch (_) {
      return 0; // leave isSynced=false; next sync retries
    }
  }

  /// Pushes pending credit payments (offline settlements) in one bulk upsert.
  /// Pushed after sales so the payment's sale FK exists. recorded_by is stamped
  /// from the current user (same device/session as recording).
  Future<int> _pushPendingCreditPayments() async {
    final db = _db!;
    final pending = await db.getPendingCreditPayments();
    if (pending.isEmpty) return 0;
    final userId = _supabase.auth.currentUser?.id;
    // recorded_by references a real user; if we somehow lost the session, leave
    // the payments queued rather than push a null attribution.
    if (userId == null) return 0;
    try {
      await _supabase.from('credit_payments').upsert(
        pending
            .map((p) => {
                  'id': p.id,
                  'sale_id': p.saleId,
                  'customer_id': p.customerId,
                  'amount': p.amount.toString(),
                  'method': p.method,
                  'notes': p.notes,
                  'recorded_by': userId,
                })
            .toList(),
        onConflict: 'id',
      );
      for (final p in pending) {
        await db.markCreditPaymentSynced(p.id);
      }
      return pending.length;
    } catch (_) {
      return 0; // leave isSynced=false; next sync retries
    }
  }

  /// Pushes pending customer identity rows (offline-created or edited) in one
  /// bulk upsert. Pushed before sales so a credit sale's customer FK exists.
  /// Only identity fields go up — never the locally-mirrored credit balance.
  Future<int> _pushPendingCustomers() async {
    final db = _db!;
    final pending = await db.getPendingCustomers();
    if (pending.isEmpty) return 0;
    try {
      await _supabase.from('customers').upsert(
        pending
            .map((c) => {
                  'id': c.id,
                  'shop_id': c.shopId,
                  'name': c.name,
                  'phone': c.phone,
                })
            .toList(),
        onConflict: 'id',
      );
      for (final c in pending) {
        await db.markCustomerSynced(c.id);
      }
      return pending.length;
    } catch (_) {
      return 0; // leave isSynced=false; next sync retries
    }
  }

  /// Pushes all pending stock adjustments (replayed in creation order via the
  /// idempotent, delta-aware [InventoryRemote.applyAdjustment]).
  Future<int> _pushPendingAdjustments() async {
    final db = _db!;
    final pending = await db.getPendingInventoryAdjustments();
    if (pending.isEmpty) return 0;
    final remote = InventoryRemote(_supabase);
    var pushed = 0;
    for (final a in pending) {
      try {
        await remote.applyAdjustment(
          id: a.id,
          type: a.type,
          branchId: a.branchId,
          productId: a.productId,
          quantityBefore: a.quantityBefore,
          quantityAfter: a.quantityAfter,
          adjustedBy: a.adjustedBy,
          notes: a.notes,
          expiryDate: a.expiryDate,
        );
        await db.markInventoryAdjustmentSynced(a.id);
        pushed++;
      } catch (_) {
        // Leave isSynced=false; next sync will retry
      }
    }
    return pushed;
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
    return DateTime.now().difference(last).inHours >=
        AppConstants.defaultSyncWarningHours;
  }

  /// Writes the device heartbeat row for overdue-sync detection. Returns false
  /// (and writes nothing) when no local branch is available yet — sync_logs
  /// requires a non-null branch_id, but the heartbeat itself isn't
  /// branch-specific, so any local branch serves. (device_id is a coarse label;
  /// a stable per-device id is future cleanup.)
  Future<bool> _writeSyncLog(String userId) async {
    final branchId = (await _db?.getAnyBranch())?.id;
    if (branchId == null) return false;
    await _supabase.from('sync_logs').insert({
      'user_id': userId,
      'branch_id': branchId,
      'device_id': 'mobile',
      'last_synced_at': DateTime.now().toIso8601String(),
      'status': 'success',
    });
    // Bounded retention: drop this user's stale heartbeats so the append-only
    // log can't grow without limit (RLS scopes the delete to own rows).
    final cutoff = DateTime.now()
        .subtract(const Duration(days: AppConstants.syncLogRetentionDays))
        .toIso8601String();
    await _supabase
        .from('sync_logs')
        .delete()
        .eq('user_id', userId)
        .lt('last_synced_at', cutoff);
    return true;
  }

  void _emit(SyncStatus s) {
    _status = s;
    _statusController.add(s);
  }

  void dispose() => _statusController.close();
}
