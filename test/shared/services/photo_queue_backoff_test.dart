// Test Contract: Pillar D — PhotoQueueService Backoff Tests
// AC9, AC11, AC12
// Author: Sentinel (SDET) / Executed: Builder (Forge)

import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:checkly/_shared/database/app_database.dart';
import 'package:checkly/_shared/database/dao/outbox_dao.dart';
import 'package:checkly/_shared/services/photo_queue_service.dart';
import 'package:checkly/features/audit/services/submission_api_service.dart';

// ─── Fakes ────────────────────────────────────────────────────────────────

class FailingPhotoApi implements SubmissionApiService {
  @override
  Future<String> uploadPhoto(String sId, String path, {String? answerId}) async {
    throw Exception('Simulated network error during photo upload');
  }

  @override dynamic noSuchMethod(Invocation inv) => super.noSuchMethod(inv);
}

// ─── Tests ────────────────────────────────────────────────────────────────

void main() {
  late AppDatabase db;
  late OutboxDao dao;
  late PhotoQueueService queueService;

  Future<String> seedPhoto({bool isFileMissing = false, int retryCount = 0}) async {
    const pId = 'photo-1';
    await dao.insertPhoto(
      PendingPhotosCompanion.insert(
        id: pId,
        pendingSubmissionId: 'sub-1',
        localPath: isFileMissing ? '/non_existent.jpg' : '/exists.jpg',
        retryCount: Value(retryCount),
        createdAt: DateTime.now().toUtc(),
      ),
    );
    return pId;
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = OutboxDao(db);
    // Add dummy submission first (foreign key constraint)
    dao.insertSubmission(PendingSubmissionsCompanion.insert(
      id: 'sub-1', // Must match FK constraint in seedPhoto
      templateId: 't1',
      storeId: 's1',
      clientScore: 100.0,
      idempotencyKey: 'sub-1',
      createdAt: DateTime.now().toUtc(),
    ));

    queueService = PhotoQueueService(
      dao,
      FailingPhotoApi(),
      fileExists: (path) => path != '/non_existent.jpg',
    );
  });

  tearDown(() async => db.close());

  // ─── AC9: Missing local file is deterministic, no retry increment ──────
  test('AC9: PhotoQueue_MissingLocalFile_SkipsBackoff', () async {
    await seedPhoto(isFileMissing: true, retryCount: 0);

    final success = await queueService.drainQueue('sub-1');

    // Continues the batch (returns true if all processed, even if dropped)
    expect(success, isTrue);

    final rows = await db.select(db.pendingPhotos).get();
    expect(rows.first.syncStatus, 'error');
    expect(rows.first.syncError, 'local_file_missing');
    expect(rows.first.retryCount, 0); // MUST NOT increment
  });

  // ─── AC11: Retriable network failure applies backoff ───────────────────
  test('AC11: PhotoQueue_NetworkCrash_AppliesBackoff', () async {
    await seedPhoto(isFileMissing: false, retryCount: 0);
    final now = DateTime.now().toUtc();

    final success = await queueService.drainQueue('sub-1');

    expect(success, isFalse); // Pauses batch

    final rows = await db.select(db.pendingPhotos).get();
    expect(rows.first.syncStatus, 'pending');
    expect(rows.first.retryCount, 1);
    expect(rows.first.nextRetryAt, isNotNull);
    expect(rows.first.nextRetryAt!.isAfter(now), isTrue);
  });

  // ─── AC12: Exhausted status for photo ──────────────────────────────────
  test('AC12: PhotoQueue_FourthFailure_SetsExhausted', () async {
    await seedPhoto(isFileMissing: false, retryCount: 4);

    final success = await queueService.drainQueue('sub-1');

    expect(success, isFalse); // Blocks further uploads in this batch

    final rows = await db.select(db.pendingPhotos).get();
    expect(rows.first.syncStatus, 'exhausted');
    expect(rows.first.retryCount, 4); // Did not increment past the array bounds
  });
}
