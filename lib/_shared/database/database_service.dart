import 'app_database.dart';

/// Singleton service wrapping the Drift [AppDatabase].
///
/// Registered in [configureDependencies] as a lazy singleton.
/// Provides the database instance to all managers and services.
class DatabaseService {
  late final AppDatabase _db;

  DatabaseService() {
    _db = AppDatabase();
  }

  /// For testing — accepts a custom database.
  DatabaseService.forTesting(AppDatabase db) : _db = db;

  /// The underlying Drift database instance.
  AppDatabase get db => _db;

  /// Closes the database connection.
  Future<void> close() async {
    await _db.close();
  }
}
