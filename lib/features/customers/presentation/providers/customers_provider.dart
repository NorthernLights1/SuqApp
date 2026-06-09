import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/local/database_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/auth/presentation/providers/shop_provider.dart';
import '../../../../features/reports/presentation/providers/reports_provider.dart'
    show reportSummaryProvider;
import '../../data/customers_remote.dart';
import '../../domain/customer.dart';
import '../../domain/customers_repository.dart';

// Re-export so existing screen imports of Customer keep resolving.
export '../../domain/customer.dart' show Customer;

// Unsettled credit sale joined with its customer — used in the reconciliation screen.
class CreditSaleWithCustomer extends Equatable {
  const CreditSaleWithCustomer({
    required this.id,
    required this.total,
    required this.createdAt,
    required this.customerId,
    required this.customerName,
  });

  final String id;
  final Decimal total;
  final DateTime createdAt;
  final String customerId;
  final String customerName;

  factory CreditSaleWithCustomer.fromJson(Map<String, dynamic> j) {
    final customer = j['customers'] as Map<String, dynamic>? ?? {};
    return CreditSaleWithCustomer(
      id: j['id'] as String,
      total: Decimal.parse(j['total'].toString()),
      createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
      customerId: j['customer_id'] as String,
      customerName: customer['name'] as String? ?? 'Unknown',
    );
  }

  @override
  List<Object?> get props => [id];
}

// Lightweight model for a single unsettled credit sale shown on the customer screen.
class CreditSale extends Equatable {
  const CreditSale({
    required this.id,
    required this.total,
    required this.createdAt,
  });

  final String id;
  final Decimal total;
  final DateTime createdAt;

  factory CreditSale.fromJson(Map<String, dynamic> j) => CreditSale(
        id: j['id'] as String,
        total: Decimal.parse(j['total'].toString()),
        createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
      );

  @override
  List<Object?> get props => [id];
}

// ─── Providers ─────────────────────────────────────────────────────────────

final customersRepositoryProvider = Provider<CustomersRepository>((ref) {
  return CustomersRepository(
    CustomersRemote(ref.read(supabaseClientProvider)),
    ref.read(appDatabaseProvider),
  );
});

final customersProvider = FutureProvider<List<Customer>>((ref) async {
  final shop = await ref.watch(currentShopProvider.future);
  if (shop == null) return [];
  return ref.read(customersRepositoryProvider).getCustomers(shop.id);
});

final customerSalesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, customerId) async {
  final client = ref.read(supabaseClientProvider);
  final data = await client
      .from('sales')
      .select('id, total, status, created_at, is_credit, credit_settled_at')
      .eq('customer_id', customerId)
      .order('created_at', ascending: false)
      .limit(20);
  return (data as List).cast<Map<String, dynamic>>();
});

// Unsettled credit sales for a customer — no date filter; only disappear when settled.
final customerCreditSalesProvider =
    FutureProvider.family<List<CreditSale>, String>((ref, customerId) async {
  final client = ref.read(supabaseClientProvider);
  final data = await client
      .from('sales')
      .select('id, total, created_at')
      .eq('customer_id', customerId)
      .eq('is_credit', true)
      .eq('status', 'completed')
      .filter('credit_settled_at', 'is', null)
      .order('created_at', ascending: false);
  return (data as List).map((e) => CreditSale.fromJson(e)).toList();
});

// All unsettled credit sales across every customer for the current shop.
final outstandingCreditProvider =
    FutureProvider<List<CreditSaleWithCustomer>>((ref) async {
  final shop = await ref.watch(currentShopProvider.future);
  if (shop == null) return [];
  final client = ref.read(supabaseClientProvider);
  final data = await client
      .from('sales')
      .select('id, total, created_at, customer_id, customers(id, name)')
      .eq('is_credit', true)
      .eq('status', 'completed')
      .filter('credit_settled_at', 'is', null)
      .not('customer_id', 'is', null)
      .order('created_at', ascending: false);
  return (data as List)
      .where((e) => (e as Map<String, dynamic>)['customers'] != null)
      .map((e) => CreditSaleWithCustomer.fromJson(e as Map<String, dynamic>))
      .toList();
});

class CustomerFormNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> save({
    String? customerId,
    required String name,
    String? phone,
  }) async {
    final shop = await ref.read(currentShopProvider.future);
    if (shop == null) return false;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(customersRepositoryProvider).save(
            customerId: customerId,
            shopId: shop.id,
            name: name,
            phone: phone,
          );
      ref.invalidate(customersProvider);
    });
    return !state.hasError;
  }

  Future<bool> settleDebt(String customerId) async {
    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await client
          .from('customers')
          .update({'credit_balance': '0'}).eq('id', customerId);
      ref.invalidate(customersProvider);
    });
    return !state.hasError;
  }

  // Mark a specific credit sale as settled and reduce the customer's running balance.
  Future<bool> settleCreditSale({
    required String customerId,
    required String saleId,
    required Decimal saleTotal,
    required String settlementMethod, // 'cash' or 'bank_transfer'
    String? settlementNotes,
  }) async {
    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await client.from('sales').update({
        'credit_settled_at': DateTime.now().toIso8601String(),
        'credit_settlement_method': settlementMethod,
        if (settlementNotes != null && settlementNotes.isNotEmpty)
          'credit_settlement_notes': settlementNotes,
      }).eq('id', saleId);
      final data = await client
          .from('customers')
          .select('credit_balance')
          .eq('id', customerId)
          .single();
      final current = Decimal.parse(data['credit_balance'].toString());
      final newBalance =
          saleTotal >= current ? Decimal.zero : current - saleTotal;
      await client
          .from('customers')
          .update({'credit_balance': newBalance.toString()})
          .eq('id', customerId);
      ref.invalidate(customersProvider);
      ref.invalidate(customerCreditSalesProvider(customerId));
      ref.invalidate(outstandingCreditProvider);
      ref.invalidate(reportSummaryProvider);
    });
    return !state.hasError;
  }

  Future<bool> receivePayment(String customerId, Decimal amount) async {
    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final data = await client
          .from('customers')
          .select('credit_balance')
          .eq('id', customerId)
          .single();
      final current = Decimal.parse(data['credit_balance'].toString());
      final newBalance = amount >= current ? Decimal.zero : current - amount;
      await client
          .from('customers')
          .update({'credit_balance': newBalance.toString()})
          .eq('id', customerId);
      // When balance is fully cleared, settle all outstanding credit sales so they
      // disappear from the reconciliation screen automatically.
      if (newBalance == Decimal.zero) {
        await client
            .from('sales')
            .update({'credit_settled_at': DateTime.now().toIso8601String()})
            .eq('customer_id', customerId)
            .eq('is_credit', true)
            .eq('status', 'completed')
            .filter('credit_settled_at', 'is', null);
      }
      ref.invalidate(customersProvider);
      ref.invalidate(customerCreditSalesProvider(customerId));
      ref.invalidate(outstandingCreditProvider);
      ref.invalidate(reportSummaryProvider);
    });
    return !state.hasError;
  }
}

final customerFormProvider =
    AsyncNotifierProvider<CustomerFormNotifier, void>(CustomerFormNotifier.new);
