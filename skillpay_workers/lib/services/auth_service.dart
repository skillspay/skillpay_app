import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'api_client.dart';

/// Artisan authentication service.
///
/// Flow:
///   1. Supabase Auth → sign up / sign in → JWT
///   2. NestJS /auth/* → sync user row in Postgres (role: ARTISAN)
class AuthService {
  final _supabase = Supabase.instance.client;
  final _api = ApiClient.instance;

  // ─── Registration ─────────────────────────────────────────────────────────

  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': '$firstName $lastName',
          'phone': phone,
          'role': 'ARTISAN',
        },
      );

      // Sync user row in NestJS Postgres
      await _api.post('/auth/register', body: {
        'email': email,
        'fullName': '$firstName $lastName',
        'phone': phone,
        'role': 'ARTISAN',
      });
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      if (e is ApiException) throw Exception(e.message);
      throw Exception(e.toString());
    }
  }

  // ─── OTP Verification ─────────────────────────────────────────────────────

  Future<void> verifyEmailOTP(String email, String otp) async {
    try {
      await _supabase.auth.verifyOTP(
        type: OtpType.signup,
        email: email,
        token: otp,
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // ─── Sign in ──────────────────────────────────────────────────────────────

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      await _api.post('/auth/login');
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      if (e is ApiException) throw Exception(e.message);
      throw Exception(e.toString());
    }
  }

  // ─── Sign out ─────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // ─── Password reset ───────────────────────────────────────────────────────

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // ─── FCM token ────────────────────────────────────────────────────────────

  Future<void> updateFcmToken(String token) async {
    try {
      await _api.patch('/auth/fcm-token', body: {'fcmToken': token});
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  // ─── Profile image ────────────────────────────────────────────────────────

  Future<String> uploadProfileImage(File imageFile) async {
    try {
      final result = await _api.uploadFile(
        '/storage/profile-image',
        file: imageFile,
        fieldName: 'file',
      );
      final url = result['url']?.toString() ?? '';
      if (url.isEmpty) throw Exception('Upload succeeded but no URL returned.');
      return url;
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  User? get currentUser => _supabase.auth.currentUser;
  bool get isSignedIn => _supabase.auth.currentSession != null;
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
