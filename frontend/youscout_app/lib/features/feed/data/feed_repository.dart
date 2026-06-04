import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youscout_app/core/network/api_client.dart';
import 'package:youscout_app/core/network/api_endpoints.dart';
import 'package:youscout_app/features/feed/data/models/video_model.dart';

class FeedRepository {
  final Dio _dio;

  FeedRepository(this._dio);

  /// Fetches the authenticated user's personal feed from Redis.
  Future<List<VideoModel>> getPersonalFeed({int page = 0, int size = 10}) =>
      _fetchTrendingVideos(page: page, size: size);

  /// Fetches the public explore / trending feed.
  /// DEMO FIX: Uses /videos/trending instead of /feed/explore because the
  /// Redis feed cache stores flat metadata that doesn't match VideoModel's
  /// expected JSON shape. The trending endpoint returns properly shaped
  /// VideoDTO objects directly from Postgres.
  Future<List<VideoModel>> getExploreFeed({int page = 0, int size = 10}) =>
      _fetchTrendingVideos(page: page, size: size);

  Future<List<VideoModel>> _fetchTrendingVideos({
    required int page,
    required int size,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.trendingVideos,
      queryParameters: {'page': page, 'size': size},
    );
    final body    = response.data as Map<String, dynamic>;
    final data    = body['data'] as Map<String, dynamic>;
    final content = data['content'] as List<dynamic>;

    return content
        .map((v) => VideoModel.fromJson(v as Map<String, dynamic>))
        .toList();
  }

  /// Like a video — returns the new likes count from the server.
  Future<int> likeVideo(String videoId) async {
    final response = await _dio.post(ApiEndpoints.likeVideo(videoId));
    final body = response.data as Map<String, dynamic>;
    return (body['data']?['likesCount'] as num?)?.toInt() ?? 0;
  }

  /// Unlike a video.
  Future<int> unlikeVideo(String videoId) async {
    final response = await _dio.delete(ApiEndpoints.likeVideo(videoId));
    final body = response.data as Map<String, dynamic>;
    return (body['data']?['likesCount'] as num?)?.toInt() ?? 0;
  }

  /// Fire-and-forget view impression.
  Future<void> recordView(String videoId) async {
    try {
      await _dio.post(ApiEndpoints.viewVideo(videoId));
    } catch (_) {
      // Best-effort — don't surface view errors to user
    }
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final feedRepositoryProvider = Provider<FeedRepository>(
  (ref) => FeedRepository(ref.watch(apiClientProvider).dio),
);
