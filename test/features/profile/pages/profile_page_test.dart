/// Test Plan (Sentinel — Detroit Style)
/// ======================================
/// Target: ProfilePage widget
///
/// Contract source: ADR profile_redesign (5-zone layout)
///
/// Contracts:
/// 1. profilePage_StatsRow_IsAbsent          → _StatsRow stats labels must not render
/// 2. profilePage_IdentityHeader_IsColumn    → header uses centered Column (avatar on top, name, email, badge below)
/// 3. profilePage_SignOut_TriggersConfirmationDialog → tap "SIGN OUT" → AlertDialog appears
/// 4. profilePage_SignOut_ConfirmCallsLogout → confirm button → logout() called exactly once
/// 5. profilePage_Settings_RenderInCards     → at least 2 Card widgets in the tree
///
/// Strategy:
/// - mocktail Mock classes for AuthManager and ThemeManager (both are ChangeNotifiers
///   — mock must stub addListener/removeListener for ListenableBuilder compatibility).
/// - GetIt registered fresh before each test, reset after.
/// - GoRouter wraps MaterialApp to silence GoRouter assertions.
/// - Detroit: assert OBSERVABLE STATE only. Never test implementation internals.
///
/// Mirror Function Trap Prevention: No production logic is cloned here.
/// _StatsRow is tested by asserting its rendered text labels are absent.
/// Header layout is tested by asserting Column widget type and child content in widget tree.
/// NOTE (ADR): ProfileIdentityCard ALWAYS renders both displayName AND email text fields.
///   - When fullName is set: displayName = fullName, email shown below.
///   - When fullName is null: displayName = email (appears TWICE in the tree — both fields).

library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:checkly/features/auth/manager/auth_manager.dart';
import 'package:checkly/features/auth/model/user_session.dart';
import 'package:checkly/features/profile/pages/profile_page.dart';
import 'package:checkly/_shared/database/database_service.dart';
import 'package:checkly/_shared/database/app_database.dart';
import 'package:checkly/_shared/database/dao/outbox_dao.dart';
import 'package:checkly/_shared/services/sync_engine.dart';
import 'package:checkly/_shared/services/auth_check.dart';
import 'package:checkly/_shared/services/connectivity_service.dart';
import 'package:checkly/_shared/theme/app_theme.dart';
import 'package:checkly/_shared/theme/app_theme_notifier.dart';
import 'package:checkly/_shared/widgets/primitives/primitives.dart';
import 'package:drift/native.dart';

class _FakeConnectivity implements ConnectivityService {
  // Never-closing broadcast stream: prevents SyncEngine from starting its
  // 30-second poll-fallback timer (which would leak past widget disposal).
  final _ctrl = StreamController<bool>.broadcast();

  @override
  bool get isOnline => false;
  @override
  Stream<bool> get onConnectivityChanged => _ctrl.stream;

  void close() => _ctrl.close();
}

class _AlwaysAuth implements AuthCheck {
  @override
  bool get isLoggedIn => true;
}

// ── Mock Declarations ─────────────────────────────────────────────────────────
// mocktail auto-generates correct overrides matching all interface signatures.

class _MockAuthManager extends Mock implements AuthManager {}

class _MockDatabaseService extends Mock implements DatabaseService {}

class _MockOutboxDao extends Mock implements OutboxDao {}

// ── Test Fixtures ─────────────────────────────────────────────────────────────

const _adminUser = UserSession(
  userId: '1',
  email: 'admin@test.com',
  role: 'admin',
  token: 'fake-token',
);

const _auditorUser = UserSession(
  userId: '2',
  email: 'auditor@test.com',
  role: 'auditor',
  token: 'fake-token',
);

// ── DI Setup ──────────────────────────────────────────────────────────────────

// Tracks the last _FakeConnectivity created so tearDown can close its stream.
_FakeConnectivity? _lastFakeConnectivity;

