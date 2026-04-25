import 'package:drift/drift.dart';

import '../app_database.dart';
import '../../../features/notifications/model/notification_dto.dart';

/// DAO for cached notifications in Drift.
class NotificationDao {
  final AppDatabase _db;

  NotificationDao(this._db);

  /// Read all cached notifications, newest first.
  Future<List<NotificationDto>> getAllNotifications() async {
    final rows =
        await (_db.select(_db.cachedNotifications)
              ..orderBy([(n) => OrderingTerm.desc(n.createdAt)])
              ..limit(500))
            .get();
    return rows.map(_rowToDto).toList();
  }

  /// Count of unread notifications.
  Future<int> unreadCount() async {
    final countExp = countAll();
    final query = _db.selectOnly(_db.cachedNotifications)
      ..addColumns([countExp])
      ..where(_db.cachedNotifications.readAt.isNull());
    return await query.map((row) => row.read(countExp)).getSingle() ?? 0;
  }

  /// Upsert a batch of notifications into cache.
  Future<void> upsertNotifications(List<NotificationDto> notifications) async {
    await _db.batch((b) {
      b.insertAllOnConflictUpdate(
        _db.cachedNotifications,
        notifications.map(_dtoToCompanion).toList(),
      );
    });
  }

  /// Mark a single notification as read in the local cache.
  Future<void> markAsRead(String id, DateTime readAt) async {
    await (_db.update(_db.cachedNotifications)..where((n) => n.id.equals(id)))
        .write(CachedNotificationsCompanion(readAt: Value(readAt)));
  }

  // ---------- Mapping ----------

  NotificationDto _rowToDto(CachedNotification row) => NotificationDto(
    id: row.id,
    userId: row.userId,
    type: row.type,
    title: row.title,
    message: row.message,
    readAt: row.readAt,
    actionUrl: row.actionUrl,
    metadata: row.metadata,
    createdAt: row.createdAt,
  );

  CachedNotificationsCompanion _dtoToCompanion(NotificationDto dto) =>
      CachedNotificationsCompanion.insert(
        id: dto.id,
        userId: dto.userId,
        type: dto.type,
        title: dto.title,
        message: Value(dto.message),
        readAt: Value(dto.readAt),
        actionUrl: Value(dto.actionUrl),
        metadata: Value(dto.metadata),
        createdAt: dto.createdAt,
      );
}
