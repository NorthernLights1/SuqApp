import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../providers/license_provider.dart';

/// Amber countdown strip shown once the trial/license enters the warning
/// window (AppConstants.licenseWarningDays). Tapping it lets the owner enter
/// a serial before the lock kicks in. Renders nothing otherwise.
class LicenseWarningBanner extends ConsumerWidget {
  const LicenseWarningBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(licenseStatusProvider).asData?.value;
    if (status == null || !status.showWarning) return const SizedBox.shrink();

    final days = status.daysLeft!;
    final when = switch (days) {
      0 => 'today',
      1 => 'in 1 day',
      _ => 'in $days days',
    };
    final label = status.isTrial
        ? 'Free trial ends $when'
        : 'License expires $when';

    return Material(
      color: AppColors.warning.withValues(alpha: 0.15),
      child: InkWell(
        onTap: () => showSerialEntryDialog(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined,
                  size: 18, color: AppColors.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: AppTextStyles.bodySmall
                        .copyWith(fontWeight: FontWeight.w600)),
              ),
              Text('Enter serial',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Serial entry as a dialog, for renewing before the lock screen appears.
/// The new period starts from today (periods do not stack).
Future<void> showSerialEntryDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (_) => const _SerialEntryDialog(),
  );
}

class _SerialEntryDialog extends ConsumerStatefulWidget {
  const _SerialEntryDialog();

  @override
  ConsumerState<_SerialEntryDialog> createState() => _SerialEntryDialogState();
}

class _SerialEntryDialogState extends ConsumerState<_SerialEntryDialog> {
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
    final ok = await ref.read(activateLicenseProvider.notifier).activate(key);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Serial accepted — license updated'),
        backgroundColor: AppColors.success,
      ));
    } else {
      setState(() => _error =
          'Serial not accepted. Check the digits, and note that only the '
          'shop owner can activate.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(activateLicenseProvider).isLoading;
    return AlertDialog(
      title: const Text('Enter serial number'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'The new license period starts today.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _keyCtrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            textAlign: TextAlign.center,
            style: AppTextStyles.headline3.copyWith(letterSpacing: 4),
            decoration: InputDecoration(
              hintText: '0000000000',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              errorText: _error,
            ),
            onSubmitted: (_) => _activate(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: loading ? null : _activate,
          child: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Activate'),
        ),
      ],
    );
  }
}
