import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';
import '../constants/api_constants.dart';

class UserProvider extends ChangeNotifier {
  Map<String, dynamic>? _user;
  String? _token;
  bool _initialized = false;

  UserProvider() {
    initialize();
  }

  Map<String, dynamic>? get user => _user;
  String? get token => _token;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(ApiConstants.tokenKey);

    final rawUser = prefs.getString(ApiConstants.userInfoKey);
    if (rawUser != null && rawUser.isNotEmpty) {
      try {
        _user = jsonDecode(rawUser) as Map<String, dynamic>;
      } catch (_) {
        _user = null;
      }
    }

    _initialized = true;
    notifyListeners();
  }

  Future<void> setAuth({
    required String token,
    required UserInfo userInfo,
  }) async {
    _token = token;
    _user = userInfo.toJson();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConstants.tokenKey, token);
    await prefs.setString(ApiConstants.userInfoKey, jsonEncode(_user));

    notifyListeners();
  }

  Future<void> clearAuth() async {
    _user = null;
    _token = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConstants.tokenKey);
    await prefs.remove(ApiConstants.userInfoKey);

    notifyListeners();
  }

  void setUser(Map<String, dynamic> user) {
    _user = user;
    notifyListeners();
  }

  void setToken(String token) {
    _token = token;
    notifyListeners();
  }

  void logout() {
    _user = null;
    _token = null;
    notifyListeners();
  }
}