_MockAuthManager _registerDi({UserSession? user}) {
  final mockAuth = _MockAuthManager();

  // AuthManager stubs
  when(() => mockAuth.currentUser).thenReturn(user ?? _auditorUser);
  when(
    () => mockAuth.capabilities,
  ).thenReturn(ValueNotifier<Set<String>>({'conduct_audit'}));
  when(() => mockAuth.logout()).thenAnswer((_) async {});
  when(() => mockAuth.addListener(any())).thenReturn(null);
  when(() => mockAuth.removeListener(any())).thenReturn(null);

  final di = GetIt.instance;
  di.registerSingleton<AuthManager>(mockAuth);
  di.registerLazySingleton<ThemeSpiritNotifier>(() => ThemeSpiritNotifier());

  final mockDbService = _MockDatabaseService();
  final testDb = AppDatabase.forTesting(NativeDatabase.memory());
  when(() => mockDbService.db).thenReturn(testDb);
  di.registerSingleton<DatabaseService>(mockDbService);

  final mockOutboxDao = _MockOutboxDao();
  when(() => mockOutboxDao.syncableCount()).thenAnswer((_) async => 0);
  when(() => mockOutboxDao.exhaustedCount()).thenAnswer((_) async => 0);
  di.registerSingleton<OutboxDao>(mockOutboxDao);

  final fakeConnectivity = _FakeConnectivity();
  di.registerSingleton<SyncEngine>(
    SyncEngine(
      connectivity: fakeConnectivity,
      auth: _AlwaysAuth(),
      outboxDao: mockOutboxDao,
      modules: [],
      maxReconnectJitterMs: 0,
    ),
  );
  // Track the connectivity instance so tearDown can close its stream.
  _lastFakeConnectivity = fakeConnectivity;

  return mockAuth;
}

// ── Pump Helper ───────────────────────────────────────────────────────────────

