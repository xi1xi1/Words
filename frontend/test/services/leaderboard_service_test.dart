import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:beileme/core/constants/api_constants.dart';
import 'package:beileme/core/network/api_client.dart';
import 'package:beileme/services/leaderboard_service.dart';

import '../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() {
    ApiClient.debugHttpClient = null;
  });

  test('LeaderboardService.getLeaderboard parses entries', () async {
    final router = TestRequestRouter();
    router.on('GET', '${ApiConstants.baseUrl}${ApiConstants.leaderboard}?type=total&limit=50', (req) async {
      return jsonResponse(200, {
        'code': 200,
        'message': 'success',
        'data': {
          'list': [
            {'rank': 1, 'userId': 1, 'username': 'u', 'avatar': null, 'totalScore': 100},
          ],
          'myRank': 3,
        },
      });
    });

    ApiClient.debugHttpClient = MockClient(router.handle);

    final s = LeaderboardService();
    final r = await s.getLeaderboard();
    expect(r.entries.length, 1);
    expect(r.entries.first.totalScore, 100);
    expect(r.myRank, 3);
  });
}
