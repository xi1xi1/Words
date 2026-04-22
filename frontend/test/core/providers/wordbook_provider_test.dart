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

  test('WordbookProvider.load populates words on success', () async {
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

    final p = WordbookProvider();
    await p.load();

    expect(p.initialized, isTrue);
    expect(p.loading, isFalse);
    expect(p.count, 1);
    expect(p.containsWord(10), isTrue);
  });

  test('WordbookProvider.load sets empty list on ApiException', () async {
    final router = TestRequestRouter();
    router.on('GET', '${ApiConstants.baseUrl}${ApiConstants.wordbookList}?page=1&size=20', (req) async {
      return jsonResponse(200, {
        'code': 500,
        'message': 'error',
        'data': null,
      });
    });

    ApiClient.debugHttpClient = MockClient(router.handle);

    final p = WordbookProvider();
    await p.load(force: true);

    expect(p.initialized, isTrue);
    expect(p.words, isEmpty);
  });
}
