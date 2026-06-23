import 'package:decimal/decimal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/setting_keys.dart';
import '../../../domain/models/product.dart';
import '../../../domain/models/sale.dart';
import '../../inventory/domain/batch_allocation.dart';

class SalesRemote {
  SalesRemote(this._client);
  final SupabaseClient _client;

  // ─── Product search ────────────────────────────────────────────────────────

  Future<List<Product>> searchProducts(String shopId, String query) async {
    final data = await _client
        .from('products')
        .select('id, shop_id, name, category_id, measurement_unit_id, low_stock_threshold, selling_price, cost_price, is_active, measurement_units(abbreviation)')
        .eq('shop_id', shopId)
        .eq('is_active', true)
        .ilike('name', '%$query%')
        .limit(20);
    return (data as List).map((e) => Product.fromJson(e)).toList();
  }

  // ─── Payment methods ───────────────────────────────────────────────────────

  Future<List<PaymentMethod>> getPaymentMethods(String shopId) async {
    final data = await _client
        .from('payment_methods')
        .select('id, name, code, is_active')
        .or('shop_id.eq.$shopId,shop_id.is.null')
        .eq('is_active', true)
        .order('is_system', ascending: false);
    return (data as List).map((e) => PaymentMethod.fromJson(e)).toList();
  }

  // ─── Customers ─────────────────────────────────────────────────────────────

  Future<List<Customer>> searchCustomers(String shopId, String query) async {
    final data = await _client
        .from('customers')
        .select('id, name, phone, credit_balance')
        .eq('shop_id', shopId)
        .ilike('name', '%$query%')
        .order('name')
        .limit(10);
    return (data as List).map((e) => Customer.fromJson(e)).toList();
  }

  Future<Customer> createCustomer({
    required String shopId,
    required String name,
    String? phone,
  }) async {
    final data = await _client.from('customers').insert({
      'shop_id': shopId,
      'name': name.trim(),
      'phone': phone?.trim().isEmpty ?? true ? null : phone?.trim(),
    }).select('id, name, phone, credit_balance').single();
    return Customer.fromJson(data);
  }

  // ─── Inventory mode ────────────────────────────────────────────────────────

  Future<String> getInventoryMode(String shopId) async {
    final data = await _client
        .from('shop_settings')
        .select('value')
        .eq('shop_id', shopId)
        .eq('key', SettingKeys.inventoryMode)
        .maybeSingle();
    if (data == null) return 'flexible';
    final raw = data['value'];
    return (raw is String ? raw : raw.toString()).replaceAll('"', '');
  }

  // ─── Stock check ───────────────────────────────────────────────────────────

  Future<Decimal?> getStockLevel(String branchId, String productId) async {
    final data = await _client
        .from('inventory')
        .select('quantity')
        .eq('branch_id', branchId)
        .eq('product_id', productId)
        .maybeSingle();
    if (data == null) return null;
    return Decimal.parse(data['quantity'].toString());
  }

  // ─── Create sale ───────────────────────────────────────────────────────────
  // The server RPC owns the sale/items/inventory transaction and stock lock.

  Future<Sale> createSale({
    required String id,
    required String branchId,
    required String shopId,
    required String cashierId,
    required String paymentMethodId,
    required List<CartItem> items,
    String? customerId,
    bool isCredit = false,
    String? notes,
    String? discountReason,
    bool useBatches = false,
  }) async {
    await _createSaleAtomically(
      id: id,
      branchId: branchId,
      cashierId: cashierId,
      paymentMethodId: paymentMethodId,
      items: items,
      customerId: customerId,
      isCredit: isCredit,
      notes: notes,
      discountReason: discountReason,
      useBatches: useBatches,
    );
    return getSale(id);
  }

  Future<void> _createSaleAtomically({
    required String id,
    required String branchId,
    required String cashierId,
    required String paymentMethodId,
    required List<CartItem> items,
    required bool isCredit,
    required bool useBatches,
    String? customerId,
    String? notes,
    String? discountReason,
  }) async {
    final itemIds = [for (var i = 0; i < items.length; i++) const Uuid().v4()];
    final rpcItems = [
      for (var i = 0; i < items.length; i++)
        {
          'id': itemIds[i],
          'product_id': items[i].productId,
          'product_name_snapshot': items[i].productName,
          'measurement_unit_id': items[i].measurementUnitId,
          'quantity': items[i].quantity.toString(),
          'unit_price': items[i].unitPrice.toString(),
          'discount_amount': items[i].discountAmount.toString(),
          'inventory_status': (items[i].productId == null
                  ? InventoryStatus.untracked
                  : InventoryStatus.tracked)
              .name,
          'cost_price_snapshot': items[i].costPrice?.toString(),
        },
    ];
    final itemBatches = useBatches
        ? await _allocateRemoteBatches(
            branchId: branchId,
            items: items,
            saleItemIds: itemIds,
          )
        : null;

    await _syncSale(
      sale: {
        'id': id,
        'branch_id': branchId,
        'customer_id': customerId,
        'cashier_id': cashierId,
        'payment_method_id': paymentMethodId,
        'is_credit': isCredit,
        'notes': notes,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      },
      items: rpcItems,
      allowOversell: false,
      discountReason: discountReason,
      itemBatches: itemBatches,
    );
  }

  Future<void> _syncSale({
    required Map<String, dynamic> sale,
    required List<Map<String, dynamic>> items,
    required bool allowOversell,
    String? discountReason,
    List<Map<String, dynamic>>? itemBatches,
  }) async {
    await _client.rpc('upsert_sale_with_inventory', params: {
      'p_sale': sale,
      'p_items': items,
      'p_allow_oversell': allowOversell,
      'p_discount_reason': discountReason,
      'p_item_batches': itemBatches,
    });
  }

