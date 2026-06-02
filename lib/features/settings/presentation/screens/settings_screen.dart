import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/shop.dart';
import '../../../../features/auth/presentation/providers/shop_provider.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../providers/settings_provider.dart' show branchNameNotifierProvider;

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
                      icon: const Icon(Icons.edit_outlined, size: 18,
                          color: AppColors.textSecondary),
                      tooltip: 'Edit branch name',
                      onPressed: () => _showEditBranchDialog(
                          context, ref, list.first),
                    ),
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const Divider(),

          // ── About ─────────────────────────────────────────────────────────
          _SectionHeader(label: 'About'),
          ListTile(
            leading: const Icon(Icons.info_outline,
                color: AppColors.textSecondary),
            title: Text('Suq ERP', style: AppTextStyles.body),
            subtitle: Text('Version 1.0.0 (Phase 4)',
                style: AppTextStyles.bodySmall),
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
  await ref.read(branchNameNotifierProvider.notifier).rename(branch.id, result);
  if (!context.mounted) return;
  final state = ref.read(branchNameNotifierProvider);
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(state.hasError ? 'Failed to update branch name' : 'Branch name updated'),
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
