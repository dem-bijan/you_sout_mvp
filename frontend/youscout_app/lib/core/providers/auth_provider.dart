import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage.dart';

/// Represents the authentication state of the app.
sealed class AuthState {
  const AuthState();
}

/// Tokens haven't been checked yet (app cold-start).
final class AuthStateLoading extends AuthState {
  const AuthStateLoading();
}

/// User is authenticated with a valid token.
final class AuthStateAuthenticated extends AuthState {
  final String userId;
  const AuthStateAuthenticated(this.userId);
}

/// No valid token found — user must log in.
final class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated();
}

// ── Notifier ────────────────────────────────────────────────────────────────

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    return _checkStoredTokens();
  }

  Future<AuthState> _checkStoredTokens() async {
    final userId = await SecureStorage.getUserId();
    final token  = await SecureStorage.getAccessToken();
    if (userId != null && token != null) {
      return AuthStateAuthenticated(userId);
    }
    return const AuthStateUnauthenticated();
  }

  /// Call after a successful login / register response.
  Future<void> onLogin({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) async {
    await SecureStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
    );
    state = AsyncData(AuthStateAuthenticated(userId));
  }

  /// Call on logout or when the refresh cycle fails.
  Future<void> onLogout() async {
    await SecureStorage.clear();
    state = const AsyncData(AuthStateUnauthenticated());
  }
}

// ── Provider ────────────────────────────────────────────────────────────────

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
