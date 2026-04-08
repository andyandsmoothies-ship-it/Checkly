import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checkly/_shared/widgets/permission_guard.dart';
import 'package:checkly/_shared/services/policy_manager.dart';
import 'package:get_it/get_it.dart';
import 'package:checkly/features/auth/manager/auth_manager.dart';
import 'package:checkly/features/auth/model/auth_state.dart';
import 'package:checkly/features/auth/model/user_session.dart';

class _FakeAuthManager extends ChangeNotifier implements AuthManager {
  final ValueNotifier<Set<String>> _caps;
  _FakeAuthManager(Set<String> capabilities) : _caps = ValueNotifier(capabilities);

  @override ValueListenable<Set<String>> get capabilities => _caps;
  @override ValueListenable<AuthState> get authState => ValueNotifier(AuthState.authenticated);
  @override UserSession? get currentUser => null;
  @override Future<void> login(String e, String p) async {}
  @override Future<void> logout() async {}
  @override Future<void> tryAutoLogin() async {}
}

// Since PolicyManager isn't an interface, we can just instantiate it with our FakeAuthManager
// and register it in GetIt because PermissionGuard uses _di<PolicyManager>().

void main() {
  setUp(() {
    GetIt.I.allowReassignment = true;
  });

  tearDown(() {
    GetIt.I.reset();
  });

  Widget buildTestWidget(String capability, Set<String> currentCapabilities, {Widget? fallback}) {
    final auth = _FakeAuthManager(currentCapabilities);
    GetIt.I.registerSingleton<AuthManager>(auth);
    GetIt.I.registerSingleton<PolicyManager>(PolicyManager(auth: auth));

    return MaterialApp(
      home: Scaffold(
        body: PermissionGuard(
          capability: capability,
          fallback: fallback,
          child: const Text('Child Widget'),
        ),
      ),
    );
  }

  testWidgets('PG-01: Renders child when can() evaluates to true', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget('templates:create', {'templates:create'}));
    
    expect(find.text('Child Widget'), findsOneWidget);
  });

  testWidgets('PG-02: Renders fallback widget when can() evaluates to false', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget(
      'templates:create', 
      {'admin:access'},
      fallback: const Text('Fallback Widget'),
    ));
    
    expect(find.text('Child Widget'), findsNothing);
    expect(find.text('Fallback Widget'), findsOneWidget);
  });

  testWidgets('PG-03: (Gap AC) Renders SizedBox.shrink when fallback is null and can() is false', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget('templates:create', {'other:capability'}));
    
    expect(find.text('Child Widget'), findsNothing);
    expect(find.byType(SizedBox), findsOneWidget); 
  });
}
