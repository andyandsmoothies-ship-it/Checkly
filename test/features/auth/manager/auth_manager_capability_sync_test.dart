import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:checkly/features/auth/manager/auth_manager.dart';
import 'package:checkly/features/auth/model/auth_state.dart';
import 'package:checkly/features/auth/model/user_session.dart';
import 'package:checkly/features/auth/services/auth_api_service.dart';
import 'package:checkly/features/auth/services/policy_api_service.dart';
import 'package:checkly/features/auth/services/secure_storage_service.dart';
import 'package:checkly/_shared/database/app_database.dart';
import 'package:checkly/_shared/database/dao/policy_dao.dart';
import 'package:checkly/_shared/services/api_client.dart';

// ── Mocktail stubs ────────────────────────────────────────────────────────────
class _MockAuthApiService extends Mock implements AuthApiService {}
class _MockPolicyApiService extends Mock implements PolicyApiService {}
class _MockSecureStorageService extends Mock implements SecureStorageService {}
class _MockApiClient extends Mock implements ApiClient {}

// ── Shared test fixture ───────────────────────────────────────────────────────
const _testSession = UserSession(
  userId: 'u-001',
  email: 'admin@test.com',
  role: 'admin',
  token: 'fake.jwt.token',
  fullName: 'Test Admin',
);

void main() {
  late AuthManager authManager;
  late AppDatabase testDb;
  late PolicyDao policyDao;
  late _MockAuthApiService mockAuth;
  late _MockPolicyApiService mockPolicyApi;
  late _MockSecureStorageService mockStorage;
  late _MockApiClient mockApiClient;

  // Mocktail requires fallback values for custom types used with any() matcher.
  setUpAll(() {
    registerFallbackValue(
      const UserSession(
        userId: '',
        email: '',
        role: '',
        token: '',
      ),
    );
  });

  setUp(() {
    testDb = AppDatabase.forTesting(NativeDatabase.memory());
    policyDao = PolicyDao(testDb);
    mockAuth = _MockAuthApiService();
    mockPolicyApi = _MockPolicyApiService();
    mockStorage = _MockSecureStorageService();
    mockApiClient = _MockApiClient();

    // Default no-op stubs for storage and apiClient (used by login / tryAutoLogin)
    when(() => mockStorage.saveToken(any())).thenAnswer((_) async {});
    when(() => mockStorage.saveSession(any())).thenAnswer((_) async {});
    when(() => mockStorage.getToken()).thenAnswer((_) async => _testSession.token);
    when(() => mockStorage.getSession()).thenAnswer((_) async => _testSession);
    when(() => mockStorage.clearAll()).thenAnswer((_) async {});
    when(() => mockApiClient.setAuthToken(any())).thenReturn(null);
    when(() => mockApiClient.clearAuthToken()).thenReturn(null);

    authManager = AuthManager(
      authApi: mockAuth,
      storage: mockStorage,
      apiClient: mockApiClient,
      policyApi: mockPolicyApi,
      policyDao: policyDao,
    );
  });

  tearDown(() => testDb.close());

  group('AuthManager — Capability Sync (ATDD Slice 4)', () {
    // AT-01: Happy Path —————————————————————————————————————————————————————
    test('AT-01: login() populates capabilities from API', () async {
      // Arrange
      when(() => mockAuth.login(any(), any()))
          .thenAnswer((_) async => _testSession);
      when(() => mockPolicyApi.fetchCapabilities())
          .thenAnswer((_) async => ['submissions:list', 'templates:create']);

      // Act
      await authManager.login('admin@test.com', 'password');

      // Assert — memory set populated
      expect(
        authManager.capabilities.value,
        containsAll(['submissions:list', 'templates:create']),
      );
      // Assert — auth state is authenticated
      expect(authManager.authState.value, AuthState.authenticated);
      // Assert — Drift table persisted (exit postcondition)
      final persisted = await policyDao.getCapabilities();
      expect(persisted, containsAll(['submissions:list', 'templates:create']));
    });

    // AT-02: Offline / Boundary ——————————————————————————————————————————————
    test('AT-02: tryAutoLogin() restores capabilities from Drift — no API call',
        () async {
      // Pre-seed the Drift table (simulates a previous active login session)
      await policyDao.upsertCapabilities(['submissions:list']);

      // Act — simulate cold restart (tryAutoLogin reads only from Drift)
      await authManager.tryAutoLogin();

      // Assert — capabilities restored from cache
      expect(authManager.capabilities.value, contains('submissions:list'));
      // Assert — fetchCapabilities NEVER called (no network hit)
      verifyNever(() => mockPolicyApi.fetchCapabilities());
    });

    // AT-03: Security / Cleanup ——————————————————————————————————————————————
    test('AT-03: logout() clears capabilities from Drift and memory', () async {
      // Arrange — login first to populate both memory and Drift
      when(() => mockAuth.login(any(), any()))
          .thenAnswer((_) async => _testSession);
      when(() => mockPolicyApi.fetchCapabilities())
          .thenAnswer((_) async => ['submissions:list']);
      await authManager.login('admin@test.com', 'password');

      // Act
      await authManager.logout();

      // Assert — memory cleared
      expect(authManager.capabilities.value, isEmpty);
      // Assert — Drift cleared (exit postcondition)
      expect(await policyDao.getCapabilities(), isEmpty);
    });

    // AT-04: Fail-Open Resilience ————————————————————————————————————————————
    test('AT-04: login() succeeds even if capability fetch fails (fail-open)',
        () async {
      // Arrange — auth succeeds, capability API throws
      when(() => mockAuth.login(any(), any()))
          .thenAnswer((_) async => _testSession);
      when(() => mockPolicyApi.fetchCapabilities())
          .thenThrow(Exception('Server down'));

      // Act & Assert — no exception thrown from login()
      await expectLater(
        authManager.login('admin@test.com', 'password'),
        completes,
      );
      // Assert — auth still succeeded despite capability sync failure
      expect(authManager.authState.value, AuthState.authenticated);
      // Assert — capabilities default to empty (not crashed)
      expect(authManager.capabilities.value, isEmpty);
    });
  });
}
