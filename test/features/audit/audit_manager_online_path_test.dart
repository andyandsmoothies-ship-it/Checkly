import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import 'package:checkly/_shared/database/app_database.dart';
import 'package:checkly/_shared/database/database_service.dart';
import 'package:checkly/_shared/database/dao/outbox_dao.dart';
import 'package:checkly/features/audit/manager/audit_manager.dart';
import 'package:checkly/features/audit/services/submission_api_service.dart';
import 'package:checkly/features/audit/model/submission_dto.dart';
import 'package:checkly/features/audit/services/draft_service.dart';
import 'package:checkly/_shared/services/connectivity_service.dart';
import 'package:checkly/features/templates/models/template_dto.dart';

// ============================================================
// Fakes & Spies
// ============================================================

class FakeConnectivity implements ConnectivityService {
  @override
  bool isOnline;
  FakeConnectivity({this.isOnline = false});
  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();
}

class SpySubmissionApiService extends SubmissionApiService {
  SpySubmissionApiService() : super(Dio());
  bool createSubmissionCalled = false;

  @override
  Future<SubmissionDto> createSubmission(
    CreateSubmissionRequest request,
  ) async {
    createSubmissionCalled = true;
    throw StateError('Should not reach HTTP layer on online submit path');
  }
}

TemplateTreeDto _makeTemplate({int criteriaCount = 2}) {
  final now = DateTime.now();
  final group = GroupDto(
    id: 'g-001',
    title: 'Test Section',
    orderIndex: 0,
    criteria: List.generate(
      criteriaCount,
      (i) => CriterionDto(
        id: 'c-$i',
        label: 'Criterion $i',
        inputType: 'pass_fail',
        orderIndex: i,
        isCcp: false,
        isRisk: false,
      ),
    ),
    children: [],
  );
  return TemplateTreeDto(
    id: 'tpl-001',
    title: 'Test Template',
    type: 'qc',
    version: 1,
    isActive: true,
    scoringLogicConfig: null,
    groups: [group],
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late AppDatabase testDb;
  late OutboxDao outboxDao;

  setUp(() async {
    await GetIt.instance.reset();
    testDb = AppDatabase.forTesting(NativeDatabase.memory());
    outboxDao = OutboxDao(testDb);
    GetIt.instance.registerSingleton<DatabaseService>(
      DatabaseService.forTesting(testDb),
    );
  });

  tearDown(() async => testDb.close());

  // ----------------------------------------------------------------
  // AC-1: Online path goes Outbox-first, does NOT hit _api.createSubmission()
  // Source: Contract 1
  // ----------------------------------------------------------------
  test(
    'AuditManager_Submit_OnlinePath_DoesNotCallHttpApi_WritesOutboxInstead',
    () async {
      // Arrange
      final spy = SpySubmissionApiService();
      final manager = AuditManager(
        api: spy,
        outbox: outboxDao,
        connectivity: FakeConnectivity(isOnline: true),
        draftService: DraftService.forTesting(testDb),
      );
      final template = _makeTemplate(criteriaCount: 2);
      await manager.startAudit(template, 'store-online-001');

      // Act
      await manager.submitAudit();

      // Assert
      expect(
        spy.createSubmissionCalled,
        isFalse,
        reason:
            'Online path must NOT call HTTP API directly. Outbox-first only.',
      );
      expect(
        (await outboxDao.getAllPending()).length,
        equals(1),
        reason:
            '1 outbox row must exist — SyncEngine drains it asynchronously.',
      );
      expect(
        manager.error,
        isNull,
        reason: 'No error must be set after successful outbox write.',
      );
    },
  );
}
