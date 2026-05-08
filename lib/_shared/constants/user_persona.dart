/// Strongly-typed user persona enum.
/// Replaces raw role string switches throughout structural layout code.
///
/// Mapping:
///   'auditor'        → UserPersona.auditor
///   'store_manager'  → UserPersona.storeManager
///   'area_manager'   → UserPersona.areaManager
///   'admin' / null / unknown → UserPersona.admin (safe fallback)
enum UserPersona {
  auditor,
  storeManager,
  areaManager,
  admin;

  /// Convert a raw server role string to a typed [UserPersona].
  /// Defaults to [UserPersona.admin] for null or unknown roles — same
  /// fail-safe as the previous `role ?? 'admin'` fallback.
  static UserPersona fromRole(String? role) => switch (role) {
    'auditor' => UserPersona.auditor,
    'store_manager' => UserPersona.storeManager,
    'area_manager' => UserPersona.areaManager,
    _ => UserPersona.admin,
  };
}
