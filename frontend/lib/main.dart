import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/network/api_client.dart';
import 'core/providers/settings_provider.dart';
import 'core/providers/user_provider.dart';
import 'core/providers/wordbook_provider.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final UserProvider _userProvider;
  late final WordbookProvider _wordbookProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _userProvider = UserProvider();
    _wordbookProvider = WordbookProvider()..load();
    _router = AppRouter.createRouter(_userProvider);

    ApiClient.onUnauthorized = () async {
      await _userProvider.clearAuth();
    };
  }

  @override
  void dispose() {
    if (ApiClient.onUnauthorized != null) {
      ApiClient.onUnauthorized = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(),
        ),
        ChangeNotifierProvider<UserProvider>.value(value: _userProvider),
        ChangeNotifierProvider<WordbookProvider>.value(
          value: _wordbookProvider,
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return MaterialApp.router(
            title: '背了么',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settingsProvider.themeMode,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
