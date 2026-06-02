import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/auth/presentation/providers/shop_provider.dart';

// ─── Branch name ───────────────────────────────────────────────────────────

class BranchNameNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> rename(String branchId, String name) async {
    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await client
          .from('branches')
          .update({'name': name.trim()})
          .eq('id', branchId);
      ref.invalidate(currentShopBranchesProvider);
    });
  }
}

final branchNameNotifierProvider =
    AsyncNotifierProvider<BranchNameNotifier, void>(BranchNameNotifier.new);
