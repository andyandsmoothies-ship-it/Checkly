import 'package:flutter/material.dart' show DateTimeRange;

import '../../../_shared/database/app_database.dart';
import '../widgets/trend_chart.dart';
import '../widgets/category_heatmap.dart';
import 'analytics_data.dart';

/// Standalone offline loader — reads from Drift SQLite cache when the
/// API is unreachable. Extracted from [AnalyticsManager] to keep file
/// size under the 250-line limit.
///
/// Receives active filter state as plain parameters (no manager coupling).
Future<AnalyticsData> loadFromDrift({
  required AppDatabase db,
  required String? selectedProvince,
  required String? selectedStore,
  required String? selectedType,
  required String? selectedAuditor,
  required String? selectedStatus,
  required String? selectedReviewStatus,
  required String dateRange,
  required DateTimeRange? customDateRange,
}) async {
  final allSubs =
      await (db.select(db.cachedSubmissions)
            ..limit(1000)) // Bounded for memory safety (Gotcha #14)
          .get();
  var subs = allSubs.where((s) => s.reviewStatus != 'rejected').toList();

  final allStores =
      await (db.select(db.cachedStores)
            ..limit(1000)) // Bounded for memory safety (Gotcha #14)
          .get();
  final provinceNames =
      allStores
          .map((s) => s.addressProvince)
          .where((a) => a != null)
          .cast<String>()
          .toSet()
          .toList()
        ..sort();

  final filteredStores = selectedProvince != null
      ? allStores.where((s) => s.addressProvince == selectedProvince).toList()
      : allStores;

  var storeNames = filteredStores.map((s) => s.name).toSet().toList()..sort();

  final templates =
      await (db.select(db.cachedTemplates)
            ..limit(500)) // Bounded for memory safety (Gotcha #14)
          .get();
  final templateTypes = templates.map((t) => t.type).toSet().toList()..sort();
  final templateTypeMap = <String, String>{};
  for (final t in templates) {
    templateTypeMap[t.id] = t.type;
  }

  final auditorNames =
      subs
          .map((s) => s.auditorName)
          .where((a) => a != null)
          .cast<String>()
          .toSet()
          .toList()
        ..sort();

  if (selectedProvince != null) {
    final provinceStoreNames = filteredStores.map((s) => s.name).toSet();
    subs = subs.where((s) => provinceStoreNames.contains(s.storeName)).toList();
  }
  if (selectedStore != null) {
    subs = subs.where((s) => s.storeName == selectedStore).toList();
  }
  if (selectedType != null) {
    final typeTemplateIds = templates
        .where((t) => t.type == selectedType)
        .map((t) => t.id)
        .toSet();
    subs = subs.where((s) => typeTemplateIds.contains(s.templateId)).toList();
  }
  if (selectedAuditor != null) {
    subs = subs.where((s) => s.auditorName == selectedAuditor).toList();
  }
  if (selectedStatus != null) {
    subs = subs.where((s) => s.status == selectedStatus).toList();
  }
  if (selectedReviewStatus != null) {
    subs = subs.where((s) => s.reviewStatus == selectedReviewStatus).toList();
  }

  final now = DateTime.now();
  if (dateRange == 'custom' && customDateRange != null) {
    subs = subs
        .where(
          (s) =>
              s.createdAt.isAfter(customDateRange.start) &&
              s.createdAt.isBefore(
                customDateRange.end.add(const Duration(days: 1)),
              ),
        )
        .toList();
  } else if (dateRange != 'all') {
    final days = int.parse(dateRange);
    final cutoff = now.subtract(Duration(days: days));
    subs = subs.where((s) => s.createdAt.isAfter(cutoff)).toList();
  }



  final totalAudits = subs.length;
  final scored = subs.where((s) => s.totalScore != null).toList();
  final avgScore = scored.isNotEmpty
      ? scored.map((s) => s.totalScore!).reduce((a, b) => a + b) / scored.length
      : 0.0;

  final completed = subs.where((s) => s.status == 'completed').toList();
  final completionRate = totalAudits > 0
      ? completed.length / totalAudits * 100
      : 0.0;

  final aps =
      await (db.select(db.cachedActionPlans)
            ..limit(1000)) // Bounded for memory safety (Gotcha #14)
          .get();
  final openAPs = aps.where((ap) => ap.status == 'open').length;
  final overdueAPs = aps
      .where(
        (ap) =>
            ap.status == 'open' &&
            ap.deadline != null &&
            ap.deadline!.isBefore(now),
      )
      .length;

  final sixMonthsAgo = now.subtract(const Duration(days: 180));
  final recentSubs = subs
      .where((s) => s.totalScore != null && s.createdAt.isAfter(sixMonthsAgo))
      .toList();

  final grouped = <String, List<double>>{};
  for (final s in recentSubs) {
    final key =
        '${s.createdAt.year}-${s.createdAt.month.toString().padLeft(2, '0')}';
    grouped.putIfAbsent(key, () => []).add(s.totalScore!);
  }

  final monthKeys = List.generate(6, (i) {
    final d = DateTime(now.year, now.month - i);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}';
  }).reversed.toList();

  final trend = monthKeys.map((key) {
    final scores = grouped[key];
    if (scores != null && scores.isNotEmpty) {
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      return TrendPoint(key, avg, scores.length);
    }
    return TrendPoint(key, 0, 0);
  }).toList();

  final catScores = <String, List<double>>{};
  for (final s in subs) {
    final type = templateTypeMap[s.templateId];
    if (type != null && s.totalScore != null) {
      catScores.putIfAbsent(type, () => []).add(s.totalScore!);
    }
  }
  final categoryScores = catScores.entries.map((e) {
    final avg = e.value.reduce((a, b) => a + b) / e.value.length;
    return CategoryScore(
      name: e.key,
      avgScore: avg,
      auditCount: e.value.length,
    );
  }).toList();

  return AnalyticsData(
    totalAudits: totalAudits,
    avgScore: avgScore,
    openAPs: openAPs,
    overdueAPs: overdueAPs,
    completionRate: completionRate,
    trend: trend,
    categoryScores: categoryScores,
    storeNames: storeNames,
    templateTypes: templateTypes,
    provinceNames: provinceNames,
    auditorNames: auditorNames,
  );
}
