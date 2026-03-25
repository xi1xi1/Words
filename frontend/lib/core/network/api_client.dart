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

  http.Client get client => http.Client();

  String get baseUrl => ApiConstants.baseUrl;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConstants.tokenKey);
  }

  Future<Map<String, String>> _getHeaders({bool needAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (needAuth) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<Map<String, dynamic>> _request({
    required String method,
    required String path,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParams,
    bool needAuth = true,
  }) async {
    final url = Uri.parse(
      '$baseUrl$path',
    ).replace(queryParameters: queryParams);
    final headers = await _getHeaders(needAuth: needAuth);

    // 添加日志：打印完整请求信息
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

    // 添加日志：打印响应状态码和重定向信息
    print('🟢 [响应状态] ${response.statusCode}');
    print('🟢 [响应头] ${response.headers}');
    print('🟢 [响应体] ${response.body}');

    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw ApiException(code: response.statusCode, message: '服务器响应格式错误');
    }

    final code = json['code'] as int;
    final httpStatusCode = response.statusCode;

    // ✅ 修改：HTTP 状态码是 200 就算成功（不管业务 code 是多少）
    if (httpStatusCode >= 200 && httpStatusCode < 300) {
      return json; // 直接返回，不检查业务 code
    }

    // HTTP 状态码是 401，清除 Token
    if (httpStatusCode == 401) {
      _clearToken();
    }

    // HTTP 状态码错误，抛出异常
    throw ApiException.fromJson(json);
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConstants.tokenKey);
  }

  // GET 请求
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParams,
    bool needAuth = true,
  }) async {
    return await _request(
      method: 'GET',
      path: path,
      queryParams: queryParams,
      needAuth: needAuth,
    );
  }

  // POST 请求
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
    bool needAuth = true,
  }) async {
    return await _request(
      method: 'POST',
      path: path,
      data: data,
      needAuth: needAuth,
    );
  }

  // PUT 请求
  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? data,
    bool needAuth = true,
  }) async {
    return await _request(
      method: 'PUT',
      path: path,
      data: data,
      needAuth: needAuth,
    );
  }

  // DELETE 请求
  Future<Map<String, dynamic>> delete(
    String path, {
    bool needAuth = true,
  }) async {
    return await _request(method: 'DELETE', path: path, needAuth: needAuth);
  }
}
