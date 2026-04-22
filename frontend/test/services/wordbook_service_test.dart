import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:beileme/core/constants/api_constants.dart';
import 'package:beileme/core/network/api_client.dart';
import 'package:beileme/services/wordbook_service.dart';

import '../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() {
    ApiClient.debugHttpClient = null;
  });

  test('WordbookService.getWordbookList parses list', () async {
    final router = TestRequestRouter();
    router.on('GET', '${ApiConstants.baseUrl}${ApiConstants.wordbookList}?page=1&size=20', (req) async {
      return jsonResponse(200, {
        'code': 200,
        'message': 'success',
        'data': {
          'list': [
            {
              'id': 1,
              'wordId': 10,
              'word': 'apple',
              'phonetic': '',
              'translation': '苹果',
              'meaning': ['苹果'],
              'example': ['ex'],
              'addedAt': '2026-04-22T00:00:00Z'
            }
          ]
        }
      });
    });

    ApiClient.debugHttpClient = MockClient(router.handle);

    final s = WordbookService();
    final list = await s.getWordbookList();
    expect(list.length, 1);
    expect(list.first.wordId, 10);
  });

  test('WordbookService.getAIMemoryContent parses response', () async {
    final router = TestRequestRouter();
    router.on('GET', '${ApiConstants.baseUrl}${ApiConstants.wordbookAi}/10', (req) async {
      return jsonResponse(200, {
        'code': 200,
        'message': 'success',
        'data': {
          'word': 'apple',
          'meaning': '苹果',
          'homophonic': {'title': '谐音', 'content': 'a', 'explanation': 'b'},
          'morpheme': null,
          'story': null,
          'summary': 's',
          'notes': 'n'
        }
      });
    });

    ApiClient.debugHttpClient = MockClient(router.handle);

    final s = WordbookService();
    final r = await s.getAIMemoryContent(10);
    expect(r.word, 'apple');
    expect(r.hasContent, isTrue);
  });
}
