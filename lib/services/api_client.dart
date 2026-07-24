import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skillpay/main.dart';
import 'package:flutter/material.dart';
import 'package:skillpay/screens/login_screen.dart';

/// A singleton HTTP client that:
///   - Reads the NestJS base URL from .env (API_URL)
///   - Attaches the current Supabase JWT as a Bearer token on every request
///   - Throws [ApiException] with a clean message on non-2xx responses
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  String get _baseUrl {
    final url = dotenv.env['API_URL'] ?? '';
    assert(url.isNotEmpty, 'API_URL is not set in .env');
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  /// Returns the current Supabase JWT, or null if the user is not signed in.
  String? get _token =>
      Supabase.instance.client.auth.currentSession?.accessToken;

  /// Returns the current Supabase JWT.
  /// Waits up to 3 seconds for the session to be restored from storage
  /// before giving up — fixes "No token" errors at app startup.
  Future<String?> _getToken() async {
    var session = Supabase.instance.client.auth.currentSession;
    if (session != null) return session.accessToken;

    // Session may still be loading — wait briefly
    for (var i = 0; i < 6; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      session = Supabase.instance.client.auth.currentSession;
      if (session != null) return session.accessToken;
    }
    return null;
  }



  Future<Map<String, String>> _asyncHeaders({bool multipart = false}) async {
    final headers = <String, String>{
      HttpHeaders.acceptHeader: 'application/json',
    };
    if (!multipart) {
      headers[HttpHeaders.contentTypeHeader] = 'application/json';
    }
    final token = await _getToken();
    if (token != null) {
      headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, dynamic>? queryParams]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$_baseUrl$cleanPath');
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(
        queryParameters: queryParams.map(
          (k, v) => MapEntry(k, v.toString()),
        ),
      );
    }
    return uri;
  }

  // ─── Core request methods ────────────────────────────────────────────────

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final response = await http.get(_uri(path, query), headers: await _asyncHeaders());
    return _handleResponse(response);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final response = await http.post(
      _uri(path),
      headers: await _asyncHeaders(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final response = await http.patch(
      _uri(path),
      headers: await _asyncHeaders(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final response = await http.put(
      _uri(path),
      headers: await _asyncHeaders(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(String path) async {
    final response = await http.delete(_uri(path), headers: await _asyncHeaders());
    return _handleResponse(response);
  }

  Future<dynamic> uploadFile(
    String path, {
    required File file,
    required String fieldName,
    Map<String, String>? fields,
  }) async {
    final request =
        http.MultipartRequest('POST', _uri(path))
          ..headers.addAll(await _asyncHeaders(multipart: true))
          ..files.add(await http.MultipartFile.fromPath(fieldName, file.path));
    if (fields != null) request.fields.addAll(fields);
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _handleResponse(response);
  }

  // ─── Response handler ────────────────────────────────────────────────────

  dynamic _handleResponse(http.Response response) {
    debugPrint('[API] ${response.request?.method} ${response.request?.url} → ${response.statusCode}');

    final body = response.body.isNotEmpty ? response.body : '{}';

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final decoded = jsonDecode(body);
        // Unwrap NestJS TransformInterceptor envelope: { success: true, data: <payload> }
        if (decoded is Map<String, dynamic> &&
            decoded.containsKey('success') &&
            decoded.containsKey('data')) {
          return decoded['data'];
        }
        return decoded;
      } catch (_) {
        return body; // Return raw string if not JSON
      }
    }

    // Try to extract a message from the NestJS error response shape
    String message = 'Request failed (${response.statusCode})';
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      message = decoded['message']?.toString() ??
          decoded['error']?.toString() ??
          message;
    } catch (_) {}

    // Handle global 401 Unauthorized
    if ((response.statusCode == 401 || response.statusCode == 403) &&
        message != 'No authorization token provided') {
      debugPrint('[API] Session invalid — signing out and redirecting to login');
      try {
        Supabase.instance.client.auth.signOut();
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } catch (_) {}
    }

    throw ApiException(message: message, statusCode: response.statusCode);
  }
}

// ─── Exception type ──────────────────────────────────────────────────────────

class ApiException implements Exception {
  final String message;
  final int statusCode;

  const ApiException({required this.message, required this.statusCode});

  /// Whether the token is expired or missing — caller should redirect to login.
  bool get isUnauthorized => statusCode == 401 || statusCode == 403;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
