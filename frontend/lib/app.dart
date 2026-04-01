import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/challenge/screens/challenge_select_screen.dart';
import 'features/challenge/screens/challenge_result_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/wordbook/screens/wordbook_screen.dart';
import 'features/offline/screens/offline_words_screen.dart';
import 'features/leaderboard/screens/leaderboard_screen.dart';
import 'features/wordbook/screens/wordbook_select_screen.dart';
import 'features/profile/screens/settings_screen.dart';
import 'features/challenge/screens/recent_battles_screen.dart';
import 'features/review/screens/review_screen.dart';
import 'models/challenge_model.dart';

class AppRouter {
  /// 根 Navigator：全屏页（设置、排行榜等）必须挂在这里，否则会压进 Shell 内部导致打不开或行为异常
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  /// Shell 内 Tab 页使用的嵌套 Navigator
  static final GlobalKey<NavigatorState> shellNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'shell');

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login',
    routes: [
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          return MainNavigationScreen(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/challenge',
            name: 'challenge',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ChallengeSelectScreen()),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/challenge-result',
        name: 'challenge-result',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final result = state.extra as ChallengeSubmitResponse;
          return MaterialPage(child: ChallengeResultScreen(result: result));
        },
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            MaterialPage(child: const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            MaterialPage(child: const RegisterScreen()),
      ),
      GoRoute(
        path: '/wordbook',
        name: 'wordbook',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            const MaterialPage(child: WordbookScreen()),
      ),
      GoRoute(
        path: '/offline-words',
        name: 'offline-words',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            const MaterialPage(child: OfflineWordsScreen()),
      ),
      GoRoute(
        path: '/leaderboard',
        name: 'leaderboard',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            const MaterialPage(child: LeaderboardScreen()),
      ),
      GoRoute(
        path: '/wordbook-select',
        name: 'wordbook-select',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            const MaterialPage(child: WordbookSelectScreen()),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            const MaterialPage(child: SettingsScreen()),
      ),
      GoRoute(
        path: '/recent-battles',
        name: 'recent-battles',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            const MaterialPage(child: RecentBattlesScreen()),
      ),
      GoRoute(
        path: '/review',
        name: 'review',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            const MaterialPage(child: ReviewScreen()),
      ),
    ],
  );
}

class MainNavigationScreen extends StatelessWidget {
  final Widget child;

  const MainNavigationScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final idx = _getCurrentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: BottomNavigationBar(
          currentIndex: idx,
          onTap: (index) => _onTap(context, index),
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: const Color(0xFF4D7CFF),
          unselectedItemColor: const Color(0xFF8E9297),
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: Icon(
                Icons.home_outlined,
                color: idx == 0
                    ? const Color(0xFF4D7CFF)
                    : const Color(0xFF8E9297),
              ),
              activeIcon: const Icon(Icons.home, color: Color(0xFF4D7CFF)),
              label: '首页',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.emoji_events_outlined,
                color: idx == 1
                    ? const Color(0xFF4D7CFF)
                    : const Color(0xFF8E9297),
              ),
              activeIcon: const Icon(
                Icons.emoji_events,
                color: Color(0xFF4D7CFF),
              ),
              label: '闯关',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.person_outline,
                color: idx == 2
                    ? const Color(0xFF4D7CFF)
                    : const Color(0xFF8E9297),
              ),
              activeIcon: const Icon(Icons.person, color: Color(0xFF4D7CFF)),
              label: '我的',
            ),
          ],
        ),
      ),
    );
  }

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/challenge')) return 1;
    if (location.startsWith('/profile')) return 2;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/challenge');
        break;
      case 2:
        context.go('/profile');
        break;
    }
  }
}
