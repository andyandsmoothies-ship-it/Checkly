class AddCommentRequest {
  final String body;

  const AddCommentRequest({
    required this.body,
  });

  Map<String, dynamic> toJson() {
    return {
      'body': body,
    };
  }
}
