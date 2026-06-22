import 'package:decimal/decimal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../domain/models/product.dart';

class InventoryRemote {
  InventoryRemote(this._client);
  final SupabaseClient _client;

  // ─── Products ──────────────────────────────────────────────────────────────

  Future<List<Product>> getProducts(String shopId) async {
    final data = await _client
        .from('products')
        .select('id, shop_id, name, description, category_id, measurement_unit_id, low_stock_threshold, selling_price, cost_price, is_active, measurement_units(abbreviation)')
        .eq('shop_id', shopId)
        .eq('is_active', true)
        .order('name');
    return (data as List).map((e) => Product.fromJson(e)).toList();
  }

  Future<Product> createProduct({
    required String shopId,
    required String name,
    required String measurementUnitId,
    required Decimal lowStockThreshold,
    Decimal? sellingPrice,
    Decimal? costPrice,
    String? categoryId,
    String? description,
  }) async {
    final data = await _client.from('products').insert({
      'shop_id': shopId,
      'name': name.trim(),
      'description': description?.trim().isEmpty ?? true ? null : description?.trim(),
      'measurement_unit_id': measurementUnitId,
      'low_stock_threshold': lowStockThreshold.toString(),
      'selling_price': sellingPrice?.toString(),
      'cost_price': costPrice?.toString(),
      'category_id': categoryId,
      'is_active': true,
    }).select('id, shop_id, name, description, category_id, measurement_unit_id, low_stock_threshold, selling_price, cost_price, is_active, measurement_units(abbreviation)').single();
    return Product.fromJson(data);
  }

  Future<Product> updateProduct({
    required String productId,
    required String name,
    required String measurementUnitId,
    required Decimal lowStockThreshold,
    Decimal? sellingPrice,
    Decimal? costPrice,
    String? categoryId,
    String? description,
  }) async {
    final data = await _client.from('products').update({
      'name': name.trim(),
      'description': description?.trim().isEmpty ?? true ? null : description?.trim(),
      'measurement_unit_id': measurementUnitId,
      'low_stock_threshold': lowStockThreshold.toString(),
      'selling_price': sellingPrice?.toString(),
      'cost_price': costPrice?.toString(),
      'category_id': categoryId,
    }).eq('id', productId)
        .select('id, shop_id, name, description, category_id, measurement_unit_id, low_stock_threshold, selling_price, cost_price, is_active, measurement_units(abbreviation)')
        .single();
    return Product.fromJson(data);
  }

  Future<void> deactivateProduct(String productId) async {
    await _client
        .from('products')
        .update({'is_active': false})
        .eq('id', productId);
  }

  // ─── Stock levels ──────────────────────────────────────────────────────────

  Future<List<StockEntry>> getStockLevels(String branchId) async {
    final data = await _client
        .from('inventory')
        .select('product_id, quantity, expiry_date, updated_at, products(id, name, low_stock_threshold, selling_price, measurement_unit_id, measurement_units(abbreviation))')
        .eq('branch_id', branchId)
        .order('products(name)');
    return (data as List).map((e) => StockEntry.fromJson(e)).toList();
  }

  // Stock writes (opening / restock / manual / correction) are owned by
  // InventoryRepository, which queues an adjustment and replays it through the
  // atomic `apply_inventory_adjustment` RPC (see [applyAdjustment]). Direct
  // table writes were removed: migration 024 makes inventory writable only via
  // that RPC.

  // ─── Replay a queued adjustment ─────────────────────────────────────────────

  /// Applies a single pending stock op to the server. Idempotent on [id]:
  /// if a ledger row with that id already exists, it does nothing.
  ///
  /// Additive ops (opening_stock / restock) apply the locally-computed delta
  /// on top of the authoritative server quantity, so concurrent restocks from
  /// other devices compose. Absolute ops (manual / correction) override.
  Future<void> applyAdjustment({
    required String id,
    required String type,
    required String branchId,
    required String productId,
    required Decimal quantityBefore,
    required Decimal quantityAfter,
    required String adjustedBy,
    String? notes,
    DateTime? expiryDate,
    DateTime? createdAt,
  }) async {
    await _client.rpc('apply_inventory_adjustment', params: {
      'p_id': id,
      'p_type': type,
      'p_branch_id': branchId,
      'p_product_id': productId,
      'p_quantity_before': quantityBefore.toString(),
      'p_quantity_after': quantityAfter.toString(),
      'p_notes': notes,
      'p_expiry_date': expiryDate?.toIso8601String().substring(0, 10),
      // Preserve the offline recording time on replay (null online → now()).
      'p_created_at': createdAt?.toUtc().toIso8601String(),
    });
  }

  // ─── Product batches (wholesale) ────────────────────────────────────────────

