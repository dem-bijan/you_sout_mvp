import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

// ── Route names (use these everywhere instead of bare strings) ───────────────

abstract final class Routes {
  static const splash        = '/';
  static const onboarding    = '/onboarding';
  static const login         = '/login';
  static const register      = '/register';
  static const home          = '/home';
  static const profile       = '/profile/:userId';
  static const upload        = '/upload';
  static const notifications = '/notifications';
  static const discover      = '/discover';

  static String profilePath(String userId) => '/profile/$userId';
}

// ── Router Provider ──────────────────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  // Listen to auth changes so GoRouter auto-redirects
  final authListenable = _AuthStateListenable(ref);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: authListenable,
    redirect: (context, state) {
      final authState = ref.read(authProvider);

      // Still loading — show splash, don't redirect yet
      if (authState is AsyncLoading) {
        return Routes.splash;
      }

      final auth = authState.valueOrNull;
      final isAuthenticated = auth is AuthStateAuthenticated;
      final isOnAuthPage = state.matchedLocation == Routes.login ||
          state.matchedLocation == Routes.register ||
          state.matchedLocation == Routes.onboarding ||
          state.matchedLocation == Routes.splash;

      // Not logged in and trying to access protected page → login
      if (!isAuthenticated && !isOnAuthPage) {
        return Routes.login;
      }

      // Logged in and on auth page → go to feed
      if (isAuthenticated && isOnAuthPage) {
        return Routes.home;
      }

      return null; // no redirect
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (_, __) => const _SplashPlaceholder(),
      ),
      GoRoute(
        path: Routes.onboarding,
        builder: (_, __) => const _Placeholder('Onboarding'),
      ),
      GoRoute(
        path: Routes.login,
        builder: (_, __) => const _Placeholder('Login'),
      ),
      GoRoute(
        path: Routes.register,
        builder: (_, __) => const _Placeholder('Register'),
      ),
      GoRoute(
        path: Routes.home,
        builder: (_, __) => const _Placeholder('Feed'),
      ),
      GoRoute(
        path: Routes.profile,
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return _Placeholder('Profile: $userId');
        },
      ),
      GoRoute(
        path: Routes.upload,
        builder: (_, __) => const _Placeholder('Upload'),
      ),
      GoRoute(
        path: Routes.notifications,
        builder: (_, __) => const _Placeholder('Notifications'),
      ),
      GoRoute(
        path: Routes.discover,
        builder: (_, __) => const _Placeholder('Discover'),
      ),
    ],
  );
});

// ── Listenable that bridges Riverpod → GoRouter ──────────────────────────────

class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}

// ── Temporary placeholders (replaced as real screens are built) ──────────────

class _SplashPlaceholder extends StatelessWidget {
  const _SplashPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'YouScout',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Color(0xFF00D4FF),
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String name;
  const _Placeholder(this.name);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: Center(child: Text(name)),
    );
  }
}
