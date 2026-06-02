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

  group('Drift Database - Version 35 Schema Migration for Action Plan Collaborative Flow', () {
    test(
      'TC-COLLAB-01: Schema version must be 35',
      () async {
        // Arrange & Act
        final version = db.schemaVersion;

        // Assert
        expect(version, 35);
      },
    );

    test(
      'TC-COLLAB-02: PendingActionPlanUpdates table has root_cause column',
      () async {
        // Arrange
        // Act
        final rows = await db.customSelect("PRAGMA table_info(pending_action_plan_updates)").get();
        final columns = rows.map((r) => r.read<String>('name')).toList();

        // Assert
        expect(columns, contains('root_cause'));

        // Check nullability
        final rootCauseCol = rows.firstWhere((r) => r.read<String>('name') == 'root_cause');
        expect(rootCauseCol.read<int>('notnull'), 0); // Nullable
      },
    );
  });
}
