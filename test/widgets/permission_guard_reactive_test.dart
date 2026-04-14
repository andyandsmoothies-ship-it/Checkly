import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checkly/_shared/widgets/permission_guard.dart';
import 'package:checkly/_shared/services/policy_manager.dart';
import 'package:get_it/get_it.dart';
import 'package:checkly/features/auth/manager/auth_manager.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthManager extends Mock implements AuthManager {}
class MockPolicyManager extends Mock implements PolicyManager {}

void main() {
  setUp(() {
    GetIt.I.allowReassignment = true;
  });

  tearDown(() {
    GetIt.I.reset();
  });

  testWidgets('PermissionGuard rebuilds reactively when capabilities change', (tester) async {
    // Arrange
    final authManager = MockAuthManager();
    final policyManager = MockPolicyManager();
    
    when(() => policyManager.can(any())).thenReturn(false);
    
    GetIt.I.registerSingleton<AuthManager>(authManager);
    GetIt.I.registerSingleton<PolicyManager>(policyManager);

    final capabilitiesNotifier = ValueNotifier<Set<String>>({'admin:access'});
    when(() => authManager.capabilities).thenReturn(capabilitiesNotifier);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PermissionGuard(
            capability: 'templates:create',
            fallback: const Text('Access Denied'),
            child: const Text('Granted Content'),
          ),
        ),
      ),
    );

    // Initial state: user doesn't have templates:create
    expect(find.text('Access Denied'), findsOneWidget);
    expect(find.text('Granted Content'), findsNothing);

    // Act: Capability becomes available (e.g. from background sync/foreground listener)
    when(() => policyManager.can('templates:create')).thenReturn(true);
    capabilitiesNotifier.value = {'admin:access', 'templates:create'};
    await tester.pumpAndSettle();

    // Assert: Widget should react to capabilities without full page rebuild
    expect(find.text('Access Denied'), findsNothing);
    expect(find.text('Granted Content'), findsOneWidget);
  });
}
