import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checkly/features/auth/manager/auth_manager.dart';
import 'package:checkly/features/auth/model/auth_state.dart';
import 'package:checkly/features/auth/model/user_session.dart';
import 'package:checkly/_shared/services/policy_manager.dart';
import 'package:get_it/get_it.dart';

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

  test('PM-01: can() returns true when capability exists in AuthManager', () {
    final fakeAuth = _FakeAuthManager({'templates:create', 'admin:access'});
    GetIt.I.registerSingleton<AuthManager>(fakeAuth);
    
    final policyManager = PolicyManager(auth: fakeAuth);
    
    expect(policyManager.can('templates:create'), isTrue);
  });

  test('PM-02: can() returns false when capability is absent', () {
    final fakeAuth = _FakeAuthManager({'submissions:create'});
    GetIt.I.registerSingleton<AuthManager>(fakeAuth);
    
    final policyManager = PolicyManager(auth: fakeAuth);
    
    expect(policyManager.can('admin:access'), isFalse);
    expect(policyManager.can('unknown:action'), isFalse);
  });

  test('PM-03: isLoaded returns true when capabilities are not empty', () {
    final fakeAuth = _FakeAuthManager({'templates:create'});
    final policyManager = PolicyManager(auth: fakeAuth);
    expect(policyManager.isLoaded, isTrue);
    
    final emptyAuth = _FakeAuthManager({});
    final emptyManager = PolicyManager(auth: emptyAuth);
    expect(emptyManager.isLoaded, isFalse);
  });
}
