import 'package:decimal/decimal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/setting_keys.dart';
import '../../../domain/models/product.dart';
import '../../../domain/models/sale.dart';

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
  }) async {
    if (await _createSaleAtomically(
      id: id,
      branchId: branchId,
      cashierId: cashierId,
      paymentMethodId: paymentMethodId,
      items: items,
      customerId: customerId,
      isCredit: isCredit,
      notes: notes,
      discountReason: discountReason,
    )) {
      return getSale(id);
    }

    // Compute totals — subtotal is pre-discount, total is what customer pays
    final subtotal = items.fold(
        Decimal.zero, (sum, i) => sum + (i.unitPrice * i.quantity));
    final totalDiscount =
        items.fold(Decimal.zero, (sum, i) => sum + i.discountAmount);
    final total = subtotal - totalDiscount;

    // ── Validate stock for ALL tracked items BEFORE writing anything ─────────
    // Insert-then-rollback is fragile: a later item failing the check would
    // strand the inventory already deducted for earlier items. Pre-check the
    // whole cart first. Aggregate quantities per product so two cart lines for
    // the same product are checked against their combined total.
    final neededQty = <String, Decimal>{};
    final productNames = <String, String>{};
    final unitAbbrs = <String, String?>{};
    for (final item in items) {
      if (item.productId == null) continue;
      neededQty[item.productId!] =
          (neededQty[item.productId!] ?? Decimal.zero) + item.quantity;
      productNames.putIfAbsent(item.productId!, () => item.productName);
      unitAbbrs.putIfAbsent(item.productId!, () => item.measurementUnitAbbr);
    }
    final stockByProduct = <String, Decimal>{};
    for (final entry in neededQty.entries) {
      final stock = await getStockLevel(branchId, entry.key);
      final name = productNames[entry.key]!;
      if (stock == null) {
        throw Exception(
            '"$name" is not in inventory. Add stock before selling.');
      }
      if (stock < entry.value) {
        final abbr = unitAbbrs[entry.key];
        throw Exception(
            'Not enough stock for "$name". Available: $stock${abbr != null ? ' $abbr' : ''}');
      }
      stockByProduct[entry.key] = stock;
    }

    // ── All items valid — insert the sale (client-generated id shared with the
    // offline path) ─────────────────────────────────────────────────────────
    await _client.from('sales').insert({
      'id': id,
      'branch_id': branchId,
      'customer_id': customerId,
      'cashier_id': cashierId,
      'payment_method_id': paymentMethodId,
      'subtotal': subtotal.toString(),
      'discount_amount': totalDiscount.toString(),
      'total': total.toString(),
      'status': 'completed',
      'is_credit': isCredit,
      'notes': notes,
    });

    // ── Insert items + discounts + inventory adjustments ────────────────────
    // Track running stock per product so repeated lines deduct cumulatively.
    final runningStock = Map<String, Decimal>.from(stockByProduct);
    for (final item in items) {
      final isTracked = item.productId != null;
      final itemResult = await _client.from('sale_items').insert({
        'sale_id': id,
        'product_id': item.productId,
        'product_name_snapshot': item.productName,
        'measurement_unit_id': item.measurementUnitId,
        'quantity': item.quantity.toString(),
        'unit_price': item.unitPrice.toString(),
        'discount_amount': item.discountAmount.toString(),
        'total': item.lineTotal.toString(),
        'inventory_status':
            (isTracked ? InventoryStatus.tracked : InventoryStatus.untracked)
                .name,
        'cost_price_snapshot': item.costPrice?.toString(),
      }).select('id').single();

      // Record discount if any
      if (item.discountAmount > Decimal.zero && discountReason != null) {
        await _client.from('discounts').insert({
          'sale_id': id,
          'sale_item_id': itemResult['id'],
          'given_by': cashierId,
          'type': 'fixed',
          'value': item.discountAmount.toString(),
          'reason': discountReason,
        });
      }

      if (isTracked) {
        final before = runningStock[item.productId!]!;
        final after = before - item.quantity;
        runningStock[item.productId!] = after;

        await _client.from('inventory_adjustments').insert({
          'branch_id': branchId,
          'product_id': item.productId,
          'adjusted_by': cashierId,
          'type': 'sale',
          'quantity_before': before.toString(),
          'quantity_after': after.toString(),
          'reference_id': id,
          'reference_type': 'sale',
        });

        await _client
            .from('inventory')
            .update({'quantity': after.toString(), 'updated_at': DateTime.now().toIso8601String()})
            .eq('branch_id', branchId)
            .eq('product_id', item.productId!);
      }
    }

    // Fetch completed sale with items
    return getSale(id);
  }

  Future<bool> _createSaleAtomically({
    required String id,
    required String branchId,
    required String cashierId,
    required String paymentMethodId,
    required List<CartItem> items,
    required bool isCredit,
    String? customerId,
    String? notes,
    String? discountReason,
  }) async {
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
      items: [
        for (final item in items)
          {
            'id': const Uuid().v4(),
            'product_id': item.productId,
            'product_name_snapshot': item.productName,
            'measurement_unit_id': item.measurementUnitId,
            'quantity': item.quantity.toString(),
            'unit_price': item.unitPrice.toString(),
            'discount_amount': item.discountAmount.toString(),
            'inventory_status': (item.productId == null
                    ? InventoryStatus.untracked
                    : InventoryStatus.tracked)
                .name,
            'cost_price_snapshot': item.costPrice?.toString(),
          },
      ],
      allowOversell: false,
      discountReason: discountReason,
    );
    return true;
  }

  Future<void> _syncSale({
    required Map<String, dynamic> sale,
    required List<Map<String, dynamic>> items,
    required bool allowOversell,
    String? discountReason,
  }) async {
    await _client.rpc('upsert_sale_with_inventory', params: {
      'p_sale': sale,
      'p_items': items,
      'p_allow_oversell': allowOversell,
      'p_discount_reason': discountReason,
    });
  }

  // ─── Void sale ─────────────────────────────────────────────────────────────

  Future<void> voidSale({
    required String saleId,
    required String voidedBy,
    required String reason,
    required String branchId,
  }) async {
    await _client.rpc('void_sale_with_inventory', params: {
      'p_sale_id': saleId,
      'p_reason': reason,
    });
    if (saleId.isNotEmpty) return;

    await _client.from('sales').update({
      'status': 'voided',
      'void_reason': reason,
      'voided_by': voidedBy,
      'voided_at': DateTime.now().toIso8601String(),
    }).eq('id', saleId);

    // Reverse inventory adjustments
    final items = await _client
        .from('sale_items')
        .select('product_id, quantity, inventory_status')
        .eq('sale_id', saleId);

    for (final item in items as List) {
      if (item['product_id'] == null || item['inventory_status'] == 'untracked') {
        continue;
      }

      final productId = item['product_id'] as String;
      final qty = Decimal.parse(item['quantity'].toString());
      final stock = await getStockLevel(branchId, productId) ?? Decimal.zero;
      final newQty = stock + qty;

      await _client.from('inventory_adjustments').insert({
        'branch_id': branchId,
        'product_id': productId,
        'adjusted_by': voidedBy,
        'type': 'void',
        'quantity_before': stock.toString(),
        'quantity_after': newQty.toString(),
        'reference_id': saleId,
        'reference_type': 'sale_void',
      });

      await _client
          .from('inventory')
          .update({'quantity': newQty.toString(), 'updated_at': DateTime.now().toIso8601String()})
          .eq('branch_id', branchId)
          .eq('product_id', productId);
    }
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
