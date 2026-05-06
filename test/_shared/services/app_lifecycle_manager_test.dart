import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:checkly/_shared/services/app_lifecycle_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLifecycleManager Tests', () {
    late AppLifecycleManager manager;
    late int authCheckCount;
    late int fullResyncCount;
    late int forceReLoginCount;

    setUp(() {
      manager = AppLifecycleManager();
      authCheckCount = 0;
      fullResyncCount = 0;
      forceReLoginCount = 0;

      manager.onAuthCheck = () => authCheckCount++;
      manager.onFullResync = () => fullResyncCount++;
      manager.onForceReLogin = () => forceReLoginCount++;
    });

    tearDown(() {
      manager.dispose();
    });

    test('TC-09-01: < 5 mins elapsed triggers no callbacks', () {
      fakeAsync((async) {
        manager.setLastPausedAt(
          DateTime.now().subtract(const Duration(minutes: 4, seconds: 59)),
        );
        manager.didChangeAppLifecycleState(AppLifecycleState.resumed);
        async.elapse(const Duration(milliseconds: 500));

        expect(authCheckCount, 0);
        expect(fullResyncCount, 0);
        expect(forceReLoginCount, 0);
      });
    });

    test('TC-09-02: Exactly 5 mins elapsed triggers onAuthCheck', () {
      fakeAsync((async) {
        manager.setLastPausedAt(
          DateTime.now().subtract(const Duration(minutes: 5)),
        );
        manager.didChangeAppLifecycleState(AppLifecycleState.resumed);
        async.elapse(const Duration(milliseconds: 500));

        expect(authCheckCount, 1);
        expect(fullResyncCount, 0);
        expect(forceReLoginCount, 0);
      });
    });

    test('TC-09-03: 5 mins - 12 hours elapsed triggers onAuthCheck', () {
      fakeAsync((async) {
        manager.setLastPausedAt(
          DateTime.now().subtract(const Duration(hours: 11, minutes: 59)),
        );
        manager.didChangeAppLifecycleState(AppLifecycleState.resumed);
        async.elapse(const Duration(milliseconds: 500));

        expect(authCheckCount, 1);
        expect(fullResyncCount, 0);
        expect(forceReLoginCount, 0);
      });
    });

    test('TC-09-04: Exactly 12 hours elapsed triggers onFullResync', () {
      fakeAsync((async) {
        manager.setLastPausedAt(
          DateTime.now().subtract(const Duration(hours: 12)),
        );
        manager.didChangeAppLifecycleState(AppLifecycleState.resumed);
        async.elapse(const Duration(milliseconds: 500));

        expect(authCheckCount, 0);
        expect(fullResyncCount, 1);
        expect(forceReLoginCount, 0);
      });
    });

    test('TC-09-05: 12 hours - 7 days elapsed triggers onFullResync', () {
      fakeAsync((async) {
        manager.setLastPausedAt(
          DateTime.now().subtract(const Duration(days: 6, hours: 23)),
        );
        manager.didChangeAppLifecycleState(AppLifecycleState.resumed);
        async.elapse(const Duration(milliseconds: 500));

        expect(authCheckCount, 0);
        expect(fullResyncCount, 1);
        expect(forceReLoginCount, 0);
      });
    });

    test('TC-09-06: Exactly 7 days elapsed triggers onForceReLogin', () {
      fakeAsync((async) {
        manager.setLastPausedAt(
          DateTime.now().subtract(const Duration(days: 7)),
        );
        manager.didChangeAppLifecycleState(AppLifecycleState.resumed);
        async.elapse(const Duration(milliseconds: 500));

        expect(authCheckCount, 0);
        expect(fullResyncCount, 0);
        expect(forceReLoginCount, 1);
      });
    });

    test('TC-09-07: > 7 days elapsed triggers onForceReLogin', () {
      fakeAsync((async) {
        manager.setLastPausedAt(
          DateTime.now().subtract(const Duration(days: 30)),
        );
        manager.didChangeAppLifecycleState(AppLifecycleState.resumed);
        async.elapse(const Duration(milliseconds: 500));

        expect(authCheckCount, 0);
        expect(fullResyncCount, 0);
        expect(forceReLoginCount, 1);
      });
    });

    test(
      'TC-09-08: Debounce cancels pending execution on repeated resumes',
      () {
        fakeAsync((async) {
          manager.setLastPausedAt(
            DateTime.now().subtract(const Duration(hours: 1)),
          );

          manager.didChangeAppLifecycleState(AppLifecycleState.resumed);
          async.elapse(const Duration(milliseconds: 200)); // Before debounce

          // Trigger resume again before the first debounce fires
          manager.setLastPausedAt(
            DateTime.now().subtract(const Duration(hours: 1)),
          );
          manager.didChangeAppLifecycleState(AppLifecycleState.resumed);
          async.elapse(
            const Duration(milliseconds: 500),
          ); // Wait out the second debounce

          // Should only be called once, not twice
          expect(authCheckCount, 1);
        });
      },
    );
  });
}
