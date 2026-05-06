// lib/core/network/api_client.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
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

  Map<String, String> _redactHeaders(Map<String, String> headers) {
    return headers.map((key, value) {
      if (key.toLowerCase() == 'authorization') {
        return MapEntry(key, 'Bearer ***');
      }
      return MapEntry(key, value);
    });
  }

  Map<String, dynamic> _redactRequestBody(Map<String, dynamic> data) {
    const sensitiveKeys = {'password', 'token', 'authorization'};
    return data.map((key, value) {
      if (sensitiveKeys.contains(key.toLowerCase())) {
        return MapEntry(key, '***');
      }
      return MapEntry(key, value);
    });
  }

  dynamic _redactSensitiveJson(dynamic value) {
    const sensitiveKeys = {
      'password',
      'token',
      'authorization',
      'accessToken',
      'refreshToken',
    };

    if (value is Map<String, dynamic>) {
      return value.map((key, nestedValue) {
        if (sensitiveKeys.contains(key) ||
            sensitiveKeys.contains(key.toLowerCase())) {
          return MapEntry(key, '***');
        }
        return MapEntry(key, _redactSensitiveJson(nestedValue));
      });
    }

    if (value is List) {
      return value.map(_redactSensitiveJson).toList();
    }

    return value;
  }

  String _redactResponseBody(String body) {
    try {
      final decoded = jsonDecode(body);
      return jsonEncode(_redactSensitiveJson(decoded));
    } catch (_) {
      return body;
    }
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint(message);
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

    _debugLog('请求: $method $url');
    _debugLog('请求头: ${_redactHeaders(headers)}');
    if (data != null) _debugLog('请求体: ${_redactRequestBody(data)}');

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

    _debugLog('响应状态: ${response.statusCode}');
    _debugLog('响应头: ${response.headers}');
    _debugLog('响应体: ${_redactResponseBody(response.body)}');

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
