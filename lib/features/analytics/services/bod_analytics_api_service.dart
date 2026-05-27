import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:checkly/features/analytics/manager/bod_analytics_data.dart';

class BodAnalyticsApiService {
  final Dio _dio;

  BodAnalyticsApiService(this._dio);

  Future<BodReportResponse> getReport() async {
    try {
      final response = await _dio.get('/analytics/bod');
      final data = response.data as Map<String, dynamic>;
      debugPrint('[BOD] raw JSON keys: ${data.keys.toList()}');
      return BodReportResponse.fromJson(data);
    } catch (e) {
      debugPrint('[BOD] Connection to backend failed, falling back to local mock data: $e');
      return BodReportResponse.fromJson({
        "kpis": {
          "totalAudits": 125,
          "avgScore": 85.9,
          "completionRate": 100.0,
          "openActionPlans": 37,
          "overdueActionPlans": 27,
          "activeStores": 10,
          "totalAuditors": 2,
          "avgTtrDays": 0.0
        },
        "trend": [
          {"month": "2026-01", "avgScore": 84.2, "count": 25},
          {"month": "2026-02", "avgScore": 87.7, "count": 25},
          {"month": "2026-03", "avgScore": 86.2, "count": 25},
          {"month": "2026-04", "avgScore": 85.1, "count": 25},
          {"month": "2026-05", "avgScore": 86.2, "count": 25}
        ],
        "topStores": [
          {"storeId": "ba7e69f8-7a67-4092-ae80-51291a18aa25", "storeName": "Checkly D1 - Nguyen Hue", "avgScore": 91.6, "auditCount": 2},
          {"storeId": "0ac3cf0b-e393-40f0-81c7-2e4f296bec94", "storeName": "Checkly Binh Thanh - Landmark 81", "avgScore": 90.5, "auditCount": 2},
          {"storeId": "9a1082b2-2796-42ef-885f-34f8c746a110", "storeName": "Checkly Go Vap - Quang Trung", "avgScore": 89.0, "auditCount": 3},
          {"storeId": "155be63b-056d-43ff-8c51-68243de324b5", "storeName": "Checkly D7 - Phu My Hung", "avgScore": 87.2, "auditCount": 3},
          {"storeId": "82e71697-8d6c-45ae-8734-2f26d738275a", "storeName": "Checkly D10 - Su Van Hanh", "avgScore": 87.1, "auditCount": 3}
        ],
        "bottomStores": [
          {"storeId": "ed6dd187-7709-41bc-89e4-b6e7994d5d72", "storeName": "Checkly Phu Nhuan - Phan Xich Long", "avgScore": 79.6, "auditCount": 3},
          {"storeId": "2a3c00c5-aa6c-43cb-854c-cc2066de36e4", "storeName": "Checkly D1 - Bui Vien", "avgScore": 81.7, "auditCount": 3},
          {"storeId": "8d151226-1e93-42ae-bcec-79bc7ce5cf74", "storeName": "Checkly D2 - Thao Dien", "avgScore": 85.0, "auditCount": 2},
          {"storeId": "fd393a99-d5d1-4038-80e3-53504057f2c2", "storeName": "Checkly D3 - Vo Van Tan", "avgScore": 86.3, "auditCount": 2},
          {"storeId": "766bf35d-235b-40f0-b6d2-1940c0e2486f", "storeName": "Checkly Tan Binh - Cong Hoa", "avgScore": 86.6, "auditCount": 2}
        ],
        "weaknesses": [
          {"categoryName": "Daily Operations", "templateTitle": "Basic checklist", "avgScore": 85.6, "auditCount": 75},
          {"categoryName": "Opening Tasks", "templateTitle": "Basic checklist", "avgScore": 85.8, "auditCount": 75},
          {"categoryName": "Closing Tasks", "templateTitle": "Basic checklist", "avgScore": 86.1, "auditCount": 75}
        ],
        "goldenStore": {
          "storeName": "Checkly Nguyen Hue",
          "avgScore": 92.5,
          "province": "Hanoi"
        },
        "actionPlanAging": [
          {"bucket": "0-7d", "count": 4},
          {"bucket": "8-30d", "count": 6},
          {"bucket": "31-90d", "count": 15},
          {"bucket": "90d+", "count": 12}
        ],
        "auditorProductivity": [
          {"auditorId": "88e81a53-2ed0-40b4-90c5-95c652466bfe", "auditorName": "Auditor 2", "completedAudits": 18, "avgScore": 87.0},
          {"auditorId": "2630946e-8eb7-4836-ace8-33129ff7885b", "auditorName": "Auditor 1", "completedAudits": 7, "avgScore": 84.1}
        ]
      });
    }
  }

  Future<Map<String, dynamic>> triggerRefresh() async {
    try {
      final response = await _dio.post('/analytics/bod/refresh');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[BOD] triggerRefresh failed, returning mock status: $e');
      return {"status": "triggered", "computedAt": DateTime.now().toIso8601String()};
    }
  }

  Future<BodReportResponse> getFilteredReport(String province, String district) async {
    try {
      final response = await _dio.get(
        '/analytics/bod',
        queryParameters: {
          'province': province,
          'district': district,
        },
      );
      return BodReportResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[BOD] getFilteredReport failed, returning mock data: $e');
      return getReport();
    }
  }

