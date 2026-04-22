import 'package:flutter_test/flutter_test.dart';

import 'package:beileme/models/study_model.dart';

void main() {
  test('StudyStats.fromJson supports fallbacks', () {
    final s = StudyStats.fromJson({
      'code': 200,
      'message': 'ok',
      'data': {
        'todayStudy': 1,
        'todayReview': 2,
        'totalLearned': 30,
        'totalVocabularyCount': 100,
        'masteredWords': 10,
        'wordbookWords': 3,
        'dueReviewCount': 4,
        'totalScore': 80,
        'level': 6,
      },
    });

    expect(s.todayStudy, 1);
    expect(s.todayReview, 2);
    expect(s.totalWords, 30);
    expect(s.totalVocabulary, 100);
    expect(s.totalLearned, 30);
    expect(s.streakDays, 6);
  });

  test('StudyStats.toJson outputs expected structure', () {
    final s = StudyStats(
      todayStudy: 1,
      todayReview: 2,
      totalWords: 3,
      totalVocabulary: 100,
      masteredWords: 1,
      wordbookWords: 2,
      dueReviewCount: 0,
      totalScore: 10,
      level: 4,
    );

    final j = s.toJson();
    expect(j['data'], isA<Map<String, dynamic>>());
    expect((j['data'] as Map<String, dynamic>)['totalWords'], 3);
  });

  test('StudyTrend.fromJson parses date and fallbacks', () {
    final t = StudyTrend.fromJson({
      'date': '2026-04-22',
      'learnedCount': 5,
      'reviewCount': 2,
      'correctRate': 0.8,
    });

    expect(t.date.year, 2026);
    expect(t.learnedCount, 5);
    expect(t.timeSpent, 2);
    expect(t.correctRate, closeTo(0.8, 1e-9));
  });

  test('StudyTrend.toJson outputs ISO date and fields', () {
    final t = StudyTrend(
      date: DateTime.utc(2026, 4, 22),
      studyCount: 1,
      reviewCount: 2,
      correctRate: 0.5,
    );

    final j = t.toJson();
    expect(j['date'], contains('2026-04-22'));
    expect(j['studyCount'], 1);
    expect(j['reviewCount'], 2);
    expect(j['correctRate'], 0.5);
  });

  test('LearningCalendar.fromJson handles missing list', () {
    final c = LearningCalendar.fromJson({
      'code': 200,
      'message': 'ok',
      'data': {'year': 2026, 'month': 4},
    });

    expect(c.year, 2026);
    expect(c.month, 4);
    expect(c.studyDates, isEmpty);
  });

  test('LearningCalendar.toJson keeps year/month/dates', () {
    final c = LearningCalendar(year: 2026, month: 4, studyDates: ['2026-04-22']);
    final j = c.toJson();

    final data = j['data'] as Map<String, dynamic>;
    expect(data['year'], 2026);
    expect(data['month'], 4);
    expect(data['studyDates'], ['2026-04-22']);
  });
}
