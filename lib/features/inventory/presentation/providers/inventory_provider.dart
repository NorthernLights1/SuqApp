import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/setting_keys.dart';
import '../../../../data/local/database_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/auth/presentation/providers/shop_provider.dart';
import '../../../../features/settings/presentation/providers/shop_type_provider.dart';
import '../../data/inventory_remote.dart';
import '../../domain/inventory_repository.dart';

// ─── Remote + repository providers ─────────────────────────────────────────

final inventoryRemoteProvider = Provider<InventoryRemote>(
  (ref) => InventoryRemote(ref.read(supabaseClientProvider)),
);

final inventoryRepositoryProvider = Provider<InventoryRepository>(
  (ref) => InventoryRepository(
    ref.read(inventoryRemoteProvider),
    ref.watch(appDatabaseProvider),
  ),
);

// ─── Measurement units ─────────────────────────────────────────────────────

final measurementUnitsProvider =
    FutureProvider<List<MeasurementUnit>>((ref) async {
  final shop = await ref.watch(currentShopProvider.future);
  if (shop == null) return [];
  return ref.read(inventoryRepositoryProvider).getMeasurementUnits(shop.id);
});

// ─── Product batches (wholesale: lots with expiry) ──────────────────────────

final productBatchesProvider =
    FutureProvider.family<List<ProductBatchView>, String>((ref, productId) async {
  final branches = await ref.watch(currentShopBranchesProvider.future);
  final branch = ref.watch(activeBranchProvider) ??
      (branches.isNotEmpty ? branches.first : null);
  if (branch == null) return [];
  return ref
      .read(inventoryRepositoryProvider)
      .getProductBatches(branch.id, productId);
});

// ─── Product categories ────────────────────────────────────────────────────

final productCategoriesProvider = FutureProvider<List<ProductCategory>>((ref) async {
  final shop = await ref.watch(currentShopProvider.future);
  if (shop == null) return [];
  return ref.read(inventoryRepositoryProvider).getProductCategories(shop.id);
});

// ─── Products list ─────────────────────────────────────────────────────────

final productsProvider = FutureProvider((ref) async {
  final shop = await ref.watch(currentShopProvider.future);
  if (shop == null) return [];
  return ref.read(inventoryRepositoryProvider).getProducts(shop.id);
});

// ─── Stock levels ──────────────────────────────────────────────────────────

final stockLevelsProvider = FutureProvider<List<StockEntry>>((ref) async {
  final branches = await ref.watch(currentShopBranchesProvider.future);
  final branch = ref.watch(activeBranchProvider) ??
      (branches.isNotEmpty ? branches.first : null);
  if (branch == null) return [];
  return ref.read(inventoryRepositoryProvider).getStockLevels(branch.id);
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
    String? batchNumber,
  }) async {
    final shop = await ref.read(currentShopProvider.future);
    if (shop == null) return false;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(inventoryRepositoryProvider);
      if (productId == null) {
        final product = await repo.createProduct(
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
            // Wholesale opening stock must be a BATCH, not a direct inventory
            // write, which the rollup trigger would overwrite on restock.
            final isWholesale =
                await ref.read(shopTypeProvider.future) == ShopType.wholesale;
            if (isWholesale) {
              final normalizedBatchNumber = batchNumber?.trim();
              if (normalizedBatchNumber == null ||
                  normalizedBatchNumber.isEmpty) {
                throw StateError(
                    'Batch / lot number is required for wholesale opening stock');
              }
              await repo.addStockBatch(
                branchId: branch.id,
                productId: product.id,
                quantity: initialQuantity,
                adjustedBy: userId,
                expiryDate: expiryDate,
                batchNumber: normalizedBatchNumber,
              );
            } else {
              await repo.setOpeningStock(
                branchId: branch.id,
                productId: product.id,
                quantity: initialQuantity,
                adjustedBy: userId,
                expiryDate: expiryDate,
              );
            }
          }
        }
      } else {
        await repo.updateProduct(
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
      await ref.read(inventoryRepositoryProvider).deactivateProduct(productId);
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
      await ref.read(inventoryRepositoryProvider).setOpeningStock(
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
      await ref.read(inventoryRepositoryProvider).manualAdjustment(
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
      await ref.read(inventoryRepositoryProvider).addStock(
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

  /// Wholesale restock — adds a new batch (qty + its own expiry/batch number).
  Future<bool> addStockBatch({
    required String productId,
    required Decimal quantity,
    String? batchNumber,
    DateTime? expiryDate,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    final branches = await ref.read(currentShopBranchesProvider.future);
    final branch = ref.read(activeBranchProvider) ??
        (branches.isNotEmpty ? branches.first : null);
    if (userId == null || branch == null) return false;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(inventoryRepositoryProvider).addStockBatch(
            branchId: branch.id,
            productId: productId,
            quantity: quantity,
            adjustedBy: userId,
            batchNumber: batchNumber,
            expiryDate: expiryDate,
          );
      ref.invalidate(stockLevelsProvider);
      ref.invalidate(productBatchesProvider(productId));
    });
    return !state.hasError;
  }

  /// Discard a lot (wholesale): expired/damaged stock written off.
  Future<bool> discardBatch(String batchId, String productId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(inventoryRepositoryProvider).discardBatch(batchId);
      ref.invalidate(stockLevelsProvider);
      ref.invalidate(productBatchesProvider(productId));
    });
    return !state.hasError;
  }

  /// Correct one lot's remaining to a counted quantity (wholesale). Records the
  /// difference as an adjustment with a reason.
  Future<bool> correctBatch({
    required String batchId,
    required String productId,
    required Decimal countedRemaining,
    required String reason,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    final branches = await ref.read(currentShopBranchesProvider.future);
    final branch = ref.read(activeBranchProvider) ??
        (branches.isNotEmpty ? branches.first : null);
    if (userId == null || branch == null) return false;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(inventoryRepositoryProvider).correctBatch(
            batchId: batchId,
            branchId: branch.id,
            productId: productId,
            countedRemaining: countedRemaining,
            reason: reason,
            adjustedBy: userId,
          );
      ref.invalidate(stockLevelsProvider);
      ref.invalidate(productBatchesProvider(productId));
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
      await ref.read(inventoryRepositoryProvider).correctStock(
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
