import 'dart:convert';
import 'package:flutter/material.dart';
import '../model/submission_dto.dart';
import '../../templates/models/template_dto.dart';
import '../../../_shared/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

bool _isScored(String? inputType) =>
    inputType != 'text' &&
    inputType != 'single_choice' &&
    inputType != 'multi_choice';

/// Read-only display of a single audit answer.
/// Renders label, value chip, numeric value, note, and remote photo.
/// Must NOT import AuditManager or audit_criterion_card.dart.
class ReadOnlyCriterionRow extends StatelessWidget {
  final AnswerDto answer;
  final CriterionDto? criterion;
  final String scoringMode;

  const ReadOnlyCriterionRow({
    super.key,
    required this.answer,
    this.criterion,
    this.scoringMode = 'penalty',
  });

  Widget? _buildPrimaryBadge(ThemeData theme) {
    if (criterion?.inputType == 'multi_choice') {
      if (answer.value != null && answer.value!.isNotEmpty) {
        final count = answer.value!
            .split(',')
            .where((e) => e.trim().isNotEmpty)
            .length;
        if (count > 0) {
          return AuditStatusBadge(
            label: '$count selected',
            color: theme.colorScheme.primary,
          );
        }
      }
    } else if (criterion?.inputType == 'pass_fail' || criterion == null) {
      if (answer.value == 'conform') {
        return AuditStatusBadge(label: 'PASS', color: AppTheme.success);
      } else if (answer.value == 'non_conform') {
        return AuditStatusBadge(label: 'FAIL', color: theme.colorScheme.error);
      } else if (answer.value == 'na') {
        return AuditStatusBadge(label: 'N/A', color: theme.colorScheme.outline);
      }
    }

    // Fallback if no specific format is matched (e.g., text, scale)
    if (answer.value != null && criterion?.inputType != 'multi_choice') {
      return _ValueChip(value: answer.value!, theme: theme);
    }
    return null;
  }

  String? _buildSubtitleText() {
    if (answer.value == null || answer.value!.isEmpty) {
      return null;
    }
    final String? input = criterion?.inputType;
    if (input == 'single_choice' || input == 'scale' || input == 'text') {
      return answer.value;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label =
        answer.criteriaLabel ?? criterion?.label ?? 'Unknown criterion';
    final numericValue = answer.numericValue;
    final faults = (numericValue ?? 0).toInt();
    final repeats = answer.isRepeatedError
        ? 1
        : 0; // The DTO boolean flag is our indicator
    final isCcp = answer.isCcp;
    final isRisk = answer.isRisk;
    final note = answer.note;
    final photoUrl = answer.photoUrl;

    bool isRequired = false;
    if (criterion?.metadata != null && criterion!.metadata!.isNotEmpty) {
      try {
        final meta = json.decode(criterion!.metadata!) as Map<String, dynamic>;
        isRequired = meta['isRequired'] == true;
      } catch (_) {}
    }

    // Local paths (from offline draft) are never on server history — skip them.
    final hasPhoto =
        photoUrl != null &&
        photoUrl.isNotEmpty &&
        !photoUrl.startsWith('/') &&
        !photoUrl.startsWith('file://');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Criterion label
          Text.rich(
            TextSpan(
              text: label,
              children: [
                if (isRequired)
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
              ],
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_buildSubtitleText() != null) ...[
            const SizedBox(height: 4),
            Text(
              _buildSubtitleText()!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 6),

          // Value chip row
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (_buildPrimaryBadge(theme) != null) _buildPrimaryBadge(theme)!,

              if (faults > 0) ...[
                if (criterion?.inputType == 'numeric' || criterion == null)
                  AuditStatusBadge(
                    label: 'F:$faults',
                    color: theme.colorScheme.error,
                  ),
                if (criterion?.inputType == 'scale' &&
                    scoringMode == 'accumulation')
                  AuditStatusBadge(
                    label: '+$faults pts',
                    color: AppTheme.success,
                  ),
              ],

              if (criterion == null || _isScored(criterion?.inputType)) ...[
                if (repeats > 0)
                  AuditStatusBadge(label: 'REPEAT', color: AppTheme.warning),
                if (isCcp)
                  AuditStatusBadge(
                    label: 'CCP',
                    color: theme.colorScheme.error,
                  ),
                if (isRisk)
                  AuditStatusBadge(label: 'RISK', color: AppTheme.warning),
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
                  Icons.chat_bubble_outline,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.7,
                  ),
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
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],

          // Action Plan deep-link
          if (answer.actionPlanId != null &&
              answer.actionPlanId!.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () => context.push('/plans/${answer.actionPlanId}'),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('View Action Plan'),
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

class AuditStatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const AuditStatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: Theme.of(context).textTheme.labelSmall?.fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ValueChip extends StatelessWidget {
  final String value;
  final ThemeData theme;

  const _ValueChip({required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    final displayValue = _formatValue(value);
    final Color bg;
    final Color fg;

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
