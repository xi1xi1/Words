// lib/services/auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/user_model.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  Future<({String token, UserInfo userInfo})> login({
    required String username,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.authLogin,
      data: {'username': username, 'password': password},
      needAuth: false,
    );

    final data = response['data'] as Map<String, dynamic>;
    final token = data['token'] as String;
    final userInfo = UserInfo.fromJson(
      data['userInfo'] as Map<String, dynamic>,
    );

    return (token: token, userInfo: userInfo);
  }

  Future<({String token, UserInfo userInfo})> register({
    required String username,
    required String password,
    required String email,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.authRegister,
      data: {'username': username, 'password': password, 'email': email},
      needAuth: false,
    );

    final data = response['data'] as Map<String, dynamic>;
    final token = data['token'] as String;
    final userInfo = UserInfo.fromJson(
      data['userInfo'] as Map<String, dynamic>,
    );

    return (token: token, userInfo: userInfo);
  }

  Future<void> logout() async {
    try {
      await _apiClient.post(ApiConstants.authLogout);
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(ApiConstants.tokenKey);
      await prefs.remove(ApiConstants.userInfoKey);
    }
  }
}
