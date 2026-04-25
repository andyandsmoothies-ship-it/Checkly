import 'package:flutter/material.dart';

import '../../../../_shared/theme/app_fonts.dart';
// Removed AppTheme import

/// Rich description renderer that parses lines and applies premium styling.
class RichDescription extends StatefulWidget {
  final String description;
  const RichDescription({super.key, required this.description});

  @override
  State<RichDescription> createState() => _RichDescriptionState();
}

class _RichDescriptionState extends State<RichDescription> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = widget.description.split('\n');
    final hasMore = lines.length > 2;
    final displayLines = _isExpanded ? lines : lines.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...displayLines.map((line) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) return const SizedBox(height: 8);

          // Header/Intro line
          if (!trimmed.startsWith('-')) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                trimmed,
                style: AppFonts.displayStyle(
                  fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
                  fontWeight: trimmed.endsWith(':') ? FontWeight.w700 : null,
                  color: Theme.of(context).colorScheme.onSurface.withValues(
                    alpha: trimmed.endsWith(':') ? 0.8 : 0.6,
                  ),
                  height: 1.5,
                ),
              ),
            );
          }

          // Bullet point line
          final content = trimmed.substring(1).trim();
          return Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: TextStyle(
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    fontSize: theme.textTheme.bodyLarge?.fontSize,
                  ),
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: _parseLine(content, theme),
                      style: AppFonts.displayStyle(
                        fontSize: theme.textTheme.bodyMedium?.fontSize,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        if (hasMore)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Text(
                _isExpanded ? 'Show less' : 'Show more',
                style: AppFonts.displayStyle(
                  fontSize: theme.textTheme.bodyMedium?.fontSize,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<InlineSpan> _parseLine(String text, ThemeData theme) {
    final spans = <InlineSpan>[];
    String currentText = text;

    // Bold action (text before " qua ")
    final quaIndex = currentText.indexOf(' qua ');
    if (quaIndex != -1) {
      final action = currentText.substring(0, quaIndex);
      spans.add(
        TextSpan(
          text: action,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
      );
      currentText = currentText.substring(quaIndex);
    }

    // Highlight (Ví dụ: ...)
    final exampleIndex = currentText.indexOf('(Ví dụ:');
    if (exampleIndex != -1) {
      spans.add(TextSpan(text: currentText.substring(0, exampleIndex)));

      final endParenIndex = currentText.indexOf(')', exampleIndex);
      if (endParenIndex != -1) {
        final exampleText = currentText.substring(
          exampleIndex,
          endParenIndex + 1,
        );
        spans.add(
          TextSpan(
            text: exampleText,
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
        spans.add(TextSpan(text: currentText.substring(endParenIndex + 1)));
      } else {
        spans.add(TextSpan(text: currentText.substring(exampleIndex)));
      }
    } else {
      spans.add(TextSpan(text: currentText));
    }

    return spans;
  }
}
