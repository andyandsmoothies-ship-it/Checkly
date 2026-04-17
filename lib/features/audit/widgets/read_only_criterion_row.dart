import 'package:flutter/material.dart';
import '../model/submission_dto.dart';

/// Read-only display of a single audit answer.
/// Renders label, value chip, numeric value, note, and remote photo.
/// Must NOT import AuditManager or audit_criterion_card.dart.
class ReadOnlyCriterionRow extends StatelessWidget {
  final AnswerDto answer;

  const ReadOnlyCriterionRow({super.key, required this.answer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = answer.criteriaLabel ?? 'Unknown criterion';
    final value = answer.value;
    final numericValue = answer.numericValue;
    final note = answer.note;
    final photoUrl = answer.photoUrl;

    // Local paths (from offline draft) are never on server history — skip them.
    final hasPhoto = photoUrl != null &&
        photoUrl.isNotEmpty &&
        !photoUrl.startsWith('/') &&
        !photoUrl.startsWith('file://');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Criterion label
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),

          // Value chip row
          Row(
            children: [
              if (value != null) _ValueChip(value: value, theme: theme),
              if (numericValue != null && value == null) ...[
                _ValueChip(value: numericValue.toString(), theme: theme),
              ],
              if (answer.isRepeatedError) ...[
                const SizedBox(width: 6),
                _ValueChip(value: 'REPEAT', theme: theme, isWarning: true),
              ],
            ],
          ),

          // Note
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.note_alt_outlined,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    note,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Photo
          if (hasPhoto) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                photoUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return SizedBox(
                    height: 160,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded /
                                progress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ],

          // Divider
          const SizedBox(height: 10),
          Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}

class _ValueChip extends StatelessWidget {
  final String value;
  final ThemeData theme;
  final bool isWarning;

  const _ValueChip({
    required this.value,
    required this.theme,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = _formatValue(value);
    final Color bg;
    final Color fg;

    if (isWarning) {
      bg = theme.colorScheme.errorContainer;
      fg = theme.colorScheme.onErrorContainer;
    } else {
      switch (value.toLowerCase()) {
        case 'conform':
        case 'na':
          bg = theme.colorScheme.primaryContainer;
          fg = theme.colorScheme.onPrimaryContainer;
        case 'non_conform':
          bg = theme.colorScheme.errorContainer;
          fg = theme.colorScheme.onErrorContainer;
        default:
          bg = theme.colorScheme.surfaceContainerHighest;
          fg = theme.colorScheme.onSurface;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        displayValue,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  String _formatValue(String value) {
    switch (value.toLowerCase()) {
      case 'conform':
        return 'CONFORM';
      case 'non_conform':
        return 'NON-CONFORM';
      case 'na':
        return 'N/A';
      default:
        return value.toUpperCase();
    }
  }
}
