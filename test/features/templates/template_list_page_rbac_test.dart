import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter/foundation.dart';

import 'package:checkly/features/auth/manager/auth_manager.dart';
import 'package:checkly/features/auth/model/auth_state.dart';
import 'package:checkly/features/auth/model/user_session.dart';
import 'package:checkly/features/templates/manager/template_manager.dart';
import 'package:checkly/features/templates/pages/template_list_page.dart';
import 'package:checkly/features/templates/models/template_dto.dart';
import 'package:checkly/_shared/services/policy_manager.dart';

class _StubAuthManager extends ChangeNotifier implements AuthManager {
  @override
  Future<void> refreshCapabilities() async {}

  final String? role;
  final Set<String> _caps;
  _StubAuthManager({this.role, Set<String>? capabilities})
    : _caps = capabilities ?? {};

  @override
  ValueListenable<AuthState> get authState => ValueNotifier(
    role != null ? AuthState.authenticated : AuthState.unauthenticated,
  );

  @override
  UserSession? get currentUser => role != null
      ? UserSession(
          userId: '1',
          fullName: 'Test',
          email: 'test@x.com',
          role: role!,
          token: 'tok',
        )
      : null;

  @override
  ValueListenable<Set<String>> get capabilities => ValueNotifier(_caps);

  @override
  Future<void> login(String e, String p) async {}
  @override
  Future<void> logout() async {}
  @override
  Future<void> tryAutoLogin() async {}
}

class MockTemplateManager extends Mock implements TemplateManager {}

void main() {
  late MockTemplateManager mockManager;

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    GetIt.I.allowReassignment = true;
    mockManager = MockTemplateManager();
    final templatesNotifier = ValueNotifier<List<TemplateDto>>([
      TemplateDto(
        id: 'abc-123',
        title: 'Mock Template',
        type: 'qc',
        version: 1,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ]);
    when(() => mockManager.templates).thenReturn(templatesNotifier);
    when(() => mockManager.isLoading).thenReturn(ValueNotifier<bool>(false));
    when(() => mockManager.error).thenReturn(null);
    when(() => mockManager.loadTemplates()).thenAnswer((_) async {});
    when(() => mockManager.addListener(any())).thenAnswer((_) {});
    when(() => mockManager.removeListener(any())).thenAnswer((_) {});

    GetIt.I.registerSingleton<TemplateManager>(mockManager);
  });

  tearDown(() {
    GetIt.I.reset();
  });

  void arrangeAuthRole(String role) {
    // Admin gets templates:create capability so PermissionGuard shows FAB.
    // Admin also needs granular capabilities to see Quick Start, Edit, Duplicate, Delete.
    // Auditor needs submissions:create to see Quick Start.
    Set<String> caps = {};
    if (role == 'admin') {
      caps = {
        'templates:create',
        'admin:access',
        'submissions:create',
        'templates:update',
        'templates:delete',
      };
    } else if (role == 'auditor') {
      caps = {'submissions:create'};
    }

    final auth = _StubAuthManager(role: role, capabilities: caps);
    GetIt.I.registerSingleton<AuthManager>(auth);
    GetIt.I.registerSingleton<PolicyManager>(PolicyManager(auth: auth));
  }

  Widget createSubject() {
    return const MaterialApp(home: TemplateListPage());
  }

  group('TemplateListPage RBAC Tests', () {
    testWidgets('TC-06a: FAB is hidden for auditor role', (tester) async {
      arrangeAuthRole('auditor');
      await tester.pumpWidget(createSubject());
      await tester.pump();
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('TC-06b: FAB is hidden for area_manager role', (tester) async {
      arrangeAuthRole('area_manager');
      await tester.pumpWidget(createSubject());
      await tester.pump();
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('TC-06c: FAB is visible only for admin role', (tester) async {
      arrangeAuthRole('admin');
      await tester.pumpWidget(createSubject());
      await tester.pump();
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('TC-07: Context menu admin sees all 4 items', (tester) async {
      arrangeAuthRole('admin');
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // ExpansionTile starts collapsed — tap the section header to expand it.
      await tester.tap(find.text('QUALITY CONTROL'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Quick Start'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Duplicate'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('TC-08: Context menu auditor sees only Quick Start', (
      tester,
    ) async {
      arrangeAuthRole('auditor');
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // ExpansionTile starts collapsed — tap the section header to expand it.
      await tester.tap(find.text('QUALITY CONTROL'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Quick Start'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Duplicate'), findsNothing);
      expect(find.text('Delete'), findsNothing);
    });
  });
}
