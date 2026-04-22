import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:beileme/core/constants/api_constants.dart';
import 'package:beileme/core/network/api_client.dart';
import 'package:beileme/core/providers/user_provider.dart';
import 'package:beileme/features/auth/screens/login_screen.dart';

import '../../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() {
    ApiClient.debugHttpClient = null;
    ApiClient.onUnauthorized = null;
  });

  testWidgets('LoginScreen validates form and shows error messages', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UserProvider(),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.tap(find.text('立即登录'));
    await tester.pump();

    expect(find.text('请输入用户名'), findsOneWidget);
    expect(find.text('请输入密码'), findsOneWidget);
  });

  testWidgets('LoginScreen login success navigates to /', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('HOME')),
        ),
      ],
      initialLocation: '/login',
    );

    final reqRouter = TestRequestRouter();
    reqRouter.on('POST', '${ApiConstants.baseUrl}${ApiConstants.authLogin}', (req) async {
      return jsonResponse(200, {
        'code': 200,
        'message': 'success',
        'data': {
          'token': 't',
          'userInfo': {
            'id': 1,
            'username': 'u',
            'avatar': null,
            'totalScore': 0,
            'level': 1,
          }
        }
      });
    });

    ApiClient.debugHttpClient = MockClient(reqRouter.handle);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'user');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.text('立即登录'));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('HOME'), findsOneWidget);
  });
}
