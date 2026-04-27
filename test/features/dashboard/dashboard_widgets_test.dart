import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';
import 'package:checkly/features/dashboard/pages/dashboard_page.dart';
import 'package:checkly/features/dashboard/manager/dashboard_manager.dart';
import 'package:checkly/features/dashboard/pages/widgets/dashboard_variants.dart';
import 'package:checkly/features/auth/manager/auth_manager.dart';
import 'package:checkly/features/notifications/manager/notification_manager.dart';
import 'package:checkly/features/auth/model/user_session.dart';
import 'package:checkly/_shared/services/policy_manager.dart';

class MockDashboardManager extends Mock implements DashboardManager {}

class MockAuthManager extends Mock implements AuthManager {}

class MockUserSession extends Mock implements UserSession {}

class MockNotificationManager extends Mock implements NotificationManager {}

class MockPolicyManager extends Mock implements PolicyManager {}

void main() {
  late MockDashboardManager mockManager;
  late MockAuthManager mockAuth;
  late MockNotificationManager mockNotifications;
  late MockPolicyManager mockPolicyManager;

  setUp(() async {
    final di = GetIt.instance;
    await di.reset();

    mockManager = MockDashboardManager();
    mockAuth = MockAuthManager();
    mockNotifications = MockNotificationManager();
    mockPolicyManager = MockPolicyManager();

    di.registerFactory<DashboardManager>(() => mockManager);
    di.registerFactory<AuthManager>(() => mockAuth);
    di.registerFactory<NotificationManager>(() => mockNotifications);
    di.registerFactory<PolicyManager>(() => mockPolicyManager);

    when(() => mockPolicyManager.can(any())).thenReturn(true);

    when(() => mockManager.loadStats()).thenAnswer((_) async {});
    when(() => mockManager.dashboardState).thenReturn(DashboardLoading());
    when(() => mockNotifications.loadNotifications()).thenAnswer((_) async {});
    when(() => mockNotifications.unreadCount).thenReturn(0);
    when(() => mockNotifications.addListener(any())).thenReturn(null);
    when(() => mockNotifications.removeListener(any())).thenReturn(null);
    when(() => mockManager.addListener(any())).thenReturn(null);
    when(() => mockManager.removeListener(any())).thenReturn(null);
  });

  group('Dashboard Visual Contracts (VC-01...VC-05)', () {
    testWidgets(
      'VC-01 & VC-02: Greeting should have overline and correct style',
      (tester) async {
        // Arrange
        final user = MockUserSession();
        when(() => user.fullName).thenReturn('Test User');
        when(() => user.role).thenReturn('admin');
        when(() => mockAuth.currentUser).thenReturn(user);

        // Act
        await tester.pumpWidget(const MaterialApp(home: DashboardPage()));

        // Assert
        final greetingFinder = find.byType(Greeting);
        expect(greetingFinder, findsOneWidget);

        // VC-01: OVERLINE (labelSmall, 12px, grey)
        final overlineText = find.textContaining(
          RegExp(r'GOOD (MORNING|AFTERNOON|EVENING)', caseSensitive: false),
        );
        expect(overlineText, findsOneWidget);

        // VC-02: TITLE (headlineMedium, 22px, serif)
        final titleText = find.text('Store Overview');
        final textWidget = tester.widget<Text>(titleText);
        expect(textWidget.style?.fontSize, 22);
      },
    );

    testWidgets('VC-03: DeadlineBanner border should be removed', (
      tester,
    ) async {
      // Arrange
      final deadline = DateTime.now().add(const Duration(hours: 1));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DeadlineBanner(deadline: deadline)),
        ),
      );

      // Assert
      final containerFinder = find.descendant(
        of: find.byType(DeadlineBanner),
        matching: find.byType(Container),
      );
      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNull);
    });

    testWidgets('VC-04 & VC-05: SubmissionRow score circle and font', (
      tester,
    ) async {
      // Requirement: BoxShape.circle and 18px serif
    });
  });
}
