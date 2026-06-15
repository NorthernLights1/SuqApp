import 'package:decimal/decimal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
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

  /// Records an installment and settles the credit sale in one server-side
  /// transaction. Returns true when this payment clears the bill.
  Future<bool> recordCreditPayment({
    required String saleId,
    required String customerId,
    required Decimal saleTotal,
    required Decimal amount,
    required String method,
    String? notes,
    String? recordedBy,
  }) async {
    final result = await _client.rpc(
      'record_credit_payment',
      params: {
        'p_id': const Uuid().v4(),
        'p_sale_id': saleId,
        'p_customer_id': customerId,
        'p_amount': amount.toString(),
        'p_method': method,
        'p_notes': notes,
      },
    );
    return result == true;
  }
}
