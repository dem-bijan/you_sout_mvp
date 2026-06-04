import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youscout_app/core/network/auth_interceptor.dart';
import 'package:flutter/foundation.dart';

/// Central Dio HTTP client.
///
/// All requests go through the API Gateway at [baseUrl].
/// The path must include the `/api` prefix (e.g. `/api/users/login`).
class ApiClient {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080/api';
    } else {
      return 'http://localhost:8080/api';
    }
  }

  late final Dio _dio;

  ApiClient(Ref ref) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.addAll([
      AuthInterceptor(ref),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (o) => debugPrint(o.toString()),
      ),
    ]);
  }

  Dio get dio => _dio;
}

// ignore: avoid_print
void debugPrint(String message) => print(message);

/// Riverpod provider so the singleton is scoped to the app lifetime.
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref));
