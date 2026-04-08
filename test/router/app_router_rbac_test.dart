import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:checkly/features/auth/manager/auth_manager.dart';
import 'package:checkly/features/auth/model/auth_state.dart';
import 'package:checkly/features/auth/model/user_session.dart';
import 'package:checkly/_shared/router/app_router.dart';

class _StubAuthManager extends ChangeNotifier implements AuthManager {
  final String? role;
  _StubAuthManager({this.role});

  @override
  ValueListenable<AuthState> get authState => ValueNotifier(
    role != null ? AuthState.authenticated : AuthState.unauthenticated
  );

  @override
  UserSession? get currentUser => role != null
    ? UserSession(userId: '1', fullName: 'Test', email: 'test@x.com', role: role!, token: 'tok')
    : null;

  @override Future<void> login(String e, String p) async {}
  @override Future<void> logout() async {}
  @override Future<void> tryAutoLogin() async {}
}

class MockBuildContext extends Fake implements BuildContext {}

class MockGoRouterState extends Fake implements GoRouterState {
  final String _matchedLocation;
  MockGoRouterState(this._matchedLocation);

  @override
  String get matchedLocation => _matchedLocation;
}

void main() {
  setUp(() {
    GetIt.I.allowReassignment = true;
  });

  tearDown(() {
    GetIt.I.reset();
  });

  void arrangeAuthRole(String role) {
    GetIt.I.registerSingleton<AuthManager>(_StubAuthManager(role: role));
  }

  String? runRedirect(String location) {
    return authRedirect(MockBuildContext(), MockGoRouterState(location));
  }

  group('GoRouter Mutation Guard', () {
    test('TC-01: Block /templates/new for unauthorized roles', () {
      arrangeAuthRole('auditor');
      expect(runRedirect('/templates/new'), '/home');
      
      arrangeAuthRole('area_manager');
      expect(runRedirect('/templates/new'), '/home');
      
      arrangeAuthRole('admin');
      expect(runRedirect('/templates/new'), isNull); // allowed
    });

    test('TC-02: Block /templates/wizard for area_manager', () {
      arrangeAuthRole('area_manager');
      expect(runRedirect('/templates/wizard'), '/home');
      
      arrangeAuthRole('admin');
      expect(runRedirect('/templates/wizard'), isNull);
    });

    test('TC-03: Block /templates/edit/:id for auditor', () {
      arrangeAuthRole('auditor');
      expect(runRedirect('/templates/edit/abc-123'), '/home');
      
      arrangeAuthRole('admin');
      expect(runRedirect('/templates/edit/abc-123'), isNull);
    });

    test('TC-04: Block /templates/:id/builder for auditor', () {
      arrangeAuthRole('auditor');
      expect(runRedirect('/templates/abc-123/builder'), '/home');
      
      arrangeAuthRole('admin');
      expect(runRedirect('/templates/abc-123/builder'), isNull);
    });

    test('TC-05: Allow /templates/:id read-only for auditor', () {
      arrangeAuthRole('auditor');
      expect(runRedirect('/templates/abc-def-123'), isNull); // explicitly allowed read-only
    });
  });
}
