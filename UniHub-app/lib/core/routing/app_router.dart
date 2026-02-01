import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/community/presentation/community_screen.dart';
import '../../features/community/presentation/community_search_screen.dart';
import '../../features/feed/presentation/campus_feed_screen.dart';
import '../../features/feed/presentation/feed_search_screen.dart';
import '../../features/marketplace/presentation/marketplace_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../widgets/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authRefreshNotifier = ref.watch(authRefreshNotifierProvider);

  return GoRouter(
    initialLocation: '/campus',
    refreshListenable: authRefreshNotifier,
    redirect: (context, state) {
      final isLoggedIn = authRefreshNotifier.session != null;
      final isLoginRoute = state.uri.path == '/login';

      if (!isLoggedIn && !isLoginRoute) {
        return '/login';
      }
      if (isLoggedIn && isLoginRoute) {
        return '/campus';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/campus/search',
        builder: (context, state) => const FeedSearchScreen(),
      ),
      GoRoute(
        path: '/community/search',
        builder: (context, state) => const CommunitySearchScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/campus',
            builder: (context, state) => const CampusFeedScreen(),
          ),
          GoRoute(
            path: '/community',
            builder: (context, state) => const CommunityScreen(),
          ),
          GoRoute(
            path: '/marketplace',
            builder: (context, state) => const MarketplaceScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});