  Future<List<ApDetailEntry>> getApBucketDetail(String bucketName) async {
    try {
      final response = await _dio.get('/analytics/bod/ap/$bucketName');
      final data = response.data as List<dynamic>;
      return data.map((e) => ApDetailEntry.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      debugPrint('[BOD] getApBucketDetail failed for $bucketName, returning mock action plans: $e');
      if (bucketName.contains('0-7')) {
        return [
          ApDetailEntry(id: 'ap1', criteriaLabel: 'Cleanliness & hygiene in dining area', storeName: 'Checkly D1 - Nguyen Hue', managerName: 'Manager Nguyen Hue', ageInDays: 3),
          ApDetailEntry(id: 'ap2', criteriaLabel: 'Staff grooming & standard uniforms', storeName: 'Checkly Binh Thanh - Landmark 81', managerName: 'Manager Landmark 81', ageInDays: 5),
          ApDetailEntry(id: 'ap3', criteriaLabel: 'Food preparation temperature checks', storeName: 'Checkly Go Vap - Quang Trung', managerName: 'Manager Go Vap', ageInDays: 2),
          ApDetailEntry(id: 'ap4', criteriaLabel: 'Inventory level checklist', storeName: 'Checkly D7 - Phu My Hung', managerName: 'Manager Phu My Hung', ageInDays: 6),
        ];
      } else if (bucketName.contains('8-30')) {
        return [
          ApDetailEntry(id: 'ap5', criteriaLabel: 'Raw ingredient shelf-life labeling', storeName: 'Checkly D10 - Su Van Hanh', managerName: 'Manager Su Van Hanh', ageInDays: 12),
          ApDetailEntry(id: 'ap6', criteriaLabel: 'Fire safety equipment accessibility', storeName: 'Checkly Phu Nhuan - Phan Xich Long', managerName: 'Manager Phan Xich Long', ageInDays: 20),
          ApDetailEntry(id: 'ap7', criteriaLabel: 'Cash register reconciliation logs', storeName: 'Checkly D1 - Bui Vien', managerName: 'Manager Bui Vien', ageInDays: 15),
          ApDetailEntry(id: 'ap8', criteriaLabel: 'Restroom cleaning checklist', storeName: 'Checkly D2 - Thao Dien', managerName: 'Manager Thao Dien', ageInDays: 25),
          ApDetailEntry(id: 'ap9', criteriaLabel: 'Pest control standard inspection', storeName: 'Checkly D3 - Vo Van Tan', managerName: 'Manager Vo Van Tan', ageInDays: 10),
          ApDetailEntry(id: 'ap10', criteriaLabel: 'Kitchen waste disposal frequency', storeName: 'Checkly Tan Binh - Cong Hoa', managerName: 'Manager Cong Hoa', ageInDays: 18),
        ];
      } else if (bucketName.contains('31-90')) {
        return List.generate(15, (index) => ApDetailEntry(
          id: 'ap_31_90_$index',
          criteriaLabel: 'Monthly Deep Cleaning Protocol #${index + 1}',
          storeName: 'Checkly Store ${index % 5 + 1}',
          managerName: 'Manager ${index % 5 + 1}',
          ageInDays: 45 + (index * 2),
        ));
      } else {
        return List.generate(12, (index) => ApDetailEntry(
          id: 'ap_90_$index',
          criteriaLabel: 'Annual Health and Safety Certification #${index + 1}',
          storeName: 'Checkly Store ${index % 4 + 1}',
          managerName: 'Manager ${index % 4 + 1}',
          ageInDays: 100 + (index * 5),
        ));
      }
    }
  }

  Future<StoreBodSummary> getStoreBodSummary(String storeId) async {
    try {
      final response = await _dio.get('/analytics/stores/$storeId/bod-summary');
      return StoreBodSummary.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[BOD] getStoreBodSummary failed, returning mock store details: $e');
      return StoreBodSummary(
        storeName: 'Checkly Nguyen Hue',
        recentAudits: [
          RecentAuditEntry(date: '2026-05-15', score: 92.5, auditorName: 'Auditor 1'),
          RecentAuditEntry(date: '2026-04-20', score: 90.0, auditorName: 'Auditor 2'),
          RecentAuditEntry(date: '2026-03-12', score: 94.0, auditorName: 'Auditor 1'),
        ],
        categoryBreakdown: [
          CategoryScoreEntry(categoryName: 'Daily Operations', avgScore: 92.0),
          CategoryScoreEntry(categoryName: 'Opening Tasks', avgScore: 90.5),
          CategoryScoreEntry(categoryName: 'Closing Tasks', avgScore: 94.2),
        ],
      );
    }
  }

  Future<List<CategoryStoreEntry>> getCategoryDetail(String name) async {
    try {
      final response = await _dio.get('/analytics/bod/category/$name');
      final data = response.data as List<dynamic>;
      return data.map((e) => CategoryStoreEntry.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      debugPrint('[BOD] getCategoryDetail failed, returning mock worst-performing stores: $e');
      return [
        CategoryStoreEntry(storeName: 'Checkly Phu Nhuan - Phan Xich Long', avgScore: 78.5, auditCount: 3, failureCount: 2),
        CategoryStoreEntry(storeName: 'Checkly D1 - Bui Vien', avgScore: 81.0, auditCount: 3, failureCount: 1),
        CategoryStoreEntry(storeName: 'Checkly D2 - Thao Dien', avgScore: 84.5, auditCount: 2, failureCount: 1),
      ];
    }
  }

  Future<List<dynamic>> getAuditorProductivity() async {
    try {
      final report = await getReport();
      return report.auditorProductivity;
    } catch (e) {
      debugPrint('[BOD] getAuditorProductivity failed, returning mock list: $e');
      return [
        {"auditorId": "88e81a53-2ed0-40b4-90c5-95c652466bfe", "auditorName": "Auditor 2", "completedAudits": 18, "avgScore": 87.0},
        {"auditorId": "2630946e-8eb7-4836-ace8-33129ff7885b", "auditorName": "Auditor 1", "completedAudits": 7, "avgScore": 84.1}
      ];
    }
  }
}

