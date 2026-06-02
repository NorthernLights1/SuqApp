import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/auth/presentation/providers/shop_provider.dart';
import '../../data/inventory_remote.dart';

// ─── Remote provider ───────────────────────────────────────────────────────

final inventoryRemoteProvider = Provider<InventoryRemote>(
  (ref) => InventoryRemote(ref.read(supabaseClientProvider)),
);

// ─── Measurement units ─────────────────────────────────────────────────────

final measurementUnitsProvider =
    FutureProvider<List<MeasurementUnit>>((ref) async {
  final shop = await ref.watch(currentShopProvider.future);
  if (shop == null) return [];
  return ref.read(inventoryRemoteProvider).getMeasurementUnits(shop.id);
});

// ─── Product categories ────────────────────────────────────────────────────

final productCategoriesProvider = FutureProvider<List<ProductCategory>>((ref) async {
  final shop = await ref.watch(currentShopProvider.future);
  if (shop == null) return [];
  return ref.read(inventoryRemoteProvider).getProductCategories(shop.id);
});

// ─── Products list ─────────────────────────────────────────────────────────

final productsProvider = FutureProvider((ref) async {
  final shop = await ref.watch(currentShopProvider.future);
  if (shop == null) return [];
  return ref.read(inventoryRemoteProvider).getProducts(shop.id);
});

// ─── Stock levels ──────────────────────────────────────────────────────────

final stockLevelsProvider = FutureProvider<List<StockEntry>>((ref) async {
  final branches = await ref.watch(currentShopBranchesProvider.future);
  final branch = ref.watch(activeBranchProvider) ??
      (branches.isNotEmpty ? branches.first : null);
  if (branch == null) return [];
  return ref.read(inventoryRemoteProvider).getStockLevels(branch.id);
});

final lowStockCountProvider = Provider<AsyncValue<int>>((ref) {
  return ref.watch(stockLevelsProvider).whenData(
        (list) => list.where((e) => e.isLowStock).length,
      );
});

// ─── Create product ────────────────────────────────────────────────────────

class ProductFormNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> save({
    String? productId,
    required String name,
    required String measurementUnitId,
    required Decimal lowStockThreshold,
    Decimal? sellingPrice,
    Decimal? costPrice,
    String? categoryId,
    String? description,
    Decimal? initialQuantity,
    DateTime? expiryDate,
  }) async {
    final shop = await ref.read(currentShopProvider.future);
    if (shop == null) return false;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final remote = ref.read(inventoryRemoteProvider);
      if (productId == null) {
        final product = await remote.createProduct(
          shopId: shop.id,
          name: name,
          measurementUnitId: measurementUnitId,
          lowStockThreshold: lowStockThreshold,
          sellingPrice: sellingPrice,
          costPrice: costPrice,
          categoryId: categoryId,
          description: description,
        );
        if (initialQuantity != null && initialQuantity > Decimal.zero) {
          final userId = ref.read(currentUserIdProvider);
          final branches = await ref.read(currentShopBranchesProvider.future);
          final branch = ref.read(activeBranchProvider) ??
              (branches.isNotEmpty ? branches.first : null);
          if (userId != null && branch != null) {
            await remote.setOpeningStock(
              branchId: branch.id,
              productId: product.id,
              quantity: initialQuantity,
              adjustedBy: userId,
              expiryDate: expiryDate,
            );
          }
        }
      } else {
        await remote.updateProduct(
          productId: productId,
          name: name,
          measurementUnitId: measurementUnitId,
          lowStockThreshold: lowStockThreshold,
          sellingPrice: sellingPrice,
          costPrice: costPrice,
          categoryId: categoryId,
          description: description,
        );
      }
      ref.invalidate(productsProvider);
      ref.invalidate(stockLevelsProvider);
    });
    return !state.hasError;
  }

  Future<bool> deactivate(String productId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(inventoryRemoteProvider).deactivateProduct(productId);
      ref.invalidate(productsProvider);
      ref.invalidate(stockLevelsProvider);
    });
    return !state.hasError;
  }
}

final productFormProvider =
    AsyncNotifierProvider<ProductFormNotifier, void>(ProductFormNotifier.new);

// ─── Adjust stock ──────────────────────────────────────────────────────────

class StockAdjustmentNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> setOpening({
    required String productId,
    required Decimal quantity,
    DateTime? expiryDate,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    final branches = await ref.read(currentShopBranchesProvider.future);
    final branch = ref.read(activeBranchProvider) ??
        (branches.isNotEmpty ? branches.first : null);
    if (userId == null || branch == null) return false;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(inventoryRemoteProvider).setOpeningStock(
            branchId: branch.id,
            productId: productId,
            quantity: quantity,
            adjustedBy: userId,
            expiryDate: expiryDate,
          );
      ref.invalidate(stockLevelsProvider);
    });
    return !state.hasError;
  }

  Future<bool> manualAdjust({
    required String productId,
    required Decimal newQuantity,
    required Decimal currentQuantity,
    required String notes,
    DateTime? expiryDate,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    final branches = await ref.read(currentShopBranchesProvider.future);
    final branch = ref.read(activeBranchProvider) ??
        (branches.isNotEmpty ? branches.first : null);
    if (userId == null || branch == null) return false;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(inventoryRemoteProvider).manualAdjustment(
            branchId: branch.id,
            productId: productId,
            newQuantity: newQuantity,
            currentQuantity: currentQuantity,
            adjustedBy: userId,
            notes: notes,
            expiryDate: expiryDate,
          );
      ref.invalidate(stockLevelsProvider);
    });
    return !state.hasError;
  }

  Future<bool> addStock({
    required String productId,
    required Decimal quantityToAdd,
    DateTime? expiryDate,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    final branches = await ref.read(currentShopBranchesProvider.future);
    final branch = ref.read(activeBranchProvider) ??
        (branches.isNotEmpty ? branches.first : null);
    if (userId == null || branch == null) return false;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(inventoryRemoteProvider).addStock(
            branchId: branch.id,
            productId: productId,
            quantityToAdd: quantityToAdd,
            adjustedBy: userId,
            expiryDate: expiryDate,
          );
      ref.invalidate(stockLevelsProvider);
    });
    return !state.hasError;
  }

  Future<bool> correctStock({
    required String productId,
    required Decimal newQuantity,
    required Decimal currentQuantity,
    required String notes,
    DateTime? expiryDate,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    final branches = await ref.read(currentShopBranchesProvider.future);
    final branch = ref.read(activeBranchProvider) ??
        (branches.isNotEmpty ? branches.first : null);
    if (userId == null || branch == null) return false;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(inventoryRemoteProvider).correctStock(
            branchId: branch.id,
            productId: productId,
            newQuantity: newQuantity,
            currentQuantity: currentQuantity,
            adjustedBy: userId,
            notes: notes,
            expiryDate: expiryDate,
          );
      ref.invalidate(stockLevelsProvider);
    });
    return !state.hasError;
  }
}

final stockAdjustmentProvider =
    AsyncNotifierProvider<StockAdjustmentNotifier, void>(
        StockAdjustmentNotifier.new);

// ─── Inventory category filter ─────────────────────────────────────────────

class _InventoryCategoryNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? id) => state = id;
}

final inventoryCategoryFilterProvider =
    NotifierProvider<_InventoryCategoryNotifier, String?>(
        _InventoryCategoryNotifier.new);
