class BodReportResponse {
  final Map<String, dynamic> chainKpis;
  final List<dynamic> trend;
  final List<dynamic> topStores;
  final List<dynamic> bottomStores;
  final List<dynamic> categoryBreakdown;
  final Map<String, dynamic> apAging;
  final List<dynamic> auditorProductivity;
  final String computedAt;
  final String snapshotStatus;
  final List<dynamic> allowedActions;

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
  });

  factory BodReportResponse.fromJson(Map<String, dynamic> json) {
    return BodReportResponse(
      chainKpis: Map<String, dynamic>.from(json['chainKpis'] ?? {}),
      trend: List<dynamic>.from(json['trend'] ?? []),
      topStores: List<dynamic>.from(json['topStores'] ?? []),
      bottomStores: List<dynamic>.from(json['bottomStores'] ?? []),
      categoryBreakdown: List<dynamic>.from(json['categoryBreakdown'] ?? []),
      apAging: Map<String, dynamic>.from(json['apAging'] ?? {}),
      auditorProductivity: List<dynamic>.from(json['auditorProductivity'] ?? []),
      computedAt: json['computedAt'] ?? '',
      snapshotStatus: json['snapshotStatus'] ?? '',
      allowedActions: List<dynamic>.from(json['allowedActions'] ?? []),
    );
  }
}
