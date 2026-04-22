import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:beileme/widgets/custom_button.dart';

void main() {
  testWidgets('CustomButton shows loading and disables tap', (tester) async {
    var tapped = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(
            text: '提交',
            isLoading: true,
            onPressed: () => tapped++,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    expect(tapped, 0);
  });

  testWidgets('CustomButton calls onPressed when not loading', (tester) async {
    var tapped = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(
            text: '提交',
            onPressed: () => tapped++,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    expect(tapped, 1);
  });
}
