import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../_shared/exceptions/app_error.dart';
import '../../../_shared/services/error_display_service.dart';
import '../models/editable_criterion.dart';
import '../models/editable_group.dart';

bool validateWizardStep(
  BuildContext context,
  int step, {
  required String title,
  required List<EditableGroup> sections,
}) {
  switch (step) {
    case 0: // Name
      if (title.trim().isEmpty) {
        GetIt.instance<ErrorDisplayService>().show(
          const AppError(
            code: 'validation_error',
            message: 'Please enter a template title',
          ),
        );
        return false;
      }
      return true;

    case 1: // Structure
      if (sections.isEmpty) {
        GetIt.instance<ErrorDisplayService>().show(
          const AppError(
            code: 'validation_error',
            message: 'Please add at least one section.',
          ),
        );
        return false;
      }
      for (int i = 0; i < sections.length; i++) {
        if (sections[i].titleCtrl.text.trim().isEmpty) {
          GetIt.instance<ErrorDisplayService>().show(
            AppError(
              code: 'validation_error',
              message: 'Please name Section ${i + 1}',
            ),
          );
          return false;
        }
      }
      return true;

    case 2: // Build Criteria
      for (int i = 0; i < sections.length; i++) {
        final sec = sections[i];
        final secName = sec.titleCtrl.text.isEmpty
            ? 'Section ${i + 1}'
            : '"${sec.titleCtrl.text}"';
        // BL-3: section is valid if it has criteria OR sub-sections.
        if (sec.criteria.isEmpty && sec.subSections.isEmpty) {
          GetIt.instance<ErrorDisplayService>().show(
            AppError(
              code: 'validation_error',
              message: '$secName needs at least one criterion',
            ),
          );
          return false;
        }
        // Validate root criteria
        final rootError = _validateCriteriaList(sec.criteria, secName);
        if (rootError != null) {
          GetIt.instance<ErrorDisplayService>().show(
            AppError(code: 'validation_error', message: rootError),
          );
          return false;
        }
        // BL-3: every sub-section must have >= 1 criterion
        for (int si = 0; si < sec.subSections.length; si++) {
          final sub = sec.subSections[si];
          final subName = sub.titleCtrl.text.isEmpty
              ? 'Sub-section ${si + 1} in $secName'
              : '"${sub.titleCtrl.text}"';
          if (sub.criteria.isEmpty) {
            GetIt.instance<ErrorDisplayService>().show(
              AppError(
                code: 'validation_error',
                message: '$subName has no criteria',
              ),
            );
            return false;
          }
          final subError = _validateCriteriaList(sub.criteria, subName);
          if (subError != null) {
            GetIt.instance<ErrorDisplayService>().show(
              AppError(code: 'validation_error', message: subError),
            );
            return false;
          }
        }
      }
      return true;

    case 3: // Review — trigger save
      return true;

    default:
      return true;
  }
}

// ── Validation helpers ──

/// Validates [criteria] labels and V6 choice-option rules.
/// Returns the first error message or null if all pass.
String? _validateCriteriaList(
  List<EditableCriterion> criteria,
  String parentName,
) {
  for (int ci = 0; ci < criteria.length; ci++) {
    final c = criteria[ci];
    if (c.labelCtrl.text.trim().isEmpty) {
      return 'Criterion ${ci + 1} in $parentName needs a label';
    }
    if ((c.inputType == 'single_choice' || c.inputType == 'multi_choice') &&
        c.choiceOptions.length < 2) {
      final label = c.labelCtrl.text.trim().isNotEmpty
          ? '"${c.labelCtrl.text.trim()}"'
          : 'Criterion ${ci + 1}';
      return '$label needs at least 2 choices. Tap it to add options.';
    }
  }
  return null;
}
