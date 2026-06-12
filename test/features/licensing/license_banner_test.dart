import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suq/features/licensing/presentation/providers/license_provider.dart';
import 'package:suq/features/licensing/presentation/widgets/license_banner.dart';

// Helper: pumps LicenseWarningBanner with a pre-resolved licenseStatusProvider.
Widget _buildBanner(LicenseStatus status) {
  return ProviderScope(
    overrides: [
      licenseStatusProvider.overrideWith((ref) async => status),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: Column(
          children: [LicenseWarningBanner()],
        ),
      ),
    ),
  );
}

void main() {
  group('LicenseWarningBanner — hidden cases', () {
    testWidgets('renders nothing when license is ok without a daysLeft value',
        (tester) async {
      await tester.pumpWidget(_buildBanner(LicenseStatus.ok));
      await tester.pump();

      expect(find.text('Enter serial'), findsNothing);
      expect(find.byType(Material), findsOneWidget); // only the Scaffold material
    });

    testWidgets('renders nothing when license is ok with daysLeft above threshold',
        (tester) async {
      const status = LicenseStatus(LicenseState.ok, daysLeft: 8);
      await tester.pumpWidget(_buildBanner(status));
      await tester.pump();

      expect(find.text('Enter serial'), findsNothing);
    });

    testWidgets('renders nothing when license is expired', (tester) async {
      const status = LicenseStatus(LicenseState.expired);
      await tester.pumpWidget(_buildBanner(status));
      await tester.pump();

      expect(find.text('Enter serial'), findsNothing);
    });

    testWidgets('renders nothing when license is blocked', (tester) async {
      const status = LicenseStatus(LicenseState.blocked);
      await tester.pumpWidget(_buildBanner(status));
      await tester.pump();

      expect(find.text('Enter serial'), findsNothing);
    });

    testWidgets('renders nothing while provider is loading', (tester) async {
      // Do NOT pump after pumpWidget — keep provider in loading state.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            licenseStatusProvider.overrideWith((ref) async {
              await Future<void>.delayed(const Duration(hours: 1));
              return LicenseStatus.ok;
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(body: LicenseWarningBanner()),
          ),
        ),
      );
      expect(find.text('Enter serial'), findsNothing);
    });
  });

  group('LicenseWarningBanner — visible cases', () {
    testWidgets('shows banner when daysLeft equals the warning threshold (7)',
        (tester) async {
      const status = LicenseStatus(LicenseState.ok, daysLeft: 7);
      await tester.pumpWidget(_buildBanner(status));
      await tester.pump();

      expect(find.text('Enter serial'), findsOneWidget);
    });

    testWidgets('shows banner when daysLeft is inside the warning window',
        (tester) async {
      const status = LicenseStatus(LicenseState.ok, daysLeft: 3);
      await tester.pumpWidget(_buildBanner(status));
      await tester.pump();

      expect(find.text('Enter serial'), findsOneWidget);
    });
  });

  group('LicenseWarningBanner — time label for trials', () {
    testWidgets('shows "today" when trial expires today (daysLeft = 0)',
        (tester) async {
      const status =
          LicenseStatus(LicenseState.ok, daysLeft: 0, isTrial: true);
      await tester.pumpWidget(_buildBanner(status));
      await tester.pump();

      expect(find.text('Free trial ends today'), findsOneWidget);
    });

    testWidgets('shows "in 1 day" when trial expires tomorrow', (tester) async {
      const status =
          LicenseStatus(LicenseState.ok, daysLeft: 1, isTrial: true);
      await tester.pumpWidget(_buildBanner(status));
      await tester.pump();

      expect(find.text('Free trial ends in 1 day'), findsOneWidget);
    });

    testWidgets('shows "in N days" for multi-day trial countdowns',
        (tester) async {
      const status =
          LicenseStatus(LicenseState.ok, daysLeft: 5, isTrial: true);
      await tester.pumpWidget(_buildBanner(status));
      await tester.pump();

      expect(find.text('Free trial ends in 5 days'), findsOneWidget);
    });

    testWidgets('trial at boundary shows "in 7 days" for threshold day',
        (tester) async {
      const status =
          LicenseStatus(LicenseState.ok, daysLeft: 7, isTrial: true);
      await tester.pumpWidget(_buildBanner(status));
      await tester.pump();

      expect(find.text('Free trial ends in 7 days'), findsOneWidget);
    });
  });

  group('LicenseWarningBanner — time label for paid licenses', () {
    testWidgets('shows "License expires today" when daysLeft = 0',
        (tester) async {
      const status = LicenseStatus(LicenseState.ok, daysLeft: 0, isTrial: false);
      await tester.pumpWidget(_buildBanner(status));
      await tester.pump();

      expect(find.text('License expires today'), findsOneWidget);
    });

    testWidgets('shows "License expires in 1 day" when daysLeft = 1',
        (tester) async {
      const status = LicenseStatus(LicenseState.ok, daysLeft: 1, isTrial: false);
      await tester.pumpWidget(_buildBanner(status));
      await tester.pump();

      expect(find.text('License expires in 1 day'), findsOneWidget);
    });

    testWidgets('shows "License expires in N days" for multi-day countdown',
        (tester) async {
      const status = LicenseStatus(LicenseState.ok, daysLeft: 4, isTrial: false);
      await tester.pumpWidget(_buildBanner(status));
      await tester.pump();

      expect(find.text('License expires in 4 days'), findsOneWidget);
    });
  });

  group('LicenseWarningBanner — trial vs license label distinction', () {
    testWidgets('trial label says "Free trial ends" not "License expires"',
        (tester) async {
      const status = LicenseStatus(LicenseState.ok, daysLeft: 3, isTrial: true);
      await tester.pumpWidget(_buildBanner(status));
      await tester.pump();

      expect(find.textContaining('Free trial ends'), findsOneWidget);
      expect(find.textContaining('License expires'), findsNothing);
    });

    testWidgets('license label says "License expires" not "Free trial ends"',
        (tester) async {
      const status =
          LicenseStatus(LicenseState.ok, daysLeft: 3, isTrial: false);
      await tester.pumpWidget(_buildBanner(status));
      await tester.pump();

      expect(find.textContaining('License expires'), findsOneWidget);
      expect(find.textContaining('Free trial ends'), findsNothing);
    });
  });

  group('LicenseWarningBanner — tapping opens serial dialog', () {
    testWidgets('tapping the banner opens the serial entry dialog',
        (tester) async {
      const status = LicenseStatus(LicenseState.ok, daysLeft: 3, isTrial: true);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            licenseStatusProvider.overrideWith((ref) async => status),
            activateLicenseProvider.overrideWith(
              () => _AlwaysRejectingActivateNotifier(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: LicenseWarningBanner()),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Enter serial'));
      await tester.pumpAndSettle();

      // Dialog should be showing the title
      expect(find.text('Enter serial number'), findsOneWidget);
    });

    testWidgets('serial dialog has Cancel button', (tester) async {
      const status = LicenseStatus(LicenseState.ok, daysLeft: 2, isTrial: false);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            licenseStatusProvider.overrideWith((ref) async => status),
            activateLicenseProvider.overrideWith(
              () => _AlwaysRejectingActivateNotifier(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: LicenseWarningBanner()),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Enter serial'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('dismissing dialog via Cancel hides it', (tester) async {
      const status = LicenseStatus(LicenseState.ok, daysLeft: 2);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            licenseStatusProvider.overrideWith((ref) async => status),
            activateLicenseProvider.overrideWith(
              () => _AlwaysRejectingActivateNotifier(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: LicenseWarningBanner()),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Enter serial'));
      await tester.pumpAndSettle();
      expect(find.text('Enter serial number'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Enter serial number'), findsNothing);
    });
  });

  group('LicenseWarningBanner — serial dialog validation', () {
    testWidgets('shows error when fewer than 10 digits entered in dialog',
        (tester) async {
      const status = LicenseStatus(LicenseState.ok, daysLeft: 2, isTrial: true);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            licenseStatusProvider.overrideWith((ref) async => status),
            activateLicenseProvider.overrideWith(
              () => _AlwaysRejectingActivateNotifier(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: LicenseWarningBanner()),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Enter serial'));
      await tester.pumpAndSettle();

      // Enter too-short serial
      await tester.enterText(find.byType(TextField), '12345');
      await tester.tap(find.text('Activate'));
      await tester.pump();

      expect(find.text('The serial number is 10 digits'), findsOneWidget);
    });

    testWidgets('shows rejection error when server rejects valid-length key',
        (tester) async {
      const status = LicenseStatus(LicenseState.ok, daysLeft: 1, isTrial: true);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            licenseStatusProvider.overrideWith((ref) async => status),
            activateLicenseProvider.overrideWith(
              () => _AlwaysRejectingActivateNotifier(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: LicenseWarningBanner()),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Enter serial'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '1234567890');
      await tester.tap(find.text('Activate'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Serial not accepted'),
        findsOneWidget,
      );
    });
  });
}

// ─── Test stub ───────────────────────────────────────────────────────────────

/// Always returns false (rejected) so we can test error-path UI without a
/// real Supabase connection.
class _AlwaysRejectingActivateNotifier extends ActivateLicenseNotifier {
  @override
  Future<bool> activate(String key) async => false;
}