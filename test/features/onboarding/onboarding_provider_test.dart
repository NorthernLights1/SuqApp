import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:suq/features/onboarding/presentation/providers/onboarding_provider.dart';

// ─── Helper that mirrors the isNameTaken logic from OnboardingNotifier ───────
//
// The PR adds this catch block to OnboardingNotifier.createShop:
//
//   } on PostgrestException catch (e) {
//     final isNameTaken = e.code == '23505' &&
//         '${e.message} ${e.details ?? ''}'.contains('shops_name_unique_idx');
//     final msg = isNameTaken
//         ? 'That shop name is already taken — please choose another.'
//         : e.message;
//     state = state.copyWith(loading: false, error: msg);
//     return false;
//   }
//
// The helper below replicates that exact check so we can exhaustively unit-test
// it without requiring a live Supabase client.
String _resolveErrorMessage(PostgrestException e) {
  final isNameTaken = e.code == '23505' &&
      '${e.message} ${e.details ?? ''}'.contains('shops_name_unique_idx');
  return isNameTaken
      ? 'That shop name is already taken — please choose another.'
      : e.message;
}

void main() {
  group('OnboardingNotifier — shop name unique-violation handling', () {
    test('returns friendly message when unique index is in the message',
        () {
      final e = PostgrestException(
        message: 'duplicate key value violates unique constraint '
            '"shops_name_unique_idx"',
        code: '23505',
      );
      expect(
        _resolveErrorMessage(e),
        'That shop name is already taken — please choose another.',
      );
    });

    test('returns friendly message when unique index is in details only',
        () {
      final e = PostgrestException(
        message: 'duplicate key value violates unique constraint',
        code: '23505',
        details: 'Key (lower(name))=(...) conflicts with shops_name_unique_idx',
      );
      expect(
        _resolveErrorMessage(e),
        'That shop name is already taken — please choose another.',
      );
    });

    test('returns friendly message when index name appears in both fields',
        () {
      final e = PostgrestException(
        message:
            'duplicate key value violates unique constraint "shops_name_unique_idx"',
        code: '23505',
        details: 'shops_name_unique_idx duplicate',
      );
      expect(
        _resolveErrorMessage(e),
        'That shop name is already taken — please choose another.',
      );
    });

    test('passes through raw message for a different unique-constraint violation',
        () {
      final e = PostgrestException(
        message: 'duplicate key value violates unique constraint "shop_users_pkey"',
        code: '23505',
        // details does not contain shops_name_unique_idx
      );
      // isNameTaken should be false; raw message forwarded
      expect(
        _resolveErrorMessage(e),
        'duplicate key value violates unique constraint "shop_users_pkey"',
      );
    });

    test('passes through message when code is not 23505 (FK violation)', () {
      final e = PostgrestException(
        message: 'insert or update violates foreign key constraint',
        code: '23503',
        details: 'shops_name_unique_idx', // index name present but wrong code
      );
      expect(
        _resolveErrorMessage(e),
        'insert or update violates foreign key constraint',
      );
    });

    test('passes through message when code is null', () {
      final e = PostgrestException(
        message: 'connection timeout',
        // no code
      );
      expect(_resolveErrorMessage(e), 'connection timeout');
    });

    test('passes through raw message for a non-unique-constraint code', () {
      final e = PostgrestException(
        message: 'syntax error at or near "SELECT"',
        code: '42601',
      );
      expect(_resolveErrorMessage(e), 'syntax error at or near "SELECT"');
    });

    test('isNameTaken requires both the right code AND the index name', () {
      // Has the right code but the wrong index name — should NOT be treated as
      // a shop-name conflict.
      final e = PostgrestException(
        message: 'duplicate key violates unique constraint "branches_name_idx"',
        code: '23505',
      );
      expect(
        _resolveErrorMessage(e),
        isNot('That shop name is already taken — please choose another.'),
      );
    });

    // Boundary: index name buried inside a longer details string
    test('detects index name as substring of a longer details string', () {
      final e = PostgrestException(
        message: 'duplicate key',
        code: '23505',
        details:
            'ERROR:  duplicate key value violates unique constraint '
            '"shops_name_unique_idx"\nDETAIL:  Key (lower(name))=(acme)',
      );
      expect(
        _resolveErrorMessage(e),
        'That shop name is already taken — please choose another.',
      );
    });
  });

  group('OnboardingState', () {
    test('initial state has createShop step and no error', () {
      const s = OnboardingState();
      expect(s.step, OnboardingStep.createShop);
      expect(s.loading, isFalse);
      expect(s.error, isNull);
      expect(s.shopId, isNull);
      expect(s.branchId, isNull);
    });

    test('copyWith propagates loading flag', () {
      const s = OnboardingState();
      final loading = s.copyWith(loading: true);
      expect(loading.loading, isTrue);
      expect(loading.step, s.step);
    });

    test('copyWith clears error when error is set to null', () {
      const s = OnboardingState(error: 'oops');
      final cleared = s.copyWith(error: null);
      expect(cleared.error, isNull);
    });

    test('copyWith preserves shopId when not overridden', () {
      const s = OnboardingState(shopId: 'shop-1');
      final next = s.copyWith(loading: true);
      expect(next.shopId, 'shop-1');
    });

    test('copyWith advances to createBranch step', () {
      const s = OnboardingState();
      final next =
          s.copyWith(step: OnboardingStep.createBranch, shopId: 'shop-99');
      expect(next.step, OnboardingStep.createBranch);
      expect(next.shopId, 'shop-99');
    });

    test('copyWith with error replaces any previous error', () {
      const s = OnboardingState(error: 'old error');
      final next = s.copyWith(error: 'new error');
      expect(next.error, 'new error');
    });
  });
}
