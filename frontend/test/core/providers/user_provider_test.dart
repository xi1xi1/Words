import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:beileme/core/constants/api_constants.dart';
import 'package:beileme/core/providers/user_provider.dart';
import 'package:beileme/models/user_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('UserProvider.initialize reads token and user info', () async {
    SharedPreferences.setMockInitialValues({
      ApiConstants.tokenKey: 't1',
      ApiConstants.userInfoKey: jsonEncode({'id': 1, 'username': 'u'}),
    });

    final p = UserProvider();
    await p.initialize();
    await Future<void>.delayed(Duration.zero);

    expect(p.isInitialized, isTrue);
    expect(p.token, 't1');
    expect(p.user?['username'], 'u');
    expect(p.isLoggedIn, isTrue);
  });

  test('UserProvider.setAuth persists values and clearAuth removes them', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final p = UserProvider();
    await p.initialize();
    await Future<void>.delayed(Duration.zero);

    await p.setAuth(
      token: 't2',
      userInfo: UserInfo(
        id: 1,
        username: 'u',
        avatar: null,
        totalScore: 0,
        level: 1,
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(ApiConstants.tokenKey), 't2');
    expect(p.token, 't2');
    expect(p.isLoggedIn, isTrue);

    await p.clearAuth();
    expect(p.isLoggedIn, isFalse);
    expect(p.token, isNull);
    expect(p.user, isNull);
    expect(prefs.getString(ApiConstants.tokenKey), isNull);
  });
}
