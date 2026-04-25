class CommentDto {
  final String id;
  final String userId;
  final String body;
  final DateTime createdAt;

  const CommentDto({
    required this.id,
    required this.userId,
    required this.body,
    required this.createdAt,
  });

  factory CommentDto.fromJson(Map<String, dynamic> json) {
    return CommentDto(
      id: json['id'] as String,
      userId: json['userId'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
    );
  }
}
