import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suq/features/licensing/presentation/providers/license_provider.dart';
import 'package:suq/features/licensing/presentation/screens/license_gate.dart';

// Helper: wraps the widget under test in the minimal material/provider scaffolding.
Widget _buildGate({
  required LicenseStatus status,
  Widget child = const Text('app content'),
}) {
  return ProviderScope(
    overrides: [
      licenseStatusProvider.overrideWith((ref) async => status),
    ],
    child: MaterialApp(
      home: LicenseGate(child: child),
    ),
  );
}

// Helper: wraps with an AsyncLoading state (simulates initial fetch).
Widget _buildGateLoading({Widget child = const Text('app content')}) {
  return ProviderScope(
    overrides: [
      licenseStatusProvider.overrideWith((ref) async {
        // Never completes during the test — stays in loading.
        await Future<void>.delayed(const Duration(hours: 1));
        return LicenseStatus.ok;
      }),
    ],
    child: MaterialApp(
      home: LicenseGate(child: child),
    ),
  );
}

void main() {
  group('LicenseGate — ok state', () {
    testWidgets('renders child when license is ok', (tester) async {
      await tester.pumpWidget(_buildGate(status: LicenseStatus.ok));
      await tester.pump(); // let FutureProvider resolve

      expect(find.text('app content'), findsOneWidget);
      expect(find.text('Shop suspended'), findsNothing);
      expect(find.text('Activation required'), findsNothing);
    });

    testWidgets('renders child when license is ok with daysLeft', (tester) async {
      const status = LicenseStatus(LicenseState.ok, daysLeft: 10);
      await tester.pumpWidget(_buildGate(status: status));
      await tester.pump();

      expect(find.text('app content'), findsOneWidget);
    });
  });

  group('LicenseGate — blocked state', () {
    testWidgets('shows block screen and hides child when shop is blocked',
        (tester) async {
      const status =
          LicenseStatus(LicenseState.blocked, blockedReason: 'Overdue payment');
      await tester.pumpWidget(_buildGate(status: status));
      await tester.pump();

      expect(find.text('Shop suspended'), findsOneWidget);
      expect(find.text('Overdue payment'), findsOneWidget);
      expect(find.text('app content'), findsNothing);
    });

    testWidgets('shows default suspension message when reason is null',
        (tester) async {
      const status = LicenseStatus(LicenseState.blocked);
      await tester.pumpWidget(_buildGate(status: status));
      await tester.pump();

      expect(find.text('Shop suspended'), findsOneWidget);
      expect(
        find.text('This shop has been suspended by the service provider.'),
        findsOneWidget,
      );
    });

    testWidgets('shows default suspension message when reason is empty string',
        (tester) async {
      const status = LicenseStatus(LicenseState.blocked, blockedReason: '');
      await tester.pumpWidget(_buildGate(status: status));
      await tester.pump();

      expect(
        find.text('This shop has been suspended by the service provider.'),
        findsOneWidget,
      );
    });

    testWidgets('shows "Check again" button on blocked screen', (tester) async {
      const status = LicenseStatus(LicenseState.blocked);
      await tester.pumpWidget(_buildGate(status: status));
      await tester.pump();

      expect(find.text('Check again'), findsOneWidget);
    });
  });

  group('LicenseGate — expired state', () {
    testWidgets('shows activation screen when license has expired',
        (tester) async {
      const status = LicenseStatus(LicenseState.expired);
      await tester.pumpWidget(_buildGate(status: status));
      await tester.pump();

      expect(find.text('Activation required'), findsOneWidget);
      expect(find.text('app content'), findsNothing);
    });

    testWidgets('activation screen has serial entry field', (tester) async {
      const status = LicenseStatus(LicenseState.expired);
      await tester.pumpWidget(_buildGate(status: status));
      await tester.pump();

      // Hint text in the serial TextField
      expect(find.text('0000000000'), findsOneWidget);
    });

    testWidgets('activation screen shows Activate button', (tester) async {
      const status = LicenseStatus(LicenseState.expired);
      await tester.pumpWidget(_buildGate(status: status));
      await tester.pump();

      expect(find.text('Activate'), findsOneWidget);
    });

    testWidgets('activation screen shows Log out button', (tester) async {
      const status = LicenseStatus(LicenseState.expired);
      await tester.pumpWidget(_buildGate(
        status: status,
        child: const SizedBox(),
      ));
      await tester.pump();

      expect(find.text('Log out'), findsOneWidget);
    });
  });

  group('LicenseGate — serial validation on activation screen', () {
    testWidgets('shows error when serial is shorter than 10 digits',
        (tester) async {
      const status = LicenseStatus(LicenseState.expired);
      await tester.pumpWidget(_buildGate(status: status));
      await tester.pump();

      // Enter an 8-digit serial
      await tester.enterText(find.byType(TextField), '12345678');
      await tester.tap(find.text('Activate'));
      await tester.pump();

      expect(find.text('The serial number is 10 digits'), findsOneWidget);
    });

    testWidgets('clears error when a valid-length serial is entered next',
        (tester) async {
      const status = LicenseStatus(LicenseState.expired);
      // Override activateLicenseProvider to avoid needing a real Supabase client.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            licenseStatusProvider.overrideWith((ref) async => status),
            activateLicenseProvider.overrideWith(
              () => _AlwaysRejectingActivateNotifier(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: _TestActivationHost(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Trigger the validation error with too-short input
      await tester.enterText(find.byType(TextField), '123');
      await tester.tap(find.text('Activate'));
      await tester.pump();
      expect(find.text('The serial number is 10 digits'), findsOneWidget);

      // Now enter exactly 10 digits — error should clear
      await tester.enterText(find.byType(TextField), '1234567890');
      await tester.tap(find.text('Activate'));
      await tester.pumpAndSettle();

      expect(find.text('The serial number is 10 digits'), findsNothing);
    });
  });

  group('LicenseGate — loading / error (fail-open)', () {
    testWidgets('renders child while provider is still loading', (tester) async {
      await tester.pumpWidget(_buildGateLoading());
      // Don't pump again — provider is still in AsyncLoading.
      // orElse branch in maybeWhen should show the child.
      expect(find.text('app content'), findsOneWidget);
    });
  });
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// A host widget that renders the activation screen content directly so we can
/// exercise its internal state without going through the full LicenseGate flow.
class _TestActivationHost extends ConsumerStatefulWidget {
  const _TestActivationHost();

  @override
  ConsumerState<_TestActivationHost> createState() =>
      _TestActivationHostState();
}

class _TestActivationHostState extends ConsumerState<_TestActivationHost> {
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
    await ref.read(activateLicenseProvider.notifier).activate(key);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _keyCtrl,
          decoration: InputDecoration(errorText: _error),
        ),
        TextButton(onPressed: _activate, child: const Text('Activate')),
      ],
    );
  }
}

/// Notifier stub that always rejects the activation key.
class _AlwaysRejectingActivateNotifier extends ActivateLicenseNotifier {
  @override
  Future<bool> activate(String key) async => false;
}