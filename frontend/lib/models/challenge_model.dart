// frontend/lib/models/challenge_model.dart
class ChallengeStartResponse {
  final String challengeId;
  final List<ChallengeQuestion> questions;
  final int timeLimit;

  ChallengeStartResponse({
    required this.challengeId,
    required this.questions,
    required this.timeLimit,
  });

  factory ChallengeStartResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final list = data['questions'] as List<dynamic>? ?? [];
    return ChallengeStartResponse(
      challengeId: data['challengeId']?.toString() ?? '',
      questions: list
          .map((e) => ChallengeQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      timeLimit: (data['timeLimit'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': {
        'challengeId': challengeId,
        'questions': questions.map((e) => e.toJson()).toList(),
        'timeLimit': timeLimit,
      },
    };
  }
}

class ChallengeQuestion {
  final int id;
  final String word;
  final List<String> options;
  final int correctIndex;

  ChallengeQuestion({
    required this.id,
    required this.word,
    required this.options,
    required this.correctIndex,
  });

  factory ChallengeQuestion.fromJson(Map<String, dynamic> json) {
    return ChallengeQuestion(
      id: (json['id'] as num?)?.toInt() ?? 0,
      word: json['word']?.toString() ?? '',
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      correctIndex: (json['correctIndex'] as num?)?.toInt() ?? 0,
    );
  }

  String get question => '';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'options': options,
      'correctIndex': correctIndex,
    };
  }
}

class ChallengeAnswer {
  final int questionId;
  final int selectedIndex;
  final int timeSpent;

  ChallengeAnswer({
    required this.questionId,
    required this.selectedIndex,
    required this.timeSpent,
  });

  factory ChallengeAnswer.fromJson(Map<String, dynamic> json) {
    return ChallengeAnswer(
      questionId: (json['questionId'] as num?)?.toInt() ?? 0,
      selectedIndex: (json['selectedIndex'] as num?)?.toInt() ?? 0,
      timeSpent: (json['timeSpent'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'selectedIndex': selectedIndex,
      'timeSpent': timeSpent,
    };
  }
}

class ChallengeSubmitResponse {
  final int score;
  final int correctCount;
  final int totalCount;
  final double accuracy;
  final int addedScore;
  final int totalScore;

  ChallengeSubmitResponse({
    required this.score,
    required this.correctCount,
    required this.totalCount,
    required this.accuracy,
    required this.addedScore,
    required this.totalScore,
  });

  factory ChallengeSubmitResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return ChallengeSubmitResponse(
      score: (data['score'] as num?)?.toInt() ?? 0,
      correctCount: (data['correctCount'] as num?)?.toInt() ?? 0,
      totalCount: (data['totalCount'] as num?)?.toInt() ?? 0,
      accuracy: (data['accuracy'] as num?)?.toDouble() ?? 0,
      addedScore: (data['addedScore'] as num?)?.toInt() ?? 0,
      totalScore: (data['totalScore'] as num?)?.toInt() ?? 0,
    );
  }

  String get result => accuracy >= 0.6 ? 'pass' : 'fail';

  Map<String, dynamic> toJson() {
    return {
      'data': {
        'score': score,
        'correctCount': correctCount,
        'totalCount': totalCount,
        'accuracy': accuracy,
        'addedScore': addedScore,
        'totalScore': totalScore,
      },
    };
  }
}

class BattleRecord {
  final int id;
  final int levelType;
  final int score;
  final int correctCount;
  final int totalCount;
  final int? duration;
  final DateTime createTime;
  final String? username;

  BattleRecord({
    required this.id,
    required this.levelType,
    required this.score,
    required this.correctCount,
    required this.totalCount,
    this.duration,
    required this.createTime,
    this.username,
  });

  factory BattleRecord.fromJson(Map<String, dynamic> json) {
    final createTimeRaw = json['createTime'] ?? json['createdAt'];
    return BattleRecord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      levelType: (json['levelType'] as num?)?.toInt() ?? 0,
      score: (json['score'] as num?)?.toInt() ?? 0,
      correctCount: (json['correctCount'] as num?)?.toInt() ?? 0,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      duration: (json['duration'] as num?)?.toInt(),
      createTime: DateTime.tryParse(createTimeRaw?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      username: json['username']?.toString(),
    );
  }

  String get levelTypeName {
    switch (levelType) {
      case 1:
        return '初级场';
      case 2:
        return '中级场';
      case 3:
        return '高级场';
      default:
        return '未知场次';
    }
  }
}
