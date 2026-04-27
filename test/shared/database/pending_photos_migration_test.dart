import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:checkly/_shared/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'AC7: PendingPhotos_Schema_AnswerIdColumnIsNullable - Optional answerId saves correctly',
    () async {
      final photo = PendingPhotosCompanion.insert(
        id: 'p1',
        pendingSubmissionId: 'sub-1',
        localPath: '/tmp/1.jpg',
        createdAt: DateTime.now(),
        syncStatus: const Value('pending'),
        answerId: const Value('ans-123'),
      );

      await database.into(database.pendingPhotos).insert(photo);

      final retrieved = await database
          .select(database.pendingPhotos)
          .getSingle();
      expect(retrieved.answerId, 'ans-123');
    },
  );

  test(
    'AC8: PendingPhotos_Migration_ExistingRowsPreserved - AnswerId preserves backwards compatibility returning null',
    () async {
      final photo = PendingPhotosCompanion.insert(
        id: 'p2',
        pendingSubmissionId: 'sub-1',
        localPath: '/tmp/2.jpg',
        createdAt: DateTime.now(),
        syncStatus: const Value('pending'),
        // not providing answerId
      );

      await database.into(database.pendingPhotos).insert(photo);

      final retrieved = await database
          .select(database.pendingPhotos)
          .getSingle();
      expect(retrieved.answerId, null);
    },
  );
}
