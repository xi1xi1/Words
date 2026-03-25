class WordbookWord {
  final int id;
  final String word;
  final String phonetic;
  final String translation;
  final DateTime addedAt;

  WordbookWord({
    required this.id,
    required this.word,
    required this.phonetic,
    required this.translation,
    required this.addedAt,
  });

  factory WordbookWord.fromJson(Map<String, dynamic> json) {
    return WordbookWord(
      id: json['id'] as int,
      word: json['word'] as String,
      phonetic: json['phonetic'] as String,
      translation: json['translation'] as String,
      addedAt: DateTime.parse(json['addedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'phonetic': phonetic,
      'translation': translation,
      'addedAt': addedAt.toIso8601String(),
    };
  }
}

class AIContentResponse {
  final String content;
  final String type;

  AIContentResponse({required this.content, required this.type});

  factory AIContentResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return AIContentResponse(
      content: data['content'] as String,
      type: data['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': {'content': content, 'type': type},
    };
  }
}
