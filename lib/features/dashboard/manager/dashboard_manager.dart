import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../../../_shared/database/database_service.dart';
import '../../../_shared/database/app_database.dart';

final _di = GetIt.instance;

/// Dashboard statistics computed from the local Drift cache.
class DashboardStats {
  final int recentAuditCount;
  final double averageScore;
  final int pendingActionPlanCount;
  final int unreadNotificationCount;

  const DashboardStats({
    this.recentAuditCount = 0,
    this.averageScore = 0,
    this.pendingActionPlanCount = 0,
    this.unreadNotificationCount = 0,
  });
}

/// Manager for the dashboard — reads stats from local Drift cache.
///
/// No API calls needed — all data comes from previously cached tables:
/// - CachedSubmissions → recent audit count + average score
/// - CachedActionPlans → pending (open) action plans count
/// - CachedNotifications → unread notification count
class DashboardManager extends ChangeNotifier {
  late final AppDatabase _db;

  DashboardManager({AppDatabase? db}) {
    _db = db ?? _di<DatabaseService>().db;
  }

  DashboardStats _stats = const DashboardStats();
  DashboardStats get stats => _stats;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Load dashboard stats from local Drift cache.
  Future<void> loadStats() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Recent audit count (all cached submissions)
      final submissions = await _db.select(_db.cachedSubmissions).get();
      final recentCount = submissions.length;

      // Average score
      double avgScore = 0;
      if (submissions.isNotEmpty) {
        final scores = submissions
            .where((s) => s.totalScore != null)
            .map((s) => s.totalScore!)
            .toList();
        if (scores.isNotEmpty) {
          avgScore = scores.reduce((a, b) => a + b) / scores.length;
        }
      }

      // Pending action plans (status == 'open' or 'pending_verify')
      final actionPlans = await (_db.select(
        _db.cachedActionPlans,
      )..where((a) => a.status.isIn(['open', 'pending_verify']))).get();

      // Unread notifications
      final unreadNotifications = await (_db.select(
        _db.cachedNotifications,
      )..where((n) => n.readAt.isNull())).get();

      _stats = DashboardStats(
        recentAuditCount: recentCount,
        averageScore: double.parse(avgScore.toStringAsFixed(1)),
        pendingActionPlanCount: actionPlans.length,
        unreadNotificationCount: unreadNotifications.length,
      );
    } catch (_) {
      // If cache is empty or DB not ready, use defaults
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
