import 'package:dio/dio.dart';

/// API service for analytics endpoints (/api/analytics).
class AnalyticsApiService {
  final Dio _dio;

  AnalyticsApiService(this._dio);

  /// GET /analytics — returns aggregate analytics data.
  Future<Map<String, dynamic>> getAnalytics({
    String? storeId,
    String? areaCode,
    String? startDate,
    String? endDate,
  }) async {
    final params = <String, dynamic>{};
    if (storeId != null) params['storeId'] = storeId;
    if (areaCode != null) params['area'] = areaCode;
    if (startDate != null) params['startDate'] = startDate;
    if (endDate != null) params['endDate'] = endDate;

    final response = await _dio.get('/analytics', queryParameters: params);
    return response.data as Map<String, dynamic>;
  }
}
