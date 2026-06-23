import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/setting_keys.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

enum OnboardingStep { selectShopType, createShop, createBranch, openingStock, inviteStaff }

class OnboardingState {
  const OnboardingState({
    this.step = OnboardingStep.selectShopType,
    this.shopId,
    this.branchId,
    this.shopType = ShopType.retail,
    this.loading = false,
    this.error,
  });

  final OnboardingStep step;
  final String? shopId;
  final String? branchId;
  final String shopType;
  final bool loading;
  final String? error;

  OnboardingState copyWith({
    OnboardingStep? step,
    String? shopId,
    String? branchId,
    String? shopType,
    bool? loading,
    String? error,
  }) =>
      OnboardingState(
        step: step ?? this.step,
        shopId: shopId ?? this.shopId,
        branchId: branchId ?? this.branchId,
        shopType: shopType ?? this.shopType,
        loading: loading ?? this.loading,
        error: error,
      );
}

class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    ref.watch(currentUserIdProvider); // rebuild if user changes
    return const OnboardingState();
  }

  SupabaseClient get _client => ref.read(supabaseClientProvider);

  void selectShopType(String type) {
    state = state.copyWith(shopType: type, step: OnboardingStep.createShop);
  }

  Future<bool> createShop(String name) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final selectedShopType = state.shopType;
      final shopId = state.shopId ??
          await _client.rpc(
            'create_shop_with_owner',
            params: {'p_name': name.trim()},
          ) as String;

      final userId = ref.read(currentUserIdProvider);
      try {
        await _client.from('shop_settings').upsert(
          {
            'shop_id': shopId,
            'branch_id': null,
            'key': SettingKeys.shopType,
            'value': '"$selectedShopType"',
            'updated_by': userId,
          },
          onConflict: 'shop_id,branch_id,key',
        );
      } catch (e) {
        state = state.copyWith(
          loading: false,
          shopId: shopId,
          step: OnboardingStep.createShop,
          error:
              "We created your shop, but couldn't save your business type. Please try again.",
        );
        return false;
      }

      state = state.copyWith(
        loading: false,
        shopId: shopId,
        step: OnboardingStep.createBranch,
      );
      return true;
    } on PostgrestException catch (e) {
      // Only translate the shop-name unique violation; createShop also
      // inserts into shop_users, whose conflicts must not masquerade as a
      // taken name.
      final isNameTaken = e.code == '23505' &&
          '${e.message} ${e.details ?? ''}'.contains('shops_name_unique_idx');
      final msg = isNameTaken
          ? 'That shop name is already taken — please choose another.'
          : e.message;
      state = state.copyWith(loading: false, error: msg);
      return false;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> createBranch(String name, {String? address}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final branchId = await _client.rpc(
        'create_branch_with_defaults',
        params: {
          'p_shop_id': state.shopId,
          'p_name': name.trim(),
          'p_address': address?.trim(),
        },
      ) as String;

      state = state.copyWith(
        loading: false,
        branchId: branchId,
        step: OnboardingStep.openingStock,
      );
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }

  void skipToStep(OnboardingStep step) {
    state = state.copyWith(step: step);
  }

}

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(OnboardingNotifier.new);
