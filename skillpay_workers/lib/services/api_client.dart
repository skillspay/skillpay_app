import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton HTTP client for the Workers app.
/// Reads API_URL from .env, attaches Supabase JWT as Bearer token.
/// Throws [ApiException] on non-2xx responses.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  String get _baseUrl {
    final url = dotenv.env['API_URL'] ?? '';
    assert(url.isNotEmpty, 'API_URL is not set in .env');
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

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
        queryParameters: queryParams.map((k, v) => MapEntry(k, v.toString())),
      );
    }
    return uri;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final response = await http.get(_uri(path, query), headers: _headers());
    return _handle(response);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final response = await http.post(
      _uri(path),
      headers: _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handle(response);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final response = await http.patch(
      _uri(path),
      headers: _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handle(response);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final response = await http.put(
      _uri(path),
      headers: _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handle(response);
  }

  Future<dynamic> delete(String path) async {
    final response = await http.delete(_uri(path), headers: _headers());
    return _handle(response);
  }

  Future<dynamic> uploadFile(
    String path, {
    required File file,
    required String fieldName,
    Map<String, String>? fields,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path))
      ..headers.addAll(_headers(multipart: true))
      ..files.add(await http.MultipartFile.fromPath(fieldName, file.path));
    if (fields != null) request.fields.addAll(fields);
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _handle(response);
  }

  dynamic _handle(http.Response response) {
    debugPrint(
      '[API] ${response.request?.method} ${response.request?.url} → ${response.statusCode}',
    );
    final body = response.body.isNotEmpty ? response.body : '{}';

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return jsonDecode(body);
      } catch (_) {
        return body;
      }
    }

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

class ApiException implements Exception {
  final String message;
  final int statusCode;
  const ApiException({required this.message, required this.statusCode});
  bool get isUnauthorized => statusCode == 401 || statusCode == 403;
  @override
  String toString() => 'ApiException($statusCode): $message';
}
