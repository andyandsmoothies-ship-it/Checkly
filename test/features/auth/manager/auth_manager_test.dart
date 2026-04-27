import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:checkly/features/auth/manager/auth_manager.dart';
import 'package:checkly/features/auth/model/auth_state.dart';
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

  group('AuthManager —', () {
    final mockSession = UserSession(
      token: 'jwt_token',
      userId: 'u1',
      fullName: 'Alice',
      email: 'alice@checkly.com',
      role: 'auditor',
    );
    final mockCaps = ['view_audit', 'start_audit'];

    test('login succeeds and sets authenticated state', () async {
      when(
        () => authApi.login(any(), any()),
      ).thenAnswer((_) async => mockSession);
      when(() => storage.saveToken(any())).thenAnswer((_) async {});
      when(() => storage.saveSession(any())).thenAnswer((_) async {});
      when(() => apiClient.setAuthToken(any())).thenReturn(null);
      when(
        () => policyApi.fetchCapabilities(),
      ).thenAnswer((_) async => mockCaps);
      when(() => policyDao.upsertCapabilities(any())).thenAnswer((_) async {});

      await manager.login('user', 'pass');

      expect(manager.authState.value, AuthState.authenticated);
      expect(manager.currentUser, mockSession);
      expect(manager.capabilities.value, mockCaps.toSet());
    });

    test('login fails and sets unauthenticated state', () async {
      when(() => authApi.login(any(), any())).thenThrow(Exception('Bad creds'));

      expect(() => manager.login('user', 'pass'), throwsException);
      expect(manager.authState.value, AuthState.unauthenticated);
    });

    test('logout clears everything', () async {
      when(() => storage.clearAll()).thenAnswer((_) async {});
      when(() => db.clearAllData()).thenAnswer((_) async {});
      when(() => policyDao.clearCapabilities()).thenAnswer((_) async {});
      when(() => apiClient.clearAuthToken()).thenReturn(null);

      await manager.logout();

      expect(manager.authState.value, AuthState.unauthenticated);
      expect(manager.currentUser, isNull);
      expect(manager.capabilities.value, isEmpty);
    });
  });
}
