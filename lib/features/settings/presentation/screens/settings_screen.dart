import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/sync_providers.dart';
import '../../../../domain/interfaces/sync_service_interface.dart';
import '../../../../domain/models/shop.dart';
import '../../../../features/auth/presentation/providers/shop_provider.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../providers/settings_provider.dart'
    show
        branchNameNotifierProvider,
        notificationSettingsProvider,
        notificationSettingsNotifierProvider,
        sendOverdueRemindersProvider,
        NotificationSettings;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shop = ref.watch(currentShopProvider);
    final branches = ref.watch(currentShopBranchesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ── Shop info ────────────────────────────────────────────────────
          _SectionHeader(label: 'Shop'),
          shop.when(
            data: (s) => ListTile(
              leading: const Icon(Icons.storefront_outlined,
                  color: AppColors.textSecondary),
              title: Text(s?.name ?? '—', style: AppTextStyles.body),
              subtitle: Text('Shop name', style: AppTextStyles.bodySmall),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          branches.when(
            data: (list) => list.isEmpty
                ? const SizedBox.shrink()
                : ListTile(
                    leading: const Icon(Icons.location_on_outlined,
                        color: AppColors.textSecondary),
                    title: Text(list.first.name, style: AppTextStyles.body),
                    subtitle: Text('Branch', style: AppTextStyles.bodySmall),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          size: 18, color: AppColors.textSecondary),
                      tooltip: 'Edit branch name',
                      onPressed: () =>
                          _showEditBranchDialog(context, ref, list.first),
                    ),
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const Divider(),

          // ── Notifications ────────────────────────────────────────────────
          _SectionHeader(label: 'Notifications'),
          ref.watch(notificationSettingsProvider).when(
                data: (settings) => _NotificationsCard(initial: settings),
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: LinearProgressIndicator(),
                ),
                error: (_, _) => const SizedBox.shrink(),
              ),
          const Divider(),

          // ── Sync ─────────────────────────────────────────────────────────
          _SectionHeader(label: 'Sync'),
          const _SyncCard(),
          const Divider(),

          // ── About ─────────────────────────────────────────────────────────
          _SectionHeader(label: 'About'),
          ListTile(
            leading: const Icon(Icons.info_outline,
                color: AppColors.textSecondary),
            title: Text('Suq ERP', style: AppTextStyles.body),
            subtitle:
                Text('Version 1.0.0 (Phase 4)', style: AppTextStyles.bodySmall),
          ),
        ],
      ),
    );
  }
}

