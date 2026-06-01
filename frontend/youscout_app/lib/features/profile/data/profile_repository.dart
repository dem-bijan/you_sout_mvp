import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../feed/data/models/video_model.dart';

class ProfileRepository {
  final Dio _dio;

  ProfileRepository(this._dio);

  Future<UserModel> getUserById(String userId) async {
    final response = await _dio.get(ApiEndpoints.userById(userId));
    final body = response.data as Map<String, dynamic>;
    return UserModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<List<VideoModel>> getUserVideos(String userId,
      {int page = 0, int size = 12}) async {
    final response = await _dio.get(
      ApiEndpoints.videosByUser(userId),
      queryParameters: {'page': page, 'size': size},
    );
    final body    = response.data as Map<String, dynamic>;
    final data    = body['data'] as Map<String, dynamic>;
    final content = data['content'] as List<dynamic>;
    return content
        .map((v) => VideoModel.fromJson(v as Map<String, dynamic>))
        .toList();
  }

  Future<bool> isFollowing(String targetId) async {
    final response =
        await _dio.get(ApiEndpoints.isFollowing(targetId));
    final body = response.data as Map<String, dynamic>;
    return (body['data']?['isFollowing'] as bool?) ?? false;
  }

  Future<void> follow(String targetId) =>
      _dio.post(ApiEndpoints.follow(targetId));

  Future<void> unfollow(String targetId) =>
      _dio.delete(ApiEndpoints.follow(targetId));

  Future<UserModel> updateProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    final response = await _dio.put(
      ApiEndpoints.updateProfile,
      data: {
        if (displayName != null) 'displayName': displayName,
        if (bio != null) 'bio': bio,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      },
    );
    final body = response.data as Map<String, dynamic>;
    return UserModel.fromJson(body['data'] as Map<String, dynamic>);
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(apiClientProvider).dio),
);
