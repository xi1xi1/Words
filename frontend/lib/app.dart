import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/providers/user_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/home/screens/word_detail_screen.dart';
import 'features/challenge/screens/challenge_select_screen.dart';
import 'features/challenge/screens/challenge_result_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/wordbook/screens/wordbook_screen.dart';
import 'features/leaderboard/screens/leaderboard_screen.dart';
import 'features/profile/screens/settings_screen.dart';
import 'features/challenge/screens/recent_battles_screen.dart';
import 'features/review/screens/review_screen.dart';
import 'features/study/screens/study_screen.dart';
import 'features/challenge/screens/challenge_game_screen.dart';
import 'models/challenge_model.dart';
import 'models/word_model.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  static final GlobalKey<NavigatorState> shellNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'shell');

  static GoRouter createRouter(UserProvider userProvider) {
    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/login',
      refreshListenable: userProvider,
      redirect: (context, state) {
        if (!userProvider.isInitialized) {
          return state.matchedLocation == '/login' ? null : '/login';
        }

        final location = state.matchedLocation;
        final isAuthRoute = location == '/login' || location == '/register';
        final isLoggedIn = userProvider.isLoggedIn;

        if (!isLoggedIn && !isAuthRoute) {
          return '/login';
        }

        if (isLoggedIn && isAuthRoute) {
          return '/';
        }

        return null;
      },
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
          path: '/challenge-game',
          name: 'challenge-game',
          parentNavigatorKey: rootNavigatorKey,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return MaterialPage(
              child: ChallengeGameScreen(
                challengeId: extra['challengeId'] as String,
                questions: extra['questions'] as List<ChallengeQuestion>,
                timeLimit: extra['timeLimit'] as int,
                levelType: extra['levelType'] as int,
                levelName: extra['levelName'] as String,
                accentColor: extra['accentColor'] as Color,
              ),
            );
          },
        ),
        GoRoute(
          path: '/challenge-result',
          name: 'challenge-result',
          parentNavigatorKey: rootNavigatorKey,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return MaterialPage(
              child: ChallengeResultScreen(
                result: extra['result'] as ChallengeSubmitResponse,
                levelType: extra['levelType'] as int,
                levelName: extra['levelName'] as String,
                accentColor: extra['accentColor'] as Color,
              ),
            );
          },
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          parentNavigatorKey: rootNavigatorKey,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return MaterialPage(
              child: LoginScreen(
                initialUsername: extra?['username'] as String?,
                initialPassword: extra?['password'] as String?,
              ),
            );
          },
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          parentNavigatorKey: rootNavigatorKey,
          pageBuilder: (context, state) =>
              MaterialPage(child: const RegisterScreen()),
        ),
        GoRoute(
          path: '/word-detail',
          name: 'word-detail',
          parentNavigatorKey: rootNavigatorKey,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return MaterialPage(
              child: WordDetailScreen(
                wordId: extra['wordId'] as int,
                previewWord: extra['word'] as Word?,
              ),
            );
          },
        ),
        GoRoute(
          path: '/wordbook',
          name: 'wordbook',
          parentNavigatorKey: rootNavigatorKey,
          pageBuilder: (context, state) =>
              const MaterialPage(child: WordbookScreen()),
        ),
        GoRoute(
          path: '/leaderboard',
          name: 'leaderboard',
          parentNavigatorKey: rootNavigatorKey,
          pageBuilder: (context, state) =>
              const MaterialPage(child: LeaderboardScreen()),
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
        GoRoute(
          path: '/study',
          name: 'study',
          parentNavigatorKey: rootNavigatorKey,
          pageBuilder: (context, state) =>
              const MaterialPage(child: StudyScreen()),
        ),
      ],
    );
  }
}

class MainNavigationScreen extends StatelessWidget {
  final Widget child;

  const MainNavigationScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final idx = _getCurrentIndex(context);
    final navTheme = Theme.of(context).bottomNavigationBarTheme;
    final selectedColor =
        navTheme.selectedItemColor ?? Theme.of(context).colorScheme.primary;
    final unselectedColor =
        navTheme.unselectedItemColor ?? Theme.of(context).hintColor;
    final navBackground =
        navTheme.backgroundColor ?? Theme.of(context).colorScheme.surface;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: navBackground),
        child: BottomNavigationBar(
          currentIndex: idx,
          onTap: (index) => _onTap(context, index),
          backgroundColor: navBackground,
          elevation: navTheme.elevation ?? 0,
          selectedItemColor: selectedColor,
          unselectedItemColor: unselectedColor,
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
                color: idx == 0 ? selectedColor : unselectedColor,
              ),
              activeIcon: Icon(Icons.home, color: selectedColor),
              label: '首页',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.emoji_events_outlined,
                color: idx == 1 ? selectedColor : unselectedColor,
              ),
              activeIcon: Icon(
                Icons.emoji_events,
                color: selectedColor,
              ),
              label: '闯关',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.person_outline,
                color: idx == 2 ? selectedColor : unselectedColor,
              ),
              activeIcon: Icon(Icons.person, color: selectedColor),
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
