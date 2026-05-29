import 'package:decimal/decimal.dart';
import '../../../domain/models/product.dart';
import '../../../domain/models/sale.dart';
import '../data/sales_remote.dart';

abstract interface class ISalesRepository {
  Future<List<Product>> searchProducts(String shopId, String query);
  Future<List<PaymentMethod>> getPaymentMethods(String shopId);
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
  SalesRepository(this._remote);
  final SalesRemote _remote;

  @override
  Future<List<Product>> searchProducts(String shopId, String query) =>
      _remote.searchProducts(shopId, query);

  @override
  Future<List<PaymentMethod>> getPaymentMethods(String shopId) =>
      _remote.getPaymentMethods(shopId);

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
  }) =>
      _remote.createSale(
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

  @override
  Future<void> voidSale({
    required String saleId,
    required String voidedBy,
    required String reason,
    required String branchId,
  }) =>
      _remote.voidSale(
        saleId: saleId,
        voidedBy: voidedBy,
        reason: reason,
        branchId: branchId,
      );

  @override
  Future<Sale> getSale(String saleId) => _remote.getSale(saleId);

  @override
  Future<List<Sale>> getSalesForBranch({
    required String branchId,
    required DateTime from,
    required DateTime to,
  }) =>
      _remote.getSalesForBranch(branchId: branchId, from: from, to: to);

  @override
  Future<Map<String, Decimal>> getTodayTotals(String branchId) =>
      _remote.getTodayTotals(branchId);
}
