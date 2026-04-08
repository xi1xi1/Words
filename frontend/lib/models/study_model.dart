// frontend/lib/models/study_model.dart
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
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return StudyStats(
      todayStudy: (data['todayStudy'] as num?)?.toInt() ?? 0,
      todayReview: (data['todayReview'] as num?)?.toInt() ?? 0,
      totalWords: (data['totalWords'] as num?)?.toInt() ??
          (data['totalLearned'] as num?)?.toInt() ??
          0,
      masteredWords: (data['masteredWords'] as num?)?.toInt() ?? 0,
      wordbookWords: (data['wordbookWords'] as num?)?.toInt() ?? 0,
      dueReviewCount: (data['dueReviewCount'] as num?)?.toInt() ?? 0,
      totalScore: (data['totalScore'] as num?)?.toInt() ?? 0,
      level: (data['level'] as num?)?.toInt() ?? 1,
    );
  }

  int get totalLearned => totalWords;
  int get streakDays => level;
  int get totalTime => todayStudy;

  Map<String, dynamic> toJson() {
    return {
      'data': {
        'todayStudy': todayStudy,
        'todayReview': todayReview,
        'totalWords': totalWords,
        'masteredWords': masteredWords,
        'wordbookWords': wordbookWords,
        'dueReviewCount': dueReviewCount,
        'totalScore': totalScore,
        'level': level,
      },
    };
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
      date: DateTime.tryParse(json['date']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      studyCount: (json['studyCount'] as num?)?.toInt() ??
          (json['learnedCount'] as num?)?.toInt() ??
          0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      correctRate: (json['correctRate'] as num?)?.toDouble() ?? 0,
    );
  }

  int get learnedCount => studyCount;
  int get timeSpent => reviewCount;

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'studyCount': studyCount,
      'reviewCount': reviewCount,
      'correctRate': correctRate,
    };
  }
}

class LearningCalendar {
  final int year;
  final int month;
  final List<String> studyDates;

  LearningCalendar({
    required this.year,
    required this.month,
    required this.studyDates,
  });

  factory LearningCalendar.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return LearningCalendar(
      year: (data['year'] as num?)?.toInt() ?? 0,
      month: (data['month'] as num?)?.toInt() ?? 0,
      studyDates: (data['studyDates'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': {
        'year': year,
        'month': month,
        'studyDates': studyDates,
      },
    };
  }
}