  /// Insert a new batch. The server rollup trigger updates `inventory.quantity`.
  /// Used by the web path (no local DB) and by SyncService is NOT — the push
  /// there is a bulk upsert. [id] is client-generated (idempotent by UUID).
  Future<void> insertBatch({
    required String id,
    required String branchId,
    required String productId,
    String? batchNumber,
    DateTime? expiryDate,
    required Decimal quantity,
    Decimal? costPrice,
    String? createdBy,
  }) async {
    await _client.from('product_batches').insert({
      'id': id,
      'branch_id': branchId,
      'product_id': productId,
      'batch_number': batchNumber,
      'expiry_date': expiryDate?.toIso8601String().substring(0, 10),
      'quantity': quantity.toString(),
      'cost_price': costPrice?.toString(),
      'created_by': createdBy,
    });
  }

  /// Web/remote read of a product's live lots (no local DB). Computes
  /// remaining = received − Σ(non-deleted depletions) per lot, resolves the
  /// adder's name, and FEFO-orders (soonest expiry first, nulls last).
  Future<List<ProductBatchView>> getProductBatches(
      String branchId, String productId) async {
    final batchRows = (await _client
        .from('product_batches')
        .select(
            'id, batch_number, expiry_date, quantity, received_at, created_by')
        .eq('branch_id', branchId)
        .eq('product_id', productId)
        .isFilter('deleted_at', null)) as List;
    if (batchRows.isEmpty) return [];

    final ids = [for (final b in batchRows) b['id'] as String];

    // Depletion per lot from the ledger.
    final sibRows = (await _client
        .from('sale_item_batches')
        .select('batch_id, quantity')
        .inFilter('batch_id', ids)
        .isFilter('deleted_at', null)) as List;
    final depleted = <String, Decimal>{};
    for (final s in sibRows) {
      final bid = s['batch_id'] as String;
      depleted[bid] = (depleted[bid] ?? Decimal.zero) +
          (Decimal.tryParse(s['quantity'].toString()) ?? Decimal.zero);
    }

    // Per-lot corrections (positive delta = removed, negative = added back).
    final adjRows = (await _client
        .from('batch_adjustments')
        .select('batch_id, quantity_delta')
        .inFilter('batch_id', ids)
        .isFilter('deleted_at', null)) as List;
    final adjusted = <String, Decimal>{};
    for (final a in adjRows) {
      final bid = a['batch_id'] as String;
      adjusted[bid] = (adjusted[bid] ?? Decimal.zero) +
          (Decimal.tryParse(a['quantity_delta'].toString()) ?? Decimal.zero);
    }

    // Adder display names.
    final creatorIds = {
      for (final b in batchRows)
        if (b['created_by'] != null) b['created_by'] as String
    }.toList();
    final names = <String, String?>{};
    if (creatorIds.isNotEmpty) {
      final profRows = (await _client
          .from('profiles')
          .select('id, full_name')
          .inFilter('id', creatorIds)) as List;
      for (final p in profRows) {
        names[p['id'] as String] = p['full_name'] as String?;
      }
    }

    final views = [
      for (final b in batchRows)
        () {
          final received =
              Decimal.tryParse(b['quantity'].toString()) ?? Decimal.zero;
          return ProductBatchView(
            id: b['id'] as String,
            batchNumber: b['batch_number'] as String?,
            expiryDate: b['expiry_date'] != null
                ? DateTime.tryParse(b['expiry_date'] as String)
                : null,
            received: received,
            remaining: received -
                (depleted[b['id']] ?? Decimal.zero) -
                (adjusted[b['id']] ?? Decimal.zero),
            receivedAt:
                DateTime.tryParse(b['received_at']?.toString() ?? '') ??
                    DateTime.now(),
            addedByName: b['created_by'] == null
                ? null
                : names[b['created_by'] as String],
          );
        }()
    ].where((v) => v.remaining > Decimal.zero).toList();

    // FEFO: soonest expiry first, nulls last.
    views.sort((a, b) {
      if (a.expiryDate == null && b.expiryDate == null) return 0;
      if (a.expiryDate == null) return 1;
      if (b.expiryDate == null) return -1;
      return a.expiryDate!.compareTo(b.expiryDate!);
    });
    return views;
  }

  /// Web/remote per-lot correction insert; the server trigger recomputes.
  Future<void> insertBatchAdjustment({
    required String id,
    required String batchId,
    required String branchId,
    required String productId,
    required Decimal quantityDelta,
    required String reason,
    required String createdBy,
  }) async {
    await _client.from('batch_adjustments').insert({
      'id': id,
      'batch_id': batchId,
      'branch_id': branchId,
      'product_id': productId,
      'quantity_delta': quantityDelta.toString(),
      'reason': reason,
      'created_by': createdBy,
    });
  }

  // ─── Measurement units ─────────────────────────────────────────────────────

  Future<List<MeasurementUnit>> getMeasurementUnits(String shopId) async {
    final data = await _client
        .from('measurement_units')
        .select('id, name, abbreviation')
        .or('shop_id.eq.$shopId,shop_id.is.null')
        .order('name');
    return (data as List).map((e) => MeasurementUnit.fromJson(e)).toList();
  }

  Future<MeasurementUnit> createMeasurementUnit({
    required String shopId,
    required String name,
    required String abbreviation,
  }) async {
    final data = await _client
        .from('measurement_units')
        .insert({
          'shop_id': shopId,
          'name': name.trim(),
          'abbreviation': abbreviation.trim(),
          'is_system': false,
        })
        .select('id, name, abbreviation')
        .single();
    return MeasurementUnit.fromJson(data);
  }

