import 'package:dio/dio.dart';
import 'package:checkly/features/analytics/manager/bod_analytics_data.dart';

class BodAnalyticsApiService {
  final Dio _dio;

  BodAnalyticsApiService(this._dio);

  Future<BodReportResponse> getReport() async {
    final response = await _dio.get('/analytics/bod');
    return BodReportResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> triggerRefresh() async {
    final response = await _dio.post('/analytics/bod/refresh');
    return response.data as Map<String, dynamic>;
  }

  Future<BodReportResponse> getFilteredReport(String province, String district) async {
    final response = await _dio.get(
      '/analytics/bod',
      queryParameters: {
        'province': province,
        'district': district,
      },
    );
    return BodReportResponse.fromJson(response.data as Map<String, dynamic>);
  }
}
