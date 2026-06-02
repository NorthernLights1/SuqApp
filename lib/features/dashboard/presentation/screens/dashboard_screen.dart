import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/auth/presentation/providers/shop_provider.dart';
import '../../../../domain/models/sale.dart';
import '../../../../features/customers/presentation/providers/customers_provider.dart';
import '../../../../features/customers/presentation/screens/customers_screen.dart';
import '../../../../features/inventory/presentation/providers/inventory_provider.dart';
import '../../../../features/sales/presentation/providers/sales_provider.dart';
import '../../../../features/sales/presentation/screens/sales_screen.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/router/app_routes.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  static const _navItems = [
    NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
    NavigationDestination(icon: Icon(Icons.point_of_sale_outlined), selectedIcon: Icon(Icons.point_of_sale), label: 'Sales'),
    NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Inventory'),
    NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Customers'),
    NavigationDestination(icon: Icon(Icons.more_horiz), selectedIcon: Icon(Icons.more_horiz), label: 'More'),
  ];

  @override
  Widget build(BuildContext context) {
    ref.watch(seedNotifierProvider); // triggers local DB seed on login
    final shop = ref.watch(currentShopProvider);

    return Scaffold(
      appBar: AppBar(
        title: shop.when(
          data: (s) => Text(s?.name ?? 'Suq'),
          loading: () => const Text('Suq'),
          error: (e, st) => const Text('Suq'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: _navItems,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primaryLight,
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.newSale),
              icon: const Icon(Icons.add),
              label: const Text('New Sale'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildBody() {
    return switch (_selectedIndex) {
      0 => const _HomeTab(),
      1 => const _SalesTab(),
      2 => const _InventoryQuickTab(),
      3 => const _CustomersQuickTab(),
      _ => const _MoreTab(),
    };
  }
}

// ─── Home Tab ───────────────────────────────────────────────────────────────

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branches = ref.watch(currentShopBranchesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Branch selector
          branches.when(
            data: (list) => list.isEmpty
                ? const SizedBox.shrink()
                : _BranchChip(branches: list),
            loading: () => const LinearProgressIndicator(),
            error: (e, st) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 20),
          Text("Today's Summary", style: AppTextStyles.headline3),
          const SizedBox(height: 12),
          _TodayTotalsRow(),
          const SizedBox(height: 24),
          Text('Quick Actions', style: AppTextStyles.headline3),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: [
              _QuickAction(icon: Icons.point_of_sale, label: 'New Sale', route: AppRoutes.newSale),
              _QuickAction(icon: Icons.inventory_2_outlined, label: 'Inventory', route: AppRoutes.inventory),
              _QuickAction(icon: Icons.people_outline, label: 'Customers', route: AppRoutes.customers),
              _QuickAction(icon: Icons.money_off_outlined, label: 'Expenses', route: AppRoutes.expenses),
              _QuickAction(icon: Icons.bar_chart, label: 'Reports', route: AppRoutes.reports),
              _QuickAction(icon: Icons.settings_outlined, label: 'Settings', route: AppRoutes.settings),
            ],
          ),
        ],
      ),
    );
  }
}

class _BranchChip extends ConsumerWidget {
  const _BranchChip({required this.branches});
  final List branches;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeBranchProvider);
    final display = active ?? (branches.isNotEmpty ? branches.first : null);

    if (display == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(display.name as String, style: AppTextStyles.label.copyWith(color: AppColors.primary)),
          const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.primary),
        ],
      ),
    );
  }
}

class _TodayTotalsRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(todaySalesTotalsProvider);
    return totals.when(
      data: (t) => Row(
        children: [
          _SummaryCard(
            label: 'Sales',
            value: 'ETB ${t['total']?.toStringAsFixed(2) ?? '0.00'}',
            icon: Icons.trending_up,
            color: AppColors.success,
          ),
          const SizedBox(width: 12),
          _SummaryCard(
            label: 'Transactions',
            value: t['count']?.toStringAsFixed(0) ?? '0',
            icon: Icons.receipt_outlined,
            color: AppColors.primary,
          ),
        ],
      ),
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: LinearProgressIndicator()),
      ),
      error: (e, st) => Row(
        children: [
          _SummaryCard(label: 'Sales', value: 'ETB 0.00', icon: Icons.trending_up, color: AppColors.success),
          const SizedBox(width: 12),
          _SummaryCard(label: 'Transactions', value: '0', icon: Icons.receipt_outlined, color: AppColors.primary),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value, required this.icon, required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value, style: AppTextStyles.headline3),
            Text(label, style: AppTextStyles.label),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.route});
  final IconData icon;
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 26),
            const SizedBox(height: 6),
            Text(label, style: AppTextStyles.label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─── Sales Tab (embeds SalesScreen inline) ──────────────────────────────────

class _SalesTab extends ConsumerWidget {
  const _SalesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sales = ref.watch(salesListProvider);
    return sales.when(
      data: (list) => list.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textDisabled),
                  const SizedBox(height: 12),
                  Text('No sales today', style: AppTextStyles.headline3),
                  const SizedBox(height: 4),
                  Text('Tap + New Sale to record one', style: AppTextStyles.bodySmall),
                ],
              ),
            )
          : ListView.separated(
              itemCount: list.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final s = list[i];
                final isVoided = s.status == SaleStatus.voided;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isVoided ? AppColors.error.withValues(alpha: 0.1) : AppColors.primaryLight,
                    child: Icon(isVoided ? Icons.cancel_outlined : Icons.receipt_outlined,
                        color: isVoided ? AppColors.error : AppColors.primary, size: 20),
                  ),
                  title: Text('ETB ${s.total.toStringAsFixed(2)}',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: isVoided ? TextDecoration.lineThrough : null,
                      )),
                  subtitle: Text('${s.items.length} item(s)', style: AppTextStyles.bodySmall),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SaleDetailScreen(sale: s)),
                  ),
                );
              },
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e', style: AppTextStyles.bodySmall)),
    );
  }
}

