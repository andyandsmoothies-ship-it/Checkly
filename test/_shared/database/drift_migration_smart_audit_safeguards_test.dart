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

  group('Drift Database - Version 34 Schema Migration for Smart Audit Safeguards', () {
    test(
      'TC-SAFEGUARDS-01: Schema version must be 34',
      () async {
        // Arrange & Act
        final version = db.schemaVersion;

        // Assert
        expect(version, 34);
      },
    );

    test(
      'TC-SAFEGUARDS-02: CachedTemplates table has new geofence and display columns',
      () async {
        // Arrange
        // Act
        final rows = await db.customSelect("PRAGMA table_info(cached_templates)").get();
        final columns = rows.map((r) => r.read<String>('name')).toList();

        // Assert
        expect(columns, contains('display_noun'));
        expect(columns, contains('geofence_mode'));
        expect(columns, contains('geofence_radius_meters'));

        // Check defaults and nullability
        final displayNounCol = rows.firstWhere((r) => r.read<String>('name') == 'display_noun');
        expect(displayNounCol.read<int>('notnull'), 0); // Nullable

        final modeCol = rows.firstWhere((r) => r.read<String>('name') == 'geofence_mode');
        expect(modeCol.read<int>('notnull'), 1); // Not Null
        expect(modeCol.read<String?>('dflt_value'), "'none'");

        final radiusCol = rows.firstWhere((r) => r.read<String>('name') == 'geofence_radius_meters');
        expect(radiusCol.read<int>('notnull'), 1); // Not Null
        expect(radiusCol.read<String?>('dflt_value'), '100');
      },
    );

    test(
      'TC-SAFEGUARDS-03: CachedSubmissions table has geofence telemetry columns',
      () async {
        // Arrange
        // Act
        final rows = await db.customSelect("PRAGMA table_info(cached_submissions)").get();
        final columns = rows.map((r) => r.read<String>('name')).toList();

        // Assert
        expect(columns, contains('is_geofence_bypassed'));
        expect(columns, contains('distance_meters_off'));

        final bypassedCol = rows.firstWhere((r) => r.read<String>('name') == 'is_geofence_bypassed');
        expect(bypassedCol.read<int>('notnull'), 0); // Nullable

        final distanceCol = rows.firstWhere((r) => r.read<String>('name') == 'distance_meters_off');
        expect(distanceCol.read<int>('notnull'), 0); // Nullable
      },
    );

    test(
      'TC-SAFEGUARDS-04: PendingSubmissions table has geofence telemetry columns',
      () async {
        // Arrange
        // Act
        final rows = await db.customSelect("PRAGMA table_info(pending_submissions)").get();
        final columns = rows.map((r) => r.read<String>('name')).toList();

        // Assert
        expect(columns, contains('is_geofence_bypassed'));
        expect(columns, contains('distance_meters_off'));

        final bypassedCol = rows.firstWhere((r) => r.read<String>('name') == 'is_geofence_bypassed');
        expect(bypassedCol.read<int>('notnull'), 0); // Nullable

        final distanceCol = rows.firstWhere((r) => r.read<String>('name') == 'distance_meters_off');
        expect(distanceCol.read<int>('notnull'), 0); // Nullable
      },
    );
  });
}
