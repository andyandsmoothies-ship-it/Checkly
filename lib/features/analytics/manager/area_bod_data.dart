class AreaBodKpis {
  final int totalAudits;
  final double avgScore;
  final double completionRate;
  final int openActionPlans;
  final int overdueActionPlans;
  final int activeStores;
  final int totalAuditors;
  final double avgTtrDays;

  AreaBodKpis({
    required this.totalAudits,
    required this.avgScore,
    required this.completionRate,
    required this.openActionPlans,
    required this.overdueActionPlans,
    required this.activeStores,
    required this.totalAuditors,
    required this.avgTtrDays,
  });

  factory AreaBodKpis.fromJson(Map<String, dynamic> json) {
    return AreaBodKpis(
      totalAudits: json['totalAudits'] ?? 0,
      avgScore: (json['avgScore'] ?? 0.0) is int
          ? (json['avgScore'] as int).toDouble()
          : (json['avgScore'] ?? 0.0).toDouble(),
      completionRate: (json['completionRate'] ?? 0.0) is int
          ? (json['completionRate'] as int).toDouble()
          : (json['completionRate'] ?? 0.0).toDouble(),
      openActionPlans: json['openActionPlans'] ?? 0,
      overdueActionPlans: json['overdueActionPlans'] ?? 0,
      activeStores: json['activeStores'] ?? 0,
      totalAuditors: json['totalAuditors'] ?? 0,
      avgTtrDays: (json['avgTtrDays'] ?? 0.0) is int
          ? (json['avgTtrDays'] as int).toDouble()
          : (json['avgTtrDays'] ?? 0.0).toDouble(),
    );
  }

  factory AreaBodKpis.zero() {
    return AreaBodKpis(
      totalAudits: 0,
      avgScore: 0.0,
      completionRate: 0.0,
      openActionPlans: 0,
      overdueActionPlans: 0,
      activeStores: 0,
      totalAuditors: 0,
      avgTtrDays: 0.0,
    );
  }
}

class AreaGoldenStore {
  final String storeName;
  final double avgScore;
  final String province;

  AreaGoldenStore({
    required this.storeName,
    required this.avgScore,
    required this.province,
  });

  factory AreaGoldenStore.fromJson(Map<String, dynamic> json) {
    return AreaGoldenStore(
      storeName: json['storeName'] ?? '',
      avgScore: (json['avgScore'] ?? 0.0) is int
          ? (json['avgScore'] as int).toDouble()
          : (json['avgScore'] ?? 0.0).toDouble(),
      province: json['province'] ?? '',
    );
  }
}

class AreaTrendPoint {
  final String month;
  final double avgScore;
  final int auditCount;

  AreaTrendPoint({
    required this.month,
    required this.avgScore,
    required this.auditCount,
  });

  factory AreaTrendPoint.fromJson(Map<String, dynamic> json) {
    return AreaTrendPoint(
      month: json['month'] ?? '',
      avgScore: (json['avgScore'] ?? 0.0) is int
          ? (json['avgScore'] as int).toDouble()
          : (json['avgScore'] ?? 0.0).toDouble(),
      auditCount: json['auditCount'] ?? 0,
    );
  }
}

class AreaStoreRankEntry {
  final String storeId;
  final String storeName;
  final double avgScore;
  final int auditCount;
  final String? lastSyncedAt;

  AreaStoreRankEntry({
    required this.storeId,
    required this.storeName,
    required this.avgScore,
    required this.auditCount,
    this.lastSyncedAt,
  });

  factory AreaStoreRankEntry.fromJson(Map<String, dynamic> json) {
    return AreaStoreRankEntry(
      storeId: json['storeId'] ?? '',
      storeName: json['storeName'] ?? '',
      avgScore: (json['avgScore'] ?? 0.0) is int
          ? (json['avgScore'] as int).toDouble()
          : (json['avgScore'] ?? 0.0).toDouble(),
      auditCount: json['auditCount'] ?? 0,
      lastSyncedAt: json['lastSyncedAt'],
    );
  }
}

