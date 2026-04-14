import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:checkly/features/auth/manager/auth_manager.dart';
import 'package:checkly/features/auth/model/auth_state.dart';
import 'package:checkly/features/auth/model/user_session.dart';
import 'package:checkly/_shared/router/app_router.dart';
import 'package:checkly/_shared/services/policy_manager.dart';

class _StubAuthManager extends ChangeNotifier implements AuthManager {
  @override
  Future<void> refreshCapabilities() async {}

  final Set<String> _caps;
  
  _StubAuthManager({required Set<String> capabilities}) 
      : _caps = capabilities;

  @override
  ValueListenable<AuthState> get authState => ValueNotifier(AuthState.authenticated);

  @override
  UserSession? get currentUser => const UserSession(userId: '1', fullName: 'Test', email: 'test@x.com', role: 'any', token: 'tok');

  @override
  ValueListenable<Set<String>> get capabilities => ValueNotifier(_caps);

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

  void arrangeCapabilities(Set<String> caps) {
    final auth = _StubAuthManager(capabilities: caps);
    GetIt.I.registerSingleton<AuthManager>(auth);
    GetIt.I.registerSingleton<PolicyManager>(PolicyManager(auth: auth));
  }

  String? runRedirect(String location) {
    return authRedirect(MockBuildContext(), MockGoRouterState(location));
  }

  group('GoRouter PBAC Capability Guard', () {
    test('AR-01: Blocks /admin/dashboard when adminDomain capabilities are missing', () {
      arrangeCapabilities({'submissions:create'}); // Has other non-admin capability
      expect(runRedirect('/admin/dashboard'), '/home');
    });

    test('AR-02: Allows /admin/dashboard when admin:access capability exists', () {
      arrangeCapabilities({'admin:access'});
      expect(runRedirect('/admin/dashboard'), isNull);
    });

    test('AR-03: Blocks /templates/new when templates:create capability is missing', () {
      arrangeCapabilities({'admin:access'});
      expect(runRedirect('/templates/new'), '/home');
    });

    test('AR-04: Allows /templates/new when templates:create capability exists', () {
      arrangeCapabilities({'templates:create'});
      expect(runRedirect('/templates/new'), isNull);
      
      expect(runRedirect('/templates/wizard'), isNull);
    });

    test('AR-05: Allows /templates/:id read-only for users without templates:create capability', () {
      arrangeCapabilities({}); // Empty capabilities
      expect(runRedirect('/templates/abc-def-123'), isNull); // explicitly allowed read-only
    });

    test('AR-06: (Gap AC) Blocks deeply nested mutation route (/templates/123/edit) when capability missing', () {
      arrangeCapabilities({}); 
      // Length of split('/') is 4 for '/templates/123/edit'. Must fail length==3 check.
      expect(runRedirect('/templates/abc-123/edit'), '/home');
    });
  });
}
