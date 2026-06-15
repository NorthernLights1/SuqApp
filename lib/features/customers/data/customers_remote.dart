import 'package:decimal/decimal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/customer.dart';

/// Supabase access for customer identity (name/phone). Credit-balance mutation
/// stays in the provider (online) — see CustomersRepository docs.
class CustomersRemote {
  CustomersRemote(this._client);
  final SupabaseClient _client;

  Future<List<Customer>> getCustomers(String shopId) async {
    final data = await _client
        .from('customers')
        .select('id, shop_id, name, phone, credit_balance, created_at')
        .eq('shop_id', shopId)
        .order('name');
    return (data as List).map((e) => Customer.fromJson(e)).toList();
  }

  /// Insert-or-update identity fields only. Deliberately omits credit_balance
  /// so syncing a customer never clobbers the server-side running balance.
  Future<void> upsertIdentity({
    required String id,
    required String shopId,
    required String name,
    String? phone,
  }) async {
    await _client.from('customers').upsert({
      'id': id,
      'shop_id': shopId,
      'name': name,
      'phone': phone,
    }, onConflict: 'id');
  }

  /// Online credit-payment record + settle (web path): inserts the payment,
  /// recomputes the total paid from the server, and stamps the sale settled when
  /// the bill is cleared (claiming a single method only when every payment used
  /// the same one). Returns true if it settled.
  ///
  /// NOTE: insert→read→update is NOT atomic. Two devices settling the SAME bill
  /// online at the same instant could each read before the other's insert lands,
  /// so neither crosses the threshold — leaving a fully-paid bill marked
  /// unsettled (self-heals on the next payment/recompute; no payment is lost).
  /// The mobile path settles atomically (AppDatabase.recordCreditPaymentTxn);
  /// the proper web fix is a server-side atomic RPC (deferred — see OPEN_TASKS).
  Future<bool> recordCreditPayment({
    required String saleId,
    required String customerId,
    required Decimal saleTotal,
    required Decimal amount,
    required String method,
    String? notes,
    String? recordedBy,
  }) async {
    await _client.from('credit_payments').insert({
      'sale_id': saleId,
      'customer_id': customerId,
      'amount': amount.toString(),
      'method': method,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'recorded_by': recordedBy,
    });
    final rows = (await _client
        .from('credit_payments')
        .select('amount, method')
        .eq('sale_id', saleId)) as List;
    final paid = rows.fold<Decimal>(
      Decimal.zero,
      (s, r) => s + Decimal.parse((r['amount'] ?? '0').toString()),
    );
    if (paid < saleTotal) return false;
    final methods = rows.map((r) => r['method'] as String).toSet();
    final update = <String, dynamic>{
      'credit_settled_at': DateTime.now().toIso8601String(),
    };
    if (methods.length == 1) update['credit_settlement_method'] = methods.first;
    await _client.from('sales').update(update).eq('id', saleId);
    return true;
  }
}
