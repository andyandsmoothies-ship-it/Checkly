import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../../../_shared/database/dao/notification_dao.dart';
import '../../../_shared/database/database_service.dart';
import '../model/notification_dto.dart';
import '../services/notification_api_service.dart';

final _di = GetIt.instance;

/// Manager for notifications — cache-first with delta sync.
///
/// Flow:
/// 1. Load from Drift cache immediately
/// 2. Background API fetch (full or delta via ?since=)
/// 3. Upsert into cache + update UI if changed
/// 4. Mark-as-read updates cache locally and syncs to server
class NotificationManager extends ChangeNotifier {
  final NotificationApiService _api;
  late final NotificationDao _dao;

  NotificationManager({NotificationApiService? api, NotificationDao? dao})
    : _api = api ?? _di<NotificationApiService>() {
    final db = _di<DatabaseService>().db;
    _dao = dao ?? NotificationDao(db);
  }

  // ---------- State ----------
  final ValueNotifier<List<NotificationDto>> notifications = ValueNotifier([]);

  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  String? _error;
  String? get error => _error;

  DateTime? _lastSyncAt;

  // ---------- Load (cache-first) ----------

  /// Load notifications: cache first, then delta refresh from API.
  Future<void> loadNotifications() async {
    isLoading.value = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Read from cache immediately
      final cached = await _dao.getAllNotifications();
      if (cached.isNotEmpty) {
        notifications.value = cached;
        _unreadCount = cached.where((n) => !n.isRead).length;
        notifyListeners();
      }

      // 2. Background API fetch (delta if we have a lastSync)
      try {
        final fresh = await _api.getNotifications(since: _lastSyncAt);
        if (fresh.isNotEmpty) {
          await _dao.upsertNotifications(fresh);
          _lastSyncAt = DateTime.now();
        }

        // 3. Re-read from cache to get merged view
        final merged = await _dao.getAllNotifications();
        notifications.value = merged;
        _unreadCount = merged.where((n) => !n.isRead).length;
      } catch (_) {
        // API failed — silently use cached data
      }
    } catch (e) {
      _error = 'Failed to load notifications';
    } finally {
      isLoading.value = false;
      notifyListeners();
    }
  }

  // ---------- Mark as read ----------

  /// Mark a notification as read — updates cache and sends to server.
  Future<void> markAsRead(String notificationId) async {
    final now = DateTime.now();

    // 1. Update local cache immediately (optimistic)
    await _dao.markAsRead(notificationId, now);

    // 2. Update in-memory state
    final updated = await _dao.getAllNotifications();
    notifications.value = updated;
    _unreadCount = updated.where((n) => !n.isRead).length;
    notifyListeners();

    // 3. Sync to server (fire and forget)
    try {
      await _api.markAsRead(notificationId);
    } catch (_) {
      // Offline — mark-read is persisted locally, will sync later
    }
  }

  /// Mark all notifications as read — updates cache and sends to server.
  Future<void> markAllRead() async {
    final now = DateTime.now();

    // 1. Update all unread in cache
    final unread = notifications.value.where((n) => !n.isRead).toList();
    for (final n in unread) {
      await _dao.markAsRead(n.id, now);
    }

    // 2. Update in-memory state
    final updated = await _dao.getAllNotifications();
    notifications.value = updated;
    _unreadCount = 0;
    notifyListeners();

    // 3. Sync to server
    try {
      await _api.markAllRead();
    } catch (_) {
      // Offline — local state already updated
    }
  }

  // ---------- Real-time push ----------

  /// Called when a SignalR push delivers a new notification.
  Future<void> onPushNotification(NotificationDto notification) async {
    await _dao.upsertNotifications([notification]);
    final updated = await _dao.getAllNotifications();
    notifications.value = updated;
    _unreadCount = updated.where((n) => !n.isRead).length;
    notifyListeners();
  }

  // ---------- Delta refresh (app resume) ----------

  /// Fetch only notifications since last sync — called on app resume.
  Future<void> refreshDelta() async {
    try {
      final fresh = await _api.getNotifications(since: _lastSyncAt);
      if (fresh.isNotEmpty) {
        await _dao.upsertNotifications(fresh);
        _lastSyncAt = DateTime.now();

        final updated = await _dao.getAllNotifications();
        notifications.value = updated;
        _unreadCount = updated.where((n) => !n.isRead).length;
        notifyListeners();
      }
    } catch (_) {
      // Offline — skip
    }
  }
}
