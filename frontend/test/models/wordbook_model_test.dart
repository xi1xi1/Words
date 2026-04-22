import 'package:flutter_test/flutter_test.dart';

import 'package:beileme/models/wordbook_model.dart';

void main() {
  test('WordbookWord.fromJson parses meaning/translation fallbacks', () {
    final w = WordbookWord.fromJson({
      'id': 1,
      'wordId': 10,
      'word': 'apple',
      'phonetic': '/a/',
      'meaning': ['苹果', '苹果公司'],
      'example': ['ex1', 'ex2'],
      'addedAt': '2026-04-22T12:00:00Z',
    });

    expect(w.translation, '苹果；苹果公司');
    expect(w.meaning.length, 2);
    expect(w.example.length, 2);
    expect(w.addedAt.year, 2026);
  });

  test('WordbookWord.toJson contains expected fields', () {
    final w = WordbookWord(
      id: 1,
      wordId: 10,
      word: 'apple',
      phonetic: '/a/',
      translation: '苹果',
      meaning: const ['苹果'],
      example: const ['ex'],
      addedAt: DateTime.utc(2026, 4, 22),
    );

    final j = w.toJson();
    expect(j['wordId'], 10);
    expect(j['addedAt'], contains('2026-04-22'));
  });

  test('MemoryHintBlock.isNotEmpty and toJson', () {
    const empty = MemoryHintBlock(title: '', content: '', explanation: '');
    expect(empty.isNotEmpty, isFalse);
    expect(empty.toJson()['title'], '');

    const filled = MemoryHintBlock(title: 't', content: '', explanation: '');
    expect(filled.isNotEmpty, isTrue);
  });

  test('AIContentResponse.hasContent works with partial blocks', () {
    final r = AIContentResponse.fromJson({
      'code': 200,
      'message': 'ok',
      'data': {
        'word': 'test',
        'meaning': '含义',
        'homophonic': {'title': '谐音', 'content': '内容', 'explanation': ''},
        'morpheme': {'title': '', 'content': '', 'explanation': ''},
        'story': null,
        'summary': '',
        'notes': '',
      }
    });

    expect(r.word, 'test');
    expect(r.homophonic, isNotNull);
    expect(r.morpheme, isNull);
    expect(r.hasContent, isTrue);
  });

  test('AIContentResponse.hasContent is false when all blocks empty', () {
    final r = AIContentResponse.fromJson({
      'code': 200,
      'message': 'ok',
      'data': {
        'word': 'test',
        'meaning': '含义',
        'homophonic': {'title': '', 'content': '', 'explanation': ''},
        'morpheme': {'title': '', 'content': '', 'explanation': ''},
        'story': {'title': '', 'content': '', 'explanation': ''},
        'summary': '',
        'notes': '',
      }
    });

    expect(r.homophonic, isNull);
    expect(r.morpheme, isNull);
    expect(r.story, isNull);
    expect(r.hasContent, isFalse);
  });

  test('AIContentResponse.toJson outputs nested data', () {
    const r = AIContentResponse(
      word: 'apple',
      meaning: '苹果',
      homophonic: MemoryHintBlock(title: 't', content: 'c', explanation: 'e'),
      morpheme: null,
      story: null,
      summary: 's',
      notes: 'n',
    );

    final j = r.toJson();
    final data = j['data'] as Map<String, dynamic>;
    expect(data['word'], 'apple');
    expect(data['homophonic'], isA<Map<String, dynamic>>());
  });
}
