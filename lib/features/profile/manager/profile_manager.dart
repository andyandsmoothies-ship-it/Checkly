import 'package:drift/drift.dart' hide Column;
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../../../_shared/database/database_service.dart';
import '../../../_shared/exceptions/app_error.dart';
import '../../../_shared/services/error_display_service.dart';
import '../model/activity_item.dart';

final _di = GetIt.instance;

/// PFA Manager for the Activity History page.
///
/// Wraps the direct [DatabaseService] query from [ActivityHistoryPage]
/// into a proper Manager layer. The UI observes [isLoading], [error],
/// and [items].
class ProfileManager extends ChangeNotifier {
  ProfileManager({DatabaseService? db}) : _db = db ?? _di<DatabaseService>();

  final DatabaseService _db;

  // ---------- State ----------
  bool isLoading = false;
  List<ActivityItem> items = [];

  // ---------- Load ----------
  /// Loads the user's activity from the local Drift cache.
  Future<void> loadActivity() async {
    isLoading = true;
    notifyListeners();

    try {
      final subs =
          await (_db.db.select(_db.db.cachedSubmissions)
                ..orderBy([(s) => OrderingTerm.desc(s.createdAt)])
                ..limit(500)) // Bounded to 500 for memory safety (Gotcha #14)
              .get();

      items =
          subs
              .map(
                (s) => ActivityItem(
                  id: s.id,
                  storeName: s.storeName ?? 'Unknown Store',
                  templateTitle: s.templateTitle ?? 'Audit',
                  status: s.status,
                  score: s.totalScore,
                  date: s.createdAt,
                ),
              )
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));
    } catch (_) {
      _di<ErrorDisplayService>().show(AppError(code: 'unknown'));
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
