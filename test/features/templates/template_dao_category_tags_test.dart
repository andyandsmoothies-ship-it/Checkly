import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:checkly/_shared/database/app_database.dart';
import 'package:checkly/_shared/database/dao/template_dao.dart';
import 'package:checkly/features/templates/models/template_dto.dart';

void main() {
  late AppDatabase db;
  late TemplateDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = TemplateDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('TemplateDao - CategoryTags SQLite Round-trip', () {
    test('TC-CAT-07: Upsert and read back Groups with categoryTags', () async {
      // Create a template first because of foreign key constraints
      await db
          .into(db.cachedTemplates)
          .insert(
            CachedTemplatesCompanion.insert(
              id: 'template-1',
              title: 'Daily Safety Audit',
              type: 'checklist',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

      final groups = <GroupDto>[
        GroupDto(
          id: 'group-1',
          title: 'FOH',
          orderIndex: 0,
          categoryTags: ['Food Safety', 'Hygiene'],
          children: [],
          criteria: [],
        ),
        GroupDto(
          id: 'group-2',
          title: 'BOH',
          orderIndex: 1,
          categoryTags: null,
          children: [],
          criteria: [],
        ),
      ];

      // Upsert groups
      await dao.upsertGroups('template-1', groups, null);

      // Read back groups natively
      final retrieved = await dao.getGroupsForTemplate('template-1');
      expect(retrieved, hasLength(2));

      final g1 = retrieved.firstWhere((g) => g.id == 'group-1');
      expect(g1.categoryTags, 'Food Safety,Hygiene');

      final g2 = retrieved.firstWhere((g) => g.id == 'group-2');
      expect(g2.categoryTags, isNull);
    });

    test(
      'TC-CAT-08: Upsert and read back Criteria with categoryTags',
      () async {
        // Set up a group first for criteria
        await db
            .into(db.cachedTemplates)
            .insert(
              CachedTemplatesCompanion.insert(
                id: 'template-2',
                title: 'Safety Audit v2',
                type: 'checklist',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );

        await db
            .into(db.cachedGroups)
            .insert(
              CachedGroupsCompanion.insert(
                id: 'group-2',
                templateId: 'template-2',
                title: 'Kitchen',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );

        final criteria = <CriterionDto>[
          CriterionDto(
            id: 'crit-1',
            label: 'Temp Check',
            inputType: 'pass_fail',
            orderIndex: 0,
            isCcp: true,
            isRisk: false,
            categoryTags: ['Critical Control', 'Temperature'],
          ),
          CriterionDto(
            id: 'crit-2',
            label: 'Clean Counters',
            inputType: 'pass_fail',
            orderIndex: 1,
            isCcp: false,
            isRisk: false,
            categoryTags: null,
          ),
        ];

        // Upsert criteria
        await dao.upsertCriteria('group-2', criteria);

        // Read back criteria natively
        final retrieved = await dao.getCriteriaForGroup('group-2');
        expect(retrieved, hasLength(2));

        final c1 = retrieved.firstWhere((c) => c.id == 'crit-1');
        expect(c1.categoryTags, 'Critical Control,Temperature');

        final c2 = retrieved.firstWhere((c) => c.id == 'crit-2');
        expect(c2.categoryTags, isNull);
      },
    );

    test(
      'TC-GAP-01: Empty or whitespace items in categoryTags list are sanitized and ignored',
      () async {
        await db
            .into(db.cachedTemplates)
            .insert(
              CachedTemplatesCompanion.insert(
                id: 'template-3',
                title: 'Audit v3',
                type: 'checklist',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );

        final groups = <GroupDto>[
          GroupDto(
            id: 'group-3',
            title: 'Storage Room',
            orderIndex: 0,
            categoryTags: ['Fire Hazard', '', '  ', 'Ventilation'],
            children: [],
            criteria: [],
          ),
        ];

        await dao.upsertGroups('template-3', groups, null);

        // Retrieve full tree to see if tags are parsed and sanitized back into clean List<String>
        final tree = await dao.getTemplateTree('template-3');
        expect(tree, isNotNull);
        expect(tree!.groups, hasLength(1));

        final g3 = tree.groups.first;
        expect(g3.id, 'group-3');
        expect(
          g3.categoryTags,
          containsAll(['Fire Hazard', '  ', 'Ventilation']),
        );
        expect(g3.categoryTags, isNot(contains('')));
      },
    );

    test(
      'TC-CAT-09: End-to-end full Tree retrieval maps categoryTags properly',
      () async {
        await db
            .into(db.cachedTemplates)
            .insert(
              CachedTemplatesCompanion.insert(
                id: 'template-4',
                title: 'Audit v4',
                type: 'checklist',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );

        final groups = <GroupDto>[
          GroupDto(
            id: 'group-4',
            title: 'Basement',
            orderIndex: 0,
            categoryTags: ['Water', 'Pest Control'],
            children: [],
            criteria: [
              CriterionDto(
                id: 'crit-4',
                label: 'Water Pump Status',
                inputType: 'pass_fail',
                orderIndex: 0,
                isCcp: false,
                isRisk: false,
                categoryTags: ['Pump', 'Electricity'],
              ),
            ],
          ),
        ];

        await dao.upsertGroups('template-4', groups, null);

        final tree = await dao.getTemplateTree('template-4');
        expect(tree, isNotNull);
        expect(tree!.groups, hasLength(1));

        final g4 = tree.groups.first;
        expect(g4.categoryTags, containsAll(['Water', 'Pest Control']));

        expect(g4.criteria, hasLength(1));
        final c4 = g4.criteria.first;
        expect(c4.categoryTags, containsAll(['Pump', 'Electricity']));
      },
    );
  });
}
