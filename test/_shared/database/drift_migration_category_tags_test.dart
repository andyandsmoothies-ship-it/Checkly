import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';

import 'package:checkly/_shared/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Drift Database - Version 31 Schema Migration for categoryTags', () {
    test('TC-GAP-02: Schema migration preserves legacy rows and version is 31', () async {
      // 1. Assert schema version is 31
      expect(db.schemaVersion, 31);

      // 2. Insert a template
      await db.into(db.cachedTemplates).insert(
        CachedTemplatesCompanion.insert(
          id: 'temp-migration',
          title: 'Migration Test Template',
          type: 'checklist',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // 3. Simulate an existing group row written before migration (null categoryTags)
      await db.into(db.cachedGroups).insert(
        CachedGroupsCompanion.insert(
          id: 'group-legacy',
          templateId: 'temp-migration',
          title: 'Legacy Group',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          categoryTags: const Value.absent(), // Simulate not writing it or null
        ),
      );

      // 4. Insert a new group row with categoryTags populated
      await db.into(db.cachedGroups).insert(
        CachedGroupsCompanion.insert(
          id: 'group-new',
          templateId: 'temp-migration',
          title: 'New Group',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          categoryTags: const Value('Audit,Safety'),
        ),
      );

      // 5. Read back both and verify legacy is null and new has tags
      final groups = await db.select(db.cachedGroups).get();
      expect(groups, hasLength(2));

      final legacyGroup = groups.firstWhere((g) => g.id == 'group-legacy');
      expect(legacyGroup.categoryTags, isNull);

      final newGroup = groups.firstWhere((g) => g.id == 'group-new');
      expect(newGroup.categoryTags, 'Audit,Safety');

      // 6. Do the same for CachedCriteria
      await db.into(db.cachedCriteria).insert(
        CachedCriteriaCompanion.insert(
          id: 'crit-legacy',
          groupId: 'group-legacy',
          label: 'Legacy Crit',
          inputType: 'pass_fail',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          categoryTags: const Value.absent(),
        ),
      );

      await db.into(db.cachedCriteria).insert(
        CachedCriteriaCompanion.insert(
          id: 'crit-new',
          groupId: 'group-legacy',
          label: 'New Crit',
          inputType: 'pass_fail',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          categoryTags: const Value('CCP,Warning'),
        ),
      );

      final criteria = await db.select(db.cachedCriteria).get();
      expect(criteria, hasLength(2));

      final legacyCrit = criteria.firstWhere((c) => c.id == 'crit-legacy');
      expect(legacyCrit.categoryTags, isNull);

      final newCrit = criteria.firstWhere((c) => c.id == 'crit-new');
      expect(newCrit.categoryTags, 'CCP,Warning');
    });
  });
}
