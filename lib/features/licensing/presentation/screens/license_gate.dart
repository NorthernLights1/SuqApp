import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../providers/license_provider.dart';

/// Wraps the whole app (MaterialApp.builder). Shows the normal UI unless the
/// platform operator has blocked this shop or its trial has expired without
/// an activated serial — in which case the app is replaced by a lock screen.
class LicenseGate extends ConsumerWidget {
  const LicenseGate({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(licenseStatusProvider);
    return status.maybeWhen(
      data: (s) => switch (s.state) {
        LicenseState.blocked => _BlockedScreen(reason: s.blockedReason),
        LicenseState.expired => const _ActivationScreen(),
        LicenseState.ok => child,
      },
      // While checking (or on provider error) keep the app usable — the
      // provider itself already fails open on network errors.
      orElse: () => child,
    );
  }
}

// ─── Blocked ─────────────────────────────────────────────────────────────────

class _BlockedScreen extends ConsumerWidget {
  const _BlockedScreen({this.reason});
  final String? reason;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.block_outlined, size: 72, color: AppColors.error),
              const SizedBox(height: 20),
              Text('Shop suspended',
                  style: AppTextStyles.headline2, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                reason?.isNotEmpty == true
                    ? reason!
                    : 'This shop has been suspended by the service provider.',
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please contact support to restore access.',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => ref.invalidate(licenseStatusProvider),
                child: const Text('Check again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Trial expired → serial entry ───────────────────────────────────────────

class _ActivationScreen extends ConsumerStatefulWidget {
  const _ActivationScreen();

  @override
  ConsumerState<_ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends ConsumerState<_ActivationScreen> {
  final _keyCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _keyCtrl.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    final key = _keyCtrl.text.trim();
    if (key.length != 10) {
      setState(() => _error = 'The serial number is 10 digits');
      return;
    }
    setState(() => _error = null);
    final ok =
        await ref.read(activateLicenseProvider.notifier).activate(key);
    if (!ok && mounted) {
      setState(() => _error =
          'Serial not accepted. Check the digits, and note that only the '
          'shop owner can activate.');
    }
    // On success licenseStatusProvider is invalidated and the gate swaps
    // back to the app automatically.
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(activateLicenseProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.key_outlined,
                    size: 72, color: AppColors.primary),
                const SizedBox(height: 20),
                Text('Activation required',
                    style: AppTextStyles.headline2,
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  'The trial or license period for this shop has ended. '
                  'Enter the 10-digit serial number from your service '
                  'provider to continue using Suq.',
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _keyCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headline3.copyWith(letterSpacing: 4),
                  decoration: InputDecoration(
                    hintText: '0000000000',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    errorText: _error,
                  ),
                  onSubmitted: (_) => _activate(),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: loading ? null : _activate,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Activate'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () =>
                      ref.read(authNotifierProvider.notifier).signOut(),
                  child: const Text('Log out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
