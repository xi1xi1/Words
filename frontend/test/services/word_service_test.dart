import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beileme/core/constants/api_constants.dart';
import 'package:beileme/core/network/api_client.dart';
import 'package:beileme/services/word_service.dart';

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

  test('WordService.getDailyWords parses response', () async {
    final router = TestRequestRouter();
    router.on('GET', '${ApiConstants.baseUrl}${ApiConstants.wordsDaily}', (req) async {
      return jsonResponse(200, {
        'code': 200,
        'message': 'success',
        'data': {
          'newWords': [
            {
              'id': 1,
              'word': 'apple',
              'phonetic': '',
              'meaning': ['苹果'],
              'stage': 1,
              'options': ['苹果', '香蕉', '梨', '桃子'],
            }
          ],
          'reviewWords': [],
          'learnableWordCount': 1,
          'reviewableWordCount': 0,
          'total': 1,
        },
      });
    });

    ApiClient.debugHttpClient = MockClient(router.handle);

    final s = WordService();
    final r = await s.getDailyWords();
    expect(r.newWords.length, 1);
    expect(r.newWords.first.word, 'apple');
  });

  test('WordService.submitLearnResult returns nextWord null', () async {
    final router = TestRequestRouter();
    router.on('POST', '${ApiConstants.baseUrl}${ApiConstants.wordsLearn}', (req) async {
      return jsonResponse(200, {
        'code': 200,
        'message': 'success',
        'data': {
          'nextWord': null,
          'completedCount': 1,
          'totalCount': 10,
        },
      });
    });

    ApiClient.debugHttpClient = MockClient(router.handle);

    final s = WordService();
    final r = await s.submitLearnResult(wordId: 1, isCorrect: true, stage: 1);
    expect(r.nextWord, isNull);
    expect(r.progress.completedCount, 1);
  });
}
