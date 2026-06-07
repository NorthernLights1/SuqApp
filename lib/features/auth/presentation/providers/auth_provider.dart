import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../domain/interfaces/notification_service_interface.dart';

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

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

  /// Step 1 of accepting an invite: email a one-time code to an invited staff
  /// member. `shouldCreateUser: false` means only emails that were actually
  /// invited (their account already exists) can receive a code. Throws on
  /// failure so the caller can show the reason.
  Future<void> sendInviteCode(String email) async {
    await _client.auth.signInWithOtp(
      email: email.trim(),
      shouldCreateUser: false,
    );
  }

  /// Step 2: verify the code, then set the staff member's password and name.
  /// On success they are signed in and the router routes them to their shop.
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
