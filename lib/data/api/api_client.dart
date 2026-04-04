import 'dart:convert';
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

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  // ─── HTTP Methods ──────────────────────────────────────────

  Future<ApiResult> get(String path) async {
    try {
      final response = await _client
          .get(_uri(path), headers: _headers)
          .timeout(ApiConfig.receiveTimeout);
      return _handleResponse(response);
    } catch (e) {
      return ApiResult.failure(_errorMessage(e));
    }
  }

  Future<ApiResult> post(String path, {Map<String, dynamic>? body}) async {
    try {
      final response = await _client
          .post(_uri(path), headers: _headers, body: jsonEncode(body ?? {}))
          .timeout(ApiConfig.receiveTimeout);
      return _handleResponse(response);
    } catch (e) {
      return ApiResult.failure(_errorMessage(e));
    }
  }

  Future<ApiResult> patch(String path, {Map<String, dynamic>? body}) async {
    try {
      final response = await _client
          .patch(_uri(path), headers: _headers, body: jsonEncode(body ?? {}))
          .timeout(ApiConfig.receiveTimeout);
      return _handleResponse(response);
    } catch (e) {
      return ApiResult.failure(_errorMessage(e));
    }
  }

  // ─── Response Handler ──────────────────────────────────────

  ApiResult _handleResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
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
    return ApiResult.failure(message, statusCode: response.statusCode);
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
