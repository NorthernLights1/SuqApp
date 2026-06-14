import 'dart:async';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../data/local/app_database.dart';
import '../../../domain/models/product.dart';
import '../../../domain/models/sale.dart';
import '../data/sales_remote.dart';

abstract interface class ISalesRepository {
  Future<List<Product>> searchProducts(String shopId, String query);
  Future<List<PaymentMethod>> getPaymentMethods(String shopId);
  Future<List<Customer>> searchCustomers(String shopId, String query);
  Future<Customer> createCustomer({
    required String shopId,
    required String name,
    String? phone,
  });
  Future<Sale> createSale({
    required String branchId,
    required String shopId,
    required String cashierId,
    required String paymentMethodId,
    required List<CartItem> items,
    String? customerId,
    bool isCredit,
    String? notes,
    String? discountReason,
  });
  Future<void> voidSale({
    required String saleId,
    required String voidedBy,
    required String reason,
    required String branchId,
  });
  Future<Sale> getSale(String saleId);
  Future<List<Sale>> getSalesForBranch({
    required String branchId,
    required DateTime from,
    required DateTime to,
  });
  Future<Map<String, Decimal>> getTodayTotals(String branchId);
}

class SalesRepository implements ISalesRepository {
  SalesRepository(this._remote, this._db);

  final SalesRemote _remote;
  final AppDatabase? _db;

  // ── Products ───────────────────────────────────────────────────────────────

  @override
  Future<List<Product>> searchProducts(String shopId, String query) async {
    if (query.trim().length < 2) return [];
    if (_db != null) {
      final rows = await _db.searchProducts(shopId, query.toLowerCase());
      if (rows.isNotEmpty) return rows.map(_productFromRow).toList();
    }
    return _remote.searchProducts(shopId, query);
  }

  @override
  Future<List<PaymentMethod>> getPaymentMethods(String shopId) =>
      _remote.getPaymentMethods(shopId);

  // ── Customers ──────────────────────────────────────────────────────────────

  @override
  Future<List<Customer>> searchCustomers(String shopId, String query) async {
    if (query.trim().length < 2) return [];
    if (_db != null) {
      final rows = await _db.searchCustomers(shopId, query.toLowerCase());
      if (rows.isNotEmpty) return rows.map(_customerFromRow).toList();
    }
    return _remote.searchCustomers(shopId, query);
  }

  @override
  Future<Customer> createCustomer({
    required String shopId,
    required String name,
    String? phone,
  }) async {
    final customer =
        await _remote.createCustomer(shopId: shopId, name: name, phone: phone);
    if (_db != null) {
      unawaited(_db.upsertCustomer(LocalCustomersCompanion(
        id: Value(customer.id),
        shopId: Value(shopId),
        name: Value(customer.name),
        phone: Value(customer.phone),
        creditBalance: Value(customer.creditBalance),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(true),
      )));
    }
    return customer;
  }

  // ── Create sale (local-first) ──────────────────────────────────────────────

