import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/presentation/providers/shop_provider.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shop = ref.watch(currentShopProvider);
    final branches = ref.watch(currentShopBranchesProvider);
    final modeAsync = ref.watch(inventoryModeProvider);

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
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const Divider(),

          // ── Inventory ────────────────────────────────────────────────────
          _SectionHeader(label: 'Inventory'),
          modeAsync.when(
            data: (mode) => _InventoryModeTile(currentMode: mode),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: LinearProgressIndicator(),
            ),
            error: (e, _) => ListTile(
              title: Text('Could not load setting: $e',
                  style: AppTextStyles.bodySmall),
            ),
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

class _InventoryModeTile extends ConsumerWidget {
  const _InventoryModeTile({required this.currentMode});
  final String currentMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isStrict = currentMode == 'strict';
    final saving = ref.watch(inventoryModeNotifierProvider).isLoading;

    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.inventory_2_outlined,
              color: AppColors.textSecondary),
          title: Text('Strict Inventory Mode', style: AppTextStyles.body),
          subtitle: Text(
            isStrict
                ? 'Sales blocked when stock is insufficient'
                : 'Sales allowed even when stock is low',
            style: AppTextStyles.bodySmall,
          ),
          value: isStrict,
          activeThumbColor: AppColors.primary,
          onChanged: saving
              ? null
              : (v) {
                  ref
                      .read(inventoryModeNotifierProvider.notifier)
                      .setMode(v ? 'strict' : 'flexible');
                },
        ),
      ],
    );
  }
}
