import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:beileme/core/constants/api_constants.dart';
import 'package:beileme/core/network/api_client.dart';
import 'package:beileme/services/auth_service.dart';

import '../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() {
    ApiClient.debugHttpClient = null;
    ApiClient.onUnauthorized = null;
  });

  test('AuthService.login parses token and userInfo', () async {
    final router = TestRequestRouter();
    router.on('POST', '${ApiConstants.baseUrl}${ApiConstants.authLogin}', (req) async {
      return jsonResponse(200, {
        'code': 200,
        'message': 'success',
        'data': {
          'token': 't',
          'userInfo': {
            'id': 1,
            'username': 'u',
            'email': 'e@e.com',
            'avatar': '',
            'level': 1,
            'totalScore': 0,
          },
        },
      });
    });

    ApiClient.debugHttpClient = MockClient(router.handle);

    final s = AuthService();
    final r = await s.login(username: 'u', password: 'p');
    expect(r.token, 't');
    expect(r.userInfo.username, 'u');
  });
}
