// frontend/lib/models/word_model.dart

class Word {
  final int id;
  final String word;
  final String phonetic;
  final List<String> meaning;
  final List<String>? example;
  final String? audioUrl;

  Word({
    required this.id,
    required this.word,
    required this.phonetic,
    required this.meaning,
    this.example,
    this.audioUrl,
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: (json['id'] as num?)?.toInt() ?? 0,
      word: json['word']?.toString() ?? '',
      phonetic: json['phonetic']?.toString() ?? '',
      meaning:
          (json['meaning'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      example: (json['example'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      audioUrl: json['audioUrl']?.toString(),
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
    };
  }
}

class LearnProgress {
  final int learnedCount;
  final int totalCount;
  final double progress;

  LearnProgress({
    required this.learnedCount,
    required this.totalCount,
    required this.progress,
  });

  factory LearnProgress.fromJson(Map<String, dynamic> json) {
    return LearnProgress(
      learnedCount: (json['learnedCount'] as num?)?.toInt() ?? 0,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'learnedCount': learnedCount,
      'totalCount': totalCount,
      'progress': progress,
    };
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

    // 处理 data 为 null 的情况
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
      total: (data['total'] as num?)?.toInt() ?? 0,
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
