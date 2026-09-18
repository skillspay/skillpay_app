import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skillpay/services/api_client.dart';

/// Handles all authentication.
///
/// Flow:
///   1. Call Supabase Auth to sign up / sign in → get JWT
///   2. Call NestJS /auth/* to sync the user record in Postgres
///
/// The Flutter app never reads from Postgres directly — NestJS owns all
/// business data. Supabase is only used here for auth token management
/// and in messages_service for Realtime.
class AuthService {
  final _supabase = Supabase.instance.client;
  final _api = ApiClient.instance;

  // ─── Registration ────────────────────────────────────────────────────────

  /// Step 1 — Create Supabase auth account.
  /// Only calls Supabase here — no NestJS sync yet because Supabase
  /// requires email confirmation before a session (and JWT) is issued.
  /// The NestJS user row is created on first signIn() after confirmation.
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
          'role': 'HOMEOWNER',
        },
      );
      // Email confirmation sent — user must verify before they can sign in.
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ─── OTP Verification ────────────────────────────────────────────────────

  /// Step 2 — Verify the 6-digit OTP sent to the user's email.
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

  // ─── Profile setup ───────────────────────────────────────────────────────

  /// Syncs the Supabase user to the NestJS Postgres database.
  /// Must be called after OTP verification and before any protected endpoints.
  Future<void> syncUserAfterVerification({
    required String email,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    try {
      await _api.post('/auth/register', body: {
        'email': email,
        'fullName': fullName,
        'phone': phone,
        'role': role.toUpperCase(),
      });
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Step 3 — Finish homeowner profile setup via NestJS.
  /// Called after OTP verification, creates the `homeowners` row.
  Future<void> finishProfileSetup({
    required String fullName,
    required String phone,
    required String address,
    required double? latitude,
    required double? longitude,
  }) async {
    try {
      await _api.post('/homeowners/profile/setup', body: {
        'fullName': fullName,
        'phone': phone,
        'defaultAddress': address,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      });
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  // ─── Profile image ───────────────────────────────────────────────────────

  /// Upload a profile image via NestJS storage endpoint.
  /// Returns the public URL of the uploaded image.
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

  // ─── Sign in ─────────────────────────────────────────────────────────────

  /// Signs in via Supabase Auth (JWT guaranteed here — email is confirmed).
  /// On first login, upserts the NestJS user row. On subsequent logins,
  /// updates last_login. The register call is idempotent so safe to call every time.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // JWT is now available — sync/upsert user in NestJS Postgres.
      // /auth/register is idempotent: creates on first call, returns existing on repeat.
      final user = response.user;
      if (user != null) {
        try {
          final fName = user.userMetadata?['full_name']?.toString() ?? '';
          await _api.post('/auth/register', body: {
            'email': user.email ?? email,
            'fullName': fName.isNotEmpty ? fName : 'SkillPay User',
            'phone': user.userMetadata?['phone']?.toString() ?? '',
            'role': 'HOMEOWNER',
          });
        } on ApiException {
          // Non-fatal — user can still proceed if register fails
          debugPrint('[Auth] NestJS register sync failed — will retry on next login');
        }
      }

      // Update last_login
      try {
        await _api.post('/auth/login');
      } on ApiException {
        // Non-fatal
      }
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      if (e is ApiException) throw Exception(e.message);
      throw Exception(e.toString());
    }
  }

  // ─── Sign out ────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // ─── Password reset ──────────────────────────────────────────────────────

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

  // ─── Update profile ──────────────────────────────────────────────────────

  /// Updates homeowner profile fields via NestJS.
  Future<void> updateUserProfile({
    required String fullName,
    required String phone,
    String? dateOfBirth,
    String? profilePhoto,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (fullName.isNotEmpty) body['fullName'] = fullName;
      if (phone.isNotEmpty) body['phone'] = phone;
      if (dateOfBirth != null && dateOfBirth.isNotEmpty) body['dob'] = dateOfBirth;
      if (profilePhoto != null && profilePhoto.isNotEmpty) body['profilePhoto'] = profilePhoto;
      if (body.isEmpty) return;
      await _api.patch('/homeowners/profile', body: body);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  /// Returns the current authenticated Supabase user, or null.
  User? get currentUser => _supabase.auth.currentUser;

  /// Whether a user is currently signed in.
  bool get isSignedIn => _supabase.auth.currentSession != null;

  /// Stream of auth state changes (use in SplashScreen / route guards).
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
