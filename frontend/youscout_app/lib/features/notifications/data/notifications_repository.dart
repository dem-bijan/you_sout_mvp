import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import 'models/notification_model.dart';

class NotificationsRepository {
  final Dio _dio;
  NotificationsRepository(this._dio);

  Future<List<NotificationModel>> getNotifications(
      {int page = 0, int size = 20}) async {
    final response = await _dio.get(
      ApiEndpoints.notifications,
      queryParameters: {'page': page, 'size': size},
    );
    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    final content = data['content'] as List<dynamic>;
    return content
        .map((n) => NotificationModel.fromJson(n as Map<String, dynamic>))
        .toList();
  }

  Future<int> getUnreadCount() async {
    final response = await _dio.get(ApiEndpoints.unreadCount);
    final body = response.data as Map<String, dynamic>;
    return (body['data']?['count'] as num?)?.toInt() ?? 0;
  }

  Future<void> markAllRead() =>
      _dio.post(ApiEndpoints.markAllRead);

  Future<void> markRead(List<String> ids) =>
      _dio.post(ApiEndpoints.markRead, data: {'ids': ids});
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(ref.watch(apiClientProvider).dio),
);
