import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../providers/staff_provider.dart';

class StaffScreen extends ConsumerWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(staffListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Staff')),
      body: staff.when(
        data: (list) => list.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_outline,
                        size: 64, color: AppColors.textDisabled),
                    const SizedBox(height: 12),
                    Text('No staff members found',
                        style: AppTextStyles.headline3),
                    const SizedBox(height: 4),
                    Text('Add team members in Supabase',
                        style: AppTextStyles.bodySmall),
                  ],
                ),
              )
            : ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (ctx, i) => _StaffTile(member: list[i]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) =>
            Center(child: Text('Error: $e', style: AppTextStyles.bodySmall)),
      ),
    );
  }
}

class _StaffTile extends ConsumerWidget {
  const _StaffTile({required this.member});
  final StaffMember member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saving = ref.watch(staffStatusProvider).isLoading;

    Color statusColor = switch (member.status) {
      'active' => AppColors.success,
      'suspended' => AppColors.error,
      _ => AppColors.textSecondary,
    };

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: member.isSuspended
            ? AppColors.error.withValues(alpha: 0.1)
            : AppColors.primaryLight,
        child: Text(
          member.displayName[0].toUpperCase(),
          style: TextStyle(
            color: member.isSuspended ? AppColors.error : AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: Text(member.displayName, style: AppTextStyles.body),
      subtitle: Text(member.roleName, style: AppTextStyles.bodySmall),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              member.status,
              style: AppTextStyles.label.copyWith(color: statusColor),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
      onTap: saving ? null : () => _showActions(context, ref),
    );
  }

  void _showActions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    child: Text(member.displayName[0].toUpperCase(),
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member.displayName, style: AppTextStyles.body),
                      Text(member.roleName, style: AppTextStyles.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            if (member.isActive)
              ListTile(
                leading:
                    const Icon(Icons.block_outlined, color: AppColors.error),
                title: Text('Suspend Access',
                    style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  ref
                      .read(staffStatusProvider.notifier)
                      .setStatus(member.id, 'suspended');
                },
              ),
            if (member.isSuspended)
              ListTile(
                leading: const Icon(Icons.check_circle_outline,
                    color: AppColors.success),
                title: Text('Restore Access',
                    style: TextStyle(color: AppColors.success)),
                onTap: () {
                  Navigator.pop(context);
                  ref
                      .read(staffStatusProvider.notifier)
                      .setStatus(member.id, 'active');
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
