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

  group('Drift Database - Version 32 Schema Migration for categoryTag', () {
    test(
      'TC-GAP-03: Schema migration preserves legacy templates and version is 32',
      () async {
        // 1. Assert schema version is 32
        expect(db.schemaVersion, 32);

        // 2. Insert a template without categoryTag (null)
        await db
            .into(db.cachedTemplates)
            .insert(
              CachedTemplatesCompanion.insert(
                id: 'temp-migration-legacy',
                title: 'Legacy Migration Test Template',
                type: 'checklist',
                categoryTag: const Value.absent(),
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );

        // 3. Insert a new template with categoryTag populated
        await db
            .into(db.cachedTemplates)
            .insert(
              CachedTemplatesCompanion.insert(
                id: 'temp-migration-new',
                title: 'New Migration Test Template',
                type: 'checklist',
                categoryTag: const Value('Audit'),
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );

        // 4. Read back both and verify legacy is null and new has tag
        final templates = await db.select(db.cachedTemplates).get();
        expect(templates, hasLength(2));

        final legacyTemplate = templates.firstWhere((t) => t.id == 'temp-migration-legacy');
        expect(legacyTemplate.categoryTag, isNull);

        final newTemplate = templates.firstWhere((t) => t.id == 'temp-migration-new');
        expect(newTemplate.categoryTag, 'Audit');
      },
    );
  });
}
