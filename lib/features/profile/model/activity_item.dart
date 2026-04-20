class ActivityItem {
  final String id;
  final String storeName;
  final String templateTitle;
  final String status;
  final double? score;
  final DateTime date;

  ActivityItem({
    required this.id,
    required this.storeName,
    required this.templateTitle,
    required this.status,
    this.score,
    required this.date,
  });
}
