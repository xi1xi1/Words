class StudyStats {
  final int totalLearned;
  final int todayStudy;
  final int todayReview;
  final int dueReviewCount;
  final int streakDays;
  final int totalTime;

  StudyStats({
    required this.totalLearned,
    required this.todayStudy,
    required this.todayReview,
    required this.dueReviewCount,
    required this.streakDays,
    required this.totalTime,
  });

  factory StudyStats.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return StudyStats(
      totalLearned: data['totalLearned'] as int,
      todayStudy: data['todayStudy'] as int,
      todayReview: data['todayReview'] as int,
      dueReviewCount: data['dueReviewCount'] as int,
      streakDays: data['streakDays'] as int,
      totalTime: data['totalTime'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': {
        'totalLearned': totalLearned,
        'todayStudy': todayStudy,
        'todayReview': todayReview,
        'dueReviewCount': dueReviewCount,
        'streakDays': streakDays,
        'totalTime': totalTime,
      },
    };
  }
}

class StudyTrend {
  final DateTime date;
  final int learnedCount;
  final int timeSpent;

  StudyTrend({
    required this.date,
    required this.learnedCount,
    required this.timeSpent,
  });

  factory StudyTrend.fromJson(Map<String, dynamic> json) {
    return StudyTrend(
      date: DateTime.parse(json['date'] as String),
      learnedCount: json['learnedCount'] as int,
      timeSpent: json['timeSpent'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'learnedCount': learnedCount,
      'timeSpent': timeSpent,
    };
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
    final list = data['days'] as List<dynamic>;
    return LearningCalendar(
      year: data['year'] as int,
      month: data['month'] as int,
      days: list
          .map((e) => CalendarDay.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': {
        'year': year,
        'month': month,
        'days': days.map((e) => e.toJson()).toList(),
      },
    };
  }
}

class CalendarDay {
  final int day;
  final bool hasLearned;
  final int learnedCount;

  CalendarDay({
    required this.day,
    required this.hasLearned,
    required this.learnedCount,
  });

  factory CalendarDay.fromJson(Map<String, dynamic> json) {
    return CalendarDay(
      day: json['day'] as int,
      hasLearned: json['hasLearned'] as bool,
      learnedCount: json['learnedCount'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {'day': day, 'hasLearned': hasLearned, 'learnedCount': learnedCount};
  }
}
