import 'package:flutter/material.dart';

import '../../../_shared/theme/app_theme.dart';
import '../../templates/models/template_dto.dart';
import '../manager/audit_manager.dart';
import 'audit_criterion_row.dart';
import 'audit_inputs.dart';

// ============================================================
// Criterion Bottom Sheet — full editing controls
// ============================================================

/// Returns true for input types that participate in scoring.
bool _isScored(String? inputType) =>
    inputType != 'text' &&
    inputType != 'single_choice' &&
    inputType != 'multi_choice';

Future<void> showAuditCriterionSheet(
  BuildContext context, {
  required CriterionDto criterion,
  required AuditManager manager,
  required bool confirmRequired,
  required bool ccpEnabled,
  required bool riskEnabled,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) {
      return ListenableBuilder(
        listenable: manager,
        builder: (ctx, _) {
          final theme = Theme.of(ctx);
          final answer = manager.answers[criterion.id];
          final hasFaults = (answer?.numericValue ?? 0) > 0;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Title
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              criterion.label,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (criterion.description != null &&
                              criterion.description!.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.info_outline),
                              onPressed: () {
                                showDialog(
                                  context: ctx,
                                  builder: (dialogCtx) => AlertDialog(
                                    title: const Text('Criterion Description'),
                                    content: SingleChildScrollView(
                                      child: Text(criterion.description!),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(dialogCtx),
                                        child: const Text('CLOSE'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Input based on type
                      if (criterion.inputType == 'pass_fail')
                        AuditPassFailInput(
                          value: answer?.value,
                          onChanged: (v) =>
                              manager.setAnswer(criterion.id, value: v),
                        )
                      else if (criterion.inputType == 'scale')
                        AuditScaleInput(
                          criterion: criterion,
                          selectedValue: answer?.value,
                          onChanged: (label, points) => manager.setAnswer(
                            criterion.id,
                            value: label,
                            numericValue: points,
                          ),
                        )
                      else if (criterion.inputType == 'single_choice')
                        AuditSingleChoiceInput(
                          criterion: criterion,
                          selectedValue: answer?.value,
                          onChanged: (v) =>
                              manager.setAnswer(criterion.id, value: v),
                        )
                      else if (criterion.inputType == 'multi_choice')
                        AuditMultiChoiceInput(
                          criterion: criterion,
                          selectedValues: answer?.value,
                          onChanged: (v) =>
                              manager.setAnswer(criterion.id, value: v),
                        )
                      else if (criterion.inputType == 'text')
                        TextFormField(
                          initialValue: answer?.value,
                          decoration: InputDecoration(
                            labelText: 'Response',
                            hintText: 'Enter text...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          maxLines: 4,
                          style: theme.textTheme.bodySmall,
                          onChanged: (v) =>
                              manager.setAnswer(criterion.id, value: v),
                        )
                      else ...[
                        // Faults + Repeats on same row
                        Row(
                          children: [
                            AuditNumericInput(
                              label: 'Faults:',
                              value: answer?.numericValue,
                              onChanged: (v) => manager.setAnswer(
                                criterion.id,
                                numericValue: v,
                              ),
                            ),
                            const Spacer(),
                            AuditNumericInput(
                              label: 'Repeats:',
                              value: (answer?.repeatedFaultCount ?? 0)
                                  .toDouble(),
                              activeColor: (answer?.repeatedFaultCount ?? 0) > 0
                                  ? AppTheme.warning
                                  : null,
                              onChanged: (v) => manager.setRepeatedFaultCount(
                                criterion.id,
                                v.toInt(),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Confirm Correct button
                      if (confirmRequired &&
                          !hasFaults &&
                          _isScored(criterion.inputType)) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              if (answer?.value == 'conform') {
                                manager.clearAnswerValue(criterion.id);
                              } else {
                                manager.setAnswer(
                                  criterion.id,
                                  value: 'conform',
                                );
                              }
                            },
                            icon: Icon(
                              answer?.value == 'conform'
                                  ? Icons.check_circle
                                  : Icons.check_circle_outline,
                              size: 20,
                            ),
                            label: Text(
                              answer?.value == 'conform'
                                  ? 'Standard Verified'
                                  : 'Confirm Correct',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                letterSpacing: 0.3,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: answer?.value == 'conform'
                                  ? AppTheme.success
                                  : theme.colorScheme.primaryContainer,
                              foregroundColor: answer?.value == 'conform'
                                  ? Colors.white
                                  : theme.colorScheme.primary,
                              disabledBackgroundColor: AppTheme.success,
                              disabledForegroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: answer?.value == 'conform' ? 0 : 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: answer?.value == 'conform'
                                      ? Colors.transparent
                                      : theme.colorScheme.primary.withAlpha(40),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],

                      // CCP / RISK toggle buttons
                      if ((ccpEnabled || riskEnabled) &&
                          _isScored(criterion.inputType)) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (ccpEnabled)
                              AuditCcpRiskButton(
                                label: 'CCP',
                                icon: Icons.shield,
                                active: answer?.isCcp ?? false,
                                activeColor: theme.colorScheme.error,
                                onTap: () {
                                  final newVal = !(answer?.isCcp ?? false);
                                  manager.setCcp(criterion.id, newVal);
                                },
                              ),
                            if (riskEnabled)
                              AuditCcpRiskButton(
                                label: 'RISK',
                                icon: Icons.warning_amber_rounded,
                                active: answer?.isRisk ?? false,
                                activeColor: AppTheme.warning,
                                onTap: () {
                                  final newVal = !(answer?.isRisk ?? false);
                                  manager.setRisk(criterion.id, newVal);
                                },
                              ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),

                      // Note field
                      TextFormField(
                        initialValue: answer?.note,
                        decoration: InputDecoration(
                          labelText: 'Note',
                          hintText: 'Add note...',
                          prefixIcon: const Icon(Icons.notes, size: 20),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        maxLines: 3,
                        style: theme.textTheme.bodySmall,
                        onChanged: (v) => manager.setNote(criterion.id, v),
                      ),

                      const SizedBox(height: 12),

                      // Photo button + preview
                      AuditPhotoSection(criterion: criterion, manager: manager),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
