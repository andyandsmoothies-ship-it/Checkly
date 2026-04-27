import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:checkly/features/auth/manager/auth_manager.dart';
import 'package:checkly/features/auth/model/user_session.dart';
import 'package:checkly/features/auth/services/auth_api_service.dart';
import 'package:checkly/features/auth/services/policy_api_service.dart';
import 'package:checkly/features/auth/services/secure_storage_service.dart';
import 'package:checkly/_shared/services/api_client.dart';
import 'package:checkly/_shared/database/dao/policy_dao.dart';
import 'package:checkly/_shared/database/database_service.dart';
import 'package:checkly/_shared/database/app_database.dart';

class MockAuthApiService extends Mock implements AuthApiService {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockApiClient extends Mock implements ApiClient {}

class MockPolicyApiService extends Mock implements PolicyApiService {}

class MockPolicyDao extends Mock implements PolicyDao {}

class MockDatabaseService extends Mock implements DatabaseService {}

class MockAppDatabase extends Mock implements AppDatabase {}

class FakeUserSession extends Fake implements UserSession {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeUserSession());
  });

  late AuthManager manager;
  late MockAuthApiService authApi;
  late MockSecureStorageService storage;
  late MockApiClient apiClient;
  late MockPolicyApiService policyApi;
  late MockPolicyDao policyDao;
  late MockDatabaseService dbService;
  late MockAppDatabase db;

  setUp(() {
    authApi = MockAuthApiService();
    storage = MockSecureStorageService();
    apiClient = MockApiClient();
    policyApi = MockPolicyApiService();
    policyDao = MockPolicyDao();
    dbService = MockDatabaseService();
    db = MockAppDatabase();

    when(() => dbService.db).thenReturn(db);

    manager = AuthManager(
      authApi: authApi,
      storage: storage,
      apiClient: apiClient,
      policyApi: policyApi,
      policyDao: policyDao,
      dbService: dbService,
    );
  });

  group('AuthManager — PBAC Slice 1: Capability Refresh —', () {
    test(
      'refreshCapabilities fetches fresh caps and updates cache when authenticated',
      () async {
        // Arrange - simulate authenticated state
        final mockSession = UserSession(
          token: 't',
          userId: 'u1',
          fullName: 'F',
          email: 'e',
          role: 'admin',
        );
        when(
          () => authApi.login(any(), any()),
        ).thenAnswer((_) async => mockSession);
        when(() => storage.saveToken(any())).thenAnswer((_) async {});
        when(() => storage.saveSession(any())).thenAnswer((_) async {});
        when(() => apiClient.setAuthToken(any())).thenReturn(null);
        when(
          () => policyApi.fetchCapabilities(),
        ).thenAnswer((_) async => ['initial_cap']);
        when(
          () => policyDao.upsertCapabilities(any()),
        ).thenAnswer((_) async {});

        await manager.login('user', 'pass');
        expect(manager.capabilities.value, {'initial_cap'});

        // Mock fresh capabilities for refresh
        when(
          () => policyApi.fetchCapabilities(),
        ).thenAnswer((_) async => ['fresh_cap']);

        // Act
        await manager.refreshCapabilities();

        // Assert
        expect(manager.capabilities.value, {'fresh_cap'});
        verify(() => policyDao.upsertCapabilities(['fresh_cap'])).called(1);
      },
    );

    test('refreshCapabilities is blocked by 5-minute cooldown guard', () async {
      // Arrange
      final mockSession = UserSession(
        token: 't',
        userId: 'u1',
        fullName: 'F',
        email: 'e',
        role: 'admin',
      );
      when(
        () => authApi.login(any(), any()),
      ).thenAnswer((_) async => mockSession);
      when(() => storage.saveToken(any())).thenAnswer((_) async {});
      when(() => storage.saveSession(any())).thenAnswer((_) async {});
      when(() => apiClient.setAuthToken(any())).thenReturn(null);
      when(
        () => policyApi.fetchCapabilities(),
      ).thenAnswer((_) async => ['cap']);
      when(() => policyDao.upsertCapabilities(any())).thenAnswer((_) async {});

      await manager.login('user', 'pass');

      // The login already called fetchCapabilities once.
      clearInteractions(policyApi);

      // Act (First refresh - should succeed)
      when(
        () => policyApi.fetchCapabilities(),
      ).thenAnswer((_) async => ['cap_1']);
      await manager.refreshCapabilities();

      // Second refresh immediately - should be blocked by cooldown
      when(
        () => policyApi.fetchCapabilities(),
      ).thenAnswer((_) async => ['cap_2']);
      await manager.refreshCapabilities();

      // Assert
      // fetchCapabilities should only be called ONCE during the two refresh attempts
      verify(() => policyApi.fetchCapabilities()).called(1);
      expect(manager.capabilities.value, {'cap_1'});
    });

    test('refreshCapabilities ignores call if unauthenticated', () async {
      // Act
      await manager.refreshCapabilities();

      // Assert
      verifyNever(() => policyApi.fetchCapabilities());
    });
  });
}
