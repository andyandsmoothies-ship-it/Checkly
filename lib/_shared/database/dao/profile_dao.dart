import 'package:drift/drift.dart';

import '../app_database.dart';
import '../../constants/user_persona.dart';

class ProfileSyncSnapshot {
  final String profileId;
  final String? fullName;
  final String? email;
  final String? role;
  final List<String> assignedStoreIds;

  const ProfileSyncSnapshot({
    required this.profileId,
    this.fullName,
    this.email,
    this.role,
    this.assignedStoreIds = const [],
  });
}

/// DAO for storing and reading synchronized profile data.
class ProfileDao {
  final AppDatabase _db;

  ProfileDao(this._db);

  Future<void> upsertProfile(ProfileSyncSnapshot snapshot) async {
    final serialized = _serializeStoreIds(snapshot.assignedStoreIds);
    await _db
        .into(_db.cachedProfiles)
        .insertOnConflictUpdate(
          CachedProfilesCompanion(
            profileId: Value(snapshot.profileId),
            fullName: Value(snapshot.fullName),
            email: Value(snapshot.email),
            role: Value(snapshot.role),
            assignedStoreOverrides: Value(serialized),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<List<String>> getAssignedStoreIdsForRole(String role) async {
    if (UserPersona.fromRole(role) != UserPersona.areaManager) return const [];
    final row =
        await (_db.select(_db.cachedProfiles)
              ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
              ..limit(1))
            .getSingleOrNull();
    if (row == null) return const [];
    return _deserializeStoreIds(row.assignedStoreOverrides);
  }

  Future<void> clearProfiles() async {
    await _db.delete(_db.cachedProfiles).go();
  }

  static String? _serializeStoreIds(List<String> ids) {
    final normalized =
        ids.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList()
          ..sort();
    if (normalized.isEmpty) return null;
    return normalized.join(',');
  }

  static List<String> _deserializeStoreIds(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  }
}
