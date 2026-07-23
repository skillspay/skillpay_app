// Compatibility wrapper — preserves the SupabaseAuthService class name used
// across all existing screens while delegating to the new NestJS-aware AuthService.
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

class SupabaseAuthService {
  final _auth = AuthService();

  /// Sign up a new artisan — creates Supabase auth account + syncs NestJS DB row.
  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
  }) {
    return _auth.signUp(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
    );
  }

  /// Sign in — Supabase auth + updates NestJS last_login.
  Future<void> login({
    required String email,
    required String password,
  }) {
    return _auth.signIn(email: email, password: password);
  }

  /// Sign out.
  Future<void> signOut() => _auth.signOut();

  /// Send password reset email via Supabase.
  Future<void> requestPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email);

  /// Verify OTP (signup or recovery).
  Future<AuthResponse> verifyOTP({
    required String email,
    required String token,
    required OtpType type,
  }) async {
    final supabase = Supabase.instance.client;
    return supabase.auth.verifyOTP(email: email, token: token, type: type);
  }

  /// Update password directly via Supabase Auth.
  Future<UserResponse> updatePassword(String newPassword) async {
    return Supabase.instance.client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  /// Stream of Supabase auth state changes.
  Stream<AuthState> get authStateChanges => _auth.authStateChanges;

  /// Current authenticated Supabase user.
  User? get currentUser => _auth.currentUser;
}
