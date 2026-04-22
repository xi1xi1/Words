import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:beileme/widgets/word_card.dart';

void main() {
  testWidgets('WordCard renders word, phonetic, meaning', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WordCard(
            word: 'apple',
            phonetic: '/a/',
            meaning: '苹果',
          ),
        ),
      ),
    );

    expect(find.text('apple'), findsOneWidget);
    expect(find.text('/a/'), findsOneWidget);
    expect(find.text('苹果'), findsOneWidget);
  });

  testWidgets('WordCard shows example when provided', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WordCard(
            word: 'apple',
            phonetic: '/a/',
            meaning: '苹果',
            example: 'Example sentence',
          ),
        ),
      ),
    );

    expect(find.text('Example sentence'), findsOneWidget);
  });
}
