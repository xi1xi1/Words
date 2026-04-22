import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:beileme/core/constants/api_constants.dart';
import 'package:beileme/core/network/api_client.dart';
import 'package:beileme/core/providers/wordbook_provider.dart';

import '../../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() {
    ApiClient.debugHttpClient = null;
  });

  test('WordbookProvider.addWord triggers add endpoint and refresh list', () async {
    final router = TestRequestRouter();

    var listCall = 0;

    router.on('POST', '${ApiConstants.baseUrl}${ApiConstants.wordbookAdd}/10', (req) async {
      return jsonResponse(200, {'code': 200, 'message': 'success', 'data': {}});
    });

    router.on('GET', '${ApiConstants.baseUrl}${ApiConstants.wordbookList}?page=1&size=20', (req) async {
      listCall++;
      if (listCall == 1) {
        return jsonResponse(200, {'code': 200, 'message': 'success', 'data': {'list': []}});
      }
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

    final p = WordbookProvider();
    await p.load(force: true);
    expect(p.containsWord(10), isFalse);

    await p.addWord(10);
    expect(p.containsWord(10), isTrue);
    expect(p.count, 1);
  });

  test('WordbookProvider.removeWord calls remove and updates local list', () async {
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

    router.on('DELETE', '${ApiConstants.baseUrl}${ApiConstants.wordbookRemove}/10', (req) async {
      return jsonResponse(200, {'code': 200, 'message': 'success', 'data': {}});
    });

    ApiClient.debugHttpClient = MockClient(router.handle);

    final p = WordbookProvider();
    await p.load(force: true);
    expect(p.containsWord(10), isTrue);

    await p.removeWord(10);
    expect(p.containsWord(10), isFalse);
    expect(p.count, 0);
  });

  test('WordbookProvider.clear resets flags and list', () async {
    final p = WordbookProvider();
    p.clear();
    expect(p.words, isEmpty);
    expect(p.loading, isFalse);
    expect(p.initialized, isFalse);
  });
}
