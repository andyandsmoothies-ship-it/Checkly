/// Authentication state for the app.
enum AuthState {
  /// User is authenticated with a valid JWT.
  authenticated,

  /// User is not authenticated — show login.
  unauthenticated,

  /// Authentication in progress (checking token, logging in).
  loading,
}
