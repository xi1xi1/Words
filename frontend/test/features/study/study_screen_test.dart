import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:beileme/core/network/api_exception.dart';
import 'package:beileme/features/study/screens/study_screen.dart';
import 'package:beileme/models/word_model.dart' as app_models;
import 'package:beileme/services/word_service.dart';

class FakeWordService extends WordService {
  FakeWordService({
    required this.dailyWordsQueue,
    required this.submitResponses,
    this.throwOnDaily = false,
  });

  final List<app_models.DailyWordsResponse> dailyWordsQueue;
  final List<({app_models.Word? nextWord, app_models.LearnProgress progress})> submitResponses;
  final bool throwOnDaily;

  int _dailyCall = 0;
  int _submitCall = 0;

  @override
  Future<app_models.DailyWordsResponse> getDailyWords() async {
    if (throwOnDaily) throw ApiException(code: 500, message: 'error');
    final idx = (_dailyCall).clamp(0, dailyWordsQueue.length - 1);
    _dailyCall++;
    return dailyWordsQueue[idx];
  }

  @override
  Future<({app_models.Word? nextWord, app_models.LearnProgress progress})> submitLearnResult({
    required int wordId,
    required bool isCorrect,
    required int stage,
  }) async {
    final idx = (_submitCall).clamp(0, submitResponses.length - 1);
    _submitCall++;
    return submitResponses[idx];
  }
}

app_models.Word makeWord({
  required int id,
  required String word,
  int stage = 1,
  List<String>? meaning,
  List<String>? options,
  List<String>? example,
}) {
  return app_models.Word(
    id: id,
    word: word,
    phonetic: '/p/',
    meaning: meaning ?? const ['含义1', '含义2'],
    options: options,
    stage: stage,
    example: example ?? const ['Example with word', '中文例句'],
  );
}

app_models.DailyWordsResponse dailyWith(app_models.Word w) {
  return app_models.DailyWordsResponse(
    newWords: [w],
    reviewWords: const [],
    total: 1,
    learnableWordCount: 1,
    reviewableWordCount: 0,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('StudyScreen stage1: selecting correct option shows check icon', (tester) async {
    final w = makeWord(
      id: 1,
      word: 'apple',
      stage: 1,
      meaning: const ['正确释义', '干扰1', '干扰2', '干扰3'],
      options: const ['正确释义', '干扰1', '干扰2', '干扰3'],
    );

    final fake = FakeWordService(
      dailyWordsQueue: [dailyWith(w)],
      submitResponses: [
        (
          nextWord: makeWord(id: 2, word: 'next', stage: 2),
          progress: app_models.LearnProgress(completedCount: 0, totalCount: 1),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: StudyScreen(wordService: fake),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('步骤 1/3 - 选择释义'), findsOneWidget);

    expect(find.text('正确释义'), findsOneWidget);

    await tester.tap(find.text('正确释义'));
    await tester.pump();

    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    // Flush the delayed timer inside _submitAnswer.
    await tester.pump(const Duration(milliseconds: 250));
  });

  testWidgets('StudyScreen stage2: tapping 认识 moves to stage prepared by nextWord', (tester) async {
    final wStage2 = makeWord(id: 1, word: 'apple', stage: 2);

    final fake = FakeWordService(
      dailyWordsQueue: [dailyWith(wStage2)],
      submitResponses: [
        (
          nextWord: makeWord(id: 2, word: 'next', stage: 3),
          progress: app_models.LearnProgress(completedCount: 0, totalCount: 1),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp(home: StudyScreen(wordService: fake)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('步骤 2/3 - 看例句'), findsOneWidget);

    await tester.tap(find.text('认识'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('步骤 3/3 - 认词'), findsOneWidget);
  });

  testWidgets('StudyScreen stage3: tapping 认识 triggers completion dialog when batch complete', (tester) async {
    final wStage3 = makeWord(id: 1, word: 'apple', stage: 3);

    final fake = FakeWordService(
      dailyWordsQueue: [dailyWith(wStage3)],
      submitResponses: [
        (
          nextWord: null,
          progress: app_models.LearnProgress(completedCount: 1, totalCount: 1),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp(home: StudyScreen(wordService: fake)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('步骤 3/3 - 认词'), findsOneWidget);

    await tester.tap(find.text('认识'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('本轮学习完成'), findsOneWidget);
    expect(find.textContaining('本轮已完成'), findsOneWidget);
  });
}
