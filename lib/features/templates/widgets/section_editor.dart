import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../_shared/theme/app_theme.dart';
import '../../../_shared/theme/app_fonts.dart';
import '../models/editable_criterion.dart';
import '../models/editable_group.dart';
import '../models/validation_result.dart';
import 'criterion_editor.dart';
import 'ghost_add_button.dart';

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
  /// to avoid visual redundancy â€” it manages section context separately.
  final bool isWizardMode;

  /// The current scoring mode — used to gate sub-section creation for
  /// Survey and Checklist modes. Null means no constraint (Builder default).
  final String? scoringMode;

  /// Global feature flags — gates CCP/Risk toggle visibility in criterion drawer.
  /// Defaults to false (toggles hidden) when not passed (sub-section recursion).
  final bool globalCcpEnabled;
  final bool globalRiskEnabled;

  /// True when the current scoring mode allows sub-sections.
  /// Survey and Checklist modes enforce a flat structure.
  bool get _allowSubSections =>
      scoringMode == null ||
      scoringMode == 'penalty' ||
      scoringMode == 'accumulation';

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
    this.scoringMode,             // optional, null → no constraint
    this.globalCcpEnabled = false,
    this.globalRiskEnabled = false,
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
      return _buildWizardContent(context, theme, sKey, sectionErrors, hasErrors);
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12, left: isRoot ? 0 : 16),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: hasErrors
              ? theme.colorScheme.error
              : isRoot
              ? theme.cardTheme.shape != null
                    ? Colors.transparent
                    : Colors.transparent
              : theme.colorScheme.primary.withValues(alpha: 0.3),
          width: hasErrors ? 2 : (isRoot ? 0 : 2),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          title: Row(
            children: [
              // Gap 9: Inline editable title in header
              Expanded(
                child: TextField(
                  controller: section.titleCtrl,
                  decoration: InputDecoration(
                    hintText: isRoot
                        ? 'Section ${index + 1}'
                        : 'Sub-section ${index + 1}',
                    hintStyle: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.38,
                      ),
                      fontStyle: FontStyle.italic,
                    ),
                    isDense: true,
                    filled: false, // Remove the global grey pill background
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.only(bottom: 6, right: 8),
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
              // Gap 6: count badge (XS â€¢ YC) â€” root sections only
              if (isRoot)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.sageGray.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${subCount}S â€¢ ${critCount}C',
                    style: AppFonts.serifStyle(
                      fontSize: 10,
                      color: AppTheme.charcoal.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              // Inline editable weight input in header (PWA parity)
              if (densityEnabled && isRoot)
                Container(
                  width: 64,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: section.weightCtrl,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: AppFonts.serifStyle(
                            fontSize: 12,
                            color: theme.colorScheme.primary,
                          ),
                          decoration: const InputDecoration(
                            hintText: '0',
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onTap: () =>
                              section.weightCtrl.selection = TextSelection(
                                baseOffset: 0,
                                extentOffset: section.weightCtrl.text.length,
                              ),
                          onChanged: (_) => onChanged(),
                        ),
                      ),
                      Text(
                        '%',
                        style: AppFonts.serifStyle(
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: onRemoveSection,
          ),
          children: [
            // Section-level error messages
            if (hasErrors)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sectionErrors
                      .map(
                        (msg) => Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 14,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                msg,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),

            // Sub-section metadata (non-root sections always show Max Points)
            if (!isRoot) ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: section.maxPointsCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Max Points',
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (_) => onChanged(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: section.minusPerFaultCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Minus / Fault',
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (_) => onChanged(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Criteria list
            ...section.criteria.asMap().entries.map((e) {
              final ci = e.key;
              final c = e.value;
              final cKey = '$sKey:c:$ci';
              final cErrors = errors?.forKey(cKey) ?? const [];
              return KeyedSubtree(
                key: errorKeys?[cKey] ?? ObjectKey(c),
                child: CriterionEditor(
                  criterion: c,
                  errors: cErrors,
                  scoringMode: scoringMode,
                  globalCcpEnabled: globalCcpEnabled,
                  globalRiskEnabled: globalRiskEnabled,
                  onRemove: () => onRemoveCriterion(ci),
                  onChanged: onChanged,
                ),
              );
            }),

            // "Add Criterion" ghost card
            if (isRoot && section.subSections.isEmpty || !isRoot)
              GhostAddButton(
                label: 'Add Criterion',
                icon: Icons.add,
                onPressed: () => onAddCriterion('pass_fail'),
                tintColor: Theme.of(context).colorScheme.primary,
              ),

            // Gap 1: Sub-sections
            if (isRoot) ...[
              if (section.criteria.isNotEmpty || section.subSections.isNotEmpty)
                const Divider(),

              if (section.criteria.isEmpty && section.subSections.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Text(
                      'â€” OR â€”',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.4,
                        ),
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ),
              ...section.subSections.asMap().entries.map((e) {
                final si = e.key;
                final sub = e.value;
                final subKey = '$sKey:sub:$si';
                return KeyedSubtree(
                  key: errorKeys?[subKey] ?? ObjectKey(sub),
                  child: SectionEditor(
                    index: si,
                    section: sub,
                    depth: depth + 1,
                    densityEnabled: densityEnabled,
                    errors: errors,
                    errorKeyPrefix: subKey,
                    errorKeys: errorKeys,
                    onRemoveSection: () => onRemoveSubSection?.call(si),
                    onAddCriterion: (inputType) {
                      sub.criteria.add(EditableCriterion(inputType: inputType));
                      onChanged();
                    },
                    onRemoveCriterion: (ci) {
                      sub.criteria[ci].dispose();
                      sub.criteria.removeAt(ci);
                      onChanged();
                    },
                    onChanged: onChanged,
                  ),
                );
              }),
              if (section.criteria.isEmpty || !_allowSubSections)
                GhostAddButton(
                  label: 'Add Sub-Section',
                  icon: Icons.subdirectory_arrow_right,
                  tintColor: _allowSubSections
                      ? theme.colorScheme.outline
                      : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
                  onPressed: _allowSubSections
                      ? onAddSubSection
                      : () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Sub-sections require Penalty or Accumulation mode.',
                              ),
                              duration: Duration(seconds: 3),
                            ),
                          ),
                ),
            ],
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
          if (hasErrors)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: sectionErrors
                    .map(
                      (msg) => Row(
                        children: [
                          Icon(Icons.error_outline, size: 14, color: theme.colorScheme.error),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              msg,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          // Criteria list
          ...section.criteria.asMap().entries.map((e) {
            final ci = e.key;
            final c = e.value;
            final cKey = '$sKey:c:$ci';
            final cErrors = errors?.forKey(cKey) ?? const [];
            return KeyedSubtree(
              key: errorKeys?[cKey] ?? ObjectKey(c),
              child: CriterionEditor(
                criterion: c,
                errors: cErrors,
                scoringMode: scoringMode,
                globalCcpEnabled: globalCcpEnabled,
                globalRiskEnabled: globalRiskEnabled,
                onRemove: () => onRemoveCriterion(ci),
                onChanged: onChanged,
              ),
            );
          }),
          // "Add Criterion" ghost button — only when no sub-sections
          if (section.subSections.isEmpty)
            GhostAddButton(
              label: 'Add Criterion',
              icon: Icons.add,
              onPressed: () => onAddCriterion('pass_fail'),
              tintColor: theme.colorScheme.primary,
            ),
          // Sub-sections zone
          if (section.criteria.isNotEmpty || section.subSections.isNotEmpty)
            const Divider(),
          if (section.criteria.isEmpty && section.subSections.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(
                  '— OR —',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    letterSpacing: 2.0,
                  ),
                ),
              ),
            ),
          ...section.subSections.asMap().entries.map((e) {
            final si = e.key;
            final sub = e.value;
            final subKey = '$sKey:sub:$si';
            return KeyedSubtree(
              key: errorKeys?[subKey] ?? ObjectKey(sub),
              child: SectionEditor(
                index: si,
                section: sub,
                depth: depth + 1,
                densityEnabled: densityEnabled,
                errors: errors,
                errorKeyPrefix: subKey,
                errorKeys: errorKeys,
                onRemoveSection: () => onRemoveSubSection?.call(si),
                onAddCriterion: (inputType) {
                  sub.criteria.add(EditableCriterion(inputType: inputType));
                  onChanged();
                },
                onRemoveCriterion: (ci) {
                  sub.criteria[ci].dispose();
                  sub.criteria.removeAt(ci);
                  onChanged();
                },
                onChanged: onChanged,
              ),
            );
          }),
          if (section.criteria.isEmpty || !_allowSubSections)
            GhostAddButton(
              label: 'Add Sub-Section',
              icon: Icons.subdirectory_arrow_right,
              tintColor: _allowSubSections
                  ? theme.colorScheme.outline
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
              onPressed: _allowSubSections
                  ? onAddSubSection
                  : () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Sub-sections require Penalty or Accumulation mode.',
                          ),
                          duration: Duration(seconds: 3),
                        ),
                      ),
            ),
        ],
      ),
    );
  }
}
