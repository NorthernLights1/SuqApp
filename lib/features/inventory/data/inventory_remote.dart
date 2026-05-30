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

  Future<void> setOpeningStock({
    required String branchId,
    required String productId,
    required Decimal quantity,
    required String adjustedBy,
    DateTime? expiryDate,
  }) async {
    await _client.from('inventory').upsert({
      'branch_id': branchId,
      'product_id': productId,
      'quantity': quantity.toString(),
      'expiry_date': expiryDate?.toIso8601String().substring(0, 10),
      'updated_at': DateTime.now().toIso8601String(),
    });

    await _client.from('inventory_adjustments').insert({
      'branch_id': branchId,
      'product_id': productId,
      'adjusted_by': adjustedBy,
      'type': 'opening_stock',
      'quantity_before': '0',
      'quantity_after': quantity.toString(),
    });
  }

  Future<void> manualAdjustment({
    required String branchId,
    required String productId,
    required Decimal newQuantity,
    required Decimal currentQuantity,
    required String adjustedBy,
    required String notes,
    DateTime? expiryDate,
  }) async {
    await _client.from('inventory').upsert({
      'branch_id': branchId,
      'product_id': productId,
      'quantity': newQuantity.toString(),
      'expiry_date': expiryDate?.toIso8601String().substring(0, 10),
      'updated_at': DateTime.now().toIso8601String(),
    });

    await _client.from('inventory_adjustments').insert({
      'branch_id': branchId,
      'product_id': productId,
      'adjusted_by': adjustedBy,
      'type': 'manual',
      'quantity_before': currentQuantity.toString(),
      'quantity_after': newQuantity.toString(),
      'notes': notes,
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
