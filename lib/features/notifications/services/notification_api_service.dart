import 'package:dio/dio.dart';

import '../model/notification_dto.dart';

/// API service for notification endpoints.
class NotificationApiService {
  final Dio _dio;

  NotificationApiService(this._dio);

  /// GET /notifications?since={ISO} — returns list of notifications.
  /// If [since] is provided, only returns notifications created after that time.
  Future<List<NotificationDto>> getNotifications({DateTime? since}) async {
    final queryParams = <String, dynamic>{};
    if (since != null) {
      queryParams['since'] = since.toUtc().toIso8601String();
    }

    final response = await _dio.get(
      '/notifications',
      queryParameters: queryParams,
    );
    final data = response.data;
    final list = (data is List) ? data : (data['items'] as List<dynamic>);
    return list
        .map((j) => NotificationDto.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// POST /notifications/{id}/read — marks notification as read.
  Future<void> markAsRead(String id) async {
    await _dio.post('/notifications/$id/read');
  }

  /// POST /notifications/read-all — marks all notifications as read.
  Future<void> markAllRead() async {
    await _dio.post('/notifications/read-all');
  }
}
