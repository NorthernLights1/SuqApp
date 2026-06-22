import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  const Customer({
    required this.id,
    required this.shopId,
    required this.name,
    this.phone,
    required this.creditBalance,
    required this.createdAt,
  });

  final String id;
  final String shopId;
  final String name;
  final String? phone;
  final Decimal creditBalance;
  final DateTime createdAt;

  bool get hasDebt => creditBalance > Decimal.zero;

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json['id'] as String,
        shopId: json['shop_id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String?,
        creditBalance: Decimal.parse(json['credit_balance'].toString()),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  @override
  List<Object?> get props => [id, name, creditBalance];
}