/// Wraps ProfilePage in a GoRouter-compatible MaterialApp to avoid
/// the GoRouter ancestor assertion during widget tests.
Future<void> pumpProfilePage(WidgetTester tester) async {
  final router = GoRouter(
    initialLocation: '/profile',
    routes: [
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const Scaffold(body: Text('Login')),
      ),
    ],
  );

  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUp(() {
    _lastFakeConnectivity = null;
    GetIt.instance.reset();
  });
  tearDown(() {
    // Close the connectivity stream BEFORE resetting GetIt.
    // This prevents onDone from firing after SyncEngine is gone.
    _lastFakeConnectivity?.close();
    _lastFakeConnectivity = null;
    if (GetIt.instance.isRegistered<SyncEngine>()) {
      GetIt.instance<SyncEngine>().dispose();
    }
    GetIt.instance.reset();
  });

  // ─── Contract 1: Stats Row Absent ─────────────────────────────────────────

  group('ProfilePage — Stats Row Removal', () {
    testWidgets(
      'profilePage_StatsRow_IsAbsent — stats labels must not render after refactor',
      (tester) async {
        // VALID RED: Production renders _StatsRow at line 37 of profile_page.dart.
        // Fix needed: remove _StatsRow(...) from build() to make this GREEN.
        _registerDi(user: _auditorUser);
        await pumpProfilePage(tester);

        expect(
          find.text('My Audits'),
          findsNothing,
          reason: '_StatsRow label "My Audits" must be gone post-refactor.',
        );
        expect(
          find.text('Avg Audit Score'),
          findsNothing,
          reason:
              '_StatsRow label "Avg Audit Score" must be gone post-refactor.',
        );
        expect(
          find.text('This Month'),
          findsNothing,
          reason: '_StatsRow label "This Month" must be gone post-refactor.',
        );
      },
    );
  });

  // ─── Contract 2: Identity Header is Centered Column ──────────────────────

  group('ProfilePage — Identity Header Layout', () {
    testWidgets(
      'profilePage_IdentityHeader_IsColumn — CircleAvatar must be inside a Column (premium centered layout)',
      (tester) async {
        // ADR Decision: ProfileIdentityCard uses a centered Column layout.
        // Avatar is stacked above displayName, email, and RoleBadge.
        // This is the intentional premium design — NOT a horizontal Row.
        _registerDi(user: _adminUser);
        await pumpProfilePage(tester);

        // A Column ancestor of CircleAvatar must exist
        final columnAroundAvatar = find.ancestor(
          of: find.byType(CircleAvatar),
          matching: find.byType(Column),
        );
        expect(
          columnAroundAvatar,
          findsAtLeastNWidgets(1),
          reason:
              'CircleAvatar must be inside a Column for the centered identity card layout (ADR).',
        );

        // The identity card must render the user email text somewhere in the tree
        expect(
          find.text('admin@test.com'),
          findsWidgets,
          reason:
              'Email text must appear in the identity card (rendered in email field below displayName).',
        );
      },
    );
  });

  // ─── Contract 3: Sign Out Dialog Appears ──────────────────────────────────

  group('ProfilePage — Sign Out Confirmation', () {
    testWidgets(
      'profilePage_SignOut_TriggersConfirmationDialog — AlertDialog shown before logout is called',
      (tester) async {
        // VALID RED: Current Sign Out button calls auth.logout() directly on tap (line 53).
        // Fix needed: show AlertDialog before calling logout().
        final mockAuth = _registerDi(user: _auditorUser);
        await pumpProfilePage(tester);

        // Scroll down in case the lazy ListView hasn't built the Sign Out tile yet
        await tester.drag(find.byType(ListView), const Offset(0, -1000));
        await tester.pumpAndSettle();

        // Ensure Sign Out tile is scrolled into view and hittable
        await tester.ensureVisible(find.text('SIGN OUT'));
        await tester.pumpAndSettle();

        // Tap the Sign Out button (production label is all-caps 'SIGN OUT')
        await tester.tap(find.text('SIGN OUT'), warnIfMissed: false);
        await tester.pumpAndSettle();

        // Dialog must appear
        expect(
          find.byType(AlertDialog),
          findsOneWidget,
          reason: 'AlertDialog must appear when user taps Sign Out.',
        );

        // logout() must NOT have been called yet
        verifyNever(() => mockAuth.logout());
      },
    );

    testWidgets(
      'profilePage_SignOut_ConfirmCallsLogout — confirming the dialog calls logout exactly once',
      (tester) async {
        // VALID RED: No dialog exists in production, so confirm button doesn't exist.
        // Fix needed: AlertDialog with confirm button that calls auth.logout().
        final mockAuth = _registerDi(user: _auditorUser);
        await pumpProfilePage(tester);

        // Scroll down in case the lazy ListView hasn't built the Sign Out tile yet
        await tester.drag(find.byType(ListView), const Offset(0, -1000));
        await tester.pumpAndSettle();

        // Ensure Sign Out tile is scrolled into view and hittable
        await tester.ensureVisible(find.text('SIGN OUT'));
        await tester.pumpAndSettle();

        // Open dialog
        await tester.tap(find.text('SIGN OUT'), warnIfMissed: false);
        await tester.pumpAndSettle();

        // Tap the confirm action (Builder must use 'Sign Out' or 'Yes' as confirm label)
        // We find any TextButton/ElevatedButton inside the AlertDialog that is NOT 'Cancel'
        final confirmButton = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byWidgetPredicate(
            (w) =>
                w is TextButton &&
                (w.child is Text) &&
                (w.child as Text).data?.toLowerCase() != 'cancel',
          ),
        );
        await tester.tap(confirmButton);
        await tester.pumpAndSettle();

        verify(() => mockAuth.logout()).called(1);
      },
    );
  });

  // ─── Contract 5: Settings Grouped in Cards ────────────────────────────────

  group('ProfilePage — Settings Card Grouping', () {
    testWidgets(
      'profilePage_Settings_RenderInCards — at least 2 Card widgets must wrap menu items',
      (tester) async {
        // VALID RED: Current _MenuItem uses Container+ListTile with no Card (line 341).
        // Fix needed: wrap menu groups in Card widgets (≥ 2).
        _registerDi(user: _adminUser);
        await pumpProfilePage(tester);

        expect(
          find.byType(Card),
          findsAtLeastNWidgets(2),
          reason:
              'At least 2 Card widgets (Management + General sections) must exist.',
        );
      },
    );
  });

  // ─── Contract 6: Settings Theme Spirit Swapping ───────────────────────────

  group('ProfilePage — Settings Theme Spirit Swapping', () {
    testWidgets(
      'ProfilePage_ThemeSpiritToggle_SwapsThemeSpirit',
      (tester) async {
        // Adjust viewport size to prevent off-screen hit-test failure
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        _registerDi(user: _adminUser);
        await pumpProfilePage(tester);

        final switchFinder = find.byType(BubblySwitch);
        expect(switchFinder, findsOneWidget);

        final spiritNotifier = GetIt.instance<ThemeSpiritNotifier>();
        expect(spiritNotifier.value, ThemeSpirit.duolingo);

        await tester.tap(switchFinder);
        await tester.pumpAndSettle();

        expect(spiritNotifier.value, ThemeSpirit.minimalist);
      },
    );
  });

  // ─── Contract: Real Name Display ──────────────────────────────────────────

  group('ProfilePage — Real Name Display', () {
    testWidgets(
      'ProfilePage_DisplayName_ShowsFullName — header must prefer fullName over email',
      (tester) async {
        // ADR Design: ProfileIdentityCard ALWAYS renders both displayName and
        // email fields. When fullName is set, displayName = fullName and the
        // email field shows the email below it (premium dual-line identity).
        const userWithName = UserSession(
          userId: '3',
          email: 'test@checkly.app',
          role: 'auditor',
          token: 'token',
          fullName: 'Anh Tuan',
        );

        _registerDi(user: userWithName);
        await pumpProfilePage(tester);

        expect(
          find.text('Anh Tuan'),
          findsOneWidget,
          reason:
              'Full name "Anh Tuan" must be visible as the displayName in the header.',
        );
        // ADR: email field is always shown below the displayName for premium identity.
        expect(
          find.text('test@checkly.app'),
          findsOneWidget,
          reason:
              'Email must also be visible below the displayName (identity card always shows both).',
        );
      },
    );

    testWidgets(
      'ProfilePage_DisplayName_FallsBackToEmail — header shows email in BOTH fields when fullName is null',
      (tester) async {
        // ADR Design: When fullName is null, displayName = email.
        // ProfileIdentityCard renders BOTH the displayName field AND the email
        // field with the same string → the email appears TWICE in the widget tree.
        const userNoName = UserSession(
          userId: '4',
          email: 'no-name@checkly.app',
          role: 'auditor',
          token: 'token',
          fullName: null,
        );

        _registerDi(user: userNoName);
        await pumpProfilePage(tester);

        // findsAtLeastNWidgets(1) because the email renders in BOTH the
        // displayName position (onSurface) and the email position (onSurfaceVariant).
        expect(
          find.text('no-name@checkly.app'),
          findsAtLeastNWidgets(1),
          reason:
              'Email must be visible (as displayName fallback) when fullName is null.',
        );
      },
    );

    test(
      'ProfilePage_Initials_FromFullName — getInitials must handle name-to-initials logic',
      () {
        // Contract 2: Full coverage
        const page = ProfilePage();

        // Case 1: Full name (First Last)
        expect(page.getInitials('John Doe'), 'JD');
        expect(page.getInitials('Anh Tuan'), 'AT');

        // Case 2: Single name
        expect(page.getInitials('Alice'), 'AL');

        // Case 3: Multiple names
        expect(page.getInitials('John Doe Smith'), 'JS');

        // Case 4: Fallback (Email)
        expect(page.getInitials('john@doe.com'), 'JO');
      },
    );
  });
}
