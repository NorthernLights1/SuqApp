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
}
