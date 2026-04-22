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
  });

  test('WordService.searchWords supports data.list', () async {
    final router = TestRequestRouter();
    router.on('GET', '${ApiConstants.baseUrl}${ApiConstants.wordsSearch}?keyword=app&page=1&size=20', (req) async {
      return jsonResponse(200, {
        'code': 200,
        'message': 'success',
        'data': {
          'list': [
            {'id': 1, 'word': 'apple', 'phonetic': '', 'meaning': ['苹果'], 'example': []},
          ],
        },
      });
    });

    ApiClient.debugHttpClient = MockClient(router.handle);

    final s = WordService();
    final r = await s.searchWords(keyword: 'app');
    expect(r.length, 1);
    expect(r.first.word, 'apple');
  });

  test('WordService.searchWords supports data.content', () async {
    final router = TestRequestRouter();
    router.on('GET', '${ApiConstants.baseUrl}${ApiConstants.wordsSearch}?keyword=app&page=1&size=20', (req) async {
      return jsonResponse(200, {
        'code': 200,
        'message': 'success',
        'data': {
          'content': [
            {'id': 2, 'word': 'application', 'phonetic': '', 'meaning': ['应用'], 'example': []},
          ],
        },
      });
    });

    ApiClient.debugHttpClient = MockClient(router.handle);

    final s = WordService();
    final r = await s.searchWords(keyword: 'app');
    expect(r.length, 1);
    expect(r.first.id, 2);
  });

  test('WordService.getWordDetail parses data', () async {
    final router = TestRequestRouter();
    router.on('GET', '${ApiConstants.baseUrl}${ApiConstants.wordsDetail}/1', (req) async {
      return jsonResponse(200, {
        'code': 200,
        'message': 'success',
        'data': {'id': 1, 'word': 'apple', 'phonetic': '', 'meaning': ['苹果'], 'example': []},
      });
    });

    ApiClient.debugHttpClient = MockClient(router.handle);

    final s = WordService();
    final w = await s.getWordDetail(1);
    expect(w.id, 1);
    expect(w.word, 'apple');
  });
}
