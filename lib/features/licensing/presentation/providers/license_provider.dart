import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/auth/presentation/providers/shop_provider.dart';

/// Platform-operator verdict on whether this shop may use the app.
enum LicenseState {
  /// Inside the trial window or holding an unexpired license.
  ok,

  /// Trial window or license period has ended — a serial is required.
  expired,

  /// The operator blocked this shop remotely.
  blocked,
}

class LicenseStatus extends Equatable {
  const LicenseStatus(
    this.state, {
    this.daysLeft,
    this.isTrial = false,
    this.blockedReason,
  });

  final LicenseState state;

  /// Whole days until the trial/license runs out (only while [state] is ok).
  final int? daysLeft;

  /// True when [daysLeft] counts the free trial rather than an active license.
  final bool isTrial;
  final String? blockedReason;

  static const ok = LicenseStatus(LicenseState.ok);

  /// Countdown banner shown once the remaining time enters the warning window.
  bool get showWarning =>
      state == LicenseState.ok &&
      daysLeft != null &&
      daysLeft! <= AppConstants.licenseWarningDays;

  @override
  List<Object?> get props => [state, daysLeft, isTrial, blockedReason];
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
        .select('blocked, blocked_reason, licensed_until')
        .eq('shop_id', shop.id)
        .maybeSingle();

    if (row != null && row['blocked'] == true) {
      return LicenseStatus(
        LicenseState.blocked,
        blockedReason: row['blocked_reason'] as String?,
      );
    }

    final now = DateTime.now();

    // Active (or lapsed) license period.
    final licensedUntilRaw = row?['licensed_until'] as String?;
    if (licensedUntilRaw != null) {
      final licensedUntil = DateTime.parse(licensedUntilRaw).toLocal();
      if (licensedUntil.isAfter(now)) {
        return LicenseStatus(LicenseState.ok,
            daysLeft: licensedUntil.difference(now).inDays);
      }
      return const LicenseStatus(LicenseState.expired);
    }

    // Never licensed: still inside the trial window?
    final trialEnd =
        shop.createdAt.add(const Duration(days: AppConstants.licenseTrialDays));
    if (trialEnd.isAfter(now)) {
      return LicenseStatus(LicenseState.ok,
          daysLeft: trialEnd.difference(now).inDays, isTrial: true);
    }
    return const LicenseStatus(LicenseState.expired);
  } catch (_) {
    return LicenseStatus.ok;
  }
});

/// Activates a 10-digit serial for the current shop via the activate_license
/// RPC (owner-only, single-use keys, validated server-side). The key's own
/// duration determines how long the shop stays licensed, counted from today.
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
