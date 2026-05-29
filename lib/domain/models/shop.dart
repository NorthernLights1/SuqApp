import 'package:equatable/equatable.dart';

class Shop extends Equatable {
  const Shop({
    required this.id,
    required this.name,
    required this.config,
    required this.createdAt,
  });

  final String id;
  final String name;
  final Map<String, dynamic> config;
  final DateTime createdAt;

  factory Shop.fromJson(Map<String, dynamic> json) => Shop(
        id: json['id'] as String,
        name: json['name'] as String,
        config: (json['config'] as Map<String, dynamic>?) ?? {},
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  @override
  List<Object?> get props => [id, name];
}

class Branch extends Equatable {
  const Branch({
    required this.id,
    required this.shopId,
    required this.name,
    this.address,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String shopId;
  final String name;
  final String? address;
  final bool isActive;
  final DateTime createdAt;

  factory Branch.fromJson(Map<String, dynamic> json) => Branch(
        id: json['id'] as String,
        shopId: json['shop_id'] as String,
        name: json['name'] as String,
        address: json['address'] as String?,
        isActive: json['is_active'] as bool,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  @override
  List<Object?> get props => [id, shopId, name];
}
