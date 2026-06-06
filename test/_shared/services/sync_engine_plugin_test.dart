import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:checkly/_shared/services/sync_engine.dart';
import 'package:checkly/_shared/services/sync_state.dart';
import 'package:checkly/_shared/services/sync_module.dart'; // Does not exist yet, will fail
import 'package:checkly/_shared/services/connectivity_service.dart';
import 'package:checkly/_shared/services/auth_check.dart';

class MockConnectivity extends Mock implements ConnectivityService {}

class MockAuth extends Mock implements AuthCheck {}

class _StubSyncModule implements SyncModule {
  final int _priority;
  final List<String> log;
  final bool shouldThrow;

  _StubSyncModule(this._priority, this.log, {this.shouldThrow = false});

  @override
  int get priority => _priority;

  @override
  Future<void> executePull() async {
    log.add('pull-$_priority');
    if (shouldThrow) throw Exception('Stub pull error');
  }

  @override
  Future<void> executePush() async {
    log.add('push-$_priority');
    if (shouldThrow) throw Exception('Stub push error');
  }
}

void main() {
  group('SyncEngine Plugin Architecture', () {
    late MockConnectivity mockConnectivity;
    late MockAuth mockAuth;

    setUp(() {
      mockConnectivity = MockConnectivity();
      mockAuth = MockAuth();

      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(
        () => mockConnectivity.onConnectivityChanged,
      ).thenAnswer((_) => const Stream.empty());
      when(() => mockAuth.isLoggedIn).thenReturn(true);
    });

    test(
      'TC-PLUGIN-1: SyncEngine_EmptyModuleList_CompletesWithoutError',
      () async {
        // Empty state
        final engine = SyncEngine(
          connectivity: mockConnectivity,
          auth: mockAuth,
          modules: [],
        );

        await engine.requestSync();

        expect(engine.state, equals(SyncState.idle));
      },
    );

    test(
      'TC-PLUGIN-2: SyncEngine_PullPhase_ExecutesAllModulesInPriorityOrder',
      () async {
        // Happy path
        final log = <String>[];
        final modules = [
          _StubSyncModule(30, log),
          _StubSyncModule(10, log),
          _StubSyncModule(20, log),
        ];

        final engine = SyncEngine(
          connectivity: mockConnectivity,
          auth: mockAuth,
          modules: modules,
        );

        await engine.requestSync();

        expect(engine.state, equals(SyncState.idle));
        expect(
          log,
          equals([
            'pull-10',
            'push-10',
            'pull-20',
            'push-20',
            'pull-30',
            'push-30',
          ]),
        );
      },
    );

    test(
      'TC-PLUGIN-3: SyncEngine_PushPhase_ModuleThrows_SetsErrorState',
      () async {
        // Error state
        final log = <String>[];
        final modules = [
          _StubSyncModule(10, log),
          _StubSyncModule(20, log, shouldThrow: true), // Throws on push
          _StubSyncModule(30, log),
        ];

        final engine = SyncEngine(
          connectivity: mockConnectivity,
          auth: mockAuth,
          modules: modules,
        );

        await engine.requestSync();

        expect(engine.state, equals(SyncState.error));
        // execution does not halt, module 30 is executed
        expect(
          log,
          equals([
            'pull-10', 'push-10',
            'pull-20', // pull throws, push-20 skipped
            'pull-30', 'push-30',
          ]),
        );
      },
    );

    test(
      'TC-PLUGIN-4: SyncEngine_OfflineCheck_BetweenModules_AbortsLoop',
      () async {
        // Error state (network drops mid-flight)
        final log = <String>[];
        final modules = [_StubSyncModule(10, log), _StubSyncModule(20, log)];

        final engine = SyncEngine(
          connectivity: mockConnectivity,
          auth: mockAuth,
          modules: modules,
        );

        // We need to change connectivity state after module 1 finishes.
        // A quick hack: module 1 pull updates the mock.
        when(() => mockConnectivity.isOnline).thenAnswer((invocation) {
          // Drop offline after module 1 has logged both pull and push
          if (log.contains('push-10')) {
            return false;
          }
          return true;
        });

        await engine.requestSync();

        expect(engine.state, equals(SyncState.offline));
        expect(log, equals(['pull-10', 'push-10'])); // 20 is never executed
      },
    );
  });
}
