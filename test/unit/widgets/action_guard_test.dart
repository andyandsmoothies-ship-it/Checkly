import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:checkly/features/auth/manager/auth_manager.dart';
import 'package:checkly/_shared/widgets/action_guard.dart';

class MockAuthManager extends Mock implements AuthManager {}

void main() {
  late MockAuthManager mockAuthManager;

  setUp(() async {
    mockAuthManager = MockAuthManager();
    await GetIt.instance.reset();
    GetIt.instance.registerSingleton<AuthManager>(mockAuthManager);
  });

  group('ActionGuard Widget', () {
    testWidgets(
      'TC-07 actions=null, user has fallbackCapability -> Child widget rendered',
      (tester) async {
        final capabilitiesNotifier = ValueNotifier<Set<String>>({
          'submissions:create',
        });
        when(
          () => mockAuthManager.capabilities,
        ).thenReturn(capabilitiesNotifier);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ActionGuard(
                actions: null,
                requiredAction: 'edit',
                fallbackCapability: 'submissions:create',
                child: const Text('Child Widget'),
              ),
            ),
          ),
        );

        expect(find.text('Child Widget'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-08 actions=null, user lacks fallbackCapability -> SizedBox.shrink() rendered',
      (tester) async {
        final capabilitiesNotifier = ValueNotifier<Set<String>>({});
        when(
          () => mockAuthManager.capabilities,
        ).thenReturn(capabilitiesNotifier);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ActionGuard(
                actions: null,
                requiredAction: 'edit',
                fallbackCapability: 'submissions:create',
                child: const Text('Child Widget'),
              ),
            ),
          ),
        );

        expect(find.text('Child Widget'), findsNothing);
      },
    );

    testWidgets(
      'TC-09 actions=[] (empty list) -> SizedBox.shrink() rendered (explicit deny, no fallback)',
      (tester) async {
        final capabilitiesNotifier = ValueNotifier<Set<String>>({
          'submissions:create',
        });
        when(
          () => mockAuthManager.capabilities,
        ).thenReturn(capabilitiesNotifier);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ActionGuard(
                actions: const [],
                requiredAction: 'edit',
                fallbackCapability: 'submissions:create',
                child: const Text('Child Widget'),
              ),
            ),
          ),
        );

        expect(find.text('Child Widget'), findsNothing);
      },
    );

    testWidgets(
      'Online check: actions contains requiredAction -> Child widget rendered',
      (tester) async {
        final capabilitiesNotifier = ValueNotifier<Set<String>>({});
        when(
          () => mockAuthManager.capabilities,
        ).thenReturn(capabilitiesNotifier);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ActionGuard(
                actions: const ['view', 'edit'],
                requiredAction: 'edit',
                fallbackCapability: 'submissions:create',
                child: const Text('Child Widget'),
              ),
            ),
          ),
        );

        expect(find.text('Child Widget'), findsOneWidget);
      },
    );
  });
}
