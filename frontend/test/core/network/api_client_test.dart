import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:beileme/core/constants/api_constants.dart';
import 'package:beileme/core/network/api_client.dart';
import 'package:beileme/core/network/api_exception.dart';

import '../../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      ApiConstants.tokenKey: 't',
    });
    ApiClient.onUnauthorized = null;
    ApiClient.debugHttpClient = null;
  });

  tearDown(() {
    ApiClient.onUnauthorized = null;
    ApiClient.debugHttpClient = null;
  });

  test('ApiClient attaches Authorization header when token exists', () async {
    final router = TestRequestRouter();
    router.on('GET', '${ApiConstants.baseUrl}/ping', (req) async {
      expect(req.headers['Authorization'], 'Bearer t');
      return jsonResponse(200, {'code': 200, 'message': 'success', 'data': {}});
    });

    ApiClient.debugHttpClient = MockClient(router.handle);
    final api = ApiClient();

    final r = await api.get('/ping');
    expect(r['code'], 200);
  });

  test('ApiClient throws ApiException on non-2xx http status', () async {
    final router = TestRequestRouter();
    router.on('GET', '${ApiConstants.baseUrl}/fail', (req) async {
      return jsonResponse(500, {'code': 500, 'message': 'server error', 'data': null});
    });

    ApiClient.debugHttpClient = MockClient(router.handle);
    final api = ApiClient();

    await expectLater(api.get('/fail'), throwsA(isA<ApiException>().having((e) => e.code, 'code', 500)));
  });

  test('ApiClient throws ApiException when business code != 200', () async {
    final router = TestRequestRouter();
    router.on('GET', '${ApiConstants.baseUrl}/biz', (req) async {
      return jsonResponse(200, {'code': 400, 'message': 'bad request', 'data': null});
    });

    ApiClient.debugHttpClient = MockClient(router.handle);
    final api = ApiClient();

    await expectLater(
      api.get('/biz'),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 400)),
    );
  });

  test('ApiClient triggers onUnauthorized on HTTP 401', () async {
    var called = 0;
    ApiClient.onUnauthorized = () async {
      called++;
    };

    final router = TestRequestRouter();
    router.on('GET', '${ApiConstants.baseUrl}/unauth', (req) async {
      return jsonResponse(401, {'code': 401, 'message': 'unauthorized', 'data': null});
    });

    ApiClient.debugHttpClient = MockClient(router.handle);
    final api = ApiClient();

    await expectLater(api.get('/unauth'), throwsA(isA<ApiException>()));
    expect(called, 1);
  });

  test('ApiClient triggers onUnauthorized on business code 401', () async {
    var called = 0;
    ApiClient.onUnauthorized = () async {
      called++;
    };

    final router = TestRequestRouter();
    router.on('GET', '${ApiConstants.baseUrl}/unauth2', (req) async {
      return jsonResponse(200, {'code': 401, 'message': 'unauthorized', 'data': null});
    });

    ApiClient.debugHttpClient = MockClient(router.handle);
    final api = ApiClient();

    await expectLater(api.get('/unauth2'), throwsA(isA<ApiException>()));
    expect(called, 1);
  });

  test('ApiClient throws ApiException when response JSON is not a map', () async {
    final router = TestRequestRouter();
    router.on('GET', '${ApiConstants.baseUrl}/bad-json', (req) async {
      return http.Response(
        '[]',
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    ApiClient.debugHttpClient = MockClient(router.handle);
    final api = ApiClient();

    await expectLater(api.get('/bad-json'), throwsA(isA<ApiException>()));
  });
}
