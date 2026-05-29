import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/product.dart';
import '../../../../domain/models/sale.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/auth/presentation/providers/shop_provider.dart';
import '../../data/sales_remote.dart';
import '../../domain/sales_repository.dart';

// ─── Repository provider ───────────────────────────────────────────────────

final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  final client = ref.read(supabaseClientProvider);
  return SalesRepository(SalesRemote(client));
});

// ─── Payment methods ───────────────────────────────────────────────────────

final paymentMethodsProvider = FutureProvider<List<PaymentMethod>>((ref) async {
  final shop = await ref.watch(currentShopProvider.future);
  if (shop == null) return [];
  return ref.read(salesRepositoryProvider).getPaymentMethods(shop.id);
});

// ─── Product search ────────────────────────────────────────────────────────

final productSearchQueryProvider = StateProvider<String>((ref) => '');

final productSearchProvider = FutureProvider<List<Product>>((ref) async {
  final query = ref.watch(productSearchQueryProvider);
  if (query.trim().length < 2) return [];
  final shop = await ref.watch(currentShopProvider.future);
  if (shop == null) return [];
  return ref.read(salesRepositoryProvider).searchProducts(shop.id, query);
});

// ─── Cart state ────────────────────────────────────────────────────────────

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addItem(CartItem item) {
    // If same product already in cart, increase quantity
    final idx = state.indexWhere((e) => e.productId == item.productId && item.productId != null);
    if (idx >= 0) {
      final existing = state[idx];
      state = [
        ...state.sublist(0, idx),
        existing.copyWith(quantity: existing.quantity + item.quantity),
        ...state.sublist(idx + 1),
      ];
    } else {
      state = [...state, item];
    }
  }

  void updateItem(int index, CartItem updated) {
    state = [...state.sublist(0, index), updated, ...state.sublist(index + 1)];
  }

  void removeItem(int index) {
    state = [...state.sublist(0, index), ...state.sublist(index + 1)];
  }

  void clear() => state = [];

  Decimal get subtotal =>
      state.fold(Decimal.zero, (sum, item) => sum + item.lineTotal);

  Decimal get totalDiscount =>
      state.fold(Decimal.zero, (sum, item) => sum + item.discountAmount);
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>(
  (ref) => CartNotifier(),
);

final cartSubtotalProvider = Provider<Decimal>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(Decimal.zero, (sum, item) => sum + item.lineTotal);
});

// ─── Selected payment method ───────────────────────────────────────────────

final selectedPaymentMethodProvider = StateProvider<PaymentMethod?>((ref) => null);

// ─── Create sale notifier ──────────────────────────────────────────────────

class CreateSaleNotifier extends AsyncNotifier<Sale?> {
  @override
  Future<Sale?> build() async => null;

  Future<Sale?> submit({
    required String paymentMethodId,
    required List<CartItem> items,
    String? customerId,
    bool isCredit = false,
    String? notes,
    String? discountReason,
  }) async {
    final shop = await ref.read(currentShopProvider.future);
    final branches = await ref.read(currentShopBranchesProvider.future);
    final userId = ref.read(currentUserIdProvider);
    final activeBranch = ref.read(activeBranchProvider) ?? (branches.isNotEmpty ? branches.first : null);

    if (shop == null || activeBranch == null || userId == null) {
      throw Exception('Missing shop, branch, or user context');
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final sale = await ref.read(salesRepositoryProvider).createSale(
            branchId: activeBranch.id,
            shopId: shop.id,
            cashierId: userId,
            paymentMethodId: paymentMethodId,
            items: items,
            customerId: customerId,
            isCredit: isCredit,
            notes: notes,
            discountReason: discountReason,
          );
      ref.read(cartProvider.notifier).clear();
      ref.invalidate(todaySalesTotalsProvider);
      return sale;
    });
    return state.valueOrNull;
  }
}

final createSaleProvider =
    AsyncNotifierProvider<CreateSaleNotifier, Sale?>(CreateSaleNotifier.new);

// ─── Sales list ────────────────────────────────────────────────────────────

final selectedSalesDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final salesListProvider = FutureProvider<List<Sale>>((ref) async {
  final date = ref.watch(selectedSalesDateProvider);
  final branches = await ref.watch(currentShopBranchesProvider.future);
  final activeBranch = ref.watch(activeBranchProvider) ?? (branches.isNotEmpty ? branches.first : null);
  if (activeBranch == null) return [];

  final from = DateTime(date.year, date.month, date.day);
  final to = from.add(const Duration(days: 1));

  return ref.read(salesRepositoryProvider).getSalesForBranch(
        branchId: activeBranch.id,
        from: from,
        to: to,
      );
});

// ─── Today's totals (for dashboard) ──────────────────────────────────────

final todaySalesTotalsProvider = FutureProvider<Map<String, Decimal>>((ref) async {
  final branches = await ref.watch(currentShopBranchesProvider.future);
  final activeBranch = ref.watch(activeBranchProvider) ?? (branches.isNotEmpty ? branches.first : null);
  if (activeBranch == null) return {'total': Decimal.zero, 'count': Decimal.zero};
  return ref.read(salesRepositoryProvider).getTodayTotals(activeBranch.id);
});

// ─── Void sale notifier ────────────────────────────────────────────────────

class VoidSaleNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> voidSale({
    required String saleId,
    required String reason,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    final branches = await ref.read(currentShopBranchesProvider.future);
    final activeBranch = ref.read(activeBranchProvider) ?? (branches.isNotEmpty ? branches.first : null);

    if (userId == null || activeBranch == null) throw Exception('Missing context');

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(salesRepositoryProvider).voidSale(
            saleId: saleId,
            voidedBy: userId,
            reason: reason,
            branchId: activeBranch.id,
          );
      ref.invalidate(salesListProvider);
      ref.invalidate(todaySalesTotalsProvider);
    });
  }
}

final voidSaleProvider =
    AsyncNotifierProvider<VoidSaleNotifier, void>(VoidSaleNotifier.new);
