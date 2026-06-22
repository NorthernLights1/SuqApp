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

      // Offline → reconnect: the access token may have expired while the device
      // was offline and the background auto-refresh couldn't run. Refresh it
      // before pushing so the first post-reconnect sync doesn't 401 and get
      // swallowed as a generic failure. If the refresh itself fails (still no
      // real connectivity, or the refresh token is gone), skip this run rather
      // than push with a dead token — a later trigger retries.
      final session = _supabase.auth.currentSession;
      if (session != null && session.isExpired) {
        try {
          await _supabase.auth.refreshSession();
        } on Exception {
          _emit(SyncStatus.failed);
          return;
        }
      }

      var pushed = 0;
      if (_db != null) {
        // FK order: categories → products → batches → customers → sales/adjustments → payments → expenses.
        pushed += await _pushPendingCategories();
        pushed += await _pushPendingProducts();
        pushed += await _pushPendingProductBatches();
        pushed += await _pushPendingBatchAdjustments();
        pushed += await _pushPendingCustomers();
        pushed += await _pushPendingInventoryWork();
        pushed += await _pushPendingRefunds();
        pushed += await _pushPendingCreditPayments();
        pushed += await _pushPendingExpenses();
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

  Future<int> _pushPendingCategories() async {
    final db = _db!;
    final pending = await db.getPendingCategories();
    if (pending.isEmpty) return 0;
    await _supabase.from('product_categories').upsert(
          pending
              .map((c) => {
                    'id': c.id,
                    'shop_id': c.shopId,
                    'name': c.name,
                  })
              .toList(),
          onConflict: 'id',
        );
    for (final c in pending) {
      await db.markCategorySynced(c.id);
    }
    return pending.length;
  }

  Future<int> _pushPendingProducts() async {
    final db = _db!;
    final pending = await db.getPendingProducts();
    if (pending.isEmpty) return 0;
    await _supabase.from('products').upsert(
          pending
              .map((p) => {
                    'id': p.id,
                    'shop_id': p.shopId,
                    'name': p.name,
                    'description': p.description,
                    'measurement_unit_id': p.measurementUnitId,
                    'low_stock_threshold': p.lowStockThreshold.toString(),
                    'selling_price': p.sellingPrice?.toString(),
                    'cost_price': p.costPrice?.toString(),
                    'category_id': p.categoryId,
                    'is_active': p.isActive,
                  })
              .toList(),
          onConflict: 'id',
        );
    for (final p in pending) {
      await db.markProductSynced(p.id);
    }
    return pending.length;
  }

  /// Pushes pending wholesale batches in one bulk upsert (idempotent by id).
  /// Pushed after products so the batch's product FK exists. The server rollup
  /// trigger recomputes inventory.quantity from the batches; distinct UUIDs from
  /// different devices simply sum, so no accumulator RPC is needed.
  Future<int> _pushPendingProductBatches() async {
    final db = _db!;
    final pending = await db.getPendingProductBatches();
    if (pending.isEmpty) return 0;
    await _supabase.from('product_batches').upsert(
          pending
              .map((b) => {
                    'id': b.id,
                    'branch_id': b.branchId,
                    'product_id': b.productId,
                    'batch_number': b.batchNumber,
                    'expiry_date':
                        b.expiryDate?.toIso8601String().substring(0, 10),
                    'quantity': b.quantity.toString(),
                    'cost_price': b.costPrice?.toString(),
                    'received_at': b.receivedAt.toUtc().toIso8601String(),
                    'created_by': b.createdBy,
                    // Carries a lot discard up; null for a normal received batch.
                    'deleted_at': b.deletedAt?.toUtc().toIso8601String(),
                  })
              .toList(),
          onConflict: 'id',
        );
    for (final b in pending) {
      await db.markProductBatchSynced(b.id);
    }
    return pending.length;
  }

  /// Pushes pending per-lot corrections (idempotent by id). Pushed after batches
  /// so the adjustment's batch FK exists. The server trigger recomputes the
  /// rollup + re-checks the lot conflict.
  Future<int> _pushPendingBatchAdjustments() async {
    final db = _db!;
    final pending = await db.getPendingBatchAdjustments();
    if (pending.isEmpty) return 0;
    await _supabase.from('batch_adjustments').upsert(
          pending
              .map((a) => {
                    'id': a.id,
                    'batch_id': a.batchId,
                    'branch_id': a.branchId,
                    'product_id': a.productId,
                    'quantity_delta': a.quantityDelta.toString(),
                    'reason': a.reason,
                    'created_by': a.createdBy,
                    'created_at': a.createdAt.toUtc().toIso8601String(),
                    'deleted_at': a.deletedAt?.toUtc().toIso8601String(),
                  })
              .toList(),
          onConflict: 'id',
        );
    for (final a in pending) {
      await db.markBatchAdjustmentSynced(a.id);
    }
    return pending.length;
  }

  /// Sales and stock operations share one inventory timeline. Replaying them
  /// by creation time preserves sequences such as restock-then-sale and avoids
  /// creating a false negative-stock conflict on the server.
  Future<int> _pushPendingInventoryWork() async {
    final db = _db!;
    final sales = await db.getPendingSales();
    final adjustments = await db.getPendingInventoryAdjustments();
    final operations =
        <
            ({
              DateTime createdAt,
              SaleRow? sale,
              InventoryAdjustmentRow? adjustment,
            })
          >[
            for (final sale in sales)
              (createdAt: sale.createdAt, sale: sale, adjustment: null),
            for (final adjustment in adjustments)
              (
                createdAt: adjustment.createdAt,
                sale: null,
                adjustment: adjustment,
              ),
          ]
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final inventoryRemote = InventoryRemote(_supabase);
    var pushed = 0;
    for (final operation in operations) {
      final sale = operation.sale;
      if (sale != null) {
        final itemRows = await db.getSaleItems(sale.id);
        final items = itemRows.map(_saleItemJson).toList();
        // Wholesale: the FEFO depletion ledger. Null for retail → the RPC takes
        // the inventory.quantity decrement path. Idempotent by allocation id.
        final sib = await db
            .getSaleItemBatchesForItems(itemRows.map((i) => i.id).toList());
        final itemBatches = sib.isEmpty
            ? null
            : [
                for (final s in sib)
                  {
                    'id': s.id,
                    'sale_item_id': s.saleItemId,
                    'batch_id': s.batchId,
                    'quantity': s.quantity.toString(),
                  }
              ];
        await _supabase.rpc(
          'upsert_sale_with_inventory',
          params: {
            'p_sale': _saleJson(sale),
            'p_items': items,
            'p_allow_oversell': true,
            'p_discount_reason': null,
            'p_item_batches': itemBatches,
          },
        );
        await db.markSaleSynced(sale.id);
      } else {
        final adjustment = operation.adjustment!;
        await inventoryRemote.applyAdjustment(
          id: adjustment.id,
          type: adjustment.type,
          branchId: adjustment.branchId,
          productId: adjustment.productId,
          quantityBefore: adjustment.quantityBefore,
          quantityAfter: adjustment.quantityAfter,
          adjustedBy: adjustment.adjustedBy,
          notes: adjustment.notes,
          expiryDate: adjustment.expiryDate,
          createdAt: adjustment.createdAt,
        );
        await db.markInventoryAdjustmentSynced(adjustment.id);
      }
      pushed++;
    }
    return pushed;
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
    'voided_at': sale.voidedAt?.toUtc().toIso8601String(),
    'is_credit': sale.isCredit,
    'notes': sale.notes,
    'created_at': sale.createdAt.toUtc().toIso8601String(),
    // Carries an offline settlement up: a bill settled offline re-pushes the
    // sale with these stamped (null otherwise, which is a no-op).
    'credit_settled_at': sale.creditSettledAt?.toUtc().toIso8601String(),
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

  /// Pushes pending refunds through one transactional, idempotent RPC per refund
  /// (upsert_refund_with_inventory) so the financial record + items + restock
  /// commit together server-side or not at all. Pushed after inventory work so
  /// the original_sale_id / sale_item_id FKs exist. Wholesale restock rows are
  /// gathered by refund id (their ids are reused server-side so the device's
  /// optimistic rows reconcile on pull); retail restock is derived server-side
  /// from the refunded lines.
  Future<int> _pushPendingRefunds() async {
    final db = _db!;
    final pending = await db.getPendingRefunds();
    if (pending.isEmpty) return 0;
    for (final r in pending) {
      final items = await db.getRefundItems(r.id);
      final restockAdj = r.restock
          ? await db.getRefundRestockAdjustments(r.id)
          : const <BatchAdjustmentRow>[];
      await _supabase.rpc(
        'upsert_refund_with_inventory',
        params: {
          'p_refund': {
            'id': r.id,
            'original_sale_id': r.originalSaleId,
            'branch_id': r.branchId,
            'reason': r.reason,
            'total_amount': r.totalAmount.toString(),
            'restock': r.restock,
            'created_at': r.createdAt.toUtc().toIso8601String(),
          },
          'p_items': [
            for (final i in items)
              {
                'id': i.id,
                'sale_item_id': i.saleItemId,
                'quantity': i.quantity.toString(),
                'amount': i.amount.toString(),
              }
          ],
          // retail: null (RPC derives restock from lines); wholesale: non-empty required.
          // quantity is the positive returned amount (RPC negates it on insert).
          'p_batch_adjustments': restockAdj.isEmpty
              ? null
              : [
                  for (final a in restockAdj)
                    {
                      'id': a.id,
                      'batch_id': a.batchId,
                      'product_id': a.productId,
                      'quantity': (-a.quantityDelta).toString(),
                    }
                ],
        },
      );
      await db.markRefundSynced(r.id);
    }
    return pending.length;
  }

  /// Pushes all pending local expenses in one bulk upsert (idempotent by id).
  Future<int> _pushPendingExpenses() async {
    final db = _db!;
    final pending = await db.getPendingExpenses();
    if (pending.isEmpty) return 0;
    await _supabase
        .from('expenses')
        .upsert(
          pending
              .map(
                (e) => {
                  'id': e.id,
                  'branch_id': e.branchId,
                  'category_id': e.categoryId,
                  'amount': e.amount.toString(),
                  'description': e.description,
                  'recorded_by': e.recordedBy,
                  'date': e.date.toIso8601String().substring(0, 10),
                  'created_at': e.createdAt.toUtc().toIso8601String(),
                },
              )
              .toList(),
          onConflict: 'id',
        );
    for (final e in pending) {
      await db.markExpenseSynced(e.id);
    }
    return pending.length;
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
    for (final p in pending) {
      await _supabase.rpc(
        'record_credit_payment',
        params: {
          'p_id': p.id,
          'p_sale_id': p.saleId,
          'p_customer_id': p.customerId,
          'p_amount': p.amount.toString(),
          'p_method': p.method,
          'p_notes': p.notes,
          // Preserve when the payment was actually recorded offline, not the
          // (possibly days-later) push time.
          'p_created_at': p.createdAt.toUtc().toIso8601String(),
        },
      );
      await db.markCreditPaymentSynced(p.id);
    }
    return pending.length;
  }

  /// Pushes pending customer identity rows (offline-created or edited) in one
  /// bulk upsert. Pushed before sales so a credit sale's customer FK exists.
  /// Only identity fields go up — never the locally-mirrored credit balance.
  Future<int> _pushPendingCustomers() async {
    final db = _db!;
    final pending = await db.getPendingCustomers();
    if (pending.isEmpty) return 0;
    await _supabase
        .from('customers')
        .upsert(
          pending
              .map(
                (c) => {
                  'id': c.id,
                  'shop_id': c.shopId,
                  'name': c.name,
                  'phone': c.phone,
                },
              )
              .toList(),
          onConflict: 'id',
        );
    for (final c in pending) {
      await db.markCustomerSynced(c.id);
    }
    return pending.length;
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
      'last_synced_at': DateTime.now().toUtc().toIso8601String(),
      'status': 'success',
    });
    // Bounded retention: drop this user's stale heartbeats so the append-only
    // log can't grow without limit (RLS scopes the delete to own rows).
    final cutoff = DateTime.now()
        .toUtc()
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
