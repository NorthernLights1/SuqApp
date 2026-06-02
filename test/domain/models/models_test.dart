import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suq/domain/models/product.dart';
import 'package:suq/domain/models/sale.dart';

void main() {
  // ── CartItem ──────────────────────────────────────────────────────────────

  group('CartItem.lineTotal', () {
    test('price × qty when no discount', () {
      final item = CartItem(
        productName: 'Bread',
        quantity: Decimal.parse('3'),
        unitPrice: Decimal.parse('25'),
        discountAmount: Decimal.zero,
      );
      expect(item.lineTotal, Decimal.parse('75'));
    });

    test('subtracts per-item discount', () {
      final item = CartItem(
        productName: 'Bread',
        quantity: Decimal.parse('4'),
        unitPrice: Decimal.parse('10'),
        discountAmount: Decimal.parse('5'),
      );
      // (10 × 4) − 5 = 35
      expect(item.lineTotal, Decimal.parse('35'));
    });

    test('fractional quantity', () {
      final item = CartItem(
        productName: 'Oil',
        quantity: Decimal.parse('1.5'),
        unitPrice: Decimal.parse('100'),
        discountAmount: Decimal.zero,
      );
      expect(item.lineTotal, Decimal.parse('150'));
    });

    test('zero when discount equals full price', () {
      final item = CartItem(
        productName: 'Gift',
        quantity: Decimal.one,
        unitPrice: Decimal.parse('20'),
        discountAmount: Decimal.parse('20'),
      );
      expect(item.lineTotal, Decimal.zero);
    });

    test('fractional unit price precision', () {
      final item = CartItem(
        productName: 'Rice',
        quantity: Decimal.parse('3'),
        unitPrice: Decimal.parse('33.33'),
        discountAmount: Decimal.zero,
      );
      expect(item.lineTotal, Decimal.parse('99.99'));
    });
  });

  group('CartItem.copyWith', () {
    final base = CartItem(
      productId: 'p-1',
      productName: 'Rice',
      measurementUnitId: 'mu-1',
      measurementUnitAbbr: 'kg',
      quantity: Decimal.parse('2'),
      unitPrice: Decimal.parse('50'),
      discountAmount: Decimal.parse('5'),
      costPrice: Decimal.parse('30'),
    );

    test('replaces only quantity', () {
      final copy = base.copyWith(quantity: Decimal.parse('10'));
      expect(copy.quantity, Decimal.parse('10'));
      expect(copy.productId, 'p-1');
      expect(copy.productName, 'Rice');
      expect(copy.unitPrice, Decimal.parse('50'));
      expect(copy.discountAmount, Decimal.parse('5'));
      expect(copy.costPrice, Decimal.parse('30'));
    });

    test('replaces only discount', () {
      final copy = base.copyWith(discountAmount: Decimal.zero);
      expect(copy.discountAmount, Decimal.zero);
      expect(copy.quantity, Decimal.parse('2'));
    });

    test('replaces only unit price', () {
      final copy = base.copyWith(unitPrice: Decimal.parse('60'));
      expect(copy.unitPrice, Decimal.parse('60'));
      expect(copy.productName, 'Rice');
    });

    test('lineTotal recalculates after copyWith', () {
      final copy = base.copyWith(quantity: Decimal.parse('3'));
      // (50 × 3) − 5 = 145
      expect(copy.lineTotal, Decimal.parse('145'));
    });
  });

  // ── Product.fromJson ──────────────────────────────────────────────────────

  group('Product.fromJson', () {
    test('parses fully populated JSON', () {
      final p = Product.fromJson({
        'id': 'p-1',
        'shop_id': 'shop-1',
        'name': 'Teff Flour',
        'category_id': 'cat-1',
        'description': 'Fine grind',
        'measurement_unit_id': 'mu-1',
        'measurement_units': {'abbreviation': 'kg'},
        'low_stock_threshold': '5',
        'selling_price': '120.00',
        'cost_price': '80.50',
        'is_active': true,
      });
      expect(p.id, 'p-1');
      expect(p.shopId, 'shop-1');
      expect(p.name, 'Teff Flour');
      expect(p.categoryId, 'cat-1');
      expect(p.measurementUnitAbbr, 'kg');
      expect(p.sellingPrice, Decimal.parse('120.00'));
      expect(p.costPrice, Decimal.parse('80.50'));
      expect(p.lowStockThreshold, Decimal.parse('5'));
      expect(p.isActive, isTrue);
    });

    test('handles null selling_price and cost_price', () {
      final p = Product.fromJson({
        'id': 'p-2',
        'shop_id': 'shop-1',
        'name': 'Salt',
        'measurement_unit_id': 'mu-1',
        'measurement_units': {'abbreviation': 'g'},
        'low_stock_threshold': '100',
        'selling_price': null,
        'cost_price': null,
        'is_active': true,
      });
      expect(p.sellingPrice, isNull);
      expect(p.costPrice, isNull);
    });

    test('returns empty string when measurement_units is null', () {
      final p = Product.fromJson({
        'id': 'p-3',
        'shop_id': 'shop-1',
        'name': 'Sugar',
        'measurement_unit_id': 'mu-1',
        'measurement_units': null,
        'low_stock_threshold': '50',
        'selling_price': '30',
        'cost_price': null,
        'is_active': true,
      });
      expect(p.measurementUnitAbbr, '');
    });

    test('handles numeric low_stock_threshold from DB', () {
      final p = Product.fromJson({
        'id': 'p-4',
        'shop_id': 'shop-1',
        'name': 'Oil',
        'measurement_unit_id': 'mu-1',
        'measurement_units': {'abbreviation': 'L'},
        'low_stock_threshold': 10,
        'selling_price': 250,
        'cost_price': 180,
        'is_active': false,
      });
      expect(p.sellingPrice, Decimal.parse('250'));
      expect(p.lowStockThreshold, Decimal.parse('10'));
      expect(p.isActive, isFalse);
    });

    test('toInsertJson includes all required fields', () {
      final p = Product.fromJson({
        'id': 'p-5',
        'shop_id': 'shop-1',
        'name': 'Tea',
        'category_id': null,
        'measurement_unit_id': 'mu-1',
        'measurement_units': {'abbreviation': 'pkg'},
        'low_stock_threshold': '5',
        'selling_price': '45',
        'cost_price': '30',
        'is_active': true,
      });
      final json = p.toInsertJson(shopId: 'shop-1', measurementUnitId: 'mu-1');
      expect(json['shop_id'], 'shop-1');
      expect(json['name'], 'Tea');
      expect(json['selling_price'], '45');
      expect(json['cost_price'], '30');
      expect(json['is_active'], isTrue);
    });
  });

  // ── Customer.fromJson ─────────────────────────────────────────────────────

  group('Customer.fromJson', () {
    test('parses all fields', () {
      final c = Customer.fromJson({
        'id': 'c-1',
        'name': 'Abebe Kebede',
        'phone': '+251911000000',
        'credit_balance': '150.50',
      });
      expect(c.id, 'c-1');
      expect(c.name, 'Abebe Kebede');
      expect(c.phone, '+251911000000');
      expect(c.creditBalance, Decimal.parse('150.50'));
    });

    test('defaults credit_balance to 0 when null', () {
      final c = Customer.fromJson({
        'id': 'c-2',
        'name': 'Lemma',
        'phone': null,
        'credit_balance': null,
      });
      expect(c.creditBalance, Decimal.zero);
      expect(c.phone, isNull);
    });

    test('parses integer credit_balance', () {
      final c = Customer.fromJson({
        'id': 'c-3',
        'name': 'Kebede',
        'phone': null,
        'credit_balance': 200,
      });
      expect(c.creditBalance, Decimal.parse('200'));
    });
  });

  // ── Sale.fromJson ─────────────────────────────────────────────────────────

  group('Sale.fromJson', () {
    final Map<String, dynamic> base = {
      'id': 'sale-1',
      'branch_id': 'b-1',
      'customer_id': null,
      'cashier_id': 'user-1',
      'payment_method_id': 'pm-1',
      'subtotal': '200.00',
      'discount_amount': '0.00',
      'total': '200.00',
      'status': 'completed',
      'void_reason': null,
      'voided_by': null,
      'voided_at': null,
      'is_credit': false,
      'notes': null,
      'created_at': '2026-06-01T10:00:00.000Z',
      'sale_items': [],
    };

    test('parses completed sale with no items', () {
      final sale = Sale.fromJson(base);
      expect(sale.id, 'sale-1');
      expect(sale.status, SaleStatus.completed);
      expect(sale.total, Decimal.parse('200.00'));
      expect(sale.isCredit, isFalse);
      expect(sale.items, isEmpty);
    });

    test('Decimal precision — total not corrupted by float', () {
      final sale = Sale.fromJson({...base, 'total': '99.99'});
      expect(sale.total.toString(), '99.99');
    });

    test('parses credit sale flag', () {
      final sale = Sale.fromJson({...base, 'is_credit': true});
      expect(sale.isCredit, isTrue);
    });

    test('parses voided sale with reason and timestamp', () {
      final sale = Sale.fromJson({
        ...base,
        'status': 'voided',
        'void_reason': 'wrong item',
        'voided_by': 'user-1',
        'voided_at': '2026-06-01T11:00:00.000Z',
      });
      expect(sale.status, SaleStatus.voided);
      expect(sale.voidReason, 'wrong item');
      expect(sale.voidedBy, 'user-1');
      expect(sale.voidedAt, isNotNull);
    });

    test('parses sale with nested items', () {
      final sale = Sale.fromJson({
        ...base,
        'sale_items': [
          {
            'id': 'item-1',
            'sale_id': 'sale-1',
            'product_id': 'p-1',
            'product_name_snapshot': 'Bread',
            'measurement_unit_id': 'mu-1',
            'quantity': '2',
            'unit_price': '100',
            'discount_amount': '0',
            'total': '200',
            'inventory_status': 'tracked',
          }
        ],
      });
      expect(sale.items.length, 1);
      expect(sale.items.first.productNameSnapshot, 'Bread');
      expect(sale.items.first.inventoryStatus, InventoryStatus.tracked);
      expect(sale.items.first.quantity, Decimal.parse('2'));
    });
  });

  // ── SaleItem.fromJson ─────────────────────────────────────────────────────

  group('SaleItem.fromJson', () {
    test('parses tracked item', () {
      final item = SaleItem.fromJson({
        'id': 'item-1',
        'sale_id': 'sale-1',
        'product_id': 'p-1',
        'product_name_snapshot': 'Teff',
        'measurement_unit_id': 'mu-1',
        'quantity': '3',
        'unit_price': '50',
        'discount_amount': '5',
        'total': '145',
        'inventory_status': 'tracked',
      });
      expect(item.inventoryStatus, InventoryStatus.tracked);
      expect(item.quantity, Decimal.parse('3'));
      expect(item.discountAmount, Decimal.parse('5'));
      expect(item.productId, 'p-1');
    });

    test('parses untracked item with null productId', () {
      final item = SaleItem.fromJson({
        'id': 'item-2',
        'sale_id': 'sale-1',
        'product_id': null,
        'product_name_snapshot': 'Custom Item',
        'measurement_unit_id': null,
        'quantity': '1',
        'unit_price': '25',
        'discount_amount': '0',
        'total': '25',
        'inventory_status': 'untracked',
      });
      expect(item.inventoryStatus, InventoryStatus.untracked);
      expect(item.productId, isNull);
      expect(item.measurementUnitId, isNull);
    });
  });

  // ── PaymentMethod.fromJson ────────────────────────────────────────────────

  group('PaymentMethod.fromJson', () {
    test('parses active payment method', () {
      final pm = PaymentMethod.fromJson({
        'id': 'pm-1',
        'name': 'Cash',
        'code': 'cash',
        'is_active': true,
      });
      expect(pm.id, 'pm-1');
      expect(pm.code, 'cash');
      expect(pm.isActive, isTrue);
    });

    test('parses inactive payment method', () {
      final pm = PaymentMethod.fromJson({
        'id': 'pm-2',
        'name': 'Cheque',
        'code': 'cheque',
        'is_active': false,
      });
      expect(pm.isActive, isFalse);
    });
  });
}
