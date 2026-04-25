/// Immutable DTO for a User Group.
/// Matches the backend JSON shape: { id, name, description }.
class UserGroupDto {
  final String id;
  final String name;
  final String? description;

  const UserGroupDto({required this.id, required this.name, this.description});

  factory UserGroupDto.fromJson(Map<String, dynamic> json) => UserGroupDto(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
  );
}
