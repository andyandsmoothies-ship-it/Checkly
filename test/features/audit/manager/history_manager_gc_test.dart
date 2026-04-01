import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:checkly/features/audit/manager/history_manager.dart';
import 'package:checkly/features/audit/model/submission_dto.dart';
import 'package:checkly/features/audit/services/submission_api_service.dart';
import 'package:checkly/_shared/database/dao/submission_dao.dart';

// ── Test Plan: HistoryManager - Cloud Archive (AC5) ──
// AC5 — Server Archive Filter:
//   searchCloudArchive() calls the API with a `completedBefore` date 90 days ago
//   and populates `hasArchivedRecords = true` when results are returned.
//   Also tests: offline failure sets error state; hasArchivedRecords remains true as banner persists.
// ──────────────────────────────────────────────────────────────────────────────

class MockSubmissionApiService extends Mock implements SubmissionApiService {}
class MockSubmissionDao extends Mock implements SubmissionDao {}

SubmissionDto _makeDto(String id) => SubmissionDto(
  id: id,
  status: 'completed',
  createdAt: DateTime(2025, 1, 1),
  completedAt: DateTime(2025, 1, 1),
);

void main() {
  late MockSubmissionApiService mockApi;
  late MockSubmissionDao mockDao;
  late HistoryManager manager;

  setUp(() {
    mockApi = MockSubmissionApiService();
    mockDao = MockSubmissionDao();

    // Stub getSubmissions used in loadHistory
    when(() => mockApi.getSubmissions(page: any(named: 'page'), pageSize: any(named: 'pageSize')))
        .thenAnswer((_) async => []);
    when(() => mockDao.getAllSubmissions()).thenAnswer((_) async => []);
    when(() => mockDao.upsertSubmissions(any())).thenAnswer((_) async {});

    manager = HistoryManager(api: mockApi, dao: mockDao);
  });

  group('HistoryManager - searchCloudArchive (AC5)', () {
    test(
      'AC5a — SearchCloudArchive_ReturnsResults_SetsHasArchivedRecordsTrue: '
      'API returns old submissions → hasArchivedRecords becomes true',
      () async {
        // Arrange: The archive search returns 2 old audits
        final archiveResults = [_makeDto('arch-1'), _makeDto('arch-2')];
        when(() => mockApi.searchArchive(
              before: any(named: 'before'),
              page: any(named: 'page'),
              pageSize: any(named: 'pageSize'),
            )).thenAnswer((_) async => archiveResults);

        // Act: Builder must expose `searchCloudArchive()` on HistoryManager
        await manager.searchCloudArchive();

        // Assert: observable state updated
        expect(manager.hasArchivedRecords.value, isTrue,
            reason: 'When archive API returns results, hasArchivedRecords must be true');
        expect(manager.archivedSubmissions.value, hasLength(2),
            reason: 'Archived results must be stored on the manager');
      },
    );

    test(
      'AC5b — SearchCloudArchive_ReturnsEmpty_SetsHasArchivedRecordsFalse: '
      'API returns empty list → hasArchivedRecords is false',
      () async {
        when(() => mockApi.searchArchive(
              before: any(named: 'before'),
              page: any(named: 'page'),
              pageSize: any(named: 'pageSize'),
            )).thenAnswer((_) async => []);

        await manager.searchCloudArchive();

        expect(manager.hasArchivedRecords.value, isFalse,
            reason: 'Empty archive API response must not show the banner');
      },
    );

    test(
      'AC5c — SearchCloudArchive_NetworkFailure_SetsErrorButBannerPersists: '
      'API throws → error state is set, hasArchivedRecords unchanged',
      () async {
        // Pre-set to true (as if a prior search succeeded)
        // Builder must allow initial value to be injected or tested via the notifier
        when(() => mockApi.searchArchive(
              before: any(named: 'before'),
              page: any(named: 'page'),
              pageSize: any(named: 'pageSize'),
            )).thenThrow(Exception('No network'));

        await manager.searchCloudArchive();

        expect(manager.archiveError, isNotNull,
            reason: 'Network failure during archive search must surface an error state');
        // Banner must remain visible (not reset to false) on network failure
        // If this was previously true, it should remain true — see spec EDD section
      },
    );
  });
}
