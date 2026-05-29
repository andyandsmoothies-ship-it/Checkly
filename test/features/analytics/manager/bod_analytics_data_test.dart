import 'package:flutter_test/flutter_test.dart';
import 'package:checkly/features/analytics/manager/bod_analytics_data.dart';

void main() {
  group('BodChainKpis Tests —', () {
    test('Should parse successfully from valid JSON with doubles', () {
      final json = {
        'totalAudits': 120,
        'avgScore': 85.5,
        'avgTtrDays': 3.5,
        'completionRate': 92.4,
        'openActionPlans': 5,
        'overdueActionPlans': 2,
        'activeStores': 8,
        'totalAuditors': 4,
      };

      final kpis = BodChainKpis.fromJson(json);

      expect(kpis.totalAudits, 120);
      expect(kpis.avgScore, 85.5);
      expect(kpis.avgTtrDays, 3.5);
      expect(kpis.completionRate, 92.4);
      expect(kpis.openAPs, 5);
      expect(kpis.overdueAPs, 2);
      expect(kpis.activeStores, 8);
      expect(kpis.totalAuditors, 4);
    });

    test('Should parse double fields from integer values gracefully', () {
      final json = {
        'totalAudits': 120,
        'avgScore': 85, // integer instead of double
        'avgTtrDays': 3, // integer instead of double
        'completionRate': 92, // integer instead of double
        'openAPs': 5,
        'overdueAPs': 2,
      };

      final kpis = BodChainKpis.fromJson(json);

      expect(kpis.avgScore, 85.0);
      expect(kpis.avgTtrDays, 3.0);
      expect(kpis.completionRate, 92.0);
    });

    test('toJson and fromJson symmetry', () {
      const kpis = BodChainKpis(
        totalAudits: 50,
        avgScore: 78.5,
        avgTtrDays: 5.1,
        completionRate: 88.0,
        openAPs: 10,
        overdueAPs: 4,
        activeStores: 15,
        totalAuditors: 6,
      );

      final json = kpis.toJson();
      final parsed = BodChainKpis.fromJson(json);

      expect(parsed.totalAudits, kpis.totalAudits);
      expect(parsed.avgScore, kpis.avgScore);
      expect(parsed.avgTtrDays, kpis.avgTtrDays);
      expect(parsed.completionRate, kpis.completionRate);
      expect(parsed.openAPs, kpis.openAPs);
      expect(parsed.overdueAPs, kpis.overdueAPs);
      expect(parsed.activeStores, kpis.activeStores);
      expect(parsed.totalAuditors, kpis.totalAuditors);
    });
  });

  group('BodStorePerformanceEntry Tests —', () {
    test('Should parse successfully with complete inputs', () {
      final json = {
        'storeId': 'st-99',
        'storeName': 'Mega Store A',
        'avgScore': 88.7,
        'auditCount': 12,
        'lastSyncedAt': '2026-05-28T14:30:00Z',
      };

      final entry = BodStorePerformanceEntry.fromJson(json);

      expect(entry.storeId, 'st-99');
      expect(entry.storeName, 'Mega Store A');
      expect(entry.avgScore, 88.7);
      expect(entry.auditCount, 12);
      expect(entry.lastSyncedAt, isNotNull);
      expect(entry.lastSyncedAt!.year, 2026);
    });

    test('Should parse gracefully with null and empty string lastSyncedAt', () {
      final jsonNull = {
        'storeId': 'st-99',
        'storeName': 'Mega Store A',
        'avgScore': 88,
        'auditCount': 12,
        'lastSyncedAt': null,
      };

      final jsonEmpty = {
        'storeId': 'st-99',
        'storeName': 'Mega Store A',
        'avgScore': 88,
        'auditCount': 12,
        'lastSyncedAt': '',
      };

      final entryNull = BodStorePerformanceEntry.fromJson(jsonNull);
      final entryEmpty = BodStorePerformanceEntry.fromJson(jsonEmpty);

      expect(entryNull.lastSyncedAt, isNull);
      expect(entryEmpty.lastSyncedAt, isNull);
      expect(entryNull.avgScore, 88.0);
    });
  });

  group('BodApAging Tests —', () {
    test('Should parse from plain JSON map', () {
      final json = {
        'bucket0to7': 10,
        'bucket8to30': 20,
        'bucket31to90': 30,
        'bucket90Plus': 40,
      };

      final aging = BodApAging.fromJson(json);

      expect(aging.bucket0to7, 10);
      expect(aging.bucket8to30, 20);
      expect(aging.bucket31to90, 30);
      expect(aging.bucket90Plus, 40);
    });

    test('fromDynamic parses null gracefully to all zeros', () {
      final aging = BodApAging.fromDynamic(null);

      expect(aging.bucket0to7, 0);
      expect(aging.bucket8to30, 0);
      expect(aging.bucket31to90, 0);
      expect(aging.bucket90Plus, 0);
    });

    test('fromDynamic parses valid Map correctly', () {
      final map = {
        'bucket0to7': 5,
        'bucket8to30': 15,
        'bucket31to90': 25,
        'bucket90Plus': 35,
      };

      final aging = BodApAging.fromDynamic(map);

      expect(aging.bucket0to7, 5);
      expect(aging.bucket8to30, 15);
      expect(aging.bucket31to90, 25);
      expect(aging.bucket90Plus, 35);
    });

    test('fromDynamic parses List with range and count fields', () {
      final list = [
        {'range': '0-7d', 'count': 4},
        {'range': '8-30d', 'count': 8},
        {'range': '31-90d', 'count': 12},
        {'range': '90+d', 'count': 16},
      ];

      final aging = BodApAging.fromDynamic(list);

      expect(aging.bucket0to7, 4);
      expect(aging.bucket8to30, 8);
      expect(aging.bucket31to90, 12);
      expect(aging.bucket90Plus, 16);
    });

    test('fromDynamic parses List with bucket and value fields', () {
      final list = [
        {'bucket': '0-7', 'value': 2},
        {'bucket': '8-30', 'value': 4},
        {'bucket': '31-90', 'value': 6},
        {'bucket': '90+', 'value': 8},
      ];

      final aging = BodApAging.fromDynamic(list);

      expect(aging.bucket0to7, 2);
      expect(aging.bucket8to30, 4);
      expect(aging.bucket31to90, 6);
      expect(aging.bucket90Plus, 8);
    });

    test('toJson produces correct map keys', () {
      const aging = BodApAging(
        bucket0to7: 1,
        bucket8to30: 2,
        bucket31to90: 3,
        bucket90Plus: 4,
      );

      final json = aging.toJson();

      expect(json['0-7'], 1);
      expect(json['8-30'], 2);
      expect(json['31-90'], 3);
      expect(json['90+'], 4);
    });
  });

  group('BodGoldenStore Tests —', () {
    test('Should parse fields and handle int-to-double conversions', () {
      final json = {
        'storeName': 'Golden Store Delta',
        'avgScore': 95,
        'province': 'Central Province',
      };

      final store = BodGoldenStore.fromJson(json);

      expect(store.storeName, 'Golden Store Delta');
      expect(store.avgScore, 95.0);
      expect(store.province, 'Central Province');
    });
  });

  group('BodReportResponse Tests —', () {
    test('Should parse full response correctly with nested resources', () {
      final json = {
        'chainKpis': {
          'totalAudits': 1500,
          'avgScore': 81.2,
          'avgTtrDays': 6.8,
        },
        'trend': [
          {'date': '2026-05-01', 'score': 80.0}
        ],
        'topStores': [
          {'storeId': 's-1', 'storeName': 'Top A', 'avgScore': 90.0}
        ],
        'bottomStores': [
          {'storeId': 's-2', 'storeName': 'Bottom A', 'avgScore': 60.0}
        ],
        'weaknesses': [
          {'category': 'Hygiene', 'score': 45.0}
        ],
        'actionPlanAging': {
          'bucket0to7': 1,
          'bucket8to30': 2,
          'bucket31to90': 3,
          'bucket90Plus': 4,
        },
        'auditorProductivity': [
          {'name': 'Auditor John', 'audits': 25}
        ],
        'computedAt': '2026-05-29T10:00:00Z',
        'snapshotStatus': 'Stale',
        'allowedActions': ['view', 'refresh'],
        'goldenStore': {
          'storeName': 'Superb Store',
          'avgScore': 98.4,
          'province': 'Northern Province',
        }
      };

      final response = BodReportResponse.fromJson(json);

      expect(response.chainKpis.totalAudits, 1500);
      expect(response.trend.length, 1);
      expect(response.topStores.first.storeName, 'Top A');
      expect(response.bottomStores.first.storeName, 'Bottom A');
      expect(response.categoryBreakdown.first['category'], 'Hygiene');
      expect(response.apAging.bucket0to7, 1);
      expect(response.auditorProductivity.first.auditorName, 'Auditor John');
      expect(response.computedAt, '2026-05-29T10:00:00Z');
      expect(response.snapshotStatus, 'Stale');
      expect(response.allowedActions, containsAll(['view', 'refresh']));
      expect(response.goldenStore, isNotNull);
      expect(response.goldenStore!.storeName, 'Superb Store');
    });
  });

  group('ApDetailEntry Tests —', () {
    test('Should parse successfully and support overdueDays fallback', () {
      final jsonNormal = {
        'id': 'ap-1',
        'criteriaLabel': 'Clean floors',
        'storeName': 'Westside Store',
        'managerName': 'Alice',
        'ageInDays': 15,
      };

      final jsonFallback = {
        'id': 'ap-2',
        'criteriaLabel': 'Clean tables',
        'storeName': 'Eastside Store',
        'managerName': 'Bob',
        'overdueDays': 25,
      };

      final entryNormal = ApDetailEntry.fromJson(jsonNormal);
      final entryFallback = ApDetailEntry.fromJson(jsonFallback);

      expect(entryNormal.id, 'ap-1');
      expect(entryNormal.criteriaLabel, 'Clean floors');
      expect(entryNormal.storeName, 'Westside Store');
      expect(entryNormal.managerName, 'Alice');
      expect(entryNormal.ageInDays, 15);

      expect(entryFallback.id, 'ap-2');
      expect(entryFallback.ageInDays, 25);
    });
  });

  group('RecentAuditEntry Tests —', () {
    test('Should parse fields and handle int-to-double conversions', () {
      final json = {
        'date': '2026-05-29',
        'score': 87,
        'auditorName': 'Sarah Jennings',
      };

      final entry = RecentAuditEntry.fromJson(json);

      expect(entry.date, '2026-05-29');
      expect(entry.score, 87.0);
      expect(entry.auditorName, 'Sarah Jennings');
    });
  });

  group('CategoryScoreEntry Tests —', () {
    test('Should parse fields and handle int-to-double conversions', () {
      final json = {
        'categoryName': 'Food Safety',
        'avgScore': 91,
      };

      final entry = CategoryScoreEntry.fromJson(json);

      expect(entry.categoryName, 'Food Safety');
      expect(entry.avgScore, 91.0);
    });
  });

  group('StoreBodSummary Tests —', () {
    test('Should parse successfully with nested arrays', () {
      final json = {
        'storeName': 'Store 311',
        'recentAudits': [
          {'date': '2026-05-20', 'score': 80.5, 'auditorName': 'Tim'}
        ],
        'categoryBreakdown': [
          {'categoryName': 'Staff Grooming', 'avgScore': 95.0}
        ]
      };

      final summary = StoreBodSummary.fromJson(json);

      expect(summary.storeName, 'Store 311');
      expect(summary.recentAudits.length, 1);
      expect(summary.recentAudits.first.auditorName, 'Tim');
      expect(summary.categoryBreakdown.length, 1);
      expect(summary.categoryBreakdown.first.categoryName, 'Staff Grooming');
    });
  });

  group('CategoryStoreEntry Tests —', () {
    test('Should parse fields and handle int-to-double conversions', () {
      final json = {
        'storeName': 'Main St Store',
        'avgScore': 78,
        'auditCount': 5,
        'failureCount': 2,
      };

      final entry = CategoryStoreEntry.fromJson(json);

      expect(entry.storeName, 'Main St Store');
      expect(entry.avgScore, 78.0);
      expect(entry.auditCount, 5);
      expect(entry.failureCount, 2);
    });
  });
}
