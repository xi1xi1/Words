import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:beileme/core/constants/api_constants.dart';
import 'package:beileme/core/network/api_client.dart';
import 'package:beileme/services/study_service.dart';

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

  test('StudyService.getStudyStats parses response', () async {
    final router = TestRequestRouter();
    router.on('GET', '${ApiConstants.baseUrl}${ApiConstants.studyStats}', (req) async {
      return jsonResponse(200, {
        'code': 200,
        'message': 'success',
        'data': {
          'todayStudy': 1,
          'todayReview': 2,
          'totalWords': 3,
          'totalVocabulary': 100,
          'masteredWords': 1,
          'wordbookWords': 0,
          'dueReviewCount': 0,
          'totalScore': 10,
          'level': 1,
        },
      });
    });

    ApiClient.debugHttpClient = MockClient(router.handle);

    final s = StudyService();
    final stats = await s.getStudyStats();
    expect(stats.todayStudy, 1);
    expect(stats.totalVocabulary, 100);
  });

  test('StudyService.getStudyTrend parses list', () async {
    final router = TestRequestRouter();
    router.on('GET', '${ApiConstants.baseUrl}${ApiConstants.studyTrend}?days=7', (req) async {
      return jsonResponse(200, {
        'code': 200,
        'message': 'success',
        'data': [
          {'date': '2026-04-22', 'studyCount': 1, 'reviewCount': 0, 'correctRate': 1.0},
        ],
      });
    });

    ApiClient.debugHttpClient = MockClient(router.handle);

    final s = StudyService();
    final list = await s.getStudyTrend(days: 7);
    expect(list.length, 1);
    expect(list.first.correctRate, 1.0);
  });

  test('StudyService.getStudyCalendar parses response', () async {
    final router = TestRequestRouter();
    router.on('GET', '${ApiConstants.baseUrl}${ApiConstants.studyCalendar}?year=2026&month=4', (req) async {
      return jsonResponse(200, {
        'code': 200,
        'message': 'success',
        'data': {'year': 2026, 'month': 4, 'studyDates': ['2026-04-22']},
      });
    });

    ApiClient.debugHttpClient = MockClient(router.handle);

    final s = StudyService();
    final c = await s.getStudyCalendar(year: 2026, month: 4);
    expect(c.studyDates, ['2026-04-22']);
  });
}
