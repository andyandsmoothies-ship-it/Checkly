// Shared date formatting utilities for consistent UX across the app.
//
// Rules:
// - < 60 min  → "Xm ago"
// - < 24 hrs  → "Xh ago"
// - ≥ 1 day   → "on 11 Mar" (named month, no ambiguity)

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Returns a human-readable relative time for recent events,
/// or "on DD Mon" for anything older than 24 hours.
String timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return 'on ${date.day} ${_months[date.month - 1]}';
}

/// Formats a date as "DD Mon YYYY" (e.g. "11 Mar 2026").
String formatDate(DateTime date) {
  return '${date.day} ${_months[date.month - 1]} ${date.year}';
}

/// Formats a date as "DD Mon" without year (e.g. "11 Mar").
String formatDateShort(DateTime date) {
  return '${date.day} ${_months[date.month - 1]}';
}