  Future<List<Map<String, dynamic>>?> _allocateRemoteBatches({
    required String branchId,
    required List<CartItem> items,
    required List<String> saleItemIds,
  }) async {
    final allocations = <Map<String, dynamic>>[];
    final remainingByBatch = <String, Decimal>{};
    final expiryByBatch = <String, DateTime?>{};
    final batchesByProduct = <String, List<String>>{};
    final now = DateTime.now();

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.productId == null) continue;
      final productId = item.productId!;
      if (!batchesByProduct.containsKey(productId)) {
        final batchRows = (await _client
            .from('product_batches')
            .select('id, expiry_date, quantity')
            .eq('branch_id', branchId)
            .eq('product_id', productId)
            .isFilter('deleted_at', null)) as List;
        final batchIds = [for (final b in batchRows) b['id'] as String];
        final depleted = await _remoteQuantityByBatch(
          table: 'sale_item_batches',
          batchIds: batchIds,
          quantityColumn: 'quantity',
        );
        final adjusted = await _remoteQuantityByBatch(
          table: 'batch_adjustments',
          batchIds: batchIds,
          quantityColumn: 'quantity_delta',
        );

        batchesByProduct[productId] = batchIds;
        for (final b in batchRows) {
          final id = b['id'] as String;
          final received =
              Decimal.tryParse(b['quantity'].toString()) ?? Decimal.zero;
          remainingByBatch[id] = received -
              (depleted[id] ?? Decimal.zero) -
              (adjusted[id] ?? Decimal.zero);
          expiryByBatch[id] = b['expiry_date'] == null
              ? null
              : DateTime.tryParse(b['expiry_date'] as String);
        }
      }

      final result = allocateFefo(
        [
          for (final id in batchesByProduct[productId]!)
            BatchAvailability(id, remainingByBatch[id] ?? Decimal.zero,
                expiryByBatch[id]),
        ],
        item.quantity,
        now,
      );
      final allocated =
          result.allocations.fold(Decimal.zero, (sum, a) => sum + a.quantity);
      if (allocated < item.quantity) {
        throw StateError(
          'No stock lots available for ${item.productName}. '
          'Add stock before selling.',
        );
      }
      for (final a in result.allocations) {
        remainingByBatch[a.batchId] =
            (remainingByBatch[a.batchId] ?? Decimal.zero) - a.quantity;
        allocations.add({
          'id': const Uuid().v4(),
          'sale_item_id': saleItemIds[i],
          'batch_id': a.batchId,
          'quantity': a.quantity.toString(),
        });
      }
    }

    return allocations.isEmpty ? null : allocations;
  }

  Future<Map<String, Decimal>> _remoteQuantityByBatch({
    required String table,
    required List<String> batchIds,
    required String quantityColumn,
  }) async {
    if (batchIds.isEmpty) return {};
    final rows = (await _client
        .from(table)
        .select('batch_id, $quantityColumn')
        .inFilter('batch_id', batchIds)
        .isFilter('deleted_at', null)) as List;
    final totals = <String, Decimal>{};
    for (final row in rows) {
      final batchId = row['batch_id'] as String;
      totals[batchId] = (totals[batchId] ?? Decimal.zero) +
          (Decimal.tryParse(row[quantityColumn].toString()) ?? Decimal.zero);
    }
    return totals;
  }

  // ─── Void sale ─────────────────────────────────────────────────────────────

  Future<void> voidSale({
    required String saleId,
    required String voidedBy,
    required String reason,
    required String branchId,
  }) async {
    // The RPC (migration 024) owns the void + stock restoration in one
    // transaction, deriving the branch from the sale and voided_by from
    // auth.uid(). voidedBy/branchId are kept on the signature for the interface
    // but are no longer sent from the client.
    await _client.rpc('void_sale_with_inventory', params: {
      'p_sale_id': saleId,
      'p_reason': reason,
    });
  }

  // ─── Fetch sales ───────────────────────────────────────────────────────────

  Future<Sale> getSale(String saleId) async {
    final data = await _client
        .from('sales')
        .select('*, sale_items(*), customers(id, name, phone), payment_methods(id, name, code), cashier:profiles!sales_cashier_id_fkey(full_name)')
        .eq('id', saleId)
        .single();
    return Sale.fromJson(data);
  }

  Future<List<Sale>> getSalesForBranch({
    required String branchId,
    required DateTime from,
    required DateTime to,
  }) async {
    final data = await _client
        .from('sales')
        .select('*, sale_items(*), customers(id, name, phone), payment_methods(id, name, code), cashier:profiles!sales_cashier_id_fkey(full_name)')
        .eq('branch_id', branchId)
        .gte('created_at', from.toUtc().toIso8601String())
        .lt('created_at', to.toUtc().toIso8601String())
        .order('created_at', ascending: false);
    return (data as List).map((e) => Sale.fromJson(e)).toList();
  }

  Future<Map<String, Decimal>> getTodayTotals(String branchId) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    final data = await _client
        .from('sales')
        .select('total, status')
        .eq('branch_id', branchId)
        .gte('created_at', start.toUtc().toIso8601String())
        .lt('created_at', end.toUtc().toIso8601String());

    // Revenue excludes voided sales, but the transaction count keeps them:
    // a voided sale still happened, so the day's transaction tally must not
    // shrink when one is voided.
    Decimal salesTotal = Decimal.zero;
    int txCount = 0;
    for (final row in data as List) {
      txCount++;
      if (row['status'] == 'completed') {
        salesTotal += Decimal.parse(row['total'].toString());
      }
    }
    return {
      'total': salesTotal,
      'count': Decimal.fromInt(txCount),
    };
  }
}