Future<void> _showEditBranchDialog(
    BuildContext context, WidgetRef ref, Branch branch) async {
  final result = await showDialog<String>(
    context: context,
    builder: (_) => _EditBranchDialog(initialName: branch.name),
  );
  if (result == null || !context.mounted) return;
  await ref
      .read(branchNameNotifierProvider.notifier)
      .rename(branch.id, result);
  if (!context.mounted) return;
  final state = ref.read(branchNameNotifierProvider);
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(state.hasError
        ? 'Failed to update branch name'
        : 'Branch name updated'),
  ));
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.label.copyWith(
          color: AppColors.primary,
          letterSpacing: 1.0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Sync card ──────────────────────────────────────────────────────────────

class _SyncCard extends ConsumerStatefulWidget {
  const _SyncCard();

  @override
  ConsumerState<_SyncCard> createState() => _SyncCardState();
}

class _SyncCardState extends ConsumerState<_SyncCard> {
  Future<void> _syncNow() async {
    await ref.read(syncSchedulerProvider).syncNow(force: true);
    if (!mounted) return;
    final status = ref.read(syncStatusProvider).asData?.value;
    final failed = status == SyncStatus.failed;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(failed
          ? 'Sync failed — check your connection'
          : 'Everything is up to date'),
      backgroundColor: failed ? AppColors.error : AppColors.success,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final status =
        ref.watch(syncStatusProvider).asData?.value ?? SyncStatus.idle;
    final lastSynced = ref.watch(lastSyncedAtProvider);
    final syncing = status == SyncStatus.syncing;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.cloud_sync_outlined,
                color: AppColors.textSecondary),
            title: Text('Sync to cloud', style: AppTextStyles.body),
            subtitle: Text(
              lastSynced.when(
                data: (t) => t == null
                    ? 'Not synced yet'
                    : 'Last synced ${_relativeTime(t)}',
                loading: () => 'Checking…',
                error: (_, _) => 'Last sync time unavailable',
              ),
              style: AppTextStyles.bodySmall,
            ),
          ),
          const SizedBox(height: 4),
          FilledButton.icon(
            onPressed: syncing ? null : _syncNow,
            icon: syncing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.sync),
            label: Text(syncing ? 'Syncing…' : 'Sync now'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

String _relativeTime(DateTime t) {
  final diff = DateTime.now().difference(t);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    return '$m minute${m == 1 ? '' : 's'} ago';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    return '$h hour${h == 1 ? '' : 's'} ago';
  }
  final d = diff.inDays;
  return '$d day${d == 1 ? '' : 's'} ago';
}

// ── Notifications card ─────────────────────────────────────────────────────

class _NotificationsCard extends ConsumerStatefulWidget {
  const _NotificationsCard({required this.initial});
  final NotificationSettings initial;

  @override
  ConsumerState<_NotificationsCard> createState() => _NotificationsCardState();
}

class _NotificationsCardState extends ConsumerState<_NotificationsCard> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailCtrl;
  late final TextEditingController _overdueDaysCtrl;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initial.email);
    _overdueDaysCtrl =
        TextEditingController(text: widget.initial.overdueDays.toString());
  }

  @override
  void didUpdateWidget(_NotificationsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initial.email != widget.initial.email) {
      _emailCtrl.text = widget.initial.email;
    }
    if (oldWidget.initial.overdueDays != widget.initial.overdueDays) {
      _overdueDaysCtrl.text = widget.initial.overdueDays.toString();
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _overdueDaysCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(notificationSettingsNotifierProvider.notifier).save(
          email: _emailCtrl.text.trim(),
          overdueDays: int.tryParse(_overdueDaysCtrl.text.trim()) ?? 7,
        );
    if (!mounted) return;
    final state = ref.read(notificationSettingsNotifierProvider);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          state.hasError ? 'Failed to save settings' : 'Notification settings saved'),
      backgroundColor:
          state.hasError ? AppColors.error : AppColors.success,
    ));
  }

  Future<void> _sendOverdueReminders() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Send Overdue Reminders'),
        content: const Text(
            'This will send you a notification listing all unpaid credits that have passed the overdue period. Continue?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Send')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final result = await ref.read(sendOverdueRemindersProvider.notifier).send();
    if (!mounted) return;
    final state = ref.read(sendOverdueRemindersProvider);

    final String message;
    final Color color;
    if (state.hasError) {
      message = 'Failed to send reminders';
      color = AppColors.error;
    } else if (result?.sent == true) {
      message = 'Overdue credit reminders sent';
      color = AppColors.success;
    } else {
      // Ran fine but nothing to send — tell the owner why instead of
      // implying an email went out.
      message = result?.reason == 'No overdue credits found'
          ? 'No credits are overdue yet — nothing to send'
          : (result?.reason ?? 'Nothing to send');
      color = AppColors.textSecondary;
    }
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(notificationSettingsNotifierProvider).isLoading;
    final sending = ref.watch(sendOverdueRemindersProvider).isLoading;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email — owner is always notified; this is an optional 2nd recipient
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Additional notification email (optional)',
                hintText: 'someone-else@gmail.com',
                helperText:
                    'You (the owner) always receive alerts. Add a second address here to copy someone.',
                helperMaxLines: 3,
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null; // optional
                final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
                return ok ? null : 'Enter a valid email address';
              },
            ),
            const SizedBox(height: 12),

            // Overdue days
            TextFormField(
              controller: _overdueDaysCtrl,
              decoration: const InputDecoration(
                labelText: 'Overdue credit period (days)',
                hintText: '7',
                prefixIcon: Icon(Icons.timer_outlined),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final n = int.tryParse(v.trim());
                if (n == null || n < 1) return 'Enter a number ≥ 1';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Save button
            FilledButton.icon(
              onPressed: saving ? null : _save,
              icon: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_outlined),
              label: const Text('Save notification settings'),
            ),
            const SizedBox(height: 12),

            // Send overdue reminders button
            OutlinedButton.icon(
              onPressed: sending ? null : _sendOverdueReminders,
              icon: sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.notifications_active_outlined),
              label: const Text('Send overdue credit reminders now'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Edit branch dialog ────────────────────────────────────────────────────

class _EditBranchDialog extends StatefulWidget {
  const _EditBranchDialog({required this.initialName});
  final String initialName;

  @override
  State<_EditBranchDialog> createState() => _EditBranchDialogState();
}

class _EditBranchDialogState extends State<_EditBranchDialog> {
  late final TextEditingController _ctrl;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Branch Name'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Branch Name'),
          textCapitalization: TextCapitalization.words,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Branch name is required' : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _ctrl.text.trim());
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
