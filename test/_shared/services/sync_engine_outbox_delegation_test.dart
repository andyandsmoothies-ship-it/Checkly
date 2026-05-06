import 'dart:async';

import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:checkly/_shared/database/app_database.dart';
import 'package:checkly/_shared/database/dao/outbox_dao.dart';
import 'package:checkly/_shared/services/sync_engine.dart';

import 'package:checkly/_shared/services/auth_check.dart';
import 'package:checkly/_shared/services/connectivity_service.dart';

class AlwaysOnlineConnectivity implements ConnectivityService {
  @override
  bool get isOnline => true;
  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();
}

class AlwaysAuthCheck implements AuthCheck {
  @override
  bool get isLoggedIn => true;
}

// ==============================================================================
// Test Contract: SyncEngine Outbox Delegation
// Author: Sentinel (SDET) / Executed: Builder (Forge)
// ==============================================================================

void main() {
  late AppDatabase db;
  late OutboxDao outboxDao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    outboxDao = OutboxDao(db);

    // We construct SyncEngine with OutboxDao. The compiler will catch if
    // outboxDao is not yet a named parameter, so we use it dynamically here or
    // we bypass it. Wait, if outboxDao isn't in SyncEngine's constructor yet,
    // `SyncEngine(outboxDao: outboxDao, ...)` will fail to compile.
    // So we use standard compilation errors as our Red Phase failures where possible.
    // For methods missing, we use dynamic to avoid full suite abort if needed,
    // but constructor errors must be fixed by the Builder.
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedSubmission(String id, String status) async {
    await outboxDao.insertSubmission(
      PendingSubmissionsCompanion.insert(
        id: id,
        templateId: 't1',
        storeId: 's1',
        clientScore: 100.0,
        idempotencyKey: id,
        syncStatus: Value(status),
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  // Helper to safely instantiate engine, bypassing compile errors if outboxDao isn't there yet
  // but we'll try to just instantiate it as if it works. If it fails compilation,
  // that is a valid Red failure. However, we want to catch it softly.
  SyncEngine createEngine() {
    // To allow compilation in Red phase even before SyncEngine is updated:
    // We instantiate it normally. If it fails, that's our RED.
    // BUT, wait, if the constructor lacks `outboxDao`, `rtk flutter test` will fail to compile.
    // The plan says: "Construct SyncEngine with the new outboxDao: parameter. Run tests -> All 8 FAIL because SyncEngine doesn't have the methods yet."
    // Actually, if we use dynamic we can bypass the compiler checking the methods.

    // The existing SyncEngine constructor:
    // SyncEngine({required ConnectivityService connectivity, required AuthCheck auth, required List<SyncModule> modules})

    // So if we pass outboxDao, it will not compile.
    // But the instructions for TDD RED say:
    // "Construct SyncEngine with the new outboxDao: parameter."
    // "Run tests -> All 8 FAIL because SyncEngine doesn't have the methods yet."

    // Dart doesn't allow passing undefined named arguments even with `dynamic`.
    // We MUST pass it normally and let the compiler fail. That's a valid Red phase!

    // Wait, if it fails to compile, it just says "Error: No named parameter with the name 'outboxDao'."
    // This is a 100% valid TDD Red failure in statically typed languages.

    return SyncEngine(
      connectivity: AlwaysOnlineConnectivity(),
      auth: AlwaysAuthCheck(),
      outboxDao: outboxDao,
      modules: [],
    );
  }

  group('SyncEngine Outbox Delegation', () {
    test('TC-01: watchExhaustedCount() emits 0 when outbox is empty', () async {
      final engine = createEngine();

      try {
        final stream = (engine as dynamic).watchExhaustedCount() as Stream<int>;
        final count = await stream.first;
        expect(count, 0);
      } on NoSuchMethodError {
        fail('MethodNotFound: watchExhaustedCount is missing from SyncEngine');
      }
    });

    test(
      'TC-02: watchExhaustedCount() emits 2 when 2 exhausted rows exist',
      () async {
        await seedSubmission('s1', 'exhausted');
        await seedSubmission('s2', 'exhausted');

        final engine = createEngine();

        try {
          final stream =
              (engine as dynamic).watchExhaustedCount() as Stream<int>;
          final count = await stream.first;
          expect(count, 2);
        } on NoSuchMethodError {
          fail(
            'MethodNotFound: watchExhaustedCount is missing from SyncEngine',
          );
        }
      },
    );

    test(
      'TC-03: discardExhausted() removes all exhausted rows from DB',
      () async {
        await seedSubmission('s1', 'exhausted');
        await seedSubmission('s2', 'pending');

        final engine = createEngine();

        try {
          await (engine as dynamic).discardExhausted();
          final remaining = await db.select(db.pendingSubmissions).get();
          expect(remaining.length, 1);
          expect(remaining.first.id, 's2');
        } on NoSuchMethodError {
          fail('MethodNotFound: discardExhausted is missing from SyncEngine');
        }
      },
    );

    test(
      'TC-04: requeueExhausted() resets exhausted rows to pending',
      () async {
        await seedSubmission('s1', 'exhausted');

        final engine = createEngine();

        try {
          await (engine as dynamic).requeueExhausted();
          final updated = await db.select(db.pendingSubmissions).get();
          expect(updated.first.syncStatus, 'pending');
          expect(updated.first.retryCount, 0);
          expect(updated.first.nextRetryAt, isNull);
        } on NoSuchMethodError {
          fail('MethodNotFound: requeueExhausted is missing from SyncEngine');
        }
      },
    );

    test('TC-05: syncableCount() returns 0 for empty outbox', () async {
      final engine = createEngine();

      try {
        final count = await (engine as dynamic).syncableCount() as int;
        expect(count, 0);
      } on NoSuchMethodError {
        fail('MethodNotFound: syncableCount is missing from SyncEngine');
      }
    });

    test(
      'TC-06: syncableCount() returns 1 when 1 pending submission exists',
      () async {
        await seedSubmission('s1', 'pending');

        final engine = createEngine();

        try {
          final count = await (engine as dynamic).syncableCount() as int;
          expect(count, 1);
        } on NoSuchMethodError {
          fail('MethodNotFound: syncableCount is missing from SyncEngine');
        }
      },
    );

    test('TC-07: exhaustedCount() returns 0 for empty outbox', () async {
      final engine = createEngine();

      try {
        final count = await (engine as dynamic).exhaustedCount() as int;
        expect(count, 0);
      } on NoSuchMethodError {
        fail('MethodNotFound: exhaustedCount is missing from SyncEngine');
      }
    });

    test(
      'TC-08: exhaustedCount() returns 1 when 1 exhausted submission exists',
      () async {
        await seedSubmission('s1', 'exhausted');

        final engine = createEngine();

        try {
          final count = await (engine as dynamic).exhaustedCount() as int;
          expect(count, 1);
        } on NoSuchMethodError {
          fail('MethodNotFound: exhaustedCount is missing from SyncEngine');
        }
      },
    );
  });
}
