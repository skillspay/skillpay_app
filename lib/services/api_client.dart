import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

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

  Map<String, String> _headers({bool multipart = false}) {
    final headers = <String, String>{
      HttpHeaders.acceptHeader: 'application/json',
    };
    if (!multipart) {
      headers[HttpHeaders.contentTypeHeader] = 'application/json';
    }
    final token = _token;
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
    final response = await http.get(_uri(path, query), headers: _headers());
    return _handleResponse(response);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final response = await http.post(
      _uri(path),
      headers: _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final response = await http.patch(
      _uri(path),
      headers: _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final response = await http.put(
      _uri(path),
      headers: _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(String path) async {
    final response =
        await http.delete(_uri(path), headers: _headers());
    return _handleResponse(response);
  }

  /// Multipart upload — for sending files to NestJS storage endpoints.
  Future<dynamic> uploadFile(
    String path, {
    required File file,
    required String fieldName,
    Map<String, String>? fields,
  }) async {
    final request =
        http.MultipartRequest('POST', _uri(path))
          ..headers.addAll(_headers(multipart: true))
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
        return jsonDecode(body);
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