  // ─── Product categories ────────────────────────────────────────────────────

  Future<List<ProductCategory>> getProductCategories(String shopId) async {
    final data = await _client
        .from('product_categories')
        .select('id, name')
        .eq('shop_id', shopId)
        .order('name');
    return (data as List).map((e) => ProductCategory.fromJson(e)).toList();
  }

  Future<ProductCategory> createProductCategory({
    required String shopId,
    required String name,
  }) async {
    final data = await _client
        .from('product_categories')
        .insert({'shop_id': shopId, 'name': name.trim()})
        .select('id, name')
        .single();
    return ProductCategory.fromJson(data);
  }
}

// ─── Local models ─────────────────────────────────────────────────────────────

class StockEntry {
  const StockEntry({
    required this.productId,
    required this.productName,
    required this.measurementUnitId,
    required this.quantity,
    required this.lowStockThreshold,
    this.sellingPrice,
    required this.unitAbbr,
    this.expiryDate,
    required this.updatedAt,
  });

  final String productId;
  final String productName;
  final String measurementUnitId;
  final Decimal quantity;
  final Decimal lowStockThreshold;
  final Decimal? sellingPrice;
  final String unitAbbr;
  final DateTime? expiryDate;
  final DateTime updatedAt;

  StockEntry withQuantity(Decimal q) => StockEntry(
        productId: productId,
        productName: productName,
        measurementUnitId: measurementUnitId,
        quantity: q,
        lowStockThreshold: lowStockThreshold,
        sellingPrice: sellingPrice,
        unitAbbr: unitAbbr,
        expiryDate: expiryDate,
        updatedAt: updatedAt,
      );

  bool get isLowStock => quantity <= lowStockThreshold && lowStockThreshold > Decimal.zero;

  bool get isExpired {
    if (expiryDate == null) return false;
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return expiryDate!.isBefore(today);
  }

  bool get isExpiringSoon {
    if (expiryDate == null || isExpired) return false;
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return expiryDate!.isBefore(today.add(const Duration(days: 7)));
  }

  factory StockEntry.fromJson(Map<String, dynamic> json) {
    final product = json['products'] as Map<String, dynamic>? ?? {};
    final unit = product['measurement_units'] as Map<String, dynamic>? ?? {};
    return StockEntry(
      productId: json['product_id'] as String,
      productName: product['name'] as String? ?? '',
      measurementUnitId: product['measurement_unit_id'] as String? ?? '',
      quantity: Decimal.parse(json['quantity'].toString()),
      lowStockThreshold:
          Decimal.parse((product['low_stock_threshold'] ?? '0').toString()),
      sellingPrice: product['selling_price'] != null
          ? Decimal.parse(product['selling_price'].toString())
          : null,
      unitAbbr: unit['abbreviation'] as String? ?? '',
      expiryDate: json['expiry_date'] != null
          ? DateTime.tryParse(json['expiry_date'] as String)
          : null,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

/// A single batch/lot for display: its remaining (received − depleted) quantity
/// and expiry status. Built locally from the batch mirror + depletion ledger.
class ProductBatchView {
  const ProductBatchView({
    required this.id,
    this.batchNumber,
    this.expiryDate,
    required this.remaining,
    required this.received,
    required this.receivedAt,
    this.addedByName,
  });

  final String id;
  final String? batchNumber;
  final DateTime? expiryDate;
  final Decimal remaining;

  /// Quantity originally received in this lot (immutable; remaining ≤ received).
  final Decimal received;

  /// When the lot was added (stock-in / opening stock).
  final DateTime receivedAt;

  /// Display name of who added the lot, resolved from the profiles mirror;
  /// null for backfilled/server-origin rows or an unknown user.
  final String? addedByName;

  static DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  bool get isExpired => expiryDate != null && expiryDate!.isBefore(_today);

  /// Within 30 days (wholesale plans ahead further than the retail 7-day window).
  bool get isExpiringSoon =>
      expiryDate != null &&
      !isExpired &&
      expiryDate!.isBefore(_today.add(const Duration(days: 30)));
}

class MeasurementUnit {
  const MeasurementUnit({
    required this.id,
    required this.name,
    required this.abbreviation,
  });

  final String id;
  final String name;
  final String abbreviation;

  factory MeasurementUnit.fromJson(Map<String, dynamic> json) =>
      MeasurementUnit(
        id: json['id'] as String,
        name: json['name'] as String,
        abbreviation: json['abbreviation'] as String,
      );

  // Value equality on id so a DropdownButton can match a freshly-created unit
  // against the refetched list (different instance, same id).
  @override
  bool operator ==(Object other) =>
      other is MeasurementUnit && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => '$name ($abbreviation)';
}

class ProductCategory {
  const ProductCategory({required this.id, required this.name});

  final String id;
  final String name;

  factory ProductCategory.fromJson(Map<String, dynamic> json) =>
      ProductCategory(
        id: json['id'] as String,
        name: json['name'] as String,
      );
}
