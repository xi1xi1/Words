class WordbookWord {
  final int id;
  final int wordId;
  final String word;
  final String phonetic;
  final String translation;
  final List<String> meaning;
  final List<String> example;
  final DateTime addedAt;

  WordbookWord({
    required this.id,
    required this.wordId,
    required this.word,
    required this.phonetic,
    required this.translation,
    required this.meaning,
    required this.example,
    required this.addedAt,
  });

  factory WordbookWord.fromJson(Map<String, dynamic> json) {
    final meaningList =
        (json['meaning'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];

    return WordbookWord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      wordId:
          (json['wordId'] as num?)?.toInt() ??
          (json['id'] as num?)?.toInt() ??
          0,
      word: json['word']?.toString() ?? '',
      phonetic: json['phonetic']?.toString() ?? '',
      translation:
          json['translation']?.toString() ??
          (meaningList.isNotEmpty ? meaningList.join('；') : ''),
      meaning: meaningList,
      example:
          (json['example'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
      addedAt:
          DateTime.tryParse(
            json['addedAt']?.toString() ?? json['addTime']?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wordId': wordId,
      'word': word,
      'phonetic': phonetic,
      'translation': translation,
      'meaning': meaning,
      'example': example,
      'addedAt': addedAt.toIso8601String(),
    };
  }
}

class AIContentResponse {
  final List<String> examples;
  final String aiExample;
  final String word;

  AIContentResponse({
    required this.examples,
    required this.aiExample,
    required this.word,
  });

  factory AIContentResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return AIContentResponse(
      examples:
          (data['examples'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      aiExample: data['aiExample']?.toString() ?? '',
      word: data['word']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': {'examples': examples, 'aiExample': aiExample, 'word': word},
    };
  }
}
