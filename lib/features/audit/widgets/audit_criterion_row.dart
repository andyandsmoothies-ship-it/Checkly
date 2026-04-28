import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../_shared/theme/app_theme.dart';
import '../../templates/models/template_dto.dart';
import '../manager/audit_manager.dart';
import 'audit_criterion_sheet.dart';
import '../../../_shared/services/scoring_mode.dart';
import 'audit_shared_widgets.dart';

// ============================================================
// Criterion Row — compact list item (Bottom Sheet pattern)
// ============================================================

/// Returns true for input types that participate in scoring.
bool _isScored(String? inputType) =>
    inputType != 'text' &&
    inputType != 'single_choice' &&
    inputType != 'multi_choice';

class AuditCriterionRow extends StatelessWidget {
  final CriterionDto criterion;
  final AuditManager manager;
  final bool confirmRequired;
  final bool ccpEnabled;
  final bool riskEnabled;
  final int? index; // 1-based display number within its section

  const AuditCriterionRow({
    super.key,
    required this.criterion,
    required this.manager,
    this.confirmRequired = false,
    this.ccpEnabled = true,
    this.riskEnabled = true,
    this.index,
  });

  Widget? _buildPrimaryBadge(ThemeData theme, AuditAnswer? answer) {
    if (answer == null) return null;
    final String input = criterion.inputType;

    if (input == 'multi_choice') {
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
    } else if (input == 'pass_fail') {
      if (answer.value == 'conform') {
        return AuditStatusBadge(label: 'PASS', color: AppTheme.success);
      } else if (answer.value == 'non_conform') {
        return AuditStatusBadge(label: 'FAIL', color: theme.colorScheme.error);
      } else if (answer.value == 'na') {
        return AuditStatusBadge(label: 'N/A', color: theme.colorScheme.outline);
      }
    }
    return null;
  }

  String? _buildSubtitleText(AuditAnswer? answer) {
    if (answer == null || answer.value == null || answer.value!.isEmpty) {
      return null;
    }
    final String input = criterion.inputType;
    if (input == 'single_choice' || input == 'scale' || input == 'text') {
      return answer.value;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final answer = manager.answers[criterion.id];
    final faults = (answer?.numericValue ?? 0).toInt();
    final repeats = answer?.repeatedFaultCount ?? 0;
    final isCcp = answer?.isCcp ?? false;
    final isRisk = answer?.isRisk ?? false;
    final hasNote = answer?.note != null && answer!.note!.isNotEmpty;
    final hasPhoto = answer?.photoUrl != null;
    // Determine overall status
    final bool isAnswered =
        answer?.value != null || (answer?.numericValue != null);

    bool isRequired = confirmRequired;
    if (!isRequired &&
        criterion.metadata != null &&
        criterion.metadata!.isNotEmpty) {
      try {
        final meta = json.decode(criterion.metadata!) as Map<String, dynamic>;
        isRequired = meta['isRequired'] == true;
      } catch (_) {}
    }

    return InkWell(
      onTap: () => showAuditCriterionSheet(
        context,
        criterion: criterion,
        manager: manager,
        confirmRequired: confirmRequired,
        ccpEnabled: ccpEnabled,
        riskEnabled: riskEnabled,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Leading numbered badge
            _CriterionNumberBadge(number: index, isAnswered: isAnswered),
            const SizedBox(width: 12),

            // Label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      text: criterion.label,
                      children: [
                        if (isRequired)
                          TextSpan(
                            text: ' *',
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                      ],
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_buildSubtitleText(answer) != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _buildSubtitleText(answer)!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Status badges (compact)
            Wrap(
              spacing: 6,
              children: [
                if (_buildPrimaryBadge(theme, answer) != null)
                  _buildPrimaryBadge(theme, answer)!,

                if (faults > 0) ...[
                  if (criterion.inputType == 'numeric')
                    AuditStatusBadge(
                      label: 'F:$faults',
                      color: theme.colorScheme.error,
                    ),
                  if (criterion.inputType == 'scale' &&
                      manager.scoringMode == ScoringMode.accumulation)
                    AuditStatusBadge(
                      label: '+$faults pts',
                      color: AppTheme.success,
                    ),
                ],

                if (_isScored(criterion.inputType)) ...[
                  if (repeats > 0)
                    AuditStatusBadge(
                      label: 'R:$repeats',
                      color: AppTheme.warning,
                    ),
                  if (isCcp)
                    AuditStatusBadge(
                      label: 'CCP',
                      color: theme.colorScheme.error,
                    ),
                  if (isRisk)
                    AuditStatusBadge(label: 'RISK', color: AppTheme.warning),
                ],

                if (hasNote)
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                if (hasPhoto)
                  Icon(
                    Icons.camera_alt,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
              ],
            ),

            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: theme.colorScheme.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Numbered circular badge replacing the status icon in the compact row.
/// Green fill = answered, grey outline = unanswered.
class _CriterionNumberBadge extends StatelessWidget {
  final int? number;
  final bool isAnswered;

  const _CriterionNumberBadge({required this.number, required this.isAnswered});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color fillColor = isAnswered ? AppTheme.success : Colors.transparent;
    final Color borderColor = isAnswered
        ? AppTheme.success
        : theme.colorScheme.outlineVariant;
    final Color textColor = isAnswered
        ? Colors.white
        : theme.colorScheme.outlineVariant;

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fillColor,
        border: Border.all(color: borderColor, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        number != null ? '$number' : '·',
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: textColor,
          height: 1,
        ),
      ),
    );
  }
}
