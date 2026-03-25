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
    final data = json['data'] as Map<String, dynamic>;
    final list = data['questions'] as List<dynamic>;
    return ChallengeStartResponse(
      challengeId: data['challengeId'] as String,
      questions: list
          .map((e) => ChallengeQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      timeLimit: data['timeLimit'] as int,
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
  final String question;
  final List<String> options;
  final int correctIndex;

  ChallengeQuestion({
    required this.id,
    required this.word,
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  factory ChallengeQuestion.fromJson(Map<String, dynamic> json) {
    return ChallengeQuestion(
      id: json['id'] as int,
      word: json['word'] as String,
      question: json['question'] as String,
      options: (json['options'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      correctIndex: json['correctIndex'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'question': question,
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
      questionId: json['questionId'] as int,
      selectedIndex: json['selectedIndex'] as int,
      timeSpent: json['timeSpent'] as int,
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
  final String result;
  final double accuracy;
  final int addedScore;
  final int totalScore;

  ChallengeSubmitResponse({
    required this.score,
    required this.correctCount,
    required this.totalCount,
    required this.result,
    required this.accuracy,
    required this.addedScore,
    required this.totalScore,
  });

  factory ChallengeSubmitResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return ChallengeSubmitResponse(
      score: data['score'] as int,
      correctCount: data['correctCount'] as int,
      totalCount: data['totalCount'] as int,
      result: data['result'] as String,
      accuracy: (data['accuracy'] as num).toDouble(),
      addedScore: data['addedScore'] as int,
      totalScore: data['totalScore'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': {
        'score': score,
        'correctCount': correctCount,
        'totalCount': totalCount,
        'result': result,
        'accuracy': accuracy,
        'addedScore': addedScore,
        'totalScore': totalScore,
      },
    };
  }
}

class BattleRecord {
  final String id;
  final String username;
  final int score;
  final int levelType;
  final DateTime createdAt;

  BattleRecord({
    required this.id,
    required this.username,
    required this.score,
    required this.levelType,
    required this.createdAt,
  });

  factory BattleRecord.fromJson(Map<String, dynamic> json) {
    return BattleRecord(
      id: json['id'] as String,
      username: json['username'] as String,
      score: json['score'] as int,
      levelType: json['levelType'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'score': score,
      'levelType': levelType,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
