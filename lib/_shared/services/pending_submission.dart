class PendingSubmission {
  final String idempotencyKey;
  final DateTime createdAt;
  final String payload;

  const PendingSubmission({
    required this.idempotencyKey,
    required this.createdAt,
    required this.payload,
  });
}
