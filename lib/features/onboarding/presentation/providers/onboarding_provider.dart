import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

enum OnboardingStep { createShop, createBranch, openingStock, inviteStaff }

class OnboardingState {
  const OnboardingState({
    this.step = OnboardingStep.createShop,
    this.shopId,
    this.branchId,
    this.loading = false,
    this.error,
  });

  final OnboardingStep step;
  final String? shopId;
  final String? branchId;
  final bool loading;
  final String? error;

  OnboardingState copyWith({
    OnboardingStep? step,
    String? shopId,
    String? branchId,
    bool? loading,
    String? error,
  }) =>
      OnboardingState(
        step: step ?? this.step,
        shopId: shopId ?? this.shopId,
        branchId: branchId ?? this.branchId,
        loading: loading ?? this.loading,
        error: error,
      );
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier(this._client, this._userId) : super(const OnboardingState());

  final SupabaseClient _client;
  final String _userId;

  Future<bool> createShop(String name) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final result = await _client.from('shops').insert({
        'owner_id': _userId,
        'name': name.trim(),
      }).select('id').single();

      final shopId = result['id'] as String;

      // Assign owner role in shop_users
      await _client.from('shop_users').insert({
        'shop_id': shopId,
        'user_id': _userId,
        'role_id': '00000000-0000-0000-0000-000000000001', // system owner role
        'status': 'active',
      });

      state = state.copyWith(
        loading: false,
        shopId: shopId,
        step: OnboardingStep.createBranch,
      );
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> createBranch(String name, {String? address}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final result = await _client.from('branches').insert({
        'shop_id': state.shopId,
        'name': name.trim(),
        'address': address?.trim(),
      }).select('id').single();

      final branchId = result['id'] as String;

      // Write default shop settings
      await _writeDefaultSettings(state.shopId!, branchId);

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

  Future<void> _writeDefaultSettings(String shopId, String branchId) async {
    final defaults = [
      {'key': 'inventory_mode', 'value': '"flexible"'},
      {'key': 'sync_warning_hours', 'value': '12'},
      {'key': 'low_stock_notify', 'value': 'true'},
      {'key': 'currency_code', 'value': '"ETB"'},
      {'key': 'locale', 'value': '"en"'},
    ];
    for (final s in defaults) {
      await _client.from('shop_settings').upsert({
        'shop_id': shopId,
        'branch_id': null,
        'key': s['key'],
        'value': s['value'],
        'updated_by': _userId,
      });
    }
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  final userId = ref.watch(currentUserIdProvider)!;
  final client = ref.read(supabaseClientProvider);
  return OnboardingNotifier(client, userId);
});
