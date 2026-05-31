import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';

import '../../../_shared/database/app_database.dart';
import '../../../_shared/database/database_service.dart';
import '../widgets/trend_chart.dart';
import '../widgets/category_heatmap.dart';
import '../services/analytics_api_service.dart';
import 'analytics_data.dart';
import 'analytics_drift_loader.dart';

final _di = GetIt.instance;

/// PFA Manager for the Analytics page.
///
/// Wraps all direct [AppDatabase] queries and API calls into a proper
/// Manager layer. The UI simply calls [load()] and observes [isLoading],
/// [error], and [data].
///
/// Data classes ([AnalyticsData], [ActionableInsight], [RadarData]) live
/// in `analytics_data.dart`. The offline Drift loader lives in
/// `analytics_drift_loader.dart`.
class AnalyticsManager extends ChangeNotifier {
  final AppDatabase _db;
  late final AnalyticsApiService _api;

  AnalyticsManager({AppDatabase? db, AnalyticsApiService? apiService})
    : _db = db ?? _di<DatabaseService>().db {
    _api = apiService ?? _di<AnalyticsApiService>();
  }

  // ---------- State ----------
  bool isLoading = false;
  String? error;
  AnalyticsData? data;
  bool isOffline = false;

  // ---------- Active Filters ----------
  String? selectedStore;
  String? selectedType;
  String? selectedProvince;
  String? selectedAuditor;
  String? selectedStatus;
  String? selectedReviewStatus;
  String dateRange = 'all'; // all, 30, 90, 180, custom
  DateTimeRange? customDateRange;

  // ---------- Filter Setters ----------
  /// Sets the date range and notifies listeners synchronously so chip
  /// selected state updates in the same frame before [load()] begins.
  void setDateRange(String range, {DateTimeRange? custom}) {
    dateRange = range;
    customDateRange = custom;
    notifyListeners();
    load();
  }

  /// Runs all DB queries and computes KPIs. Call on page init and on filter changes.
  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final allStores = await (_db.select(_db.cachedStores)..limit(1000)).get();
      String? storeId;
      if (selectedStore != null) {
        try {
          storeId = allStores.firstWhere((s) => s.name == selectedStore).id;
        } catch (_) {}
      }
      String? province = selectedProvince;

      String? startDate;
      String? endDate;
      final now = DateTime.now();
      if (dateRange == 'custom' && customDateRange != null) {
        startDate = customDateRange!.start.toIso8601String();
        endDate = customDateRange!.end
            .add(const Duration(days: 1))
            .toIso8601String();
      } else if (dateRange != 'all') {
        final days = int.parse(dateRange);
        startDate = now.subtract(Duration(days: days)).toIso8601String();
        endDate = now.toIso8601String();
      }

      final json = await _api.getAnalytics(
        storeId: storeId,
        province: province,
        startDate: startDate,
        endDate: endDate,
      );

      isOffline = false;

      // Extract filter list values from Drift (must populate for UI)
      final allSubs = await (_db.select(
        _db.cachedSubmissions,
      )..limit(1000)).get();
      var subs = allSubs.where((s) => s.reviewStatus != 'rejected').toList();
      final provinceNames =
          allStores
              .map((s) => s.addressProvince)
              .where((a) => a != null)
              .cast<String>()
              .toSet()
              .toList()
            ..sort();
      final filteredStores = selectedProvince != null
          ? allStores
                .where((s) => s.addressProvince == selectedProvince)
                .toList()
          : allStores;
      var storeNames = filteredStores.map((s) => s.name).toSet().toList()
        ..sort();
      final templates = await (_db.select(
        _db.cachedTemplates,
      )..limit(500)).get();
      final templateTypes = templates.map((t) => t.type).toSet().toList()
        ..sort();
      final auditorNames =
          subs
              .map((s) => s.auditorName)
              .where((a) => a != null)
              .cast<String>()
              .toSet()
              .toList()
            ..sort();

      final trendList = (json['trend'] as List<dynamic>?) ?? [];
      final trend = trendList
          .map(
            (e) => TrendPoint(
              e['month'] as String,
              (e['avgScore'] as num).toDouble(),
              e['count'] as int,
            ),
          )
          .toList();

      final catList = (json['categoryScores'] as List<dynamic>?) ?? [];
      final categoryScores = catList
          .map(
            (e) => CategoryScore(
              name: e['name'] as String,
              avgScore: (e['avgScore'] as num).toDouble(),
              auditCount: e['auditCount'] as int,
            ),
          )
          .toList();

      // Parse insights and radarData from the API response. radarData is only
      // accepted when it has at least 3 categories (enough to draw a polygon).
      final insightsList = (json['insights'] as List<dynamic>?) ?? [];
      final insights = insightsList
          .map((e) => ActionableInsight.fromJson(e as Map<String, dynamic>))
          .toList();

      RadarData? radarData;
      final radarJson = json['radarData'] as Map<String, dynamic>?;
      if (radarJson != null) {
        final candidate = RadarData.fromJson(radarJson);
        if (candidate.categories.length >= 3) {
          radarData = candidate;
        }
      }
      // ──────────────────────────────────────────────────────────────────────


      final kpis = (json['kpis'] as Map<String, dynamic>?) ?? {};
      data = AnalyticsData(
        totalAudits: kpis['totalAudits'] ?? 0,
        avgScore: (kpis['avgScore'] as num?)?.toDouble() ?? 0.0,
        openAPs: kpis['openAPs'] ?? 0,
        overdueAPs: kpis['overdueAPs'] ?? 0,
        completionRate: (kpis['completionRate'] as num?)?.toDouble() ?? 0.0,
        trend: trend,
        categoryScores: categoryScores,
        storeNames: storeNames,
        templateTypes: templateTypes,
        provinceNames: provinceNames,
        auditorNames: auditorNames,
        insights: insights,
        radarData: radarData,
        insightsStale: json['insightsStale'] ?? false,
      );
    } on DioException catch (_) {
      isOffline = true;
      data = await loadFromDrift(
        db: _db,
        selectedProvince: selectedProvince,
        selectedStore: selectedStore,
        selectedType: selectedType,
        selectedAuditor: selectedAuditor,
        selectedStatus: selectedStatus,
        selectedReviewStatus: selectedReviewStatus,
        dateRange: dateRange,
        customDateRange: customDateRange,
      );
    } catch (e) {
      error = 'Failed to load analytics';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
