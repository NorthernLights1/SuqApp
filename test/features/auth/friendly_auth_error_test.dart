import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:suq/features/auth/presentation/providers/auth_provider.dart';

void main() {
  group('friendlyAuthError', () {
    test('offline (retryable fetch) → connection message, not raw exception', () {
      final msg = friendlyAuthError(
        AuthRetryableFetchException(message: 'Failed host lookup'),
      );
      expect(msg, contains('internet'));
      expect(msg, isNot(contains('Exception')));
    });

    test('raw socket error → connection message', () {
      final msg =
          friendlyAuthError(Exception('SocketException: Failed host lookup'));
      expect(msg, contains('internet'));
    });

    test('wrong credentials (400) → incorrect email or password', () {
      final msg = friendlyAuthError(
        AuthApiException('Invalid login credentials', statusCode: '400'),
      );
      expect(msg, 'Incorrect email or password.');
    });

    test('rate limit (429) → wait message', () {
      final msg = friendlyAuthError(
        AuthApiException('Too many requests', statusCode: '429'),
      );
      expect(msg, contains('wait'));
    });

    test('unknown error → generic fallback, never raw', () {
      final msg = friendlyAuthError(StateError('boom'));
      expect(msg, 'Could not sign in. Please try again.');
    });
  });
}
