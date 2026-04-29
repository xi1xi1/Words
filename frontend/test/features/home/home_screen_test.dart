import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:beileme/core/constants/api_constants.dart';
import 'package:beileme/core/network/api_client.dart';
import 'package:beileme/core/providers/wordbook_provider.dart';
import 'package:beileme/features/home/screens/home_screen.dart';

import '../../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() {
    ApiClient.debugHttpClient = null;
  });

  testWidgets('HomeScreen shows loading then featured word on success', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/word-detail',
          builder: (context, state) => const Scaffold(body: Text('DETAIL')),
        ),
      ],
      initialLocation: '/',
    );

    final reqRouter = TestRequestRouter();
    reqRouter.on('GET', '${ApiConstants.baseUrl}${ApiConstants.wordsDaily}', (req) async {
      return jsonResponse(200, {
        'code': 200,
        'message': 'success',
        'data': {
          'newWords': [
            {
              'id': 1,
              'word': 'apple',
              'phonetic': '/a/',
              'meaning': ['苹果'],
              'example': ['I eat an apple.', '我吃了一个苹果。'],
            }
          ],
          'reviewWords': [],
          'learnableWordCount': 1,
          'reviewableWordCount': 0,
        }
      });
    });

    ApiClient.debugHttpClient = MockClient(reqRouter.handle);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => WordbookProvider()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('apple'), findsOneWidget);
    expect(find.text('查看详情 >'), findsOneWidget);
  });

  testWidgets('HomeScreen shows placeholder word on API error', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      ],
      initialLocation: '/',
    );

    final reqRouter = TestRequestRouter();
    reqRouter.on('GET', '${ApiConstants.baseUrl}${ApiConstants.wordsDaily}', (req) async {
      // business code error -> ApiClient throws -> HomeScreen falls back to placeholder.
      return jsonResponse(200, {
        'code': 500,
        'message': 'error',
        'data': null,
      });
    });

    ApiClient.debugHttpClient = MockClient(reqRouter.handle);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => WordbookProvider()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('serendipity'), findsOneWidget);
  });

  testWidgets('HomeScreen toggles wordbook for placeholder word shows snackbar', (tester) async {
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (context, state) => const HomeScreen())],
      initialLocation: '/',
    );

    final reqRouter = TestRequestRouter();
    reqRouter.on('GET', '${ApiConstants.baseUrl}${ApiConstants.wordsDaily}', (req) async {
      return jsonResponse(200, {
        'code': 500,
        'message': 'error',
        'data': null,
      });
    });

    ApiClient.debugHttpClient = MockClient(reqRouter.handle);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => WordbookProvider()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Placeholder card shows '+ 生词本'
    await tester.tap(find.text('+ 生词本'));
    await tester.pump();

    expect(find.text('当前是演示单词，暂不支持加入生词本'), findsOneWidget);
  });
}
