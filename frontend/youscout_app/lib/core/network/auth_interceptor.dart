import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youscout_app/core/storage/secure_storage.dart';

/// Intercepts every request to attach the Bearer token,
/// and retries once on 401 after attempting a token refresh.
class AuthInterceptor extends Interceptor {
  final Ref _ref;

  AuthInterceptor(this._ref);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await SecureStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Attempt silent refresh
      try {
        final refreshToken = await SecureStorage.getRefreshToken();
        if (refreshToken != null) {
          // Use a fresh Dio instance to avoid recursive interception
          final freshDio = Dio(BaseOptions(
            baseUrl: err.requestOptions.baseUrl,
            connectTimeout: const Duration(seconds: 10),
          ));
          final response = await freshDio.post(
            '/api/users/refresh',
            data: {'refreshToken': refreshToken},
          );

          final newAccessToken =
              response.data['data']['accessToken'] as String?;
          final newRefreshToken =
              response.data['data']['refreshToken'] as String?;
          final userId =
              response.data['data']['user']?['id'] as String?;

          if (newAccessToken != null && newRefreshToken != null && userId != null) {
            await SecureStorage.saveTokens(
              accessToken: newAccessToken,
              refreshToken: newRefreshToken,
              userId: userId,
            );

            // Retry the original request with the new token
            final opts = err.requestOptions;
            opts.headers['Authorization'] = 'Bearer $newAccessToken';
            final retryResponse = await freshDio.fetch(opts);
            handler.resolve(retryResponse);
            return;
          }
        }
      } catch (_) {
        // Refresh failed — fall through to logout below
      }

      // Clear stored tokens; the router redirect will send user to login
      await SecureStorage.clear();
    }
    handler.next(err);
  }
}
