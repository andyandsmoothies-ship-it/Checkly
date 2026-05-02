import 'dart:convert';
import 'package:flutter/material.dart';
import '../model/answer_dto.dart';
import '../../templates/models/template_dto.dart';
import '../../../_shared/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'audit_shared_widgets.dart';
import '../../../_shared/widgets/app_network_image.dart';
import '../../../_shared/widgets/read_more_text.dart';

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
        return AuditStatusBadge(
          label: 'PASS',
          color: AppTheme.success,
          icon: Icons.check_circle_outline,
        );
      } else if (answer.value == 'non_conform') {
        return AuditStatusBadge(
          label: 'FAIL',
          color: theme.colorScheme.error,
          icon: Icons.cancel_outlined,
        );
      } else if (answer.value == 'na') {
        return AuditStatusBadge(
          label: 'N/A',
          color: theme.colorScheme.outline,
          icon: Icons.remove_circle_outline,
        );
      }
    }

    // Fallback if no specific format is matched (e.g., text, scale)
    if (answer.value != null && criterion?.inputType != 'multi_choice') {
      if (answer.value!.trim().isNotEmpty) {
        return _ValueChip(value: answer.value!, theme: theme);
      }
    }
    return null;
  }

  String? _buildSubtitleText() {
    if (answer.value == null || answer.value!.isEmpty) {
      return null;
    }
    final String? input = criterion?.inputType;
    // Don't show subtitle if it's just repeating the primary badge value
    if (input == 'text') {
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

    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Criterion label
          ReadMoreText(
            label,
            trimLines: 3,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            extraSpan: isRequired
                ? TextSpan(
                    text: ' *',
                    style: TextStyle(color: theme.colorScheme.error),
                  )
                : null,
          ),
          if (_buildSubtitleText() != null) ...[
            const SizedBox(height: 4),
            ReadMoreText(
              _buildSubtitleText()!,
              trimLines: 2,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 16),

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
                    label: '-$faults pt${faults > 1 ? 's' : ''}',
                    color: theme.colorScheme.error,
                  ),
                if (criterion?.inputType == 'scale' &&
                    scoringMode == 'accumulation')
                  AuditStatusBadge(
                    label: '+$faults pt${faults > 1 ? 's' : ''}',
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
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ReadMoreText(
                    note,
                    trimLines: 3,
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
              child: AppNetworkImage(
                url: photoUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image_outlined,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Image unavailable',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // Action Plan deep-link
          if (answer.actionPlanId != null &&
              answer.actionPlanId!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/plans/${answer.actionPlanId}'),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('View Action Plan'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ),
          ],
        ],
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
