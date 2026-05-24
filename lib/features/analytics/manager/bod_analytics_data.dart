class BodChainKpis {
  final int totalAudits;
  final double avgScore;
  final double avgTtrDays;
  final double completionRate;
  final int openAPs;
  final int overdueAPs;

  const BodChainKpis({
    required this.totalAudits,
    required this.avgScore,
    required this.avgTtrDays,
    this.completionRate = 0.0,
    this.openAPs = 0,
    this.overdueAPs = 0,
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
  final int bucket0to30;
  final int bucket31to60;
  final int bucket61to90;
  final int bucket90Plus;

  const BodApAging({
    required this.bucket0to30,
    required this.bucket31to60,
    required this.bucket61to90,
    required this.bucket90Plus,
  });

  factory BodApAging.fromJson(Map<String, dynamic> json) {
    return BodApAging(
      bucket0to30: json['bucket0to30'] ?? 0,
      bucket31to60: json['bucket31to60'] ?? 0,
      bucket61to90: json['bucket61to90'] ?? 0,
      bucket90Plus: json['bucket90Plus'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '0-30': bucket0to30,
      '31-60': bucket31to60,
      '61-90': bucket61to90,
      '90+': bucket90Plus,
    };
  }
}

class BodGoldenStore {
  final String storeId;
  final String storeName;
  final double avgScore;

  BodGoldenStore({
    required this.storeId,
    required this.storeName,
    required this.avgScore,
  });

  factory BodGoldenStore.fromJson(Map<String, dynamic> json) {
    return BodGoldenStore(
      storeId: json['storeId'] ?? '',
      storeName: json['storeName'] ?? '',
      avgScore: (json['avgScore'] ?? 0.0) is int
          ? (json['avgScore'] as int).toDouble()
          : (json['avgScore'] ?? 0.0).toDouble(),
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
        Map<String, dynamic>.from(json['chainKpis'] ?? {}),
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
      categoryBreakdown: List<dynamic>.from(json['categoryBreakdown'] ?? []),
      apAging: BodApAging.fromJson(
        Map<String, dynamic>.from(json['apAging'] ?? {}),
      ),
      auditorProductivity: List<dynamic>.from(
        json['auditorProductivity'] ?? [],
      ),
      computedAt: json['computedAt'] ?? '',
      snapshotStatus: json['snapshotStatus'] ?? '',
      allowedActions: List<dynamic>.from(json['allowedActions'] ?? []),
      goldenStore: json['goldenStore'] != null
          ? BodGoldenStore.fromJson(
              Map<String, dynamic>.from(json['goldenStore']),
            )
          : null,
    );
  }
}
