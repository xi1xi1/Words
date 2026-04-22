// lib/core/network/api_client.dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';
import 'api_exception.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() => _instance;

  ApiClient._internal();

  /// For testing: override the underlying HTTP client.
  ///
  /// When set, `ApiClient` will reuse this client for all requests.
  static http.Client? debugHttpClient;

  /// Called when server indicates the user is unauthorized (HTTP 401 or business code 401).
  ///
  /// Typically wired to `UserProvider.clearAuth()` in `main.dart`.
  static Future<void> Function()? onUnauthorized;

  http.Client get client => debugHttpClient ?? http.Client();

  String get baseUrl => ApiConstants.baseUrl;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConstants.tokenKey);
  }

  Future<Map<String, String>> _getHeaders({bool needAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (needAuth) {
      final token = await _getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  int? _parseBusinessCode(Map<String, dynamic> json) {
    final raw = json['code'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  ApiException _toApiException({
    required int fallbackCode,
    required String fallbackMessage,
    Map<String, dynamic>? json,
  }) {
    if (json == null) {
      return ApiException(code: fallbackCode, message: fallbackMessage);
    }

    try {
      return ApiException.fromJson(json);
    } catch (_) {
      final code = _parseBusinessCode(json) ?? fallbackCode;
      final message = json['message']?.toString() ?? fallbackMessage;
      return ApiException(code: code, message: message);
    }
  }

  Future<Map<String, dynamic>> _request({
    required String method,
    required String path,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParams,
    bool needAuth = true,
  }) async {
    final normalizedQueryParams = queryParams?.map(
      (key, value) => MapEntry(key, value?.toString() ?? ''),
    );

    final url = Uri.parse('$baseUrl$path')
        .replace(queryParameters: normalizedQueryParams);
    final headers = await _getHeaders(needAuth: needAuth);

    print('🔵 [请求] $method $url');
    print('🔵 [请求头] $headers');
    if (data != null) print('🔵 [请求体] $data');

    http.Response response;

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await client.get(url, headers: headers);
          break;
        case 'POST':
          response = await client.post(
            url,
            headers: headers,
            body: data != null ? jsonEncode(data) : null,
          );
          break;
        case 'PUT':
          response = await client.put(
            url,
            headers: headers,
            body: data != null ? jsonEncode(data) : null,
          );
          break;
        case 'DELETE':
          response = await client.delete(url, headers: headers);
          break;
        default:
          throw Exception('Unsupported method: $method');
      }
    } catch (e) {
      throw ApiException(code: -1, message: '网络连接失败，请检查网络设置');
    }

    print('🟢 [响应状态] ${response.statusCode}');
    print('🟢 [响应头] ${response.headers}');
    print('🟢 [响应体] ${response.body}');

    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        code: response.statusCode,
        message: '服务器响应格式错误',
      );
    }

    final httpStatusCode = response.statusCode;
    final businessCode = _parseBusinessCode(json);

    final unauthorizedByHttp = httpStatusCode == 401;
    final unauthorizedByBusiness = businessCode == 401;
    if (unauthorizedByHttp || unauthorizedByBusiness) {
      final handler = onUnauthorized;
      if (handler != null) {
        try {
          await handler();
        } catch (_) {
          // ignore
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(ApiConstants.tokenKey);
        await prefs.remove(ApiConstants.userInfoKey);
      }
    }

    if (httpStatusCode < 200 || httpStatusCode >= 300) {
      throw _toApiException(
        fallbackCode: httpStatusCode,
        fallbackMessage: '请求失败',
        json: json,
      );
    }

    if (businessCode != null && businessCode != 200) {
      throw _toApiException(
        fallbackCode: businessCode,
        fallbackMessage: '请求失败',
        json: json,
      );
    }

    return json;
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParams,
    bool needAuth = true,
  }) async {
    return _request(
      method: 'GET',
      path: path,
      queryParams: queryParams,
      needAuth: needAuth,
    );
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
    bool needAuth = true,
  }) async {
    return _request(
      method: 'POST',
      path: path,
      data: data,
      needAuth: needAuth,
    );
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? data,
    bool needAuth = true,
  }) async {
    return _request(
      method: 'PUT',
      path: path,
      data: data,
      needAuth: needAuth,
    );
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    bool needAuth = true,
  }) async {
    return _request(
      method: 'DELETE',
      path: path,
      needAuth: needAuth,
    );
  }
}
