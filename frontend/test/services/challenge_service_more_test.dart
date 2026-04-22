import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:beileme/core/constants/api_constants.dart';
import 'package:beileme/core/network/api_client.dart';
import 'package:beileme/services/challenge_service.dart';

import '../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() {
    ApiClient.debugHttpClient = null;
  });

  test('ChallengeService.getChallengeRecords supports data.list', () async {
    final router = TestRequestRouter();
    router.on('GET', '${ApiConstants.baseUrl}${ApiConstants.challengeRecords}?page=1&size=20', (req) async {
      return jsonResponse(200, {
        'code': 200,
        'message': 'success',
        'data': {
          'list': [
            {
              'id': 1,
              'levelType': 1,
              'score': 10,
              'correctCount': 1,
              'totalCount': 2,
              'duration': 5,
              'createTime': '2026-04-22T00:00:00Z',
            }
          ]
        }
      });
    });

    ApiClient.debugHttpClient = MockClient(router.handle);

    final s = ChallengeService();
    final r = await s.getChallengeRecords();
    expect(r.length, 1);
    expect(r.first.levelTypeName, '初级场');
  });

  test('ChallengeService.getChallengeRecords includes levelType when provided', () async {
    final router = TestRequestRouter();
    router.on('GET', '${ApiConstants.baseUrl}${ApiConstants.challengeRecords}?page=1&size=20&levelType=2', (req) async {
      return jsonResponse(200, {
        'code': 200,
        'message': 'success',
        'data': {'list': []},
      });
    });

    ApiClient.debugHttpClient = MockClient(router.handle);

    final s = ChallengeService();
    final r = await s.getChallengeRecords(levelType: 2);
    expect(r, isEmpty);
  });
}
