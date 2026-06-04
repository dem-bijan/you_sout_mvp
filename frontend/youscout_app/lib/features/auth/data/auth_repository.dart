import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youscout_app/core/network/api_client.dart';
import 'package:youscout_app/core/network/api_endpoints.dart';
import 'package:youscout_app/core/providers/auth_provider.dart';
import 'package:youscout_app/features/auth/data/models/user_model.dart';

/// Result type so callers don't need to catch exceptions directly.
sealed class AuthResult<T> {
  const AuthResult();
}

final class AuthSuccess<T> extends AuthResult<T> {
  final T data;
  const AuthSuccess(this.data);
}

final class AuthFailure<T> extends AuthResult<T> {
  final String message;
  const AuthFailure(this.message);
}

// ── Repository ───────────────────────────────────────────────────────────────

class AuthRepository {
  final Dio _dio;
  final AuthNotifier _authNotifier;

  AuthRepository(this._dio, this._authNotifier);

  Future<AuthResult<UserModel>> register({
    required String username,
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.register,
        data: {
          'username': username,
          'email': email,
          'password': password,
          'displayName': displayName,
        },
      );
      return _handleAuthResponse(response);
    } on DioException catch (e) {
      return AuthFailure(_extractMessage(e));
    }
  }

  Future<AuthResult<UserModel>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );
      return _handleAuthResponse(response);
    } on DioException catch (e) {
      return AuthFailure(_extractMessage(e));
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } catch (_) {
      // Best-effort — always clear locally
    }
    await _authNotifier.onLogout();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  AuthResult<UserModel> _handleAuthResponse(Response response) {
    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;

    final accessToken  = data['accessToken']  as String;
    final refreshToken = data['refreshToken'] as String;
    final userJson     = data['user']         as Map<String, dynamic>;
    final user         = UserModel.fromJson(userJson);

    // Persist tokens and update auth state
    _authNotifier.onLogin(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: user.id,
    );

    return AuthSuccess(user);
  }

  String _extractMessage(DioException e) {
    try {
      final data = e.response?.data as Map<String, dynamic>?;
      return (data?['message'] as String?) ?? 'Something went wrong';
    } catch (_) {
      return 'Network error — please check your connection';
    }
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio          = ref.watch(apiClientProvider).dio;
  final authNotifier = ref.read(authProvider.notifier);
  return AuthRepository(dio, authNotifier);
});
