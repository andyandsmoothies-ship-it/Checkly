import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:get_it/get_it.dart';

import '../../../_shared/database/app_database.dart';
import '../../../_shared/database/database_service.dart';
import '../widgets/trend_chart.dart';
import '../widgets/category_heatmap.dart';

final _di = GetIt.instance;

/// Holds the fully-computed analytics snapshot after a [load] call.
class AnalyticsData {
  final int totalAudits;
  final double avgScore;
  final int openAPs;
  final int overdueAPs;
  final double completionRate;
  final List<TrendPoint> trend;
  final List<CategoryScore> categoryScores;
  final List<String> storeNames;
  final List<String> templateTypes;
  final List<String> areaNames;
  final List<String> auditorNames;

  const AnalyticsData({
    required this.totalAudits,
    required this.avgScore,
    required this.openAPs,
    required this.overdueAPs,
    required this.completionRate,
    required this.trend,
    required this.categoryScores,
    required this.storeNames,
    required this.templateTypes,
    required this.areaNames,
    required this.auditorNames,
  });
}

/// PFA Manager for the Analytics page.
///
/// Wraps all direct [AppDatabase] queries from the old [AnalyticsPage]
/// into a proper Manager layer. The UI simply calls [load()] and observes
/// [isLoading], [error], and [data].
class AnalyticsManager extends ChangeNotifier {
  final AppDatabase _db;

  AnalyticsManager({AppDatabase? db}) : _db = db ?? _di<DatabaseService>().db;

  // ---------- State ----------
  bool isLoading = false;
  String? error;
  AnalyticsData? data;

  // ---------- Active Filters ----------
  String? selectedStore;
  String? selectedType;
  String? selectedArea;
  String? selectedAuditor;
  String? selectedStatus;
  String? selectedReviewStatus;
  String dateRange = 'all'; // all, 30, 90, 180, custom
  DateTimeRange? customDateRange;

  // ---------- Load ----------
  /// Runs all DB queries and computes KPIs. Call on page init and on filter changes.
  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final allSubs =
          await (_db.select(_db.cachedSubmissions)
                ..limit(1000)) // Bounded for memory safety (Gotcha #14)
              .get();
      var subs = allSubs.where((s) => s.reviewStatus != 'rejected').toList();

      final allStores =
          await (_db.select(_db.cachedStores)
                ..limit(1000)) // Bounded for memory safety (Gotcha #14)
              .get();
      final areaNames =
          allStores
              .map((s) => s.areaName)
              .where((a) => a != null)
              .cast<String>()
              .toSet()
              .toList()
            ..sort();

      final filteredStores = selectedArea != null
          ? allStores.where((s) => s.areaName == selectedArea).toList()
          : allStores;

      var storeNames = filteredStores.map((s) => s.name).toSet().toList()
        ..sort();

      // Reset store if it's no longer valid after area change
      if (selectedStore != null && !storeNames.contains(selectedStore)) {
        selectedStore = null;
      }

      final templates =
          await (_db.select(_db.cachedTemplates)
                ..limit(500)) // Bounded for memory safety (Gotcha #14)
              .get();
      final templateTypes = templates.map((t) => t.type).toSet().toList()
        ..sort();
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

      // ── Apply filters ──
      if (selectedArea != null) {
        final areaStoreNames = filteredStores.map((s) => s.name).toSet();
        subs = subs.where((s) => areaStoreNames.contains(s.storeName)).toList();
      }
      if (selectedStore != null) {
        subs = subs.where((s) => s.storeName == selectedStore).toList();
      }
      if (selectedType != null) {
        final typeTemplateIds = templates
            .where((t) => t.type == selectedType)
            .map((t) => t.id)
            .toSet();
        subs = subs
            .where((s) => typeTemplateIds.contains(s.templateId))
            .toList();
      }
      if (selectedAuditor != null) {
        subs = subs.where((s) => s.auditorName == selectedAuditor).toList();
      }
      if (selectedStatus != null) {
        subs = subs.where((s) => s.status == selectedStatus).toList();
      }
      if (selectedReviewStatus != null) {
        subs = subs
            .where((s) => s.reviewStatus == selectedReviewStatus)
            .toList();
      }

      final now = DateTime.now();
      if (dateRange == 'custom' && customDateRange != null) {
        subs = subs
            .where(
              (s) =>
                  s.createdAt.isAfter(customDateRange!.start) &&
                  s.createdAt.isBefore(
                    customDateRange!.end.add(const Duration(days: 1)),
                  ),
            )
            .toList();
      } else if (dateRange != 'all') {
        final days = int.parse(dateRange);
        final cutoff = now.subtract(Duration(days: days));
        subs = subs.where((s) => s.createdAt.isAfter(cutoff)).toList();
      }

      // ── KPIs ──
      final totalAudits = subs.length;
      final scored = subs.where((s) => s.totalScore != null).toList();
      final avgScore = scored.isNotEmpty
          ? scored.map((s) => s.totalScore!).reduce((a, b) => a + b) /
                scored.length
          : 0.0;

      final completed = subs.where((s) => s.status == 'completed').toList();
      final completionRate = totalAudits > 0
          ? completed.length / totalAudits * 100
          : 0.0;

      final aps =
          await (_db.select(_db.cachedActionPlans)
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

      // ── 6-month trend ──
      final sixMonthsAgo = now.subtract(const Duration(days: 180));
      final recentSubs = subs
          .where(
            (s) => s.totalScore != null && s.createdAt.isAfter(sixMonthsAgo),
          )
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

      // ── Category heatmap ──
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

      data = AnalyticsData(
        totalAudits: totalAudits,
        avgScore: avgScore,
        openAPs: openAPs,
        overdueAPs: overdueAPs,
        completionRate: completionRate,
        trend: trend,
        categoryScores: categoryScores,
        storeNames: storeNames,
        templateTypes: templateTypes,
        areaNames: areaNames,
        auditorNames: auditorNames,
      );
    } catch (e) {
      error = 'Failed to load analytics';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