class AreaCategoryWeakness {
  final String categoryName;
  final String templateName;
  final double avgScore;
  final int auditCount;

  AreaCategoryWeakness({
    required this.categoryName,
    required this.templateName,
    required this.avgScore,
    required this.auditCount,
  });

  factory AreaCategoryWeakness.fromJson(Map<String, dynamic> json) {
    return AreaCategoryWeakness(
      categoryName: json['categoryName'] ?? '',
      templateName: json['templateName'] ?? '',
      avgScore: (json['avgScore'] ?? 0.0) is int
          ? (json['avgScore'] as int).toDouble()
          : (json['avgScore'] ?? 0.0).toDouble(),
      auditCount: json['auditCount'] ?? 0,
    );
  }
}

class AreaApAgingBucket {
  final String bucket;
  final int count;

  AreaApAgingBucket({
    required this.bucket,
    required this.count,
  });

  factory AreaApAgingBucket.fromJson(Map<String, dynamic> json) {
    return AreaApAgingBucket(
      bucket: json['bucket'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class AreaAuditorProductivity {
  final String auditorName;
  final int completedCount;
  final double avgScore;

  AreaAuditorProductivity({
    required this.auditorName,
    required this.completedCount,
    required this.avgScore,
  });

  factory AreaAuditorProductivity.fromJson(Map<String, dynamic> json) {
    return AreaAuditorProductivity(
      auditorName: json['auditorName'] ?? '',
      completedCount: json['completedCount'] ?? json['completedAudits'] ?? 0,
      avgScore: (json['avgScore'] ?? 0.0) is int
          ? (json['avgScore'] as int).toDouble()
          : (json['avgScore'] ?? 0.0).toDouble(),
    );
  }
}

class AreaBodResponse {
  final bool isLiveData;
  final AreaBodKpis kpis;
  final AreaGoldenStore? goldenStore;
  final List<AreaTrendPoint> trend;
  final List<AreaStoreRankEntry> topStores;
  final List<AreaStoreRankEntry> bottomStores;
  final List<AreaCategoryWeakness> weaknesses;
  final List<AreaApAgingBucket> actionPlanAging;
  final List<AreaAuditorProductivity> auditorProductivity;
  final List<String> allowedActions;

  AreaBodResponse({
    required this.isLiveData,
    required this.kpis,
    this.goldenStore,
    required this.trend,
    required this.topStores,
    required this.bottomStores,
    required this.weaknesses,
    required this.actionPlanAging,
    required this.auditorProductivity,
    required this.allowedActions,
  });

  factory AreaBodResponse.fromJson(Map<String, dynamic> json) {
    return AreaBodResponse(
      isLiveData: json['isLiveData'] ?? true,
      kpis: AreaBodKpis.fromJson(
        Map<String, dynamic>.from(json['kpis'] ?? {}),
      ),
      goldenStore: json['goldenStore'] != null
          ? AreaGoldenStore.fromJson(
              Map<String, dynamic>.from(json['goldenStore']),
            )
          : null,
      trend: (json['trend'] as List<dynamic>?)
              ?.map((e) => AreaTrendPoint.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      topStores: (json['topStores'] as List<dynamic>?)
              ?.map((e) => AreaStoreRankEntry.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      bottomStores: (json['bottomStores'] as List<dynamic>?)
              ?.map((e) => AreaStoreRankEntry.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      weaknesses: (json['weaknesses'] as List<dynamic>?)
              ?.map((e) => AreaCategoryWeakness.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      actionPlanAging: (json['actionPlanAging'] as List<dynamic>?)
              ?.map((e) => AreaApAgingBucket.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      auditorProductivity: (json['auditorProductivity'] as List<dynamic>?)
              ?.map((e) => AreaAuditorProductivity.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      allowedActions: (json['allowedActions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
