import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:youscout_app/core/providers/auth_provider.dart';
import 'package:youscout_app/features/auth/presentation/screens/login_screen.dart';
import 'package:youscout_app/features/auth/presentation/screens/register_screen.dart';
import 'package:youscout_app/features/auth/presentation/screens/splash_screen.dart';
import 'package:youscout_app/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:youscout_app/features/feed/presentation/screens/home_screen.dart';
import 'package:youscout_app/features/upload/presentation/screens/upload_screen.dart';
import 'package:youscout_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:youscout_app/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:youscout_app/features/discover/presentation/screens/discover_screen.dart';
import 'package:youscout_app/shared/widgets/bottom_nav_bar.dart';

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

// ── Tab index helper ─────────────────────────────────────────────────────────

int _tabIndex(String location) {
  if (location.startsWith('/home'))          return 0;
  if (location.startsWith('/discover'))      return 1;
  if (location.startsWith('/notifications')) return 3;
  if (location.startsWith('/profile'))       return 4;
  return 0;
}

// ── Router Provider ──────────────────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  final authListenable = _AuthStateListenable(ref);

  return GoRouter(
    initialLocation: Routes.login,
    refreshListenable: authListenable,
    redirect: (context, state) {
      final authState = ref.read(authProvider);

      final auth = authState.valueOrNull;
      final isAuthenticated = auth is AuthStateAuthenticated;
      final isOnAuthPage = state.matchedLocation == Routes.login ||
          state.matchedLocation == Routes.register ||
          state.matchedLocation == Routes.onboarding;

      if (!isAuthenticated && !isOnAuthPage) return Routes.login;
      if (isAuthenticated && isOnAuthPage) return Routes.home;
      return null;
    },
    routes: [
      // ── Auth routes (no bottom nav) ────────────────────────────────────
      GoRoute(
        path: Routes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.register,
        builder: (_, __) => const RegisterScreen(),
      ),

      // ── Upload (push-only, no bottom nav) ──────────────────────────────
      GoRoute(
        path: Routes.upload,
        builder: (_, __) => const UploadScreen(),
      ),

      // ── Shell route — pages that show the bottom nav bar ───────────────
      ShellRoute(
        builder: (context, state, child) {
          final index = _tabIndex(state.matchedLocation);
          return Scaffold(
            body: child,
            bottomNavigationBar: BottomNavBar(currentIndex: index),
          );
        },
        routes: [
          GoRoute(
            path: Routes.home,
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: Routes.discover,
            builder: (_, __) => const DiscoverScreen(),
          ),
          GoRoute(
            path: Routes.notifications,
            builder: (_, __) => const NotificationsScreen(),
          ),
          GoRoute(
            path: Routes.profile,
            builder: (context, state) {
              final userId = state.pathParameters['userId']!;
              return ProfileScreen(userId: userId);
            },
          ),
        ],
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

// ── Temporary placeholders ───────────────────────────────────────────────────

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
