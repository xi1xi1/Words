import 'package:flutter_test/flutter_test.dart';

import 'package:beileme/models/user_model.dart' as legacy;

void main() {
  group('legacy models inside user_model.dart file', () {
    test('Word/DailyWordsResponse/LearnProgress parsing', () {
      final w = legacy.Word.fromJson({
        'id': 1,
        'word': 'apple',
        'meaning': ['苹果'],
        'phonetic': '/a/',
        'example': ['ex'],
      });
      expect(w.id, 1);
      expect(w.word, 'apple');
      expect(w.meaning, ['苹果']);

      final r = legacy.DailyWordsResponse.fromJson({
        'data': {
          'newWords': [
            {'id': 1, 'word': 'a', 'meaning': ['m'], 'phonetic': null, 'example': []},
          ],
          'reviewWords': [],
        },
      });
      expect(r.newWords.length, 1);
      expect(r.reviewWords, isEmpty);

      final p = legacy.LearnProgress.fromJson({'todayLearned': 2, 'todayTarget': 5});
      expect(p.todayLearned, 2);
      expect(p.todayTarget, 5);
    });

    test('Challenge models parsing and helpers', () {
      final q = legacy.ChallengeQuestion.fromJson({
        'id': 1,
        'word': 'apple',
        'options': ['苹果', '香蕉'],
        'correctIndex': 0,
      });
      expect(q.correctIndex, 0);

      final start = legacy.ChallengeStartResponse.fromJson({
        'data': {
          'challengeId': 'c1',
          'timeLimit': 10,
          'questions': [
            {'id': 1, 'word': 'apple', 'options': ['苹果'], 'correctIndex': 0},
          ],
        },
      });
      expect(start.challengeId, 'c1');
      expect(start.questions.length, 1);

      final ans = legacy.ChallengeAnswer(questionId: 1, selectedIndex: 0, timeSpent: 1);
      expect(ans.toJson()['questionId'], 1);

      final submit = legacy.ChallengeSubmitResponse.fromJson({
        'data': {
          'score': 100,
          'correctCount': 1,
          'totalCount': 1,
          'accuracy': 1.0,
          'addedScore': 10,
          'totalScore': 1000,
        }
      });
      expect(submit.score, 100);

      final record = legacy.BattleRecord.fromJson({
        'id': 1,
        'levelType': 2,
        'score': 10,
        'correctCount': 1,
        'totalCount': 2,
        'duration': 5,
        'createTime': '2026-04-22T00:00:00Z',
      });
      expect(record.levelTypeName, '中级场');
    });

    test('Leaderboard models parsing', () {
      final item = legacy.RankItem.fromJson({
        'rank': 1,
        'userId': 2,
        'username': 'u',
        'avatar': null,
        'totalScore': 10,
      });
      expect(item.rank, 1);

      final lb = legacy.LeaderboardResponse.fromJson({
        'data': {
          'list': [
            {'rank': 1, 'userId': 2, 'username': 'u', 'avatar': null, 'totalScore': 10},
          ],
          'myRank': 3,
        },
      });
      expect(lb.list.length, 1);
      expect(lb.myRank, 3);
    });

    test('Wordbook/AI models parsing', () {
      final w = legacy.WordbookWord.fromJson({
        'id': 1,
        'word': 'apple',
        'meaning': ['苹果'],
        'phonetic': '/a/',
        'aiExamples': ['e1'],
        'aiDialogues': ['d1'],
        'addedAt': '2026-04-22T00:00:00Z',
      });
      expect(w.aiExamples, ['e1']);

      final ai = legacy.AIContentResponse.fromJson({
        'data': {
          'examples': ['ex'],
          'dialogues': ['dg'],
        },
      });
      expect(ai.examples, ['ex']);
      expect(ai.dialogues, ['dg']);
    });

    test('Study models parsing and masteredRate', () {
      final s = legacy.StudyStats.fromJson({
        'data': {
          'todayStudy': 1,
          'todayReview': 2,
          'totalWords': 10,
          'masteredWords': 5,
          'wordbookWords': 0,
          'dueReviewCount': 0,
          'totalScore': 10,
          'level': 1,
        },
      });
      expect(s.masteredRate, closeTo(0.5, 1e-9));

      final t = legacy.StudyTrend.fromJson({
        'date': '2026-04-22T00:00:00Z',
        'studyCount': 1,
        'reviewCount': 2,
        'correctRate': 0.8,
      });
      expect(t.correctRate, closeTo(0.8, 1e-9));

      final day = legacy.CalendarDay.fromJson({
        'date': '2026-04-22T00:00:00Z',
        'studyCount': 1,
        'intensity': 2,
      });
      expect(day.intensity, 2);

      final cal = legacy.LearningCalendar.fromJson({
        'data': {
          'year': 2026,
          'month': 4,
          'days': [
            {'date': '2026-04-22T00:00:00Z', 'studyCount': 1, 'intensity': 2},
          ],
        },
      });
      expect(cal.days.length, 1);
    });
  });
}
