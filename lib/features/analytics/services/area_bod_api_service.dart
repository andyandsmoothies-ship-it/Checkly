import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:checkly/features/analytics/manager/area_bod_data.dart';
import 'package:checkly/features/analytics/manager/bod_analytics_data.dart'
    show
        ApDetailEntry,
        StoreBodSummary,
        CategoryStoreEntry,
        RecentAuditEntry,
        CategoryScoreEntry;

class AreaBodApiService {
  final Dio _dio;

  AreaBodApiService(this._dio);

  Future<AreaBodResponse> getReport() async {
    try {
      final response = await _dio.get('/analytics/bod/area');
      final data = response.data as Map<String, dynamic>;
      return AreaBodResponse.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        return _defaultMockReport();
      }
      rethrow;
    }
  }

  Future<AreaBodResponse> getFilteredReport(
    String province,
    String district,
  ) async {
    try {
      final response = await _dio.get(
        '/analytics/bod/area',
        queryParameters: {'province': province, 'district': district},
      );
      return AreaBodResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) {
        return getReport();
      }
      rethrow;
    }
  }

  Future<List<ApDetailEntry>> getApBucketDetail(String bucketName) async {
    try {
      final response = await _dio.get('/analytics/bod/area/ap/$bucketName');
      final data = response.data as List<dynamic>;
      return data
          .map((e) => ApDetailEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        return _defaultMockApDetails(bucketName);
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
        return _defaultMockStoreSummary();
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
        return _defaultMockCategoryDetail();
      }
      rethrow;
    }
  }

  Future<List<AreaAuditorProductivity>> getAuditorProductivity() async {
    try {
      final report = await getReport();
      return report.auditorProductivity;
    } catch (e) {
      if (kDebugMode) {
        return _defaultMockAuditors();
      }
      rethrow;
    }
  }

  AreaBodResponse _defaultMockReport() {
    return AreaBodResponse.fromJson({
      "isLiveData": true,
      "kpis": {
        "totalAudits": 45,
        "avgScore": 87.2,
        "completionRate": 95.5,
        "openActionPlans": 12,
        "overdueActionPlans": 4,
        "activeStores": 4,
        "totalAuditors": 2,
        "avgTtrDays": 2.5,
      },
      "trend": [
        {"month": "2026-01", "avgScore": 85.0, "count": 8},
        {"month": "2026-02", "avgScore": 86.5, "count": 9},
        {"month": "2026-03", "avgScore": 87.0, "count": 10},
        {"month": "2026-04", "avgScore": 87.2, "count": 10},
        {"month": "2026-05", "avgScore": 88.1, "count": 8},
      ],
      "topStores": [
        {
          "storeId": "store-a",
          "storeName": "Area Store A (Nguyen Hue)",
          "avgScore": 92.5,
          "auditCount": 12,
        },
        {
          "storeId": "store-b",
          "storeName": "Area Store B (Landmark 81)",
          "avgScore": 89.0,
          "auditCount": 11,
        },
      ],
      "bottomStores": [
        {
          "storeId": "store-c",
          "storeName": "Area Store C (Su Van Hanh)",
          "avgScore": 81.2,
          "auditCount": 11,
        },
        {
          "storeId": "store-d",
          "storeName": "Area Store D (Bui Vien)",
          "avgScore": 79.5,
          "auditCount": 11,
        },
      ],
      "weaknesses": [
        {
          "categoryName": "Daily Operations",
          "templateName": "Basic checklist",
          "avgScore": 82.5,
          "auditCount": 20,
        },
        {
          "categoryName": "Opening Tasks",
          "templateName": "Basic checklist",
          "avgScore": 83.1,
          "auditCount": 20,
        },
      ],
      "goldenStore": {
        "storeName": "Area Store A (Nguyen Hue)",
        "avgScore": 92.5,
        "province": "Hanoi",
      },
      "actionPlanAging": [
        {"bucket": "0-7d", "count": 3},
        {"bucket": "8-30d", "count": 4},
        {"bucket": "31-90d", "count": 3},
        {"bucket": "90d+", "count": 2},
      ],
      "auditorProductivity": [
        {
          "auditorName": "Area Auditor 1",
          "completedCount": 25,
          "avgScore": 88.0,
        },
        {
          "auditorName": "Area Auditor 2",
          "completedCount": 20,
          "avgScore": 86.2,
        },
      ],
      "allowedActions": ["refresh"],
    });
  }

  List<ApDetailEntry> _defaultMockApDetails(String bucket) {
    return [
      ApDetailEntry(
        id: 'ap-1',
        criteriaLabel: 'Area Cleanliness & Hygiene',
        storeName: 'Area Store D (Bui Vien)',
        managerName: 'Manager Bui Vien',
        ageInDays: bucket.contains('0-7') ? 3 : 15,
      ),
    ];
  }

  StoreBodSummary _defaultMockStoreSummary() {
    return StoreBodSummary(
      storeName: 'Area Store A (Nguyen Hue)',
      recentAudits: [
        RecentAuditEntry(
          date: '2026-05-20',
          score: 92.5,
          auditorName: 'Area Auditor 1',
        ),
      ],
      categoryBreakdown: [
        CategoryScoreEntry(categoryName: 'Daily Operations', avgScore: 92.0),
      ],
    );
  }

  List<CategoryStoreEntry> _defaultMockCategoryDetail() {
    return [
      CategoryStoreEntry(
        storeName: 'Area Store D (Bui Vien)',
        avgScore: 79.5,
        auditCount: 11,
        failureCount: 4,
      ),
    ];
  }

  List<AreaAuditorProductivity> _defaultMockAuditors() {
    return [
      AreaAuditorProductivity(
        auditorName: 'Area Auditor 1',
        completedCount: 25,
        avgScore: 88.0,
      ),
    ];
  }
}
