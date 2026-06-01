import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../feed/data/models/video_model.dart';

class UploadRepository {
  final Dio _dio;

  UploadRepository(this._dio);

  /// Fetches the list of available skill tags from the backend.
  Future<List<SkillModel>> fetchSkills() async {
    final response = await _dio.get(ApiEndpoints.skills);
    final body = response.data as Map<String, dynamic>;
    final list = body['data'] as List<dynamic>;
    return list
        .map((s) => SkillModel.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  /// Uploads a video file with metadata.
  ///
  /// [onProgress] receives a 0–1 fraction as bytes are sent.
  Future<VideoModel> uploadVideo({
    required File file,
    required String description,
    required List<String> skillIds,
    required List<String> hashtags,
    void Function(double progress)? onProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      ),
      'description': description,
      'skillIds': skillIds.isEmpty ? '[]' : '[${skillIds.map((id) => '"$id"').join(',')}]',
      'hashtags': hashtags.join(','),
    });

    final response = await _dio.post(
      ApiEndpoints.uploadVideo,
      data: formData,
      onSendProgress: (sent, total) {
        if (total > 0 && onProgress != null) {
          onProgress(sent / total);
        }
      },
    );

    final body = response.data as Map<String, dynamic>;
    return VideoModel.fromJson(body['data'] as Map<String, dynamic>);
  }
}

final uploadRepositoryProvider = Provider<UploadRepository>(
  (ref) => UploadRepository(ref.watch(apiClientProvider).dio),
);
