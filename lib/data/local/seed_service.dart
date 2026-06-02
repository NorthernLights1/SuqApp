import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/inventory/data/inventory_remote.dart';
import 'app_database.dart';

class SeedService {
  SeedService(this._client, this._inventoryRemote, this._db);

  final SupabaseClient _client;
  final InventoryRemote _inventoryRemote;
  final AppDatabase _db;

  Future<void> seedAll({
    required String shopId,
    required String branchId,
  }) async {
    await Future.wait([
      _seedProducts(shopId),
      _seedStock(branchId),
      _seedCustomers(shopId),
    ]);
  }

  Future<void> _seedProducts(String shopId) async {
    final products = await _inventoryRemote.getProducts(shopId);
    await _db.upsertProducts(products
        .map((p) => LocalProductsCompanion(
              id: Value(p.id),
              shopId: Value(p.shopId),
              name: Value(p.name),
              categoryId: Value(p.categoryId),
              description: Value(p.description),
              measurementUnitId: Value(p.measurementUnitId),
              measurementUnitAbbr: Value(p.measurementUnitAbbr),
              lowStockThreshold: Value(p.lowStockThreshold),
              sellingPrice: Value(p.sellingPrice),
              costPrice: Value(p.costPrice),
              isActive: Value(p.isActive),
              syncedAt: Value(DateTime.now()),
            ))
        .toList());
  }

  Future<void> _seedStock(String branchId) async {
    final stockList = await _inventoryRemote.getStockLevels(branchId);
    await _db.upsertStock(stockList
        .map((s) => LocalStockCompanion(
              productId: Value(s.productId),
              branchId: Value(branchId),
              quantity: Value(s.quantity),
              syncedAt: Value(DateTime.now()),
            ))
        .toList());
  }

  Future<void> _seedCustomers(String shopId) async {
    final data = await _client
        .from('customers')
        .select('id, shop_id, name, phone, credit_balance')
        .eq('shop_id', shopId)
        .order('name');
    await _db.upsertCustomers((data as List)
        .map((e) => LocalCustomersCompanion(
              id: Value(e['id'] as String),
              shopId: Value(e['shop_id'] as String),
              name: Value(e['name'] as String),
              phone: Value(e['phone'] as String?),
              creditBalance:
                  Value(Decimal.parse((e['credit_balance'] ?? '0').toString())),
              updatedAt: Value(DateTime.now()),
              isSynced: const Value(true),
            ))
        .toList());
  }
}
