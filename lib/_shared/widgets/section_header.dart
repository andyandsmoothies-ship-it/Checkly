import 'package:flutter/material.dart';
import '../theme/app_fonts.dart';

/// Uppercase tracked section header — "RECENT SCANS", "AUDITS", etc.
///
/// Matches the Apothecary reference: uppercase, deeply tracked, small text.
/// ```dart
/// SectionHeader('RECENT SCANS')
/// SectionHeader('OPEN ITEMS', padding: EdgeInsets.only(bottom: 12))
/// ```
class SectionHeader extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry padding;

  const SectionHeader(
    this.text, {
    super.key,
    this.padding = const EdgeInsets.only(bottom: 16),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        text,
        style: AppFonts.displayStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
          letterSpacing: 3,
        ),
      ),
    );
  }
}
