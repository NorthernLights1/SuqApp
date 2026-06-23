import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/sync_providers.dart';
import '../../../../data/local/database_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/auth/presentation/providers/shop_provider.dart';
import '../../../../features/reports/presentation/providers/reports_provider.dart'
    show reportSummaryProvider;
import '../../../../features/sales/presentation/providers/sales_provider.dart'
    show salesListProvider;
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

Decimal _refundedFromJson(Map<String, dynamic> j) {
  final items = j['sale_items'] as List? ?? const [];
  var total = Decimal.zero;
  for (final item in items) {
    final refunds =
        (item as Map<String, dynamic>)['refund_items'] as List? ?? const [];
    for (final refundItem in refunds) {
      final ri = refundItem as Map<String, dynamic>;
      final refund = ri['refunds'] as Map<String, dynamic>?;
      if (ri['deleted_at'] == null && refund?['deleted_at'] == null) {
        total += Decimal.parse((ri['amount'] ?? '0').toString());
      }
    }
  }
  return total;
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
  CreditSaleWithCustomer({
    required this.id,
    required this.total,
    required this.paid,
    Decimal? refunded,
    required this.createdAt,
    required this.customerId,
    required this.customerName,
  }) : refunded = refunded ?? Decimal.zero;

  final String id;
  final Decimal total;
  final Decimal paid; // sum of recorded payments so far
  final Decimal refunded;
  final DateTime createdAt;
  final String customerId;
  final String customerName;

  Decimal get remaining {
    final r = total - paid - refunded;
    return r > Decimal.zero ? r : Decimal.zero;
  }

  factory CreditSaleWithCustomer.fromJson(Map<String, dynamic> j) {
    final customer = j['customers'] as Map<String, dynamic>? ?? {};
    return CreditSaleWithCustomer(
      id: j['id'] as String,
      total: Decimal.parse(j['total'].toString()),
      paid: _paidFromJson(j),
      refunded: _refundedFromJson(j),
      createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
      customerId: j['customer_id'] as String,
      customerName: customer['name'] as String? ?? 'Unknown',
    );
  }

  @override
  List<Object?> get props => [id, paid, refunded];
}

// Lightweight model for a single unsettled credit sale shown on the customer screen.
class CreditSale extends Equatable {
  CreditSale({
    required this.id,
    required this.total,
    required this.paid,
    Decimal? refunded,
    required this.createdAt,
  }) : refunded = refunded ?? Decimal.zero;

  final String id;
  final Decimal total;
  final Decimal paid;
  final Decimal refunded;
  final DateTime createdAt;

  Decimal get remaining {
    final r = total - paid - refunded;
    return r > Decimal.zero ? r : Decimal.zero;
  }

  factory CreditSale.fromJson(Map<String, dynamic> j) => CreditSale(
    id: j['id'] as String,
    total: Decimal.parse(j['total'].toString()),
    paid: _paidFromJson(j),
    refunded: _refundedFromJson(j),
    createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
  );

  @override
  List<Object?> get props => [id, paid, refunded];
}

// ─── Providers ─────────────────────────────────────────────────────────────

final customersRepositoryProvider = Provider<CustomersRepository>((ref) {
  return CustomersRepository(
    CustomersRemote(ref.read(supabaseClientProvider)),
    ref.watch(appDatabaseProvider),
  );
});

final customersProvider = FutureProvider<List<Customer>>((ref) async {
  final shop = await ref.watch(currentShopProvider.future);
  if (shop == null) return [];
  return ref.read(customersRepositoryProvider).getCustomers(shop.id);
});

final customerSalesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      customerId,
    ) async {
      // Local-first: the mirror (seeded + synced, incl. the user's own writes) is
      // authoritative and works offline. Web (no local DB) reads from the server.
      final db = ref.read(appDatabaseProvider);
      if (db != null) {
        final rows = await db.getSalesByCustomer(customerId);
        return rows
            .map(
              (r) => <String, dynamic>{
                'id': r.id,
                'total': r.total.toString(),
                'status': r.status,
                'created_at': r.createdAt.toIso8601String(),
                'is_credit': r.isCredit,
                'credit_settled_at': r.creditSettledAt?.toIso8601String(),
              },
            )
            .toList();
      }
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
final customerCreditSalesProvider = FutureProvider.family<List<CreditSale>, String>((
  ref,
  customerId,
) async {
  // Local-first: unsettled credits + payments come from the mirror, so a
  // just-recorded payment is reflected immediately (and offline). Web → server.
  final db = ref.read(appDatabaseProvider);
  if (db != null) {
    final rows = (await db.getUnsettledCreditSales())
        .where((r) => r.customerId == customerId)
        .toList();
    final saleIds = rows.map((r) => r.id).toList();
    final paid = await db.getPaidBySale(saleIds);
    final refunded = await db.getRefundedAmountBySale(saleIds);
    return rows
        .map(
          (r) => CreditSale(
            id: r.id,
            total: r.total,
            paid: paid[r.id] ?? Decimal.zero,
            refunded: refunded[r.id] ?? Decimal.zero,
            createdAt: r.createdAt,
          ),
        )
        .toList();
  }
  final client = ref.read(supabaseClientProvider);
  final data = await client
      .from('sales')
      .select(
        'id, total, created_at, credit_payments(amount), sale_items(refund_items(amount, deleted_at, refunds(deleted_at)))',
      )
      .eq('customer_id', customerId)
      .eq('is_credit', true)
      .eq('status', 'completed')
      .filter('credit_settled_at', 'is', null)
      .order('created_at', ascending: false);
  return (data as List).map((e) => CreditSale.fromJson(e)).toList();
});

// All unsettled credit sales across every customer for the current shop.
final outstandingCreditProvider = FutureProvider<List<CreditSaleWithCustomer>>((
  ref,
) async {
  final shop = await ref.watch(currentShopProvider.future);
  if (shop == null) return [];
  // Local-first: assemble unsettled credits from the mirror (sales + payments +
  // customers) so balances reflect own writes instantly and work offline.
  final db = ref.read(appDatabaseProvider);
  if (db != null) {
    final rows = (await db.getUnsettledCreditSales())
        .where((r) => r.customerId != null)
        .toList();
    final saleIds = rows.map((r) => r.id).toList();
    final paid = await db.getPaidBySale(saleIds);
    final refunded = await db.getRefundedAmountBySale(saleIds);
    final names = {
      for (final c in await db.getCustomersByShop(shop.id)) c.id: c.name,
    };
    return rows
        .map(
          (r) => CreditSaleWithCustomer(
            id: r.id,
            total: r.total,
            paid: paid[r.id] ?? Decimal.zero,
            refunded: refunded[r.id] ?? Decimal.zero,
            createdAt: r.createdAt,
            customerId: r.customerId!,
            customerName: names[r.customerId] ?? 'Unknown',
          ),
        )
        .toList();
  }
  final client = ref.read(supabaseClientProvider);
  final data = await client
      .from('sales')
      .select(
        'id, total, created_at, customer_id, customers(id, name), credit_payments(amount), sale_items(refund_items(amount, deleted_at, refunds(deleted_at)))',
      )
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
final customerOutstandingMapProvider = FutureProvider<Map<String, Decimal>>((
  ref,
) async {
  final sales = await ref.watch(outstandingCreditProvider.future);
  final map = <String, Decimal>{};
  for (final s in sales) {
    map[s.customerId] = (map[s.customerId] ?? Decimal.zero) + s.remaining;
  }
  return map;
});

// Payment history for one credit sale (newest first), for the dispute trail.
final creditPaymentsProvider = FutureProvider.family<List<CreditPayment>, String>((
  ref,
  saleId,
) async {
  // Local-first: payment history (incl. a just-recorded payment) comes from the
  // mirror; newest-first to match the dispute trail. Web (no DB) → server.
  final db = ref.read(appDatabaseProvider);
  if (db != null) {
    final rows = await db.getCreditPaymentsForSale(saleId);
    final payments =
        rows
            .map(
              (r) => CreditPayment(
                id: r.id,
                amount: r.amount,
                method: r.method,
                notes: r.notes,
                createdAt: r.createdAt,
              ),
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return payments;
  }
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
      await ref
          .read(customersRepositoryProvider)
          .save(
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
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // Data access lives in the repository (native: local-first + atomic settle
      // + queued push; web: online). The provider only orchestrates + refreshes.
      // recorded_by is stamped server-side (auth.uid()) by the RPC.
      await ref
          .read(customersRepositoryProvider)
          .recordCreditPayment(
            saleId: saleId,
            customerId: customerId,
            saleTotal: saleTotal,
            amount: amount,
            method: method,
            notes: notes,
          );
      // Nudge a sync so an offline-recorded payment pushes promptly (no-op on
      // web / when offline).
      unawaited(ref.read(syncSchedulerProvider).syncNow());
      ref.invalidate(customersProvider);
      ref.invalidate(customerCreditSalesProvider(customerId));
      ref.invalidate(customerSalesProvider(customerId));
      ref.invalidate(outstandingCreditProvider);
      ref.invalidate(creditPaymentsProvider(saleId));
      ref.invalidate(reportSummaryProvider);
      // The Sales tab colors credit sales by settlement state — refresh it so
      // a settled bill flips to "Paid" without an app restart.
      ref.invalidate(salesListProvider);
    });
    return !state.hasError;
  }
}

final customerFormProvider = AsyncNotifierProvider<CustomerFormNotifier, void>(
  CustomerFormNotifier.new,
);
