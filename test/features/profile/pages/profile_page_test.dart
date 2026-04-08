/// Test Plan (Sentinel — Detroit Style)
/// ======================================
/// Target: ProfilePage widget
///
/// Contract source: test_contracts_profile_ui_fixes.md
///
/// Contracts:
/// 1. profilePage_StatsRow_IsAbsent        → _StatsRow must not exist in the tree
/// 2. profilePage_IdentityHeader_IsHorizontalRow → header uses Row (not Column) for avatar+email
/// 3. profilePage_SignOut_TriggersConfirmationDialog → tap "SIGN OUT" → AlertDialog appears
/// 4. profilePage_SignOut_ConfirmCallsLogout → confirm button → logout() called exactly once
/// 5. profilePage_Settings_RenderInCards   → at least 2 Card widgets in the tree
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
/// Header layout is tested by asserting Row/Column widget types in widget tree.

library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:checkly/features/auth/manager/auth_manager.dart';
import 'package:checkly/features/auth/model/user_session.dart';
import 'package:checkly/features/profile/pages/profile_page.dart';
import 'package:checkly/_shared/theme/theme_manager.dart';
import 'package:checkly/_shared/theme/app_theme.dart';
import 'package:checkly/_shared/database/database_service.dart';
import 'package:checkly/_shared/database/app_database.dart';
import 'package:drift/native.dart';


// ── Mock Declarations ─────────────────────────────────────────────────────────
// mocktail auto-generates correct overrides matching all interface signatures.

class _MockAuthManager extends Mock implements AuthManager {}
class _MockThemeManager extends Mock implements ThemeManager {}
class _MockDatabaseService extends Mock implements DatabaseService {}

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

_MockAuthManager _registerDi({UserSession? user}) {
  final mockAuth = _MockAuthManager();
  final mockTheme = _MockThemeManager();

  // AuthManager stubs
  when(() => mockAuth.currentUser).thenReturn(user ?? _auditorUser);
  when(() => mockAuth.logout()).thenAnswer((_) async {});
  when(() => mockAuth.addListener(any())).thenReturn(null);
  when(() => mockAuth.removeListener(any())).thenReturn(null);

  // ThemeManager stubs — ListenableBuilder calls addListener/removeListener
  when(() => mockTheme.themeMode).thenReturn(ThemeMode.light);
  when(() => mockTheme.toggleTheme()).thenAnswer((_) async {});
  when(() => mockTheme.addListener(any())).thenReturn(null);
  when(() => mockTheme.removeListener(any())).thenReturn(null);

  final di = GetIt.instance;
  di.registerSingleton<AuthManager>(mockAuth);
  di.registerSingleton<ThemeManager>(mockTheme);

  final mockDbService = _MockDatabaseService();
  final testDb = AppDatabase.forTesting(NativeDatabase.memory());
  when(() => mockDbService.db).thenReturn(testDb);
  di.registerSingleton<DatabaseService>(mockDbService);

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
  setUp(() => GetIt.instance.reset());
  tearDown(() => GetIt.instance.reset());

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
          reason: '_StatsRow label "Avg Audit Score" must be gone post-refactor.',
        );
        expect(
          find.text('This Month'),
          findsNothing,
          reason: '_StatsRow label "This Month" must be gone post-refactor.',
        );
      },
    );
  });

  // ─── Contract 2: Identity Header is Horizontal ────────────────────────────

  group('ProfilePage — Identity Header Layout', () {
    testWidgets(
      'profilePage_IdentityHeader_IsHorizontalRow — CircleAvatar and email must share a Row ancestor',
      (tester) async {
        // VALID RED: Current _ProfileCard wraps avatar+email in a Column (line 181).
        // Fix needed: change _ProfileCard to use a Row for the identity section.
        _registerDi(user: _adminUser);
        await pumpProfilePage(tester);

        // A Row ancestor of CircleAvatar must exist
        final rowAroundAvatar = find.ancestor(
          of: find.byType(CircleAvatar),
          matching: find.byType(Row),
        );
        expect(
          rowAroundAvatar,
          findsAtLeastNWidgets(1),
          reason: 'CircleAvatar must be inside a Row for horizontal header layout.',
        );

        // That same Row must also contain the email text as a descendant
        expect(
          find.descendant(
            of: rowAroundAvatar.first,
            matching: find.text('admin@test.com'),
          ),
          findsOneWidget,
          reason: 'Email text must be a sibling/descendant of CircleAvatar within the Row.',
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
          reason: 'At least 2 Card widgets (Management + General sections) must exist.',
        );
      },
    );
  });

  // ─── Contract: Dark Mode Compatibility ────────────────────────────────────

  group('ProfilePage — Dark Mode Compatibility', () {
    testWidgets(
      'ProfilePage_EmailText_UsesOnSurfaceColor — email text color must adapt to theme brightness',
      (tester) async {
        // VALID RED: Email text color is hardcoded to AppTheme.charcoal on line 176 of profile_page.dart.
        // Fix needed: Change Color to theme.colorScheme.onSurface (or variant).
        final darkTheme = AppTheme.dark;
        _registerDi(user: _adminUser);

        // We use a custom pump here to inject the DARK theme specifically
        await tester.pumpWidget(
          MaterialApp.router(
            theme: darkTheme,
            routerConfig: GoRouter(
              initialLocation: '/profile',
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (context, state) => const ProfilePage(),
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        final emailTextFinder = find.text('admin@test.com');
        final textWidget = tester.widget<Text>(emailTextFinder);
        final color = textWidget.style?.color;

        expect(
          color,
          isNot(AppTheme.charcoal),
          reason: 'Email text color should not be hardcoded to charcoal in dark mode.',
        );

        expect(
          color,
          darkTheme.colorScheme.onSurface,
          reason:
              'Email text color should match theme.colorScheme.onSurface in dark mode.',
        );
      },
    );
  });

  // ─── Contract: Real Name Display ──────────────────────────────────────────

  group('ProfilePage — Real Name Display', () {
    testWidgets(
      'ProfilePage_DisplayName_ShowsFullName — header must prefer fullName over email',
      (tester) async {
        // VALID RED: ProfilePage currently only binds to user.email (line 22).
        // Fix needed: update build() to use user.fullName ?? user.email.
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
          reason: 'Full name "Anh Tuan" should be visible in the header.',
        );
        expect(
          find.text('test@checkly.app'),
          findsNothing,
          reason: 'Email should be hidden when fullName is present.',
        );
      },
    );


    testWidgets(
      'ProfilePage_DisplayName_FallsBackToEmail — header must show email when fullName is null',
      (tester) async {
        // Contract 1: Empty/Cancel State
        const userNoName = UserSession(
          userId: '4',
          email: 'no-name@checkly.app',
          role: 'auditor',
          token: 'token',
          fullName: null,
        );

        _registerDi(user: userNoName);
        await pumpProfilePage(tester);

        expect(
          find.text('no-name@checkly.app'),
          findsOneWidget,
          reason: 'Email should be visible when fullName is null.',
        );
      },
    );

    test('ProfilePage_Initials_FromFullName — getInitials must handle name-to-initials logic', () {
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
    });
  });
}
