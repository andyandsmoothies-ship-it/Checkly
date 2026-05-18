import 'package:flutter/material.dart';
import '../theme/app_fonts.dart';

/// Unified section header widget with two visual variants.
///
/// **Primary** (default) — uppercase, deeply tracked, small text.
/// Used for top-level page sections: "RECENT AUDITS", "INSIGHTS".
/// ```dart
/// SectionHeader('RECENT AUDITS')
/// SectionHeader('OPEN ITEMS', padding: EdgeInsets.only(bottom: 12))
/// ```
///
/// **Sub** — sentence-case, medium weight. Used for detail-page sub-sections
/// such as "Root Cause", "Correction Plan", "Evidence".
/// ```dart
/// SectionHeader('Root Cause', variant: SectionHeaderVariant.sub)
/// ```
enum SectionHeaderVariant { primary, sub }

class SectionHeader extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry padding;
  final SectionHeaderVariant variant;

  const SectionHeader(
    this.text, {
    super.key,
    this.padding = const EdgeInsets.only(bottom: 16),
    this.variant = SectionHeaderVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final TextStyle? style = switch (variant) {
      SectionHeaderVariant.primary => theme.textTheme.labelSmall?.merge(
          AppFonts.displayStyle(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
            letterSpacing: 3,
          ),
        ),
      SectionHeaderVariant.sub => theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
    };

    return Padding(
      padding: padding,
      child: Text(text, style: style),
    );
  }
}
