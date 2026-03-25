// lib/models/user_model.dart
class UserInfo {
  final int id;
  final String username;
  final String? avatar;
  final int totalScore;
  final int level;

  UserInfo({
    required this.id,
    required this.username,
    this.avatar,
    required this.totalScore,
    required this.level,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: (json['id'] as num?)?.toInt() ?? 0,
      username: json['username']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      totalScore: (json['totalScore'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'avatar': avatar,
      'totalScore': totalScore,
      'level': level,
    };
  }

  UserInfo copyWith({
    int? id,
    String? username,
    String? avatar,
    int? totalScore,
    int? level,
  }) {
    return UserInfo(
      id: id ?? this.id,
      username: username ?? this.username,
      avatar: avatar ?? this.avatar,
      totalScore: totalScore ?? this.totalScore,
      level: level ?? this.level,
    );
  }
}

// lib/models/word_model.dart
class Word {
  final int id;
  final String word;
  final List<String> meaning;
  final String? phonetic;
  final List<String> example;

  Word({
    required this.id,
    required this.word,
    required this.meaning,
    this.phonetic,
    required this.example,
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: json['id'] as int,
      word: json['word'] as String,
      meaning: (json['meaning'] as List<dynamic>).cast<String>(),
      phonetic: json['phonetic'] as String?,
      example: (json['example'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'meaning': meaning,
      'phonetic': phonetic,
      'example': example,
    };
  }
}

class DailyWordsResponse {
  final List<Word> newWords;
  final List<Word> reviewWords;

  DailyWordsResponse({required this.newWords, required this.reviewWords});

  factory DailyWordsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return DailyWordsResponse(
      newWords: (data['newWords'] as List<dynamic>)
          .map((e) => Word.fromJson(e as Map<String, dynamic>))
          .toList(),
      reviewWords: (data['reviewWords'] as List<dynamic>)
          .map((e) => Word.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LearnProgress {
  final int todayLearned;
  final int todayTarget;

  LearnProgress({required this.todayLearned, required this.todayTarget});

  factory LearnProgress.fromJson(Map<String, dynamic> json) {
    return LearnProgress(
      todayLearned: json['todayLearned'] as int,
      todayTarget: json['todayTarget'] as int,
    );
  }
}

// lib/models/challenge_model.dart
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
      id: json['id'] as int,
      word: json['word'] as String,
      options: (json['options'] as List<dynamic>).cast<String>(),
      correctIndex: json['correctIndex'] as int,
    );
  }
}

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
    return ChallengeStartResponse(
      challengeId: data['challengeId'] as String,
      questions: (data['questions'] as List<dynamic>)
          .map((e) => ChallengeQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      timeLimit: data['timeLimit'] as int,
    );
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
    final data = json['data'] as Map<String, dynamic>;
    return ChallengeSubmitResponse(
      score: data['score'] as int,
      correctCount: data['correctCount'] as int,
      totalCount: data['totalCount'] as int,
      accuracy: (data['accuracy'] as num).toDouble(),
      addedScore: data['addedScore'] as int,
      totalScore: data['totalScore'] as int,
    );
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

  BattleRecord({
    required this.id,
    required this.levelType,
    required this.score,
    required this.correctCount,
    required this.totalCount,
    this.duration,
    required this.createTime,
  });

  factory BattleRecord.fromJson(Map<String, dynamic> json) {
    return BattleRecord(
      id: json['id'] as int,
      levelType: json['levelType'] as int,
      score: json['score'] as int,
      correctCount: json['correctCount'] as int,
      totalCount: json['totalCount'] as int,
      duration: json['duration'] as int?,
      createTime: DateTime.parse(json['createTime'] as String),
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
        return '未知';
    }
  }
}

// lib/models/leaderboard_model.dart
class RankItem {
  final int rank;
  final int userId;
  final String username;
  final String? avatar;
  final int totalScore;

  RankItem({
    required this.rank,
    required this.userId,
    required this.username,
    this.avatar,
    required this.totalScore,
  });

  factory RankItem.fromJson(Map<String, dynamic> json) {
    return RankItem(
      rank: json['rank'] as int,
      userId: json['userId'] as int,
      username: json['username'] as String,
      avatar: json['avatar'] as String?,
      totalScore: json['totalScore'] as int,
    );
  }
}

class LeaderboardResponse {
  final List<RankItem> list;
  final int? myRank;

  LeaderboardResponse({required this.list, this.myRank});

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return LeaderboardResponse(
      list: (data['list'] as List<dynamic>)
          .map((e) => RankItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      myRank: data['myRank'] as int?,
    );
  }
}

// lib/models/wordbook_model.dart
class WordbookWord {
  final int id;
  final String word;
  final List<String> meaning;
  final String? phonetic;
  final List<String> aiExamples;
  final List<String> aiDialogues;
  final DateTime addedAt;

  WordbookWord({
    required this.id,
    required this.word,
    required this.meaning,
    this.phonetic,
    required this.aiExamples,
    required this.aiDialogues,
    required this.addedAt,
  });

  factory WordbookWord.fromJson(Map<String, dynamic> json) {
    return WordbookWord(
      id: json['id'] as int,
      word: json['word'] as String,
      meaning: (json['meaning'] as List<dynamic>).cast<String>(),
      phonetic: json['phonetic'] as String?,
      aiExamples: (json['aiExamples'] as List<dynamic>?)?.cast<String>() ?? [],
      aiDialogues:
          (json['aiDialogues'] as List<dynamic>?)?.cast<String>() ?? [],
      addedAt: DateTime.parse(json['addedAt'] as String),
    );
  }
}

class AIContentResponse {
  final List<String> examples;
  final List<String> dialogues;

  AIContentResponse({required this.examples, required this.dialogues});

  factory AIContentResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return AIContentResponse(
      examples: (data['examples'] as List<dynamic>?)?.cast<String>() ?? [],
      dialogues: (data['dialogues'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}

// lib/models/study_model.dart
class StudyStats {
  final int todayStudy;
  final int todayReview;
  final int totalWords;
  final int masteredWords;
  final int wordbookWords;
  final int dueReviewCount;
  final int totalScore;
  final int level;

  StudyStats({
    required this.todayStudy,
    required this.todayReview,
    required this.totalWords,
    required this.masteredWords,
    required this.wordbookWords,
    required this.dueReviewCount,
    required this.totalScore,
    required this.level,
  });

  factory StudyStats.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return StudyStats(
      todayStudy: data['todayStudy'] as int,
      todayReview: data['todayReview'] as int,
      totalWords: data['totalWords'] as int,
      masteredWords: data['masteredWords'] as int,
      wordbookWords: data['wordbookWords'] as int,
      dueReviewCount: data['dueReviewCount'] as int,
      totalScore: data['totalScore'] as int,
      level: data['level'] as int,
    );
  }

  double get masteredRate {
    if (totalWords == 0) return 0;
    return masteredWords / totalWords;
  }
}

class StudyTrend {
  final DateTime date;
  final int studyCount;
  final int reviewCount;
  final double correctRate;

  StudyTrend({
    required this.date,
    required this.studyCount,
    required this.reviewCount,
    required this.correctRate,
  });

  factory StudyTrend.fromJson(Map<String, dynamic> json) {
    return StudyTrend(
      date: DateTime.parse(json['date'] as String),
      studyCount: json['studyCount'] as int,
      reviewCount: json['reviewCount'] as int,
      correctRate: (json['correctRate'] as num).toDouble(),
    );
  }
}

class CalendarDay {
  final DateTime date;
  final int studyCount;
  final int intensity;

  CalendarDay({
    required this.date,
    required this.studyCount,
    required this.intensity,
  });

  factory CalendarDay.fromJson(Map<String, dynamic> json) {
    return CalendarDay(
      date: DateTime.parse(json['date'] as String),
      studyCount: json['studyCount'] as int,
      intensity: json['intensity'] as int,
    );
  }
}

class LearningCalendar {
  final int year;
  final int month;
  final List<CalendarDay> days;

  LearningCalendar({
    required this.year,
    required this.month,
    required this.days,
  });

  factory LearningCalendar.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return LearningCalendar(
      year: data['year'] as int,
      month: data['month'] as int,
      days: (data['days'] as List<dynamic>)
          .map((e) => CalendarDay.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
