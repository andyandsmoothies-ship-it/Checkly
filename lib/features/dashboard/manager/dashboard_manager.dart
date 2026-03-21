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
  final int overdueActionPlanCount;
  final int unreadNotificationCount;
  final int weakStoreCount;
  final DateTime? nearestDeadline;
  final int monthlyCompleted;
  final int monthlyTotal;
  final List<CachedSubmission> recentSubmissions;

  const DashboardStats({
    this.recentAuditCount = 0,
    this.averageScore = 0,
    this.pendingActionPlanCount = 0,
    this.overdueActionPlanCount = 0,
    this.unreadNotificationCount = 0,
    this.weakStoreCount = 0,
    this.nearestDeadline,
    this.monthlyCompleted = 0,
    this.monthlyTotal = 0,
    this.recentSubmissions = const [],
  });
}

/// Manager for the dashboard — reads stats from local Drift cache.
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
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);

      // ── Submissions ──
      final allSubmissions = await _db.select(_db.cachedSubmissions).get();
      // C8: Exclude rejected audits from all dashboard metrics
      final submissions = allSubmissions
          .where((s) => s.reviewStatus != 'rejected')
          .toList();
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

      // Monthly completed (this month)
      final monthlyCompleted = submissions
          .where(
            (s) => s.status == 'completed' && s.createdAt.isAfter(monthStart),
          )
          .length;

      // Weak stores
      int weakStoreCount = 0;
      final storeScores = <String, List<double>>{};
      for (final s in submissions) {
        if (s.storeId != null && s.totalScore != null) {
          storeScores.putIfAbsent(s.storeId!, () => []).add(s.totalScore!);
        }
      }
      weakStoreCount = storeScores.entries.where((e) {
        final avg = e.value.reduce((a, b) => a + b) / e.value.length;
        return avg < 80;
      }).length;

      // Monthly total = templates × stores (active audit plan targets)
      final templates = await _db.select(_db.cachedTemplates).get();
      final stores = await _db.select(_db.cachedStores).get();
      final monthlyTotal = templates.length * stores.length;

      // ── Recent submissions for the feed (top 5, sorted by createdAt) ──
      final sortedSubs = List.of(submissions)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final recentSubs = sortedSubs.take(5).toList();

      // ── Action Plans ──
      final openPlans = await (_db.select(
        _db.cachedActionPlans,
      )..where((a) => a.status.isIn(['open', 'pending_verify']))).get();

      final overduePlans = openPlans
          .where(
            (p) =>
                p.status == 'open' &&
                p.deadline != null &&
                p.deadline!.isBefore(now),
          )
          .length;

      DateTime? nearestDeadline;
      for (final p in openPlans) {
        if (p.deadline != null && p.deadline!.isAfter(now)) {
          if (nearestDeadline == null ||
              p.deadline!.isBefore(nearestDeadline)) {
            nearestDeadline = p.deadline;
          }
        }
      }

      // ── Notifications ──
      final unreadNotifications = await (_db.select(
        _db.cachedNotifications,
      )..where((n) => n.readAt.isNull())).get();

      _stats = DashboardStats(
        recentAuditCount: recentCount,
        averageScore: double.parse(avgScore.toStringAsFixed(1)),
        pendingActionPlanCount: openPlans.length,
        overdueActionPlanCount: overduePlans,
        unreadNotificationCount: unreadNotifications.length,
        weakStoreCount: weakStoreCount,
        nearestDeadline: nearestDeadline,
        monthlyCompleted: monthlyCompleted,
        monthlyTotal: monthlyTotal > 0 ? monthlyTotal : 1,
        recentSubmissions: recentSubs,
      );
    } catch (_) {
      // If cache is empty or DB not ready, use defaults
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
