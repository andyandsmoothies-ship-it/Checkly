import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:checkly/features/dashboard/manager/dashboard_manager.dart';
import 'package:checkly/features/auth/manager/auth_manager.dart';
import 'package:checkly/features/auth/model/user_session.dart';
import 'package:checkly/_shared/database/app_database.dart';

class MockAuthManager extends Mock implements AuthManager {}

class MockUserSession extends Mock implements UserSession {}

void main() {
  late DashboardManager manager;
  late AppDatabase db;
  late MockAuthManager mockAuth;

  setUp(() {
    // TC-REF: Use in-memory SQLite for reliable query testing without fragile mocks
    db = AppDatabase.forTesting(NativeDatabase.memory());
    mockAuth = MockAuthManager();
    manager = DashboardManager(db: db, auth: mockAuth);
  });

  tearDown(() async {
    await db.close();
  });

  group('DashboardManager IA Overhaul (TC-01...TC-04)', () {
    test(
      'TC-02: Should return ManagerDashboardState when stores are empty',
      () async {
        // Arrange
        final user = MockUserSession();
        when(() => user.role).thenReturn('store_manager');
        when(() => user.fullName).thenReturn('Test Manager');
        when(() => mockAuth.currentUser).thenReturn(user);

        // Act
        await manager.loadStats();

        // Assert
        // EXPECTED: Real resilient fallback logic triggers ManagerDashboardState
        expect(manager.dashboardState, isA<ManagerDashboardState>());
      },
    );

    test(
      'TC-03 & TC-04: Should set storeName to "Syncing..." and storeId to null when empty',
      () async {
        // Arrange
        final user = MockUserSession();
        when(() => user.role).thenReturn('store_manager');
        when(() => user.fullName).thenReturn('Test Manager');
        when(() => mockAuth.currentUser).thenReturn(user);

        // Act
        await manager.loadStats();

        // Assert
        final state = manager.dashboardState;
        if (state is ManagerDashboardState) {
          expect(state.storeName, 'Syncing...');
          expect(
            state.storeId,
            equals(null),
          ); // TC-01 & TC-04 resilience requirement
        } else {
          fail('State was not ManagerDashboardState (TC-02 failure chained)');
        }
      },
    );

    test(
      'TC-05: Should pull personal metrics despite empty store cache',
      () async {
        // Arrange
        final user = MockUserSession();
        when(() => user.role).thenReturn('store_manager');
        when(() => user.fullName).thenReturn('Test');
        when(() => mockAuth.currentUser).thenReturn(user);

        // Seed some personal APs but no store-assigned data
        await db
            .into(db.cachedActionPlans)
            .insert(
              CachedActionPlansCompanion.insert(
                id: 'ap-1',
                groupTitle: 'Test Group',
                criteriaLabel: 'Test Criterion',
                planDescription: const Value('Personal Task'),
                status: const Value('open'),
                deadline: Value(DateTime.now().add(const Duration(days: 1))),
                storeId: const Value(null),
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );

        // Act
        await manager.loadStats();

        // Assert
        final state = manager.dashboardState as ManagerDashboardState;
        expect(state.openActionPlans, 1); // Pulled from global fallback
        expect(state.storeName, 'Syncing...');
      },
    );
  });
}
