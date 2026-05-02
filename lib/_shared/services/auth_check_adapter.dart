import '../../features/auth/manager/auth_manager.dart';
import '../../features/auth/model/auth_state.dart';
import 'auth_check.dart';

/// Production implementation of [AuthCheck] using AuthManager state.
class AuthCheckAdapter implements AuthCheck {
  final AuthManager _auth;

  AuthCheckAdapter(this._auth);

  @override
  bool get isLoggedIn => _auth.authState.value == AuthState.authenticated;
}
