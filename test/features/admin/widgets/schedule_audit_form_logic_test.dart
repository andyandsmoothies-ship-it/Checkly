// Test Plan:
//   filterAuditors():
//     FA-01: selectedStoreId == null → returns ALL auditors unfiltered
//     FA-02: area_manager whose assignedStoreIds contains selectedStoreId → included
//     FA-03: area_manager whose assignedStoreIds does NOT contain selectedStoreId → excluded
//     FA-04: non-area_manager role (auditor) always passes through regardless of storeId
//     FA-05: empty allAuditors list → returns empty list
//     FA-06: area_manager with null/missing assignedStoreIds → excluded (treated as empty)
//
//   filterStores():
//     FS-01: selectedAuditorId == null → returns ALL stores unfiltered
//     FS-02: area_manager auditor → returns only stores in assignedStoreIds
//     FS-03: non-area_manager auditor (auditor role) → returns all stores
//     FS-04: auditor id not found in list → unknown role → admin fallback → returns all stores
//     FS-05: empty allStores list → returns empty list
//     FS-06: area_manager with null assignedStoreIds → returns empty store list

import 'package:flutter_test/flutter_test.dart';

import 'package:checkly/features/admin/widgets/schedule_audit_form_logic.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────
  // Shared fixtures
  // ─────────────────────────────────────────────────────────────────────

  const storeA = {'id': 'store-A', 'name': 'Store Alpha'};
  const storeB = {'id': 'store-B', 'name': 'Store Beta'};
  const storeC = {'id': 'store-C', 'name': 'Store Gamma'};

  final auditorUser = {
    'id': 'user-auditor',
    'name': 'Ann Auditor',
    'role': 'auditor',
  };

  final areaManagerInA = {
    'id': 'user-am-a',
    'name': 'Alan AM',
    'role': 'area_manager',
    'assignedStoreIds': ['store-A', 'store-C'],
  };

  final areaManagerInB = {
    'id': 'user-am-b',
    'name': 'Beth AM',
    'role': 'area_manager',
    'assignedStoreIds': ['store-B'],
  };

  final areaManagerNoStores = {
    'id': 'user-am-none',
    'name': 'NoStore AM',
    'role': 'area_manager',
    'assignedStoreIds': <String>[],
  };

  final areaManagerNullStores = {
    'id': 'user-am-null',
    'name': 'Null AM',
    'role': 'area_manager',
    // no 'assignedStoreIds' key → cast returns []
  };

  final allStores = [
    Map<String, dynamic>.from(storeA),
    Map<String, dynamic>.from(storeB),
    Map<String, dynamic>.from(storeC),
  ];

  final allAuditors = [
    Map<String, dynamic>.from(auditorUser),
    Map<String, dynamic>.from(areaManagerInA),
    Map<String, dynamic>.from(areaManagerInB),
  ];

  // ─────────────────────────────────────────────────────────────────────
  // filterAuditors()
  // ─────────────────────────────────────────────────────────────────────

  group('ScheduleAuditFormLogic.filterAuditors()', () {
    // FA-01
    test(
      'FA-01: selectedStoreId null returns all auditors unfiltered',
      () {
        final result = ScheduleAuditFormLogic.filterAuditors(
          selectedStoreId: null,
          allAuditors: allAuditors,
          allStores: allStores,
        );

        expect(result.length, 3);
        expect(result.map((u) => u['id']), containsAll(['user-auditor', 'user-am-a', 'user-am-b']));
      },
    );

    // FA-02
    test(
      'FA-02: area_manager whose assignedStoreIds contains selectedStoreId is included',
      () {
        final result = ScheduleAuditFormLogic.filterAuditors(
          selectedStoreId: 'store-A',
          allAuditors: [
            Map<String, dynamic>.from(areaManagerInA),
            Map<String, dynamic>.from(areaManagerInB),
          ],
          allStores: allStores,
        );

        expect(result.length, 1);
        expect(result.first['id'], 'user-am-a');
      },
    );

    // FA-03
    test(
      'FA-03: area_manager whose assignedStoreIds does NOT contain selectedStoreId is excluded',
      () {
        final result = ScheduleAuditFormLogic.filterAuditors(
          selectedStoreId: 'store-A',
          allAuditors: [Map<String, dynamic>.from(areaManagerInB)],
          allStores: allStores,
        );

        expect(result, isEmpty);
      },
    );

    // FA-04
    test(
      'FA-04: non-area_manager (auditor role) always passes through regardless of storeId',
      () {
        final result = ScheduleAuditFormLogic.filterAuditors(
          selectedStoreId: 'store-A',
          allAuditors: [Map<String, dynamic>.from(auditorUser)],
          allStores: allStores,
        );

        expect(result.length, 1);
        expect(result.first['id'], 'user-auditor');
      },
    );

    // FA-05
    test(
      'FA-05: empty allAuditors list returns empty list',
      () {
        final result = ScheduleAuditFormLogic.filterAuditors(
          selectedStoreId: 'store-A',
          allAuditors: [],
          allStores: allStores,
        );

        expect(result, isEmpty);
      },
    );

    // FA-06
    test(
      'FA-06: area_manager with null assignedStoreIds key is excluded from results',
      () {
        final result = ScheduleAuditFormLogic.filterAuditors(
          selectedStoreId: 'store-A',
          allAuditors: [Map<String, dynamic>.from(areaManagerNullStores)],
          allStores: allStores,
        );

        expect(result, isEmpty);
      },
    );

    // FA-07
    test(
      'FA-07: area_manager with empty assignedStoreIds list is excluded from results',
      () {
        final result = ScheduleAuditFormLogic.filterAuditors(
          selectedStoreId: 'store-A',
          allAuditors: [Map<String, dynamic>.from(areaManagerNoStores)],
          allStores: allStores,
        );

        expect(result, isEmpty);
      },
    );

    // FA-08: mix of area_managers and auditors — only matching ones survive
    test(
      'FA-08: mixed list filters area_managers by store and passes all other roles',
      () {
        final result = ScheduleAuditFormLogic.filterAuditors(
          selectedStoreId: 'store-A',
          allAuditors: allAuditors, // auditor + am-a (in A,C) + am-b (in B only)
          allStores: allStores,
        );

        // auditor → passes; am-a → passes (in A); am-b → excluded
        expect(result.length, 2);
        expect(result.map((u) => u['id']), containsAll(['user-auditor', 'user-am-a']));
        expect(result.map((u) => u['id']), isNot(contains('user-am-b')));
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────
  // filterStores()
  // ─────────────────────────────────────────────────────────────────────

  group('ScheduleAuditFormLogic.filterStores()', () {
    // FS-01
    test(
      'FS-01: selectedAuditorId null returns all stores unfiltered',
      () {
        final result = ScheduleAuditFormLogic.filterStores(
          selectedAuditorId: null,
          allStores: allStores,
          allAuditors: allAuditors,
        );

        expect(result.length, 3);
        expect(result.map((s) => s['id']), containsAll(['store-A', 'store-B', 'store-C']));
      },
    );

    // FS-02
    test(
      'FS-02: area_manager auditor returns only stores in their assignedStoreIds',
      () {
        final result = ScheduleAuditFormLogic.filterStores(
          selectedAuditorId: 'user-am-a', // assigned to store-A and store-C
          allStores: allStores,
          allAuditors: [Map<String, dynamic>.from(areaManagerInA)],
        );

        expect(result.length, 2);
        expect(result.map((s) => s['id']), containsAll(['store-A', 'store-C']));
        expect(result.map((s) => s['id']), isNot(contains('store-B')));
      },
    );

    // FS-03
    test(
      'FS-03: non-area_manager auditor returns all stores',
      () {
        final result = ScheduleAuditFormLogic.filterStores(
          selectedAuditorId: 'user-auditor',
          allStores: allStores,
          allAuditors: [Map<String, dynamic>.from(auditorUser)],
        );

        expect(result.length, 3);
      },
    );

    // FS-04
    test(
      'FS-04: auditor id not found in list returns all stores (admin fallback)',
      () {
        final result = ScheduleAuditFormLogic.filterStores(
          selectedAuditorId: 'unknown-id',
          allStores: allStores,
          allAuditors: allAuditors,
        );

        expect(result.length, 3);
      },
    );

    // FS-05
    test(
      'FS-05: empty allStores list returns empty list',
      () {
        final result = ScheduleAuditFormLogic.filterStores(
          selectedAuditorId: 'user-auditor',
          allStores: [],
          allAuditors: [Map<String, dynamic>.from(auditorUser)],
        );

        expect(result, isEmpty);
      },
    );

    // FS-06
    test(
      'FS-06: area_manager with null assignedStoreIds returns empty store list',
      () {
        final result = ScheduleAuditFormLogic.filterStores(
          selectedAuditorId: 'user-am-null',
          allStores: allStores,
          allAuditors: [Map<String, dynamic>.from(areaManagerNullStores)],
        );

        expect(result, isEmpty);
      },
    );

    // FS-07
    test(
      'FS-07: area_manager with empty assignedStoreIds returns empty store list',
      () {
        final result = ScheduleAuditFormLogic.filterStores(
          selectedAuditorId: 'user-am-none',
          allStores: allStores,
          allAuditors: [Map<String, dynamic>.from(areaManagerNoStores)],
        );

        expect(result, isEmpty);
      },
    );

    // FS-08
    test(
      'FS-08: area_manager assignedStoreIds that do not match any store id returns empty list',
      () {
        final amWithGhostStores = {
          'id': 'user-am-ghost',
          'name': 'Ghost AM',
          'role': 'area_manager',
          'assignedStoreIds': ['store-X', 'store-Y'], // not in allStores
        };

        final result = ScheduleAuditFormLogic.filterStores(
          selectedAuditorId: 'user-am-ghost',
          allStores: allStores,
          allAuditors: [amWithGhostStores],
        );

        expect(result, isEmpty);
      },
    );
  });
}
