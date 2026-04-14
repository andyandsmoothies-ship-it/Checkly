import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checkly/features/auth/manager/auth_manager.dart';
import 'package:checkly/features/auth/model/auth_state.dart';
import 'package:checkly/features/auth/model/user_session.dart';
import 'package:checkly/_shared/services/policy_manager.dart';
import 'package:checkly/_shared/constants/app_capabilities.dart';
import 'package:get_it/get_it.dart';

// Copy of Fake from existing test to avoid coupling
class _FakeAuthManager extends ChangeNotifier implements AuthManager {
  @override
  Future<void> refreshCapabilities() async {}

  final ValueNotifier<Set<String>> _caps;
  
  _FakeAuthManager(Set<String> capabilities) : _caps = ValueNotifier(capabilities);

  @override
  ValueListenable<Set<String>> get capabilities => _caps;

  @override ValueListenable<AuthState> get authState => ValueNotifier(AuthState.authenticated);
  @override UserSession? get currentUser => null;
  @override Future<void> login(String e, String p) async {}
  @override Future<void> logout() async {}
  @override Future<void> tryAutoLogin() async {}
}

void main() {
  setUp(() {
    GetIt.I.allowReassignment = true;
  });

  tearDown(() {
    GetIt.I.reset();
  });

  group('Implicit Policy Manager ATDD Gate Specs', () {
    test('AC-1: Implicit Grant - can(adminAccess) is true when user has an adminDomain capability', () {
      // templates:create is an adminDomainCapability
      final fakeAuth = _FakeAuthManager({AppCapabilities.templatesCreate});
      GetIt.I.registerSingleton<AuthManager>(fakeAuth);
      
      final pm = PolicyManager(auth: fakeAuth);
      
      // Expected RED: Currently fails because implicit logic is not written yet
      expect(pm.can(AppCapabilities.adminAccess), isTrue);
    });

    test('AC-2: Explicit Only - can(adminAccess) is false when user only has non-admin capabilities', () {
      final fakeAuth = _FakeAuthManager({
        AppCapabilities.submissionsCreate,
        AppCapabilities.actionPlansWrite,
      });
      GetIt.I.registerSingleton<AuthManager>(fakeAuth);
      
      final pm = PolicyManager(auth: fakeAuth);
      
      // Expected GREEN: Already works natively, acts as a control anchor
      expect(pm.can(AppCapabilities.adminAccess), isFalse);
    });

    test('AC-3: Unhydrated Safety - can(adminAccess) safely handles empty capability sets', () {
      final fakeAuth = _FakeAuthManager({});
      GetIt.I.registerSingleton<AuthManager>(fakeAuth);
      
      final pm = PolicyManager(auth: fakeAuth);
      
      expect(pm.can(AppCapabilities.adminAccess), isFalse);
    });

    test('AC-4: No Spillovers - can(templates:create) is false when implicit logic acts sideways', () {
      // User only has adminAccess, they should not magically get templatesCreate implicitly
      // Implicit only flows UP to adminAccess, not DOWN or SIDEWAYS
      final fakeAuth = _FakeAuthManager({AppCapabilities.adminAccess});
      GetIt.I.registerSingleton<AuthManager>(fakeAuth);
      
      final pm = PolicyManager(auth: fakeAuth);
      
      expect(pm.can(AppCapabilities.templatesCreate), isFalse);
    });
  });
}
