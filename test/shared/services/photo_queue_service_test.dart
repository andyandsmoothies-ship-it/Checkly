import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:checkly/_shared/database/app_database.dart';
import 'package:checkly/_shared/database/dao/outbox_dao.dart';
import 'package:checkly/_shared/services/photo_queue_service.dart';
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
    when(() => mockOutboxDao.getPhotosForSubmission('sub-1'))
        .thenAnswer((_) async => []);

    final service = PhotoQueueService(mockOutboxDao, mockApi);
    final result = await service.drainQueue('sub-1');

    expect(result, isTrue);
    verifyNever(() => mockApi.uploadPhoto(any(), any(), answerId: any(named: 'answerId')));
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

    when(() => mockOutboxDao.getPhotosForSubmission('sub-1'))
        .thenAnswer((_) async => [photo1, photo2]); // Dao returns sorted
        
    when(() => mockApi.uploadPhoto(any(), any(), answerId: any(named: 'answerId')))
        .thenAnswer((_) async => 'https://cdn.example.com/photo.jpg');
        
    when(() => mockOutboxDao.updatePhotoSyncStatus(any(), 'uploaded'))
        .thenAnswer((_) async {});

    final service = PhotoQueueService(mockOutboxDao, mockApi, fileExists: (_) => true);
    final result = await service.drainQueue('sub-1');

    expect(result, isTrue);
    
    // Verify upload order
    final captured = verify(() => mockApi.uploadPhoto(any(), captureAny(), answerId: any(named: 'answerId'))).captured;
    expect(captured.length, 2);
    expect(captured[0] as String, '/tmp/1.jpg');
    expect(captured[1] as String, '/tmp/2.jpg');
  });

  test('AC5: MissingFile_MarksErrorContinuesBatch - Deterministic skip on missing file', () async {
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

    when(() => mockOutboxDao.getPhotosForSubmission('sub-1'))
        .thenAnswer((_) async => [photo1, photo2]);

    when(() => mockApi.uploadPhoto(any(), '/tmp/valid.jpg', answerId: any(named: 'answerId')))
        .thenAnswer((_) async => 'url');
        
    when(() => mockOutboxDao.updatePhotoSyncStatus('p1', 'error', error: 'local_file_missing'))
        .thenAnswer((_) async {});
    when(() => mockOutboxDao.updatePhotoSyncStatus('p2', 'uploaded'))
        .thenAnswer((_) async {});

    bool mockFileExists(String path) => path == '/tmp/valid.jpg';

    final service = PhotoQueueService(mockOutboxDao, mockApi, fileExists: mockFileExists);
    final result = await service.drainQueue('sub-1');

    expect(result, isTrue); // batch completes successfully!
    
    verify(() => mockOutboxDao.updatePhotoSyncStatus('p1', 'error', error: 'local_file_missing')).called(1);
    verifyNever(() => mockApi.uploadPhoto(any(), '/tmp/missing.jpg', answerId: any(named: 'answerId')));
    verify(() => mockApi.uploadPhoto(any(), '/tmp/valid.jpg', answerId: any(named: 'answerId'))).called(1);
  });

  test('AC6: NetworkFailure_MarksErrorBlocksBatch - Network crash prevents subsequent uploads', () async {
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

    when(() => mockOutboxDao.getPhotosForSubmission('sub-1'))
        .thenAnswer((_) async => [photo1, photo2]);

    when(() => mockApi.uploadPhoto(any(), '/tmp/1.jpg', answerId: any(named: 'answerId')))
        .thenThrow(DioException(requestOptions: RequestOptions(path: ''))); // Network exception
        
    when(() => mockOutboxDao.updatePhotoSyncStatus('p1', 'error', error: any(named: 'error')))
        .thenAnswer((_) async {});

    final service = PhotoQueueService(mockOutboxDao, mockApi, fileExists: (_) => true);
    final result = await service.drainQueue('sub-1');

    expect(result, isFalse); // Network fail correctly returns false 
    
    // Status updated wrapper to error
    verify(() => mockOutboxDao.updatePhotoSyncStatus('p1', 'error', error: any(named: 'error'))).called(1);
    
    // Photo 2 never attempted
    verifyNever(() => mockApi.uploadPhoto(any(), '/tmp/2.jpg', answerId: any(named: 'answerId')));
  });
}
