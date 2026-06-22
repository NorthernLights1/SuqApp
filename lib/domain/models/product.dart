import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

class Product extends Equatable {
  const Product({
    required this.id,
    required this.shopId,
    required this.name,
    this.categoryId,
    this.description,
    required this.measurementUnitId,
    required this.measurementUnitAbbr,
    required this.lowStockThreshold,
    this.sellingPrice,
    this.costPrice,
    required this.isActive,
  });

  final String id;
  final String shopId;
  final String name;
  final String? categoryId;
  final String? description;
  final String measurementUnitId;
  final String measurementUnitAbbr;
  final Decimal lowStockThreshold;
  final Decimal? sellingPrice;
  final Decimal? costPrice;
  final bool isActive;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        shopId: json['shop_id'] as String,
        name: json['name'] as String,
        categoryId: json['category_id'] as String?,
        description: json['description'] as String?,
        measurementUnitId: json['measurement_unit_id'] as String,
        measurementUnitAbbr:
            (json['measurement_units'] as Map<String, dynamic>?)?['abbreviation']
                as String? ??
            '',
        lowStockThreshold:
            Decimal.parse(json['low_stock_threshold'].toString()),
        sellingPrice: json['selling_price'] != null
            ? Decimal.parse(json['selling_price'].toString())
            : null,
        costPrice: json['cost_price'] != null
            ? Decimal.parse(json['cost_price'].toString())
            : null,
        isActive: json['is_active'] as bool,
      );

  Map<String, dynamic> toInsertJson({
    required String shopId,
    required String measurementUnitId,
  }) =>
      {
        'shop_id': shopId,
        'name': name,
        'category_id': categoryId,
        'measurement_unit_id': measurementUnitId,
        'low_stock_threshold': lowStockThreshold.toString(),
        'selling_price': sellingPrice?.toString(),
        'cost_price': costPrice?.toString(),
        'is_active': isActive,
      };

  @override
  List<Object?> get props => [id, name];
}
