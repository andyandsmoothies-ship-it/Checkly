class BodChainKpis {
  final int totalAudits;
  final double avgScore;
  final double avgTtrDays;
  final double completionRate;
  final int openAPs;
  final int overdueAPs;
  final int activeStores;
  final int totalAuditors;

  const BodChainKpis({
    required this.totalAudits,
    required this.avgScore,
    required this.avgTtrDays,
    this.completionRate = 0.0,
    this.openAPs = 0,
    this.overdueAPs = 0,
    this.activeStores = 0,
    this.totalAuditors = 0,
  });

  factory BodChainKpis.fromJson(Map<String, dynamic> json) {
    return BodChainKpis(
      totalAudits: json['totalAudits'] ?? 0,
      avgScore: (json['avgScore'] ?? 0.0) is int
          ? (json['avgScore'] as int).toDouble()
          : (json['avgScore'] ?? 0.0).toDouble(),
      avgTtrDays: (json['avgTtrDays'] ?? 0.0) is int
          ? (json['avgTtrDays'] as int).toDouble()
          : (json['avgTtrDays'] ?? 0.0).toDouble(),
      completionRate: (json['completionRate'] ?? 0.0) is int
          ? (json['completionRate'] as int).toDouble()
          : (json['completionRate'] ?? 0.0).toDouble(),
      openAPs: json['openActionPlans'] ?? json['openAPs'] ?? 0,
      overdueAPs: json['overdueActionPlans'] ?? json['overdueAPs'] ?? 0,
      activeStores: json['activeStores'] ?? 0,
      totalAuditors: json['totalAuditors'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalAudits': totalAudits,
      'avgScore': avgScore,
      'avgTtrDays': avgTtrDays,
      'completionRate': completionRate,
      'openAPs': openAPs,
      'overdueAPs': overdueAPs,
      'activeStores': activeStores,
      'totalAuditors': totalAuditors,
    };
  }
}

class BodStorePerformanceEntry {
  final String storeId;
  final String storeName;
  final double avgScore;
  final int auditCount;
  final DateTime? lastSyncedAt;

  BodStorePerformanceEntry({
    required this.storeId,
    required this.storeName,
    required this.avgScore,
    required this.auditCount,
    this.lastSyncedAt,
  });

  factory BodStorePerformanceEntry.fromJson(Map<String, dynamic> json) {
    return BodStorePerformanceEntry(
      storeId: json['storeId'] ?? '',
      storeName: json['storeName'] ?? '',
      avgScore: (json['avgScore'] ?? 0.0) is int
          ? (json['avgScore'] as int).toDouble()
          : (json['avgScore'] ?? 0.0).toDouble(),
      auditCount: json['auditCount'] ?? 0,
      lastSyncedAt: json['lastSyncedAt'] != null && json['lastSyncedAt'] != ''
          ? DateTime.tryParse(json['lastSyncedAt'])
          : null,
    );
  }
}

class BodApAging {
  final int bucket0to7;
  final int bucket8to30;
  final int bucket31to90;
  final int bucket90Plus;

  const BodApAging({
    required this.bucket0to7,
    required this.bucket8to30,
    required this.bucket31to90,
    required this.bucket90Plus,
  });

  factory BodApAging.fromJson(Map<String, dynamic> json) {
    return BodApAging(
      bucket0to7: json['bucket0to7'] ?? json['bucket0to30'] ?? 0,
      bucket8to30: json['bucket8to30'] ?? json['bucket31to60'] ?? 0,
      bucket31to90: json['bucket31to90'] ?? json['bucket61to90'] ?? 0,
      bucket90Plus: json['bucket90Plus'] ?? 0,
    );
  }

  /// Handles both server shapes:
  ///   List: [{"range":"0-7d","count":5}, ...]
  ///   Map:  {"bucket0to7": 5, ...}
  static BodApAging fromDynamic(dynamic raw) {
    if (raw == null) {
      return const BodApAging(
        bucket0to7: 0,
        bucket8to30: 0,
        bucket31to90: 0,
        bucket90Plus: 0,
      );
    }
    if (raw is Map) {
      return BodApAging.fromJson(Map<String, dynamic>.from(raw));
    }
    if (raw is List) {
      int b0to7 = 0, b8to30 = 0, b31to90 = 0, b90Plus = 0;
      for (final item in raw) {
        if (item is! Map) continue;
        final range = (item['range'] ?? item['bucket'] ?? '').toString().toLowerCase();
        final count = (item['count'] ?? item['value'] ?? 0) as int;
        if (range.contains('0-7')) {
          b0to7 = count;
        } else if (range.contains('8-30')) {
          b8to30 = count;
        } else if (range.contains('31-90')) {
          b31to90 = count;
        } else if (range.contains('90') || range.contains('+')) {
          b90Plus = count;
        }
      }
      return BodApAging(
        bucket0to7: b0to7,
        bucket8to30: b8to30,
        bucket31to90: b31to90,
        bucket90Plus: b90Plus,
      );
    }
    return const BodApAging(
      bucket0to7: 0,
      bucket8to30: 0,
      bucket31to90: 0,
      bucket90Plus: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '0-7': bucket0to7,
      '8-30': bucket8to30,
      '31-90': bucket31to90,
      '90+': bucket90Plus,
    };
  }
}

class BodGoldenStore {
  final String storeName;
  final double avgScore;
  final String province;

  BodGoldenStore({
    required this.storeName,
    required this.avgScore,
    required this.province,
  });

  factory BodGoldenStore.fromJson(Map<String, dynamic> json) {
    return BodGoldenStore(
      storeName: json['storeName'] ?? '',
      avgScore: (json['avgScore'] ?? 0.0) is int
          ? (json['avgScore'] as int).toDouble()
          : (json['avgScore'] ?? 0.0).toDouble(),
      province: json['province'] ?? '',
    );
  }
}

class BodReportResponse {
  final BodChainKpis chainKpis;
  final List<dynamic> trend;
  final List<BodStorePerformanceEntry> topStores;
  final List<BodStorePerformanceEntry> bottomStores;
  final List<dynamic> categoryBreakdown;
  final BodApAging apAging;
  final List<dynamic> auditorProductivity;
  final String computedAt;
  final String snapshotStatus;
  final List<dynamic> allowedActions;
  final BodGoldenStore? goldenStore;

  BodReportResponse({
    required this.chainKpis,
    required this.trend,
    required this.topStores,
    required this.bottomStores,
    required this.categoryBreakdown,
    required this.apAging,
    required this.auditorProductivity,
    required this.computedAt,
    required this.snapshotStatus,
    required this.allowedActions,
    this.goldenStore,
  });

  factory BodReportResponse.fromJson(Map<String, dynamic> json) {
    return BodReportResponse(
      chainKpis: BodChainKpis.fromJson(
        Map<String, dynamic>.from(json['kpis'] ?? json['chainKpis'] ?? {}),
      ),
      trend: List<dynamic>.from(json['trend'] ?? []),
      topStores:
          (json['topStores'] as List<dynamic>?)
              ?.map(
                (item) => BodStorePerformanceEntry.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList() ??
          [],
      bottomStores:
          (json['bottomStores'] as List<dynamic>?)
              ?.map(
                (item) => BodStorePerformanceEntry.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList() ??
          [],
      categoryBreakdown: List<dynamic>.from(json['weaknesses'] ?? json['categoryBreakdown'] ?? []),
      apAging: BodApAging.fromDynamic(json['actionPlanAging'] ?? json['apAging']),
      auditorProductivity: List<dynamic>.from(
        json['auditorProductivity'] ?? [],
      ),
      computedAt: json['computedAt'] ?? '',
      snapshotStatus: json['status'] ?? json['snapshotStatus'] ?? '',
      allowedActions: List<dynamic>.from(json['allowedActions'] ?? []),
      goldenStore: json['goldenStore'] != null
          ? BodGoldenStore.fromJson(
              Map<String, dynamic>.from(json['goldenStore']),
            )
          : null,
    );
  }
}

class ApDetailEntry {
  final String id;
  final String criteriaLabel;
  final String storeName;
  final String managerName;
  final int ageInDays;

  ApDetailEntry({
    required this.id,
    required this.criteriaLabel,
    required this.storeName,
    required this.managerName,
    required this.ageInDays,
  });

  factory ApDetailEntry.fromJson(Map<String, dynamic> json) {
    return ApDetailEntry(
      id: json['id'] ?? '',
      criteriaLabel: json['criteriaLabel'] ?? '',
      storeName: json['storeName'] ?? '',
      managerName: json['managerName'] ?? '',
      ageInDays: json['ageInDays'] ?? json['overdueDays'] ?? 0,
    );
  }
}

class RecentAuditEntry {
  final String date;
  final double score;
  final String auditorName;

  RecentAuditEntry({
    required this.date,
    required this.score,
    required this.auditorName,
  });

  factory RecentAuditEntry.fromJson(Map<String, dynamic> json) {
    return RecentAuditEntry(
      date: json['date'] ?? '',
      score: (json['score'] ?? 0.0) is int
          ? (json['score'] as int).toDouble()
          : (json['score'] ?? 0.0).toDouble(),
      auditorName: json['auditorName'] ?? '',
    );
  }
}

class CategoryScoreEntry {
  final String categoryName;
  final double avgScore;

  CategoryScoreEntry({
    required this.categoryName,
    required this.avgScore,
  });

  factory CategoryScoreEntry.fromJson(Map<String, dynamic> json) {
    return CategoryScoreEntry(
      categoryName: json['categoryName'] ?? '',
      avgScore: (json['avgScore'] ?? 0.0) is int
          ? (json['avgScore'] as int).toDouble()
          : (json['avgScore'] ?? 0.0).toDouble(),
    );
  }
}

class StoreBodSummary {
  final String storeName;
  final List<RecentAuditEntry> recentAudits;
  final List<CategoryScoreEntry> categoryBreakdown;

  StoreBodSummary({
    required this.storeName,
    required this.recentAudits,
    required this.categoryBreakdown,
  });

  factory StoreBodSummary.fromJson(Map<String, dynamic> json) {
    return StoreBodSummary(
      storeName: json['storeName'] ?? '',
      recentAudits: (json['recentAudits'] as List<dynamic>?)
              ?.map((e) => RecentAuditEntry.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      categoryBreakdown: (json['categoryBreakdown'] as List<dynamic>?)
              ?.map((e) => CategoryScoreEntry.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }
}

class CategoryStoreEntry {
  final String storeName;
  final double avgScore;
  final int auditCount;
  final int failureCount;

  CategoryStoreEntry({
    required this.storeName,
    required this.avgScore,
    required this.auditCount,
    required this.failureCount,
  });

  factory CategoryStoreEntry.fromJson(Map<String, dynamic> json) {
    return CategoryStoreEntry(
      storeName: json['storeName'] ?? '',
      avgScore: (json['avgScore'] ?? 0.0) is int
          ? (json['avgScore'] as int).toDouble()
          : (json['avgScore'] ?? 0.0).toDouble(),
      auditCount: json['auditCount'] ?? 0,
      failureCount: json['failureCount'] ?? 0,
    );
  }
}

