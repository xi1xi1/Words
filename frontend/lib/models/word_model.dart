// frontend/lib/models/word_model.dart
class Word {
  final int id;
  final String word;
  final String phonetic;
  final List<String> meaning;
  final List<String>? example;
  final String? audioUrl;
  final String? levelLabel;
  final String? partOfSpeech;
  final List<String>? synonyms;
  final List<String>? antonyms;
  final int? stage;
  final List<String>? options;

  Word({
    required this.id,
    required this.word,
    required this.phonetic,
    required this.meaning,
    this.example,
    this.audioUrl,
    this.levelLabel,
    this.partOfSpeech,
    this.synonyms,
    this.antonyms,
    this.stage,
    this.options,
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    final exampleValue = json['example'];
    final parsedExample = exampleValue is List<dynamic>
        ? exampleValue.map((e) => e.toString()).toList()
        : exampleValue is String
        ? <String>[exampleValue]
        : null;

    final optionsValue = json['options'];
    final parsedOptions = optionsValue is List<dynamic>
        ? optionsValue.map((e) => e.toString()).toList()
        : optionsValue is String
        ? <String>[optionsValue]
        : null;

    return Word(
      id:
          (json['id'] as num?)?.toInt() ??
          (json['wordId'] as num?)?.toInt() ??
          0,
      word: json['word']?.toString() ?? '',
      phonetic: json['phonetic']?.toString() ?? '',
      meaning:
          (json['meaning'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      example: parsedExample,
      audioUrl: json['audioUrl']?.toString(),
      levelLabel: json['levelLabel']?.toString() ?? json['level']?.toString(),
      partOfSpeech:
          json['partOfSpeech']?.toString() ?? json['wordClass']?.toString(),
      synonyms: (json['synonyms'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      antonyms: (json['antonyms'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      stage: (json['stage'] as num?)?.toInt(),
      options: parsedOptions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'phonetic': phonetic,
      'meaning': meaning,
      'example': example,
      'audioUrl': audioUrl,
      'levelLabel': levelLabel,
      'partOfSpeech': partOfSpeech,
      'synonyms': synonyms,
      'antonyms': antonyms,
    };
  }
}

class LearnProgress {
  final int completedCount;
  final int totalCount;

  LearnProgress({required this.completedCount, required this.totalCount});

  factory LearnProgress.fromJson(Map<String, dynamic> json) {
    return LearnProgress(
      completedCount:
          (json['completedCount'] as num?)?.toInt() ??
          (json['learnedCount'] as num?)?.toInt() ??
          (json['todayLearned'] as num?)?.toInt() ??
          0,
      totalCount:
          (json['totalCount'] as num?)?.toInt() ??
          (json['todayTarget'] as num?)?.toInt() ??
          0,
    );
  }

  int get learnedCount => completedCount;
  double get progress => totalCount == 0 ? 0 : completedCount / totalCount;

  Map<String, dynamic> toJson() {
    return {'completedCount': completedCount, 'totalCount': totalCount};
  }
}

class DailyWordsResponse {
  final List<Word> newWords;
  final List<Word> reviewWords;
  final int total;

  DailyWordsResponse({
    required this.newWords,
    required this.reviewWords,
    required this.total,
  });

  factory DailyWordsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data == null || data is! Map<String, dynamic>) {
      return DailyWordsResponse(newWords: [], reviewWords: [], total: 0);
    }

    final newWordsList = data['newWords'] as List<dynamic>? ?? [];
    final reviewWordsList = data['reviewWords'] as List<dynamic>? ?? [];

    return DailyWordsResponse(
      newWords: newWordsList
          .map((e) => Word.fromJson(e as Map<String, dynamic>))
          .toList(),
      reviewWords: reviewWordsList
          .map((e) => Word.fromJson(e as Map<String, dynamic>))
          .toList(),
      total:
          (data['total'] as num?)?.toInt() ??
          newWordsList.length + reviewWordsList.length,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': {
        'newWords': newWords.map((e) => e.toJson()).toList(),
        'reviewWords': reviewWords.map((e) => e.toJson()).toList(),
        'total': total,
      },
    };
  }
}
