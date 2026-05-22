import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

/// Unified section header widget with two visual variants.
///
/// **Primary** (default) — uppercase, deeply tracked, bold Nunito display.
/// Used for top-level page sections: "RECENT AUDITS", "INSIGHTS".
/// ```dart
/// SectionHeader('RECENT AUDITS')
/// SectionHeader('OPEN ITEMS', padding: EdgeInsets.only(bottom: 12))
/// ```
///
/// **Sub** — sentence-case, heavy Nunito weight. Used for detail-page sub-sections
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
    final TextStyle? style = switch (variant) {
      SectionHeaderVariant.primary => AppFonts.displayStyle(
        fontWeight: FontWeight.w800,
        fontSize: 11,
        color: AppColors.wolf,
        letterSpacing: 2.5,
      ),
      SectionHeaderVariant.sub =>
        Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppColors.eel,
          fontWeight: FontWeight.w900,
        ),
    };

    final displayText = variant == SectionHeaderVariant.primary
        ? text.toUpperCase()
        : text;

    return Padding(
      padding: padding,
      child: Text(displayText, style: style),
    );
  }
}
