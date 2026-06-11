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

// Sum of the embedded credit_payments(amount) rows on a sale select.
Decimal _paidFromJson(Map<String, dynamic> j) {
  final payments = j['credit_payments'] as List? ?? const [];
  return payments.fold(
    Decimal.zero,
    (sum, p) => sum + Decimal.parse((p['amount'] ?? '0').toString()),
  );
}

// A single recorded payment against a credit sale (the dispute audit trail).
class CreditPayment extends Equatable {
  const CreditPayment({
    required this.id,
    required this.amount,
    required this.method,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final Decimal amount;
  final String method; // 'cash' | 'bank_transfer'
  final String? notes;
  final DateTime createdAt;

  factory CreditPayment.fromJson(Map<String, dynamic> j) => CreditPayment(
        id: j['id'] as String,
        amount: Decimal.parse(j['amount'].toString()),
        method: j['method'] as String,
        notes: j['notes'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
      );

  @override
  List<Object?> get props => [id];
}

// Unsettled credit sale joined with its customer — used in the reconciliation screen.
class CreditSaleWithCustomer extends Equatable {
  const CreditSaleWithCustomer({
    required this.id,
    required this.total,
    required this.paid,
    required this.createdAt,
    required this.customerId,
    required this.customerName,
  });

  final String id;
  final Decimal total;
  final Decimal paid; // sum of recorded payments so far
  final DateTime createdAt;
  final String customerId;
  final String customerName;

  Decimal get remaining {
    final r = total - paid;
    return r > Decimal.zero ? r : Decimal.zero;
  }

  factory CreditSaleWithCustomer.fromJson(Map<String, dynamic> j) {
    final customer = j['customers'] as Map<String, dynamic>? ?? {};
    return CreditSaleWithCustomer(
      id: j['id'] as String,
      total: Decimal.parse(j['total'].toString()),
      paid: _paidFromJson(j),
      createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
      customerId: j['customer_id'] as String,
      customerName: customer['name'] as String? ?? 'Unknown',
    );
  }

  @override
  List<Object?> get props => [id, paid];
}

// Lightweight model for a single unsettled credit sale shown on the customer screen.
class CreditSale extends Equatable {
  const CreditSale({
    required this.id,
    required this.total,
    required this.paid,
    required this.createdAt,
  });

  final String id;
  final Decimal total;
  final Decimal paid;
  final DateTime createdAt;

  Decimal get remaining {
    final r = total - paid;
    return r > Decimal.zero ? r : Decimal.zero;
  }

  factory CreditSale.fromJson(Map<String, dynamic> j) => CreditSale(
        id: j['id'] as String,
        total: Decimal.parse(j['total'].toString()),
        paid: _paidFromJson(j),
        createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
      );

  @override
  List<Object?> get props => [id, paid];
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

// Unsettled credit sales for a customer — no date filter; only disappear when
// fully paid. Embeds credit_payments so each bill knows how much is left.
final customerCreditSalesProvider =
    FutureProvider.family<List<CreditSale>, String>((ref, customerId) async {
  final client = ref.read(supabaseClientProvider);
  final data = await client
      .from('sales')
      .select('id, total, created_at, credit_payments(amount)')
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
      .select(
          'id, total, created_at, customer_id, customers(id, name), credit_payments(amount)')
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

// customerId -> total still owed (sum of remaining across their unsettled
// bills). Drives the "owes" badge/amount on the customer list and detail.
final customerOutstandingMapProvider =
    FutureProvider<Map<String, Decimal>>((ref) async {
  final sales = await ref.watch(outstandingCreditProvider.future);
  final map = <String, Decimal>{};
  for (final s in sales) {
    map[s.customerId] = (map[s.customerId] ?? Decimal.zero) + s.remaining;
  }
  return map;
});

// Payment history for one credit sale (newest first), for the dispute trail.
final creditPaymentsProvider =
    FutureProvider.family<List<CreditPayment>, String>((ref, saleId) async {
  final client = ref.read(supabaseClientProvider);
  final data = await client
      .from('credit_payments')
      .select('id, amount, method, notes, created_at')
      .eq('sale_id', saleId)
      .order('created_at', ascending: false);
  return (data as List)
      .map((e) => CreditPayment.fromJson(e as Map<String, dynamic>))
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

  /// Record a payment against a single credit sale. [amount] may be less than
  /// what's left (a partial payment) — the bill stays open until the recorded
  /// payments cover its total, at which point the sale is stamped settled.
  /// Each call adds a timestamped row to credit_payments (the dispute trail).
  Future<bool> recordCreditPayment({
    required String customerId,
    required String saleId,
    required Decimal saleTotal,
    required Decimal amount,
    required String method, // 'cash' | 'bank_transfer'
    String? notes,
  }) async {
    if (amount <= Decimal.zero) return false;
    final client = ref.read(supabaseClientProvider);
    final userId = ref.read(currentUserIdProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // 1) Record the payment (the audit trail).
      await client.from('credit_payments').insert({
        'sale_id': saleId,
        'customer_id': customerId,
        'amount': amount.toString(),
        'method': method,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        'recorded_by': userId,
      });
      // 2) Recompute total paid from the server to decide if the bill is
      //    cleared (avoids a stale client-side balance).
      final rows = await client
          .from('credit_payments')
          .select('amount')
          .eq('sale_id', saleId);
      final paid = (rows as List).fold<Decimal>(
        Decimal.zero,
        (s, r) => s + Decimal.parse((r['amount'] ?? '0').toString()),
      );
      // 3) Fully paid? stamp the sale settled and mirror it locally so the
      //    offline sales list reflects it.
      if (paid >= saleTotal) {
        await client.from('sales').update({
          'credit_settled_at': DateTime.now().toIso8601String(),
          'credit_settlement_method': method,
          if (notes != null && notes.isNotEmpty)
            'credit_settlement_notes': notes,
        }).eq('id', saleId);
        await ref.read(appDatabaseProvider)?.markSaleCreditSettled(saleId);
      }
      ref.invalidate(customersProvider);
      ref.invalidate(customerCreditSalesProvider(customerId));
      ref.invalidate(outstandingCreditProvider);
      ref.invalidate(creditPaymentsProvider(saleId));
      ref.invalidate(reportSummaryProvider);
    });
    return !state.hasError;
  }
}

final customerFormProvider =
    AsyncNotifierProvider<CustomerFormNotifier, void>(CustomerFormNotifier.new);
