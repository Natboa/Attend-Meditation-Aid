import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/views/home_screen.dart';
import '../../features/onboarding/views/onboarding_screen.dart';
import '../../features/timer/views/timer_screen.dart';
import '../../features/timer/views/session_history_screen.dart';
import '../../features/timer/views/manage_timers_screen.dart';
import '../../features/gathas/views/gatha_library_screen.dart';
import '../../features/gathas/views/gatha_detail_screen.dart';
import '../../features/notifications/views/notification_settings_screen.dart';
import '../../features/settings/views/settings_screen.dart';
import '../providers/repositories.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final settings = ref.read(settingsRepositoryProvider);
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: settings.hasSeenOnboarding ? '/home' : '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => _AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/timer',
            name: 'timer',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TimerScreen(),
            ),
            routes: [
              GoRoute(
                path: 'history',
                name: 'session-history',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const SessionHistoryScreen(),
              ),
              GoRoute(
                path: 'manage',
                name: 'manage-timers',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const ManageTimersScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/library',
            name: 'library',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: GathaLibraryScreen(),
            ),
            routes: [
              GoRoute(
                path: ':id',
                name: 'gatha-detail',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => GathaDetailScreen(
                  gathaId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
            routes: [
              GoRoute(
                path: 'notifications',
                name: 'notification-settings',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const NotificationSettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _AppShell extends StatelessWidget {
  const _AppShell({required this.child});

  final Widget child;

  static const _tabs = ['/home', '/timer', '/library', '/settings'];

  int _indexForLocation(String location) {
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _indexForLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => context.go(_tabs[i]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer),
            label: 'Timer',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
