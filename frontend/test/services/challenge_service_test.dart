import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:beileme/core/constants/api_constants.dart';
import 'package:beileme/core/network/api_client.dart';
import 'package:beileme/models/challenge_model.dart';
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

  test('ChallengeService.startChallenge parses response', () async {
    final router = TestRequestRouter();
    router.on('POST', '${ApiConstants.baseUrl}${ApiConstants.challengeStart}', (req) async {
      return jsonResponse(200, {
        'code': 200,
        'message': 'success',
        'data': {
          'challengeId': 'c1',
          'timeLimit': 10,
          'questions': [
            {
              'id': 1,
              'word': 'apple',
              'options': ['苹果', '香蕉', '梨', '桃子'],
              'correctIndex': 0,
            }
          ],
        }
      });
    });

    ApiClient.debugHttpClient = MockClient(router.handle);

    final s = ChallengeService();
    final r = await s.startChallenge(1);
    expect(r.challengeId, 'c1');
    expect(r.questions.first.word, 'apple');
  });

  test('ChallengeService.submitChallenge sends answers and parses response', () async {
    final router = TestRequestRouter();
    router.on('POST', '${ApiConstants.baseUrl}${ApiConstants.challengeSubmit}', (req) async {
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      expect(body['challengeId'], 'c1');
      expect(body['answers'], isA<List<dynamic>>());

      return jsonResponse(200, {
        'code': 200,
        'message': 'success',
        'data': {
          'score': 100,
          'correctCount': 1,
          'totalCount': 1,
          'accuracy': 1.0,
          'addedScore': 10,
          'totalScore': 1000,
        },
      });
    });

    ApiClient.debugHttpClient = MockClient(router.handle);

    final s = ChallengeService();
    final r = await s.submitChallenge(
      challengeId: 'c1',
      levelType: 1,
      answers: [
        ChallengeAnswer(questionId: 1, selectedIndex: 0, timeSpent: 1),
      ],
    );
    expect(r.score, 100);
    expect(r.result, 'pass');
  });
}
