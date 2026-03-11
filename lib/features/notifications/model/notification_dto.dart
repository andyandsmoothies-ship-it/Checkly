/// DTO for notifications matching server NotificationDto.
/// See: server/Features/Notifications/Dtos.cs
class NotificationDto {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String? message;
  final DateTime? readAt;
  final String? actionUrl;
  final String? metadata;
  final DateTime createdAt;

  const NotificationDto({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.message,
    this.readAt,
    this.actionUrl,
    this.metadata,
    required this.createdAt,
  });

  bool get isRead => readAt != null;

  factory NotificationDto.fromJson(Map<String, dynamic> json) =>
      NotificationDto(
        id: json['id'] as String,
        userId: json['userId'] as String,
        type: json['type'] as String,
        title: json['title'] as String,
        message: json['message'] as String?,
        readAt: json['readAt'] != null
            ? DateTime.parse(json['readAt'] as String)
            : null,
        actionUrl: json['actionUrl'] as String?,
        metadata: json['metadata'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