  @override
  Future<Sale> createSale({
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
    final saleId = const Uuid().v4();

    final subtotal =
        items.fold(Decimal.zero, (sum, i) => sum + (i.unitPrice * i.quantity));
    final totalDiscount =
        items.fold(Decimal.zero, (sum, i) => sum + i.discountAmount);
    final total = subtotal - totalDiscount;
    final now = DateTime.now();

    // Pre-check local stock before writing anything.
    // Aggregate quantities per product so that two cart lines for the same
    // product are checked against their combined total, not each individually.
    if (_db != null) {
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
      for (final entry in neededQty.entries) {
        final stock = await _db.getStockLevel(branchId, entry.key);
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
      }
    }

    // When DB is available: write locally first (offline-safe), then sync to Supabase.
    // When DB is null (web): write directly to Supabase and return its result.
    if (_db == null) {
      return _remote.createSale(
        id: saleId,
        branchId: branchId,
        shopId: shopId,
        cashierId: cashierId,
        paymentMethodId: paymentMethodId,
        items: items,
        customerId: customerId,
        isCredit: isCredit,
        notes: notes,
        discountReason: discountReason,
      );
    }

    final itemCompanions = items.map((item) {
      InventoryStatus status = InventoryStatus.untracked;
      if (item.productId != null) status = InventoryStatus.tracked;
      return LocalSaleItemsCompanion(
        id: Value(const Uuid().v4()),
        saleId: Value(saleId),
        productId: Value(item.productId),
        productNameSnapshot: Value(item.productName),
        measurementUnitId: Value(item.measurementUnitId),
        quantity: Value(item.quantity),
        unitPrice: Value(item.unitPrice),
        discountAmount: Value(item.discountAmount),
        total: Value(item.lineTotal),
        inventoryStatus: Value(status.name),
        costPriceSnapshot: Value(item.costPrice),
      );
    }).toList();

    final saleRow = await _db.insertSaleWithItems(
      LocalSalesCompanion(
        id: Value(saleId),
        branchId: Value(branchId),
        customerId: Value(customerId),
        cashierId: Value(cashierId),
        paymentMethodId: Value(paymentMethodId),
        subtotal: Value(subtotal),
        discountAmount: Value(totalDiscount),
        total: Value(total),
        status: const Value('completed'),
        isCredit: Value(isCredit),
        notes: Value(notes),
        createdAt: Value(now),
        isSynced: const Value(false),
      ),
      itemCompanions,
    );

    // Update local stock levels
    for (final item in items) {
      if (item.productId == null) continue;
      final stock = await _db.getStockLevel(branchId, item.productId!);
      if (stock != null) {
        await _db.adjustStock(branchId, item.productId!, stock - item.quantity);
      }
    }

    // No inline push (offline-first v2 absolute boundary): the sale stays
    // isSynced=false and SyncService is the sole pusher. The caller nudges a
    // sync after a successful write (see CreateSaleNotifier.submit).
    final itemRows = await _db.getSaleItems(saleId);
    return _saleFromRows(saleRow, itemRows);
  }

  // ── Void sale ──────────────────────────────────────────────────────────────

  @override
  Future<void> voidSale({
    required String saleId,
    required String voidedBy,
    required String reason,
    required String branchId,
  }) async {
    // Void requires connectivity — inventory reversal must reach the server
    await _remote.voidSale(
        saleId: saleId, voidedBy: voidedBy, reason: reason, branchId: branchId);
    await _db?.markSaleVoided(saleId, reason, voidedBy);
  }

  // ── Reads ──────────────────────────────────────────────────────────────────

  @override
  Future<Sale> getSale(String saleId) async {
    // Server-first: the server row carries the customer, payment-method, and
    // cashier names (via joins) that the local mirror doesn't store, and
    // reflects settlement/void changes made on other devices. Fall back to the
    // local copy only when offline.
    try {
      return await _remote.getSale(saleId);
    } catch (_) {
      final row = await _db?.getSale(saleId);
      if (row != null) {
        final items = await _db!.getSaleItems(saleId);
        return _saleFromRows(row, items);
      }
      rethrow;
    }
  }

  @override
  Future<List<Sale>> getSalesForBranch({
    required String branchId,
    required DateTime from,
    required DateTime to,
  }) async {
    // Server-first so the list shows the WHOLE shop's sales (every cashier),
    // not just those created on this device, and includes the joined customer
    // / cashier / payment names. Offline → fall back to the local mirror
    // (this device's own sales).
    try {
      return await _remote.getSalesForBranch(
          branchId: branchId, from: from, to: to);
    } catch (_) {
      if (_db == null) rethrow;
      final rows = await _db.getSalesByBranch(branchId, from, to);
      final result = <Sale>[];
      for (final row in rows) {
        final items = await _db.getSaleItems(row.id);
        result.add(_saleFromRows(row, items));
      }
      return result;
    }
  }

  @override
  Future<Map<String, Decimal>> getTodayTotals(String branchId) async {
    if (_db != null) {
      final local = await _db.getTodayTotals(branchId, DateTime.now());
      if (local['count']! > Decimal.zero) return local;
      // No local sales today: the server may have some from other devices, but
      // fall back to the (zero) local total when offline instead of throwing.
      try {
        return await _remote.getTodayTotals(branchId);
      } catch (_) {
        return local;
      }
    }
    return _remote.getTodayTotals(branchId);
  }

  // ── Mappers ────────────────────────────────────────────────────────────────

  Product _productFromRow(ProductRow r) => Product(
        id: r.id,
        shopId: r.shopId,
        name: r.name,
        categoryId: r.categoryId,
        description: r.description,
        measurementUnitId: r.measurementUnitId,
        measurementUnitAbbr: r.measurementUnitAbbr,
        lowStockThreshold: r.lowStockThreshold,
        sellingPrice: r.sellingPrice,
        costPrice: r.costPrice,
        isActive: r.isActive,
      );

  Customer _customerFromRow(CustomerRow r) => Customer(
        id: r.id,
        name: r.name,
        phone: r.phone,
        creditBalance: r.creditBalance,
      );

  Sale _saleFromRows(SaleRow r, List<SaleItemRow> items) => Sale(
        id: r.id,
        branchId: r.branchId,
        customerId: r.customerId,
        cashierId: r.cashierId,
        paymentMethodId: r.paymentMethodId,
        subtotal: r.subtotal,
        discountAmount: r.discountAmount,
        total: r.total,
        status: saleStatusFromName(r.status),
        voidReason: r.voidReason,
        voidedBy: r.voidedBy,
        voidedAt: r.voidedAt,
        isCredit: r.isCredit,
        notes: r.notes,
        createdAt: r.createdAt,
        creditSettledAt: r.creditSettledAt,
        items: items.map(_saleItemFromRow).toList(),
      );

  SaleItem _saleItemFromRow(SaleItemRow r) => SaleItem(
        id: r.id,
        saleId: r.saleId,
        productId: r.productId,
        productNameSnapshot: r.productNameSnapshot,
        measurementUnitId: r.measurementUnitId,
        quantity: r.quantity,
        unitPrice: r.unitPrice,
        discountAmount: r.discountAmount,
        total: r.total,
        inventoryStatus: inventoryStatusFromName(r.inventoryStatus),
      );
}
