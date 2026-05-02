import '../../features/auth/manager/auth_manager.dart';
import 'user_role_provider.dart';

/// Production implementation of [UserRoleProvider] using AuthManager.
class UserRoleAdapter implements UserRoleProvider {
  final AuthManager _auth;

  UserRoleAdapter(this._auth);

  @override
  String get role => _auth.currentUser?.role ?? 'unknown';
}
