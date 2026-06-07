import 'package:flutter_test/flutter_test.dart';
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

  group('Drift Database - Version 36 Schema Migration for Historical Manager Snapshots', () {
    test(
      'TC-HISTORICAL-MGR-01: Schema version must be at least 36',
      () async {
        final version = db.schemaVersion;
        expect(version, greaterThanOrEqualTo(36));
      },
    );

    test(
      'TC-HISTORICAL-MGR-02: CachedSubmissions table has historical manager snapshot columns',
      () async {
        final rows = await db.customSelect("PRAGMA table_info(cached_submissions)").get();
        final columns = rows.map((r) => r.read<String>('name')).toList();

        expect(columns, contains('area_manager_id'));
        expect(columns, contains('area_manager_name'));
        expect(columns, contains('store_manager_id'));
        expect(columns, contains('store_manager_name'));

        final areaMgrIdCol = rows.firstWhere((r) => r.read<String>('name') == 'area_manager_id');
        expect(areaMgrIdCol.read<int>('notnull'), 0); // Nullable

        final areaMgrNameCol = rows.firstWhere((r) => r.read<String>('name') == 'area_manager_name');
        expect(areaMgrNameCol.read<int>('notnull'), 0); // Nullable

        final storeMgrIdCol = rows.firstWhere((r) => r.read<String>('name') == 'store_manager_id');
        expect(storeMgrIdCol.read<int>('notnull'), 0); // Nullable

        final storeMgrNameCol = rows.firstWhere((r) => r.read<String>('name') == 'store_manager_name');
        expect(storeMgrNameCol.read<int>('notnull'), 0); // Nullable
      },
    );

    test(
      'TC-HISTORICAL-MGR-03: CachedActionPlans table has historical area manager columns',
      () async {
        final rows = await db.customSelect("PRAGMA table_info(cached_action_plans)").get();
        final columns = rows.map((r) => r.read<String>('name')).toList();

        expect(columns, contains('area_manager_id'));
        expect(columns, contains('area_manager_name'));

        final areaMgrIdCol = rows.firstWhere((r) => r.read<String>('name') == 'area_manager_id');
        expect(areaMgrIdCol.read<int>('notnull'), 0); // Nullable

        final areaMgrNameCol = rows.firstWhere((r) => r.read<String>('name') == 'area_manager_name');
        expect(areaMgrNameCol.read<int>('notnull'), 0); // Nullable
      },
    );
  });
}
