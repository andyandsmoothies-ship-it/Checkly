import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:checkly/_shared/database/app_database.dart';
import 'package:checkly/_shared/database/dao/outbox_dao.dart';
import 'package:checkly/_shared/services/photo_queue_service.dart';
import 'package:checkly/_shared/services/drain_result.dart';
import 'package:checkly/features/audit/services/submission_api_service.dart';

class MockOutboxDao extends Mock implements OutboxDao {}

class MockSubmissionApiService extends Mock implements SubmissionApiService {}

void main() {
  late MockOutboxDao mockOutboxDao;
  late MockSubmissionApiService mockApi;

  setUpAll(() {
    registerFallbackValue('');
  });

  setUp(() {
    mockOutboxDao = MockOutboxDao();
    mockApi = MockSubmissionApiService();
  });

  test('AC9: EmptyQueue_ReturnsTrue - Safe no-op', () async {
    when(
      () => mockOutboxDao.getPhotosForSubmission('sub-1'),
    ).thenAnswer((_) async => []);

    final service = PhotoQueueService(mockOutboxDao, mockApi);
    final result = await service.drainQueue('sub-1');

    expect(result, isA<DrainSuccess>());
    verifyNever(
      () => mockApi.uploadPhoto(any(), any(), answerId: any(named: 'answerId')),
    );
  });

  test('AC11: PhotosUploadedInFifoOrder - FIFO strictly enforced', () async {
    final photo1 = PendingPhoto(
      id: 'p1',
      pendingSubmissionId: 'sub-1',
      localPath: '/tmp/1.jpg',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      syncStatus: 'pending',
      retryCount: 0,
    );
    final photo2 = PendingPhoto(
      id: 'p2',
      pendingSubmissionId: 'sub-1',
      localPath: '/tmp/2.jpg',
      createdAt: DateTime.now(),
      syncStatus: 'pending',
      retryCount: 0,
    );

    when(
      () => mockOutboxDao.getPhotosForSubmission('sub-1'),
    ).thenAnswer((_) async => [photo1, photo2]); // Dao returns sorted

    when(
      () => mockApi.uploadPhoto(any(), any(), answerId: any(named: 'answerId')),
    ).thenAnswer((_) async => 'https://cdn.example.com/photo.jpg');

    when(
      () => mockOutboxDao.updatePhotoSyncStatus(any(), 'uploaded'),
    ).thenAnswer((_) async {});

    final service = PhotoQueueService(
      mockOutboxDao,
      mockApi,
      fileExists: (_) => true,
    );
    final result = await service.drainQueue('sub-1');

    expect(result, isA<DrainSuccess>());

    // Verify upload order
    final captured = verify(
      () => mockApi.uploadPhoto(
        any(),
        captureAny(),
        answerId: any(named: 'answerId'),
      ),
    ).captured;
    expect(captured.length, 2);
    expect(captured[0] as String, '/tmp/1.jpg');
    expect(captured[1] as String, '/tmp/2.jpg');
  });

  test(
    'AC5: MissingFile_MarksErrorContinuesBatch - Deterministic skip on missing file',
    () async {
      final photo1 = PendingPhoto(
        id: 'p1',
        pendingSubmissionId: 'sub-1',
        localPath: '/tmp/missing.jpg',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        syncStatus: 'pending',
        retryCount: 0,
      );
      final photo2 = PendingPhoto(
        id: 'p2',
        pendingSubmissionId: 'sub-1',
        localPath: '/tmp/valid.jpg',
        createdAt: DateTime.now(),
        syncStatus: 'pending',
        retryCount: 0,
      );

      when(
        () => mockOutboxDao.getPhotosForSubmission('sub-1'),
      ).thenAnswer((_) async => [photo1, photo2]);

      when(
        () => mockApi.uploadPhoto(
          any(),
          '/tmp/valid.jpg',
          answerId: any(named: 'answerId'),
        ),
      ).thenAnswer((_) async => 'url');

      when(
        () => mockOutboxDao.updatePhotoSyncStatus(
          'p1',
          'error',
          error: 'local_file_missing',
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockOutboxDao.updatePhotoSyncStatus('p2', 'uploaded'),
      ).thenAnswer((_) async {});

      bool mockFileExists(String path) => path == '/tmp/valid.jpg';

      final service = PhotoQueueService(
        mockOutboxDao,
        mockApi,
        fileExists: mockFileExists,
      );
      final result = await service.drainQueue('sub-1');

      expect(result, isA<DrainSuccess>()); // batch completes successfully!

      verify(
        () => mockOutboxDao.updatePhotoSyncStatus(
          'p1',
          'error',
          error: 'local_file_missing',
        ),
      ).called(1);
      verifyNever(
        () => mockApi.uploadPhoto(
          any(),
          '/tmp/missing.jpg',
          answerId: any(named: 'answerId'),
        ),
      );
      verify(
        () => mockApi.uploadPhoto(
          any(),
          '/tmp/valid.jpg',
          answerId: any(named: 'answerId'),
        ),
      ).called(1);
    },
  );

  test(
    'AC6: NetworkFailure_MarksErrorBlocksBatch - Network crash prevents subsequent uploads',
    () async {
      final photo1 = PendingPhoto(
        id: 'p1',
        pendingSubmissionId: 'sub-1',
        localPath: '/tmp/1.jpg',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        syncStatus: 'pending',
        retryCount: 0,
      );
      final photo2 = PendingPhoto(
        id: 'p2',
        pendingSubmissionId: 'sub-1',
        localPath: '/tmp/2.jpg',
        createdAt: DateTime.now(),
        syncStatus: 'pending',
        retryCount: 0,
      );

      when(
        () => mockOutboxDao.getPhotosForSubmission('sub-1'),
      ).thenAnswer((_) async => [photo1, photo2]);

      when(
        () => mockApi.uploadPhoto(
          any(),
          '/tmp/1.jpg',
          answerId: any(named: 'answerId'),
        ),
      ).thenThrow(
        DioException(requestOptions: RequestOptions(path: '')),
      ); // Network exception

      when(
        () => mockOutboxDao.updatePhotoSyncStatus(
          'p1',
          'pending',
          error: any(named: 'error'),
          retryCount: 1,
          nextRetryAt: any(named: 'nextRetryAt'),
        ),
      ).thenAnswer((_) async {});

      final service = PhotoQueueService(
        mockOutboxDao,
        mockApi,
        fileExists: (_) => true,
      );
      final result = await service.drainQueue('sub-1');

      expect(
        result,
        isA<DrainFailure>(),
      ); // Network fail correctly returns false

      // Status updated wrapper to pending with backoff
      verify(
        () => mockOutboxDao.updatePhotoSyncStatus(
          'p1',
          'pending',
          error: any(named: 'error'),
          retryCount: 1,
          nextRetryAt: any(named: 'nextRetryAt'),
        ),
      ).called(1);

      // Photo 2 never attempted
      verifyNever(
        () => mockApi.uploadPhoto(
          any(),
          '/tmp/2.jpg',
          answerId: any(named: 'answerId'),
        ),
      );
    },
  );

  test('TC-F1-01: AC_429_ReturnsRetryScheduled_NoDelay', () async {
    final photo = PendingPhoto(
      id: 'p1',
      pendingSubmissionId: 'sub-1',
      localPath: '/tmp/1.jpg',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      syncStatus: 'pending',
      retryCount: 0,
    );

    when(
      () => mockOutboxDao.getPhotosForSubmission('sub-1'),
    ).thenAnswer((_) async => [photo]);

    when(
      () => mockApi.uploadPhoto(any(), any(), answerId: any(named: 'answerId')),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 429,
          headers: Headers.fromMap({
            'retry-after': ['30'],
          }),
        ),
      ),
    );

    final service = PhotoQueueService(
      mockOutboxDao,
      mockApi,
      fileExists: (_) => true,
    );
    final result = await service.drainQueue('sub-1');

    expect(result, isA<DrainRetryScheduled>());
    expect((result as DrainRetryScheduled).delay.inSeconds, 30);
  });

  test('TC-F1-02: ConcurrentCalls_ForSameSubmissionId_PreventsOverlappingRuns', () async {
    final photo = PendingPhoto(
      id: 'p1',
      pendingSubmissionId: 'sub-1',
      localPath: '/tmp/1.jpg',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      syncStatus: 'pending',
      retryCount: 0,
    );

    // Call 1 mock setup: wait on a completer inside getPhotosForSubmission
    final completer = Completer<List<PendingPhoto>>();
    when(
      () => mockOutboxDao.getPhotosForSubmission('sub-1'),
    ).thenAnswer((_) => completer.future);

    final mockRandom = MockRandom();
    when(() => mockRandom.nextInt(any())).thenReturn(0);

    final service = PhotoQueueService(
      mockOutboxDao,
      mockApi,
      fileExists: (_) => true,
      random: mockRandom,
    );

    // Act 1: start the first drain call (will await the completer)
    final future1 = service.drainQueue('sub-1');

    // Act 2: synchronously trigger the second drain call (same ID)
    final result2 = await service.drainQueue('sub-1');

    // Assert: Call 2 should instantly return DrainSuccess
    expect(result2, isA<DrainSuccess>());

    // Complete Call 1 mock
    completer.complete([photo]);

    when(
      () => mockApi.uploadPhoto(any(), any(), answerId: any(named: 'answerId')),
    ).thenAnswer((_) async => 'url');
    when(
      () => mockOutboxDao.updatePhotoSyncStatus('p1', 'uploaded'),
    ).thenAnswer((_) async {});

    final result1 = await future1;

    // Assert: Call 1 completes normally
    expect(result1, isA<DrainSuccess>());

    // Verify DB was queried only once
    verify(() => mockOutboxDao.getPhotosForSubmission('sub-1')).called(1);
  });
}

class MockRandom extends Mock implements Random {}

