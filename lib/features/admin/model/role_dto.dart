/// DTO for a system role with its assigned capabilities.
/// Maps to GET /api/admin/roles response items.
class RoleDto {
  final String role;
  final List<String> capabilities;

  const RoleDto({required this.role, required this.capabilities});

  factory RoleDto.fromJson(Map<String, dynamic> json) {
    return RoleDto(
      role: json['role'] as String,
      capabilities: (json['capabilities'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }
}
