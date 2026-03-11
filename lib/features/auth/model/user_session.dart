/// Data class representing an authenticated user session.
/// Matches the backend `Login.Response` DTO.
class UserSession {
  final String userId;
  final String email;
  final String role;
  final String token;

  const UserSession({
    required this.userId,
    required this.email,
    required this.role,
    required this.token,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) => UserSession(
    userId: json['userId'] as String,
    email: json['email'] as String,
    role: json['role'] as String,
    token: json['token'] as String,
  );

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'email': email,
    'role': role,
    'token': token,
  };
}
