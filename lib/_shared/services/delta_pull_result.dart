class DeltaPullResult {
  final DateTime serverTimestamp;
  final bool hasNextPage;
  final List<dynamic> submissions;

  const DeltaPullResult({
    required this.serverTimestamp,
    this.hasNextPage = false,
    this.submissions = const [],
  });
}
