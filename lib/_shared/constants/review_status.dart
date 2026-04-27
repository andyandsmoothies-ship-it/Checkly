/// Strongly-typed review status constants for audit approval workflows.
/// Mirrors the server-side ReviewStatus values to eliminate naked strings.
///
/// Anti-Magic-String Mandate: Never use raw status strings in production code.
/// Always use these constants so the compiler catches typos at build time.
class ReviewStatus {
  ReviewStatus._(); // prevent instantiation

  static const String approved = 'approved';
  static const String rejected = 'rejected';
}
