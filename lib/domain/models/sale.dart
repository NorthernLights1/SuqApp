import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

// ─── Enums ──────────────────────────────────────────────────────────────────

enum SaleStatus { completed, voided, refunded }

enum InventoryStatus { tracked, untracked, flagged }

enum DiscountType { percentage, fixed }

// ─── Sale ───────────────────────────────────────────────────────────────────

class Sale extends Equatable {
  const Sale({
    required this.id,
    required this.branchId,
    this.customerId,
    required this.cashierId,
    required this.paymentMethodId,
    required this.subtotal,
    required this.discountAmount,
    required this.total,
    required this.status,
    this.voidReason,
    this.voidedBy,
    this.voidedAt,
    required this.isCredit,
    this.notes,
    required this.createdAt,
    this.items = const [],
  });

  final String id;
  final String branchId;
  final String? customerId;
  final String cashierId;
  final String paymentMethodId;
  final Decimal subtotal;
  final Decimal discountAmount;
  final Decimal total;
  final SaleStatus status;
  final String? voidReason;
  final String? voidedBy;
  final DateTime? voidedAt;
  final bool isCredit;
  final String? notes;
  final DateTime createdAt;
  final List<SaleItem> items;

  factory Sale.fromJson(Map<String, dynamic> json) => Sale(
        id: json['id'] as String,
        branchId: json['branch_id'] as String,
        customerId: json['customer_id'] as String?,
        cashierId: json['cashier_id'] as String,
        paymentMethodId: json['payment_method_id'] as String,
        subtotal: Decimal.parse(json['subtotal'].toString()),
        discountAmount: Decimal.parse(json['discount_amount'].toString()),
        total: Decimal.parse(json['total'].toString()),
        status: SaleStatus.values.byName(json['status'] as String),
        voidReason: json['void_reason'] as String?,
        voidedBy: json['voided_by'] as String?,
        voidedAt: json['voided_at'] != null
            ? DateTime.parse(json['voided_at'] as String)
            : null,
        isCredit: json['is_credit'] as bool,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        items: (json['sale_items'] as List? ?? [])
            .map((e) => SaleItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [id, status, total, createdAt];
}

// ─── SaleItem ────────────────────────────────────────────────────────────────

class SaleItem extends Equatable {
  const SaleItem({
    required this.id,
    required this.saleId,
    this.productId,
    required this.productNameSnapshot,
    this.measurementUnitId,
    required this.quantity,
    required this.unitPrice,
    required this.discountAmount,
    required this.total,
    required this.inventoryStatus,
  });

  final String id;
  final String saleId;
  final String? productId;
  final String productNameSnapshot;
  final String? measurementUnitId;
  final Decimal quantity;
  final Decimal unitPrice;
  final Decimal discountAmount;
  final Decimal total;
  final InventoryStatus inventoryStatus;

  factory SaleItem.fromJson(Map<String, dynamic> json) => SaleItem(
        id: json['id'] as String,
        saleId: json['sale_id'] as String,
        productId: json['product_id'] as String?,
        productNameSnapshot: json['product_name_snapshot'] as String,
        measurementUnitId: json['measurement_unit_id'] as String?,
        quantity: Decimal.parse(json['quantity'].toString()),
        unitPrice: Decimal.parse(json['unit_price'].toString()),
        discountAmount: Decimal.parse(json['discount_amount'].toString()),
        total: Decimal.parse(json['total'].toString()),
        inventoryStatus:
            InventoryStatus.values.byName(json['inventory_status'] as String),
      );

  @override
  List<Object?> get props => [id, productNameSnapshot, quantity, unitPrice];
}

// ─── CartItem (local-only, not persisted) ────────────────────────────────────

class CartItem extends Equatable {
  const CartItem({
    this.productId,
    required this.productName,
    this.measurementUnitId,
    this.measurementUnitAbbr,
    required this.quantity,
    required this.unitPrice,
    required this.discountAmount,
    this.costPrice,
  });

  final String? productId;
  final String productName;
  final String? measurementUnitId;
  final String? measurementUnitAbbr;
  final Decimal quantity;
  final Decimal unitPrice;
  final Decimal discountAmount;
  final Decimal? costPrice;

  Decimal get lineTotal => (unitPrice * quantity) - discountAmount;

  CartItem copyWith({
    Decimal? quantity,
    Decimal? unitPrice,
    Decimal? discountAmount,
  }) =>
      CartItem(
        productId: productId,
        productName: productName,
        measurementUnitId: measurementUnitId,
        measurementUnitAbbr: measurementUnitAbbr,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice ?? this.unitPrice,
        discountAmount: discountAmount ?? this.discountAmount,
        costPrice: costPrice,
      );

  @override
  List<Object?> get props => [productId, productName, quantity, unitPrice];
}

// ─── Discount ────────────────────────────────────────────────────────────────

class Discount extends Equatable {
  const Discount({
    required this.id,
    required this.saleId,
    this.saleItemId,
    required this.givenBy,
    required this.type,
    required this.value,
    required this.reason,
    required this.createdAt,
  });

  final String id;
  final String saleId;
  final String? saleItemId;
  final String givenBy;
  final DiscountType type;
  final Decimal value;
  final String reason;
  final DateTime createdAt;

  factory Discount.fromJson(Map<String, dynamic> json) => Discount(
        id: json['id'] as String,
        saleId: json['sale_id'] as String,
        saleItemId: json['sale_item_id'] as String?,
        givenBy: json['given_by'] as String,
        type: DiscountType.values.byName(json['type'] as String),
        value: Decimal.parse(json['value'].toString()),
        reason: json['reason'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  @override
  List<Object?> get props => [id, saleId, value];
}

// ─── Customer ────────────────────────────────────────────────────────────────

class Customer extends Equatable {
  const Customer({
    required this.id,
    required this.name,
    this.phone,
    required this.creditBalance,
  });

  final String id;
  final String name;
  final String? phone;
  final Decimal creditBalance;

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String?,
        creditBalance: Decimal.parse((json['credit_balance'] ?? '0').toString()),
      );

  @override
  List<Object?> get props => [id, name];
}

// ─── PaymentMethod ───────────────────────────────────────────────────────────

class PaymentMethod extends Equatable {
  const PaymentMethod({
    required this.id,
    required this.name,
    required this.code,
    required this.isActive,
  });

  final String id;
  final String name;
  final String code;
  final bool isActive;

  factory PaymentMethod.fromJson(Map<String, dynamic> json) => PaymentMethod(
        id: json['id'] as String,
        name: json['name'] as String,
        code: json['code'] as String,
        isActive: json['is_active'] as bool,
      );

  @override
  List<Object?> get props => [id, code];
}
