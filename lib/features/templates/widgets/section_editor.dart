import 'package:flutter/material.dart';
import '../../../_shared/widgets/primitives/stroke_card.dart';

import '../../../_shared/theme/app_theme.dart';
import '../../../_shared/theme/app_fonts.dart';
import '../models/editable_criterion.dart';
import '../models/editable_group.dart';
import '../models/validation_result.dart';
import 'criterion_editor.dart';
import 'ghost_add_button.dart';

part 'section_editor_parts.dart';

class SectionEditor extends StatelessWidget {
  final int index;
  final EditableGroup section;
  final int depth;

  final bool densityEnabled;
  final ValidationErrors? errors;
  final String? errorKeyPrefix;
  final Map<String, GlobalKey>? errorKeys;
  final VoidCallback onRemoveSection;
  final ValueChanged<String> onAddCriterion;
  final ValueChanged<int> onRemoveCriterion;
  final VoidCallback? onAddSubSection;
  final ValueChanged<int>? onRemoveSubSection;
  final VoidCallback onChanged;

  /// When true and depth==0, renders without the ExpansionTile header
  /// (title TextField, badge, delete button). Wizard injects this flag
  /// to avoid visual redundancy — it manages section context separately.
  final bool isWizardMode;

  /// The current scoring mode — used to gate sub-section creation for
  /// Survey and Checklist modes. Null means no constraint (Builder default).
  final String? scoringMode;

  /// Global feature flags — gates CCP/Risk toggle visibility in criterion drawer.
  /// Defaults to false (toggles hidden) when not passed (sub-section recursion).
  final bool globalCcpEnabled;
  final bool globalRiskEnabled;

  /// When true, locks the Required toggle ON in all CriterionEditor drawers.
  /// Defaults to false when not passed (sub-section recursion).
  final bool globalConfirmRequired;

  const SectionEditor({
    super.key,
    required this.index,
    required this.section,
    this.depth = 0,
    this.densityEnabled = true,
    this.errors,
    this.errorKeyPrefix,
    this.errorKeys,
    required this.onRemoveSection,
    required this.onAddCriterion,
    required this.onRemoveCriterion,
    this.onAddSubSection,
    this.onRemoveSubSection,
    required this.onChanged,
    this.isWizardMode = false,
    this.scoringMode, // optional, null → no constraint
    this.globalCcpEnabled = false,
    this.globalRiskEnabled = false,
    this.globalConfirmRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRoot = depth == 0;
    final sKey = errorKeyPrefix ?? 'section:$index';
    final sectionErrors = errors?.forKey(sKey) ?? const [];
    final hasErrors = sectionErrors.isNotEmpty;

    // Gap 6: count badge
    final subCount = section.countSubs();
    final critCount = section.countCriteria();

    // In wizard mode at root depth, skip the ExpansionTile header entirely.
    // The wizard manages its own section header (title, progress) above.
    if (isWizardMode && isRoot) {
      return _buildWizardContent(
        context,
        theme,
        sKey,
        sectionErrors,
        hasErrors,
      );
    }

    return StrokeCard(
      margin: EdgeInsets.only(bottom: 12, left: isRoot ? 0 : 16),
      padding: EdgeInsets.zero,
      borderColor: hasErrors
          ? theme.colorScheme.error
          : isRoot
          ? null
          : theme.colorScheme.primary.withValues(alpha: 0.3),
      borderRadius: 12,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          title: _SectionEditorHeader(
            section: section,
            index: index,
            isRoot: isRoot,
            densityEnabled: densityEnabled,
            subCount: subCount,
            critCount: critCount,
            onChanged: onChanged,
          ),
          trailing: IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: theme.colorScheme.error,
              size: 20,
            ),
            onPressed: onRemoveSection,
          ),
          children: [
            // Section-level error messages
            if (hasErrors) _SectionErrorMessages(errors: sectionErrors),

            // Criteria list
            _SectionCriteriaList(
              section: section,
              sKey: sKey,
              errors: errors,
              errorKeys: errorKeys,
              scoringMode: scoringMode,
              globalCcpEnabled: globalCcpEnabled,
              globalRiskEnabled: globalRiskEnabled,
              globalConfirmRequired: globalConfirmRequired,
              onRemoveCriterion: onRemoveCriterion,
              onChanged: onChanged,
              onAddCriterion: onAddCriterion,
            ),

            if (isRoot)
              _SectionSubSections(
                section: section,
                sKey: sKey,
                depth: depth,
                densityEnabled: densityEnabled,
                errors: errors,
                errorKeys: errorKeys,
                onRemoveSubSection: onRemoveSubSection,
                onChanged: onChanged,
              ),
          ],
        ),
      ),
    );
  }

  /// Wizard-mode layout: renders only the section body content without
  /// the Card/ExpansionTile header (title, badge, delete button).
  /// The wizard provides its own section header above this widget.
  Widget _buildWizardContent(
    BuildContext context,
    ThemeData theme,
    String sKey,
    List<String> sectionErrors,
    bool hasErrors,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section-level error messages
          if (hasErrors) _SectionErrorMessages(errors: sectionErrors),
          // Criteria list
          _SectionCriteriaList(
            section: section,
            sKey: sKey,
            errors: errors,
            errorKeys: errorKeys,
            scoringMode: scoringMode,
            globalCcpEnabled: globalCcpEnabled,
            globalRiskEnabled: globalRiskEnabled,
            globalConfirmRequired: globalConfirmRequired,
            onRemoveCriterion: onRemoveCriterion,
            onChanged: onChanged,
            onAddCriterion: onAddCriterion,
          ),
          _SectionSubSections(
            section: section,
            sKey: sKey,
            depth: depth,
            densityEnabled: densityEnabled,
            errors: errors,
            errorKeys: errorKeys,
            onRemoveSubSection: onRemoveSubSection,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
