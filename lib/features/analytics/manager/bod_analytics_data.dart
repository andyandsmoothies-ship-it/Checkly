import 'bod_analytics_models.dart';
export 'bod_analytics_models.dart';

class BodChainKpis {
  final int totalAudits;
  final double avgScore;
  final double avgTtrDays;
  final double completionRate;
  final int openAPs;
  final int overdueAPs;
  final int activeStores;
  final int totalAuditors;
  final int geofenceBypassCount;

  const BodChainKpis({
    required this.totalAudits,
    required this.avgScore,
    required this.avgTtrDays,
    this.completionRate = 0.0,
    this.openAPs = 0,
    this.overdueAPs = 0,
    this.activeStores = 0,
    this.totalAuditors = 0,
    this.geofenceBypassCount = 0,
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
      geofenceBypassCount: json['geofenceBypassCount'] ?? 0,
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
      'geofenceBypassCount': geofenceBypassCount,
    };
  }
}

class BodReportResponse {
  final BodChainKpis chainKpis;
  final List<dynamic> trend;
  final List<BodStorePerformanceEntry> topStores;
  final List<BodStorePerformanceEntry> bottomStores;
  final List<dynamic> categoryBreakdown;
  final BodApAging apAging;
  final List<BodAuditorEntry> auditorProductivity;
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
      categoryBreakdown: List<dynamic>.from(
        json['weaknesses'] ?? json['categoryBreakdown'] ?? [],
      ),
      apAging: BodApAging.fromDynamic(
        json['actionPlanAging'] ?? json['apAging'],
      ),
      auditorProductivity:
          (json['auditorProductivity'] as List<dynamic>?)
              ?.map(
                (item) =>
                    BodAuditorEntry.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList() ??
          [],
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

class StoreBodSummary {
  final String storeName;
  final List<RecentAuditEntry> recentAudits;
  final List<CategoryScoreEntry> categoryBreakdown;
  final String? quartileLabel;
  final double? regionalAvgScore;
  final List<SlaOverdueSegment>? slaOverdueBuckets;

  StoreBodSummary({
    required this.storeName,
    required this.recentAudits,
    required this.categoryBreakdown,
    this.quartileLabel,
    this.regionalAvgScore,
    this.slaOverdueBuckets,
  });

  factory StoreBodSummary.fromJson(Map<String, dynamic> json) {
    return StoreBodSummary(
      storeName: json['storeName'] ?? '',
      recentAudits:
          (json['recentAudits'] as List<dynamic>?)
              ?.map(
                (e) => RecentAuditEntry.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList() ??
          [],
      categoryBreakdown:
          (json['categoryBreakdown'] as List<dynamic>?)
              ?.map(
                (e) =>
                    CategoryScoreEntry.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList() ??
          [],
      quartileLabel: json['quartileLabel'],
      regionalAvgScore: json['regionalAvgScore'] != null
          ? (json['regionalAvgScore'] as num).toDouble()
          : null,
      slaOverdueBuckets: (json['slaOverdueBuckets'] as List<dynamic>?)
          ?.map((e) => SlaOverdueSegment.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

