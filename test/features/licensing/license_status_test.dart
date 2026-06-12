import 'package:flutter_test/flutter_test.dart';
import 'package:suq/core/constants/app_constants.dart';
import 'package:suq/features/licensing/presentation/providers/license_provider.dart';

void main() {
  group('LicenseStatus.showWarning', () {
    test('false when state is expired', () {
      const status = LicenseStatus(LicenseState.expired);
      expect(status.showWarning, isFalse);
    });

    test('false when state is blocked', () {
      const status = LicenseStatus(LicenseState.blocked);
      expect(status.showWarning, isFalse);
    });

    test('false when state is ok but daysLeft is null', () {
      const status = LicenseStatus(LicenseState.ok);
      expect(status.showWarning, isFalse);
    });

    test('false when daysLeft exceeds the warning threshold', () {
      final status = LicenseStatus(
        LicenseState.ok,
        daysLeft: AppConstants.licenseWarningDays + 1,
      );
      expect(status.showWarning, isFalse);
    });

    test('true when daysLeft equals the warning threshold', () {
      final status = LicenseStatus(
        LicenseState.ok,
        daysLeft: AppConstants.licenseWarningDays,
      );
      expect(status.showWarning, isTrue);
    });

    test('true when daysLeft is below the warning threshold', () {
      final status = LicenseStatus(
        LicenseState.ok,
        daysLeft: AppConstants.licenseWarningDays - 1,
      );
      expect(status.showWarning, isTrue);
    });

    test('true when daysLeft is 1', () {
      const status = LicenseStatus(LicenseState.ok, daysLeft: 1);
      expect(status.showWarning, isTrue);
    });

    test('true when daysLeft is 0 (expiring today)', () {
      const status = LicenseStatus(LicenseState.ok, daysLeft: 0);
      expect(status.showWarning, isTrue);
    });
  });

  group('LicenseStatus static ok constant', () {
    test('has state ok', () {
      expect(LicenseStatus.ok.state, LicenseState.ok);
    });

    test('has null daysLeft', () {
      expect(LicenseStatus.ok.daysLeft, isNull);
    });

    test('is not a trial', () {
      expect(LicenseStatus.ok.isTrial, isFalse);
    });

    test('has null blockedReason', () {
      expect(LicenseStatus.ok.blockedReason, isNull);
    });

    test('showWarning is false', () {
      expect(LicenseStatus.ok.showWarning, isFalse);
    });
  });

  group('LicenseStatus isTrial', () {
    test('defaults to false', () {
      const status = LicenseStatus(LicenseState.ok, daysLeft: 5);
      expect(status.isTrial, isFalse);
    });

    test('can be set to true', () {
      const status = LicenseStatus(LicenseState.ok, daysLeft: 3, isTrial: true);
      expect(status.isTrial, isTrue);
    });

    test('trial status shows warning within warning window', () {
      const status = LicenseStatus(LicenseState.ok, daysLeft: 3, isTrial: true);
      expect(status.showWarning, isTrue);
    });
  });

  group('LicenseStatus blockedReason', () {
    test('null by default', () {
      const status = LicenseStatus(LicenseState.blocked);
      expect(status.blockedReason, isNull);
    });

    test('preserves provided reason', () {
      const reason = 'Unpaid invoices';
      const status = LicenseStatus(LicenseState.blocked, blockedReason: reason);
      expect(status.blockedReason, reason);
    });
  });

  group('LicenseStatus equality (Equatable)', () {
    test('two ok statuses with same daysLeft are equal', () {
      const a = LicenseStatus(LicenseState.ok, daysLeft: 5);
      const b = LicenseStatus(LicenseState.ok, daysLeft: 5);
      expect(a, b);
    });

    test('statuses with different daysLeft are not equal', () {
      const a = LicenseStatus(LicenseState.ok, daysLeft: 5);
      const b = LicenseStatus(LicenseState.ok, daysLeft: 4);
      expect(a, isNot(b));
    });

    test('statuses with different states are not equal', () {
      const a = LicenseStatus(LicenseState.ok);
      const b = LicenseStatus(LicenseState.expired);
      expect(a, isNot(b));
    });

    test('blocked statuses with different reasons are not equal', () {
      const a = LicenseStatus(LicenseState.blocked, blockedReason: 'reason 1');
      const b = LicenseStatus(LicenseState.blocked, blockedReason: 'reason 2');
      expect(a, isNot(b));
    });

    test('isTrial distinction is part of equality', () {
      const a = LicenseStatus(LicenseState.ok, daysLeft: 5, isTrial: true);
      const b = LicenseStatus(LicenseState.ok, daysLeft: 5, isTrial: false);
      expect(a, isNot(b));
    });
  });

  group('AppConstants license thresholds', () {
    test('licenseTrialDays is 14', () {
      expect(AppConstants.licenseTrialDays, 14);
    });

    test('licenseWarningDays is 7', () {
      expect(AppConstants.licenseWarningDays, 7);
    });

    test('warning window is strictly less than trial window', () {
      expect(AppConstants.licenseWarningDays,
          lessThan(AppConstants.licenseTrialDays));
    });
  });

  group('LicenseState enum', () {
    test('has exactly three values', () {
      expect(LicenseState.values, hasLength(3));
    });

    test('contains ok, expired, blocked', () {
      expect(LicenseState.values,
          containsAll([LicenseState.ok, LicenseState.expired, LicenseState.blocked]));
    });
  });
}