import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/accept_invite_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/sales/presentation/screens/sales_screen.dart';
import '../../features/sales/presentation/screens/new_sale_screen.dart';
import '../../features/inventory/presentation/screens/inventory_screen.dart';
import '../../features/customers/presentation/screens/customers_screen.dart';
import '../../features/expenses/presentation/screens/expenses_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/staff/presentation/screens/staff_screen.dart';
import 'app_routes.dart';

/// Notifies GoRouter whenever Supabase auth state changes.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier() {
    Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }
}

GoRouter createRouter() {
  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: _AuthRefreshNotifier(),
    redirect: (context, state) async {
      try {
        final client = Supabase.instance.client;
        final session = client.auth.currentSession;
        final isLoggedIn = session != null;
        final loc = state.matchedLocation;
        final isAuthRoute = loc == AppRoutes.login ||
            loc == AppRoutes.signup ||
            loc == AppRoutes.acceptInvite;

        // Not logged in → force to login (but allow the invite-acceptance screen)
        if (!isLoggedIn) {
          return isAuthRoute ? null : AppRoutes.login;
        }

        // Logged in, not on an auth screen → no redirect needed
        if (!isAuthRoute) return null;

        // Logged in, on auth screen → check if shop exists (owner) or staff
        // membership. Bound the network calls: offline these would otherwise
        // hang with no UI, showing a black screen on cold start. On timeout
        // the catch below sends an already-logged-in user to the dashboard.
        const lookupTimeout = Duration(seconds: 5);

        final shopData = await client
            .from('shops')
            .select('id')
            .eq('owner_id', session.user.id)
            .maybeSingle()
            .timeout(lookupTimeout);

        if (shopData != null) return AppRoutes.dashboard;

        // Not an owner — check staff membership
        final memberData = await client
            .from('shop_users')
            .select('id, status')
            .eq('user_id', session.user.id)
            .neq('status', 'suspended')
            .maybeSingle()
            .timeout(lookupTimeout);

        if (memberData != null) {
          // Activate invited staff on first login. shop_users is
          // owner-write-only, so a staff member can't update their own row;
          // this SECURITY DEFINER RPC flips their own invited membership active.
          if (memberData['status'] == 'invited') {
            await client.rpc('activate_my_membership');
          }
          return AppRoutes.dashboard;
        }

        return AppRoutes.onboarding;
      } catch (_) {
        // If the shop query fails for any reason, fall back to login
        final isLoggedIn =
            Supabase.instance.client.auth.currentSession != null;
        return isLoggedIn ? AppRoutes.dashboard : AppRoutes.login;
      }
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.acceptInvite,
        builder: (context, state) => const AcceptInviteScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(path: AppRoutes.sales,     builder: (context, state) => const SalesScreen()),
      GoRoute(path: AppRoutes.newSale,   builder: (context, state) => const NewSaleScreen()),
      GoRoute(path: AppRoutes.inventory, builder: (context, state) => const InventoryScreen()),
      GoRoute(path: AppRoutes.customers, builder: (context, state) => const CustomersScreen()),
      GoRoute(path: AppRoutes.expenses,  builder: (context, state) => const ExpensesScreen()),
      GoRoute(path: AppRoutes.reports,   builder: (context, state) => const ReportsScreen()),
      GoRoute(path: AppRoutes.settings,  builder: (context, state) => const SettingsScreen()),
      GoRoute(path: AppRoutes.staff,     builder: (context, state) => const StaffScreen()),
    ],
  );
}