// ─── Inventory Quick Tab ────────────────────────────────────────────────────

class _InventoryQuickTab extends ConsumerWidget {
  const _InventoryQuickTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stock = ref.watch(stockLevelsProvider);
    return stock.when(
      data: (list) {
        final lowStock = list.where((e) => e.isLowStock).toList();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (lowStock.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_outlined, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Text('${lowStock.length} item(s) running low',
                        style: AppTextStyles.body.copyWith(color: AppColors.warning)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            AppButton(
              label: 'Manage Inventory',
              outlined: true,
              onPressed: () => context.push(AppRoutes.inventory),
            ),
            const SizedBox(height: 16),
            if (list.isEmpty)
              Center(
                child: Text('No stock recorded yet', style: AppTextStyles.bodySmall),
              )
            else
              ...list.take(10).map((e) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(e.productName, style: AppTextStyles.body),
                    trailing: Text(
                      '${e.quantity.toStringAsFixed(2)} ${e.unitAbbr}',
                      style: AppTextStyles.body.copyWith(
                        color: e.isLowStock ? AppColors.warning : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e', style: AppTextStyles.bodySmall)),
    );
  }
}

// ─── Customers Quick Tab ─────────────────────────────────────────────────────

class _CustomersQuickTab extends ConsumerWidget {
  const _CustomersQuickTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customers = ref.watch(customersProvider);
    return customers.when(
      data: (list) {
        final debtors = list.where((c) => c.hasDebt).toList();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (debtors.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${debtors.length} customer(s) with outstanding credit',
                  style: AppTextStyles.body.copyWith(color: AppColors.warning),
                ),
              ),
              const SizedBox(height: 12),
            ],
            AppButton(
              label: 'Manage Customers',
              outlined: true,
              onPressed: () => context.push(AppRoutes.customers),
            ),
            const SizedBox(height: 16),
            ...list.take(10).map((c) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: c.hasDebt
                        ? AppColors.warning.withValues(alpha: 0.15)
                        : AppColors.primaryLight,
                    child: Text(c.name[0].toUpperCase(),
                        style: TextStyle(
                            color: c.hasDebt ? AppColors.warning : AppColors.primary,
                            fontWeight: FontWeight.w700)),
                  ),
                  title: Text(c.name, style: AppTextStyles.body),
                  trailing: c.hasDebt
                      ? Text('ETB ${c.creditBalance.toStringAsFixed(2)}',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.warning, fontWeight: FontWeight.w600))
                      : null,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => CustomerDetailScreen(customer: c))),
                )),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e', style: AppTextStyles.bodySmall)),
    );
  }
}

// ─── More Tab ───────────────────────────────────────────────────────────────

class _MoreTab extends ConsumerWidget {
  const _MoreTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _MoreTile(icon: Icons.money_off_outlined, label: 'Expenses', route: AppRoutes.expenses),
        _MoreTile(icon: Icons.bar_chart, label: 'Reports', route: AppRoutes.reports),
        _MoreTile(icon: Icons.people_outline, label: 'Staff', route: AppRoutes.staff),
        _MoreTile(icon: Icons.settings_outlined, label: 'Settings', route: AppRoutes.settings),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: AppColors.error),
          title: Text('Sign Out', style: TextStyle(color: AppColors.error)),
          onTap: () async {
            await ref.read(authNotifierProvider.notifier).signOut();
            if (context.mounted) context.go(AppRoutes.login);
          },
        ),
      ],
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({required this.icon, required this.label, required this.route});
  final IconData icon;
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(label, style: AppTextStyles.body),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: () => context.push(route),
    );
  }
}

