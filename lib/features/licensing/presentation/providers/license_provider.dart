import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/auth/presentation/providers/shop_provider.dart';

/// Platform-operator verdict on whether this shop may use the app.
enum LicenseState {
  /// Licensed, or still inside the trial window — app runs normally.
  ok,

  /// Trial window has ended and no serial has been activated.
  expired,

  /// The operator blocked this shop remotely.
  blocked,
}

class LicenseStatus extends Equatable {
  const LicenseStatus(this.state, {this.trialDaysLeft, this.blockedReason});

  final LicenseState state;

  /// Remaining trial days (only meaningful while unlicensed and not expired).
  final int? trialDaysLeft;
  final String? blockedReason;

  static const ok = LicenseStatus(LicenseState.ok);

  @override
  List<Object?> get props => [state, trialDaysLeft, blockedReason];
}

/// Evaluates the shop's license/block state from shop_controls. Re-checked on
/// app start and resume (see SuqApp), and after activation.
///
/// Fails OPEN on network errors: a connectivity blip must never lock a
/// legitimate shop out of its sales data. Enforcement happens on the next
/// successful check.
final licenseStatusProvider = FutureProvider<LicenseStatus>((ref) async {
  final shop = await ref.watch(currentShopProvider.future);
  // No shop yet (login/onboarding) — nothing to enforce.
  if (shop == null) return LicenseStatus.ok;

  final client = ref.read(supabaseClientProvider);
  try {
    final row = await client
        .from('shop_controls')
        .select('blocked, blocked_reason, licensed')
        .eq('shop_id', shop.id)
        .maybeSingle();

    if (row != null && row['blocked'] == true) {
      return LicenseStatus(
        LicenseState.blocked,
        blockedReason: row['blocked_reason'] as String?,
      );
    }
    if (row != null && row['licensed'] == true) return LicenseStatus.ok;

    // Unlicensed: still inside the trial window?
    final trialEnd =
        shop.createdAt.add(const Duration(days: AppConstants.licenseTrialDays));
    final left = trialEnd.difference(DateTime.now()).inDays;
    if (left < 0) return const LicenseStatus(LicenseState.expired);
    return LicenseStatus(LicenseState.ok, trialDaysLeft: left);
  } catch (_) {
    return LicenseStatus.ok;
  }
});

/// Activates a 10-digit serial for the current shop via the activate_license
/// RPC (owner-only, single-use keys, validated server-side).
class ActivateLicenseNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Returns true when the key was accepted.
  Future<bool> activate(String key) async {
    final shop = await ref.read(currentShopProvider.future);
    if (shop == null) return false;
    final client = ref.read(supabaseClientProvider);

    state = const AsyncLoading();
    var accepted = false;
    state = await AsyncValue.guard(() async {
      final result = await client.rpc('activate_license', params: {
        'p_shop_id': shop.id,
        'p_key': key,
      });
      accepted = result == true;
      if (accepted) ref.invalidate(licenseStatusProvider);
    });
    return !state.hasError && accepted;
  }
}

final activateLicenseProvider =
    AsyncNotifierProvider<ActivateLicenseNotifier, void>(
        ActivateLicenseNotifier.new);
