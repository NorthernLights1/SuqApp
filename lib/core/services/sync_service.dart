import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../data/local/app_database.dart';
import '../../domain/interfaces/sync_service_interface.dart';

class SyncService implements ISyncService {
  SyncService(this._supabase, this._connectivity, this._db);

  final SupabaseClient _supabase;
  final Connectivity _connectivity;
  final AppDatabase? _db;

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

      if (_db != null) await _pushPendingSales();
      await _upsertSyncLog(userId);
      _emit(SyncStatus.success);
    } catch (_) {
      _emit(SyncStatus.failed);
    }
  }

  Future<void> _pushPendingSales() async {
    final db = _db!;
    final pending = await db.getPendingSales();
    for (final sale in pending) {
      try {
        await _pushSale(sale, db);
      } catch (_) {
        // Leave isSynced=false; next sync will retry
      }
    }
  }

  Future<void> _pushSale(SaleRow sale, AppDatabase db) async {
    // If sale already reached Supabase (online push succeeded but markSynced failed),
    // just mark it synced locally and return.
    final existing = await _supabase
        .from('sales')
        .select('id')
        .eq('id', sale.id)
        .maybeSingle();
    if (existing != null) {
      await db.markSaleSynced(sale.id);
      return;
    }

    await _supabase.from('sales').insert({
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
    });

    final items = await db.getSaleItems(sale.id);
    for (final item in items) {
      await _supabase.from('sale_items').insert({
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
      });
    }

    await db.markSaleSynced(sale.id);
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

  Future<void> _upsertSyncLog(String userId) async {
    await _supabase.from('sync_logs').upsert({
      'user_id': userId,
      'branch_id': '',
      'device_id': 'mobile',
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
