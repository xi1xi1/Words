import 'package:flutter_test/flutter_test.dart';

import 'package:beileme/models/word_model.dart';

void main() {
  group('Word.fromJson', () {
    test('parses id from id and wordId fallback', () {
      final w1 = Word.fromJson({
        'id': 12,
        'word': 'apple',
        'phonetic': '/a/',
        'meaning': ['苹果'],
      });
      expect(w1.id, 12);

      final w2 = Word.fromJson({
        'wordId': 34,
        'word': 'banana',
        'phonetic': '/b/',
        'meaning': ['香蕉'],
      });
      expect(w2.id, 34);
    });

    test('parses example/options as list or string', () {
      final wList = Word.fromJson({
        'id': 1,
        'word': 'a',
        'phonetic': '',
        'meaning': ['m'],
        'example': ['en', 'zh'],
        'options': ['m', 'x', 'y', 'z'],
      });
      expect(wList.example, ['en', 'zh']);
      expect(wList.options, ['m', 'x', 'y', 'z']);

      final wStr = Word.fromJson({
        'id': 2,
        'word': 'b',
        'phonetic': '',
        'meaning': ['m'],
        'example': 'only one',
        'options': 'opt',
      });
      expect(wStr.example, ['only one']);
      expect(wStr.options, ['opt']);
    });

    test('toJson includes optional fields when present', () {
      final w = Word(
        id: 1,
        word: 'apple',
        phonetic: '/a/',
        meaning: const ['苹果'],
        example: const ['ex'],
        audioUrl: 'a.mp3',
        levelLabel: 'A1',
        partOfSpeech: 'n.',
        synonyms: const ['pome'],
        antonyms: const [''],
      );

      final j = w.toJson();
      expect(j['audioUrl'], 'a.mp3');
      expect(j['synonyms'], ['pome']);
      expect(j['antonyms'], ['']);
    });
  });

  group('DailyWordsResponse.fromJson', () {
    test('returns empty when data missing', () {
      final r = DailyWordsResponse.fromJson({'code': 200, 'message': 'ok'});
      expect(r.newWords, isEmpty);
      expect(r.reviewWords, isEmpty);
      expect(r.total, 0);
    });

    test('parses lists and counts with fallbacks', () {
      final r = DailyWordsResponse.fromJson({
        'code': 200,
        'message': 'ok',
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
          'learnableWordCount': 10,
          'reviewableWordCount': 3,
        }
      });
      expect(r.newWords.length, 1);
      expect(r.learnableWordCount, 10);
      expect(r.reviewableWordCount, 3);
      expect(r.total, 1);
    });

    test('toJson outputs nested lists and counts', () {
      final r = DailyWordsResponse(
        newWords: [
          Word(id: 1, word: 'a', phonetic: '', meaning: const ['m']),
        ],
        reviewWords: const [],
        total: 1,
        learnableWordCount: 1,
        reviewableWordCount: 0,
      );

      final j = r.toJson();
      final data = j['data'] as Map<String, dynamic>;
      expect(data['total'], 1);
      expect((data['newWords'] as List<dynamic>).length, 1);
    });
  });

  group('LearnProgress.fromJson', () {
    test('supports multiple field names', () {
      expect(
        LearnProgress.fromJson({'completedCount': 2, 'totalCount': 5}).progress,
        closeTo(0.4, 1e-9),
      );
      expect(
        LearnProgress.fromJson({'learnedCount': 3, 'todayTarget': 6}).learnedCount,
        3,
      );
      expect(LearnProgress.fromJson({'todayLearned': 1, 'todayTarget': 2}).totalCount, 2);
    });

    test('toJson outputs completedCount/totalCount', () {
      final p = LearnProgress(completedCount: 1, totalCount: 4);
      expect(p.toJson(), {'completedCount': 1, 'totalCount': 4});
    });
  });
}
