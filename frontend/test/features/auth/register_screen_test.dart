import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:beileme/core/constants/api_constants.dart';
import 'package:beileme/core/network/api_client.dart';
import 'package:beileme/core/providers/user_provider.dart';
import 'package:beileme/features/auth/screens/register_screen.dart';

import '../../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() {
    ApiClient.debugHttpClient = null;
  });

  testWidgets('RegisterScreen validates form', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UserProvider(),
        child: const MaterialApp(home: RegisterScreen()),
      ),
    );

    await tester.ensureVisible(find.text('立即注册'));
    await tester.tap(find.text('立即注册'));
    await tester.pump();

    expect(find.text('请输入用户名'), findsWidgets);
    expect(find.text('请输入邮箱'), findsWidgets);
    expect(find.text('请输入密码'), findsWidgets);
    expect(find.text('请确认密码'), findsWidgets);
  });

  testWidgets('RegisterScreen success navigates to login with extra', (tester) async {
    final observed = <String>[];

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            observed.add('login:${extra?['username']}:${extra?['password']}');
            return const Scaffold(body: Text('LOGIN'));
          },
        ),
      ],
      initialLocation: '/register',
    );

    final reqRouter = TestRequestRouter();
    reqRouter.on('POST', '${ApiConstants.baseUrl}${ApiConstants.authRegister}', (req) async {
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
    await tester.enterText(find.byType(TextFormField).at(1), 'user@test.com');
    await tester.enterText(find.byType(TextFormField).at(2), '123456');
    await tester.enterText(find.byType(TextFormField).at(3), '123456');

    await tester.ensureVisible(find.text('立即注册'));
    await tester.tap(find.text('立即注册'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(observed.any((e) => e.startsWith('login:user:123456')), isTrue);
  });
}
