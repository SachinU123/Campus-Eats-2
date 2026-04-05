import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import 'package:campus_eats_ag/core/constants/api_config.dart';

/// Lightweight HTTP client wrapper for CampusEats API.
/// Handles JSON encoding, auth headers, and standardized error responses.
class ApiClient {
  final http.Client _client = http.Client();
  String? _accessToken;
  String? _refreshToken;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  void setTokens({String? access, String? refresh}) {
    _accessToken = access;
    _refreshToken = refresh;
  }

  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  bool get _hasAuth => _accessToken != null;

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  // ─── HTTP Methods ──────────────────────────────────────────

  Future<ApiResult> get(String path) async {
    _logRequest('GET', path);
    try {
      final response = await _client
          .get(_uri(path), headers: _headers)
          .timeout(ApiConfig.receiveTimeout);
      return _handleResponse('GET', path, response);
    } catch (e) {
      _logError('GET', path, e);
      return ApiResult.failure(_errorMessage(e));
    }
  }

  Future<ApiResult> post(String path, {Map<String, dynamic>? body}) async {
    _logRequest('POST', path, body: body);
    try {
      final response = await _client
          .post(_uri(path), headers: _headers, body: jsonEncode(body ?? {}))
          .timeout(ApiConfig.receiveTimeout);
      return _handleResponse('POST', path, response);
    } catch (e) {
      _logError('POST', path, e);
      return ApiResult.failure(_errorMessage(e));
    }
  }

  Future<ApiResult> patch(String path, {Map<String, dynamic>? body}) async {
    _logRequest('PATCH', path, body: body);
    try {
      final response = await _client
          .patch(_uri(path), headers: _headers, body: jsonEncode(body ?? {}))
          .timeout(ApiConfig.receiveTimeout);
      return _handleResponse('PATCH', path, response);
    } catch (e) {
      _logError('PATCH', path, e);
      return ApiResult.failure(_errorMessage(e));
    }
  }

  // ─── Response Handler ──────────────────────────────────────

  ApiResult _handleResponse(String method, String path, http.Response response) {
    // Try to parse JSON body
    Map<String, dynamic>? body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      dev.log(
        '[API] [$method] $path → ${response.statusCode} (invalid JSON body)',
        name: 'ApiClient',
        level: 900,
      );
      return ApiResult.failure('Invalid server response', statusCode: response.statusCode);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      dev.log(
        '[API] [$method] $path → ${response.statusCode} ✓',
        name: 'ApiClient',
      );
      return ApiResult.success(body['data'], body['message'] as String? ?? 'OK');
    }

    var message = 'Request failed';
    if (body['message'] != null) {
      if (body['message'] is List) {
        message = (body['message'] as List).join(', ');
      } else {
        message = body['message'].toString();
      }
    }
    dev.log(
      '[API] [$method] $path → ${response.statusCode} ✗ $message',
      name: 'ApiClient',
      level: 900,
    );
    return ApiResult.failure(message, statusCode: response.statusCode);
  }

  // ─── Debug Logging ─────────────────────────────────────────
  // NOTE: These logs appear in flutter run console / DevTools.
  // Remove or gate behind kDebugMode before production hardening.

  void _logRequest(String method, String path, {Map<String, dynamic>? body}) {
    final authState = _hasAuth ? 'Bearer [token]' : 'NO AUTH';
    final bodyStr = body != null ? _sanitizeBody(body) : '(none)';
    dev.log(
      '[API] [$method] ${ApiConfig.baseUrl}$path | auth=$authState | body=$bodyStr',
      name: 'ApiClient',
    );
  }

  void _logError(String method, String path, dynamic error) {
    dev.log(
      '[API] [$method] $path EXCEPTION: $error',
      name: 'ApiClient',
      level: 1000,
    );
  }

  /// Strips sensitive fields from logs.
  String _sanitizeBody(Map<String, dynamic> body) {
    final safe = Map<String, dynamic>.from(body);
    if (safe.containsKey('password')) safe['password'] = '***';
    if (safe.containsKey('otp')) safe['otp'] = '***';
    if (safe.containsKey('refreshToken')) safe['refreshToken'] = '[token]';
    if (safe.containsKey('razorpaySignature')) safe['razorpaySignature'] = '[sig]';
    return safe.toString();
  }

  String _errorMessage(dynamic error) {
    if (error.toString().contains('TimeoutException')) {
      return 'Request timed out. Check your connection.';
    }
    if (error.toString().contains('SocketException')) {
      return 'Cannot reach server. Check your connection.';
    }
    return 'Network error: ${error.toString().split('\n').first}';
  }

  void dispose() {
    _client.close();
  }
}

/// Standardized API result.
class ApiResult {
  final bool isSuccess;
  final String message;
  final dynamic data;
  final int? statusCode;

  const ApiResult._({
    required this.isSuccess,
    required this.message,
    this.data,
    this.statusCode,
  });

  factory ApiResult.success(dynamic data, String message) {
    return ApiResult._(isSuccess: true, message: message, data: data);
  }

  factory ApiResult.failure(String message, {int? statusCode}) {
    return ApiResult._(
      isSuccess: false,
      message: message,
      statusCode: statusCode,
    );
  }
}
