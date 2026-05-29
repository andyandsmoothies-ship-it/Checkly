import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:checkly/features/analytics/manager/bod_analytics_data.dart';
import 'package:checkly/features/analytics/services/mock/bod_mock_data.dart';

class BodAnalyticsApiService {
  final Dio _dio;

  BodAnalyticsApiService(this._dio);

  Future<BodReportResponse> getReport() async {
    try {
      final response = await _dio.get('/analytics/bod');
      final data = response.data as Map<String, dynamic>;
      return BodReportResponse.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        return BodMockData.defaultReport();
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> triggerRefresh() async {
    try {
      final response = await _dio.post('/analytics/bod/refresh');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        return BodMockData.refreshStatusJson();
      }
      rethrow;
    }
  }

  Future<BodReportResponse> getFilteredReport(
    String province,
    String district,
  ) async {
    try {
      final response = await _dio.get(
        '/analytics/bod',
        queryParameters: {'province': province, 'district': district},
      );
      return BodReportResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) {
        return getReport();
      }
      rethrow;
    }
  }

  Future<List<ApDetailEntry>> getApBucketDetail(String bucketName) async {
    try {
      final response = await _dio.get('/analytics/bod/ap/$bucketName');
      final data = response.data as List<dynamic>;
      return data
          .map((e) => ApDetailEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        return BodMockData.apBucketDetail(bucketName);
      }
      rethrow;
    }
  }

  Future<StoreBodSummary> getStoreBodSummary(String storeId) async {
    try {
      final response = await _dio.get('/analytics/stores/$storeId/bod-summary');
      return StoreBodSummary.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) {
        return BodMockData.storeBodSummary();
      }
      rethrow;
    }
  }

  Future<List<CategoryStoreEntry>> getCategoryDetail(String name) async {
    try {
      final response = await _dio.get('/analytics/bod/category/$name');
      final data = response.data as List<dynamic>;
      return data
          .map((e) => CategoryStoreEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        return BodMockData.categoryDetail();
      }
      rethrow;
    }
  }

  Future<List<BodAuditorEntry>> getAuditorProductivity() async {
    try {
      final report = await getReport();
      return report.auditorProductivity;
    } catch (e) {
      if (kDebugMode) {
        return BodMockData.auditorProductivity();
      }
      rethrow;
    }
  }
}
