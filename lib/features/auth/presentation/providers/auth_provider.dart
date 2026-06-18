import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../domain/interfaces/notification_service_interface.dart';

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

/// Maps a raw sign-in failure to a short, user-facing message so the login
/// screen never shows a raw exception. Distinguishes "you're offline" (gotrue
/// wraps fetch failures in [AuthRetryableFetchException]) from "wrong
/// credentials" (400) from rate-limiting (429). Covers Bug 8 (offline login)
/// and Bug 9 (wrong-password message).
String friendlyAuthError(Object error) {
  if (error is AuthRetryableFetchException) return _offlineSignInMessage;
  if (error is AuthException) {
    final m = error.message.toLowerCase();
    if (error.statusCode == '400' || m.contains('invalid login credentials')) {
      return 'Incorrect email or password.';
    }
    if (error.statusCode == '429' || m.contains('rate') || m.contains('after')) {
      return 'Too many attempts — wait a minute, then try again.';
    }
    return 'Incorrect email or password.';
  }
  // Non-auth errors that still mean "no network" (raw socket/client errors).
  final msg = error.toString();
  if (msg.contains('SocketException') ||
      msg.contains('Failed host lookup') ||
      msg.contains('ClientException') ||
      msg.contains('Connection') ||
      msg.contains('Network is unreachable') ||
      msg.contains('TimeoutException') ||
      msg.contains('timed out')) {
    return _offlineSignInMessage;
  }
  return 'Could not sign in. Please try again.';
}

const _offlineSignInMessage =
    'No internet connection. You need to be online the first time you sign in. '
    'After that, the app keeps working offline.';

final notificationServiceProvider = Provider<INotificationService>(
  (ref) => NotificationService(ref.read(supabaseClientProvider)),
);

/// Streams every auth state change (sign in, sign out, token refresh).
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

/// The current Supabase session, or null when signed out.
final currentSessionProvider = Provider<Session?>((ref) {
  ref.watch(authStateProvider); // re-evaluate on any auth change
  return Supabase.instance.client.auth.currentSession;
});

/// The current user's profile ID, or null.
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(currentSessionProvider)?.user.id;
});

/// Notifier that handles sign-in and sign-up operations.
class AuthNotifier extends AsyncNotifier<void> {
  SupabaseClient get _client => ref.read(supabaseClientProvider);

  @override
  Future<void> build() async {}

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'phone': phone},
      );
    });
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _client.auth.signOut());
  }

  /// Accept an invite: verify the one-time code the owner's invite emailed,
  /// then set the staff member's password and name. On success they are signed
  /// in and the router routes them to their shop.
  Future<void> claimInvite({
    required String email,
    required String code,
    required String fullName,
    required String password,
  }) async {
    await _client.auth.verifyOTP(
      email: email.trim(),
      token: code.trim(),
      type: OtpType.email,
    );
    await _client.auth.updateUser(
      UserAttributes(password: password, data: {'full_name': fullName.trim()}),
    );
    final userId = _client.auth.currentUser?.id;
    if (userId != null) {
      // profiles RLS allows a user to write their own row (auth.uid() = id).
      await _client
          .from('profiles')
          .upsert({'id': userId, 'full_name': fullName.trim()});
    }
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, void>(AuthNotifier.new);
