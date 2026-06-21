import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/setting_keys.dart';
import '../../../../shared/router/app_routes.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(onboardingProvider).step;
    return switch (step) {
      OnboardingStep.selectShopType => const _SelectShopTypeStep(),
      OnboardingStep.createShop     => const _CreateShopStep(),
      OnboardingStep.createBranch   => const _CreateBranchStep(),
      OnboardingStep.openingStock   => const _OpeningStockStep(),
      OnboardingStep.inviteStaff    => const _InviteStaffStep(),
    };
  }
}

// ─── Step scaffold ─────────────────────────────────────────────────────────

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({
    required this.stepNumber,
    required this.totalSteps,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final int stepNumber;
  final int totalSteps;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress dots
              Row(
                children: List.generate(totalSteps, (i) {
                  final active = i < stepNumber;
                  final current = i == stepNumber - 1;
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: active || current ? AppColors.primary : AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              Text('Step $stepNumber of $totalSteps', style: AppTextStyles.label),
              const SizedBox(height: 8),
              Text(title, style: AppTextStyles.headline2),
              const SizedBox(height: 8),
              Text(subtitle, style: AppTextStyles.bodySmall),
              const SizedBox(height: 32),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Step 1: Select Shop Type ───────────────────────────────────────────────

class _SelectShopTypeStep extends ConsumerWidget {
  const _SelectShopTypeStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void select(String type) =>
        ref.read(onboardingProvider.notifier).selectShopType(type);

    return _StepScaffold(
      stepNumber: 1,
      totalSteps: 5,
      title: 'What kind of business?',
      subtitle: 'This shapes your experience and cannot be changed later.',
      child: Column(
        children: [
          _TypeCard(
            icon: Icons.storefront_outlined,
            title: 'Retail Shop',
            description:
                'Sell directly to walk-in customers. Great for general stores, boutiques, and small shops.',
            onTap: () => select(ShopType.retail),
          ),
          const SizedBox(height: 16),
          _TypeCard(
            icon: Icons.warehouse_outlined,
            title: 'Wholesale / Distributor',
            description:
                'Sell in bulk to other businesses. Includes batch tracking, expiry dates, and invoice printing.',
            onTap: () => select(ShopType.wholesale),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.headline3),
                  const SizedBox(height: 4),
                  Text(description, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ─── Step 2: Create Shop ────────────────────────────────────────────────────

class _CreateShopStep extends ConsumerStatefulWidget {
  const _CreateShopStep();

  @override
  ConsumerState<_CreateShopStep> createState() => _CreateShopStepState();
}

class _CreateShopStepState extends ConsumerState<_CreateShopStep> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(onboardingProvider.notifier).createShop(_nameCtrl.text);
    if (!ok && mounted) {
      final err = ref.read(onboardingProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Failed'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(onboardingProvider).loading;
    return _StepScaffold(
      stepNumber: 2,
      totalSteps: 5,
      title: 'Name your shop',
      subtitle: 'This is how your shop will appear across the app.',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            AppTextField(
              controller: _nameCtrl,
              label: 'Shop Name',
              hint: 'e.g. Habesha General Store',
              autofocus: true,
              prefixIcon: const Icon(Icons.storefront_outlined),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _next(),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Shop name is required';
                return null;
              },
            ),
            const Spacer(),
            AppButton(label: 'Continue', loading: loading, onPressed: _next),
          ],
        ),
      ),
    );
  }
}

// ─── Step 2: Create Branch ──────────────────────────────────────────────────

class _CreateBranchStep extends ConsumerStatefulWidget {
  const _CreateBranchStep();

  @override
  ConsumerState<_CreateBranchStep> createState() => _CreateBranchStepState();
}

class _CreateBranchStepState extends ConsumerState<_CreateBranchStep> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController(text: 'Main Branch');
  final _addressCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(onboardingProvider.notifier).createBranch(
          _nameCtrl.text,
          address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        );
    if (!ok && mounted) {
      final err = ref.read(onboardingProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Failed'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(onboardingProvider).loading;
    return _StepScaffold(
      stepNumber: 3,
      totalSteps: 5,
      title: 'Add your shop location',
      subtitle: 'Where you sell from. You can rename it later in Settings.',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            AppTextField(
              controller: _nameCtrl,
              label: 'Branch Name',
              autofocus: true,
              prefixIcon: const Icon(Icons.location_on_outlined),
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Branch name is required';
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _addressCtrl,
              label: 'Address (optional)',
              prefixIcon: const Icon(Icons.map_outlined),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _next(),
            ),
            const Spacer(),
            AppButton(label: 'Continue', loading: loading, onPressed: _next),
          ],
        ),
      ),
    );
  }
}

// ─── Step 3: Opening Stock (skippable) ──────────────────────────────────────

class _OpeningStockStep extends ConsumerWidget {
  const _OpeningStockStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _StepScaffold(
      stepNumber: 4,
      totalSteps: 5,
      title: 'Add opening stock',
      subtitle: 'Enter your existing inventory. You can always do this later.',
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Opening stock lets you track what you currently have before your first sale.',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          AppButton(
            label: 'Add Stock Later',
            outlined: true,
            onPressed: () => ref
                .read(onboardingProvider.notifier)
                .skipToStep(OnboardingStep.inviteStaff),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Add Opening Stock',
            onPressed: () => ref
                .read(onboardingProvider.notifier)
                .skipToStep(OnboardingStep.inviteStaff),
            // TODO(phase3): navigate to inventory entry when built
          ),
        ],
      ),
    );
  }
}

// ─── Step 4: Invite Staff (skippable) ───────────────────────────────────────

class _InviteStaffStep extends ConsumerWidget {
  const _InviteStaffStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _StepScaffold(
      stepNumber: 5,
      totalSteps: 5,
      title: 'Invite your staff',
      subtitle: 'Add managers and cashiers. You can do this later in Settings.',
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.people_outline, color: AppColors.primary, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Staff members get their own login and see only what their role allows.',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          AppButton(
            label: 'Invite Later',
            outlined: true,
            onPressed: () => context.go(AppRoutes.dashboard),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Get Started',
            icon: Icons.rocket_launch_outlined,
            onPressed: () => context.go(AppRoutes.dashboard),
          ),
        ],
      ),
    );
  }
}
