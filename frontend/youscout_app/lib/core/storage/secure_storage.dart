import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps flutter_secure_storage for JWT token persistence.
/// DEMO FIX: Uses in-memory storage to prevent Android Emulator Keystore deadlocks.
class SecureStorage {
  SecureStorage._();

  static final Map<String, String> _memoryStorage = {};

  static const _keyAccessToken  = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyUserId       = 'user_id';

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) async {
    _memoryStorage[_keyAccessToken] = accessToken;
    _memoryStorage[_keyRefreshToken] = refreshToken;
    _memoryStorage[_keyUserId] = userId;
  }

  static Future<String?> getAccessToken() async => _memoryStorage[_keyAccessToken];
  static Future<String?> getRefreshToken() async => _memoryStorage[_keyRefreshToken];
  static Future<String?> getUserId() async => _memoryStorage[_keyUserId];

  static Future<void> clear() async => _memoryStorage.clear();
}

