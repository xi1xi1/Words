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

class MemoryHintBlock {
  final String title;
  final String content;
  final String explanation;

  const MemoryHintBlock({
    required this.title,
    required this.content,
    required this.explanation,
  });

  bool get isNotEmpty =>
      title.trim().isNotEmpty ||
      content.trim().isNotEmpty ||
      explanation.trim().isNotEmpty;

  factory MemoryHintBlock.fromJson(Map<String, dynamic> json) {
    return MemoryHintBlock(
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'explanation': explanation,
    };
  }
}

class AIContentResponse {
  final String word;
  final String meaning;
  final MemoryHintBlock? homophonic;
  final MemoryHintBlock? morpheme;
  final MemoryHintBlock? story;
  final String summary;
  final String notes;

  const AIContentResponse({
    required this.word,
    required this.meaning,
    required this.homophonic,
    required this.morpheme,
    required this.story,
    required this.summary,
    required this.notes,
  });

  bool get hasContent =>
      (homophonic?.isNotEmpty ?? false) ||
      (morpheme?.isNotEmpty ?? false) ||
      (story?.isNotEmpty ?? false) ||
      summary.trim().isNotEmpty ||
      notes.trim().isNotEmpty;

  factory AIContentResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};

    MemoryHintBlock? parseBlock(dynamic value) {
      if (value is! Map<String, dynamic>) return null;
      final block = MemoryHintBlock.fromJson(value);
      return block.isNotEmpty ? block : null;
    }

    return AIContentResponse(
      word: data['word']?.toString() ?? '',
      meaning: data['meaning']?.toString() ?? '',
      homophonic: parseBlock(data['homophonic']),
      morpheme: parseBlock(data['morpheme']),
      story: parseBlock(data['story']),
      summary: data['summary']?.toString() ?? '',
      notes: data['notes']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': {
        'word': word,
        'meaning': meaning,
        'homophonic': homophonic?.toJson(),
        'morpheme': morpheme?.toJson(),
        'story': story?.toJson(),
        'summary': summary,
        'notes': notes,
      },
    };
  }
}
