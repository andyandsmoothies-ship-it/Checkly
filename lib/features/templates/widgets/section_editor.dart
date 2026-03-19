import 'package:flutter/material.dart';

import '../../../_shared/theme/app_theme.dart';
import '../../../_shared/theme/app_fonts.dart';
import '../models/editable_criterion.dart';
import '../models/editable_group.dart';
import 'criterion_editor.dart';

class SectionEditor extends StatelessWidget {
  final int index;
  final EditableGroup section;
  final int depth;

  final bool densityEnabled;
  final VoidCallback onRemoveSection;
  final ValueChanged<String> onAddCriterion;
  final ValueChanged<int> onRemoveCriterion;
  final VoidCallback? onAddSubSection;
  final ValueChanged<int>? onRemoveSubSection;
  final VoidCallback onChanged;

  const SectionEditor({
    super.key,
    required this.index,
    required this.section,
    this.depth = 0,

    this.densityEnabled = true,
    required this.onRemoveSection,
    required this.onAddCriterion,
    required this.onRemoveCriterion,
    this.onAddSubSection,
    this.onRemoveSubSection,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRoot = depth == 0;

    // Gap 6: count badge
    final subCount = section.countSubs();
    final critCount = section.countCriteria();

    return Card(
      margin: EdgeInsets.only(
        bottom: 12,
        left: isRoot ? 0 : 16, // Gap 1: indent sub-sections
      ),
      shape: isRoot
          ? null
          : RoundedRectangleBorder(
              side: BorderSide(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                width: 2,
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
                    hintStyle: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.38,
                      ),
                      fontStyle: FontStyle.italic,
                    ),
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
              // Gap 6: count badge (XS • YC) — root sections only
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
                    '${subCount}S • ${critCount}C',
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
              return CriterionEditor(
                criterion: c,

                onRemove: () => onRemoveCriterion(ci),
                onChanged: onChanged,
              );
            }),

            // Quick-Add Input Chips — hidden if root has sub-sections
            if (isRoot && section.subSections.isEmpty || !isRoot)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _QuickAddChip(
                      label: '+ Pass/Fail',
                      icon: Icons.check_circle_outline,
                      onTap: () => onAddCriterion('pass_fail'),
                    ),
                    _QuickAddChip(
                      label: '+ Fault Count',
                      icon: Icons.pin_outlined,
                      onTap: () => onAddCriterion('numeric'),
                    ),
                    _QuickAddChip(
                      label: '+ Scale',
                      icon: Icons.linear_scale,
                      onTap: () => onAddCriterion('scale'),
                    ),
                    _QuickAddChip(
                      label: '+ Choice',
                      icon: Icons.radio_button_checked,
                      onTap: () => onAddCriterion('single_choice'),
                    ),
                  ],
                ),
              ),

            // Gap 1: Sub-sections
            if (isRoot) ...[
              const Divider(),
              ...section.subSections.asMap().entries.map((e) {
                final si = e.key;
                final sub = e.value;
                return SectionEditor(
                  index: si,
                  section: sub,
                  depth: depth + 1,

                  densityEnabled: densityEnabled,

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
                );
              }),
              if (section.criteria.isEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: onAddSubSection,
                    icon: const Icon(Icons.subdirectory_arrow_right, size: 14),
                    label: const Text('Add Sub-Section'),
                    style: TextButton.styleFrom(
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickAddChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickAddChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ActionChip(
      avatar: Icon(icon, size: 14, color: theme.colorScheme.primary),
      label: Text(
        label,
        style: TextStyle(fontSize: 11, color: theme.colorScheme.primary),
      ),
      backgroundColor: theme.colorScheme.primaryContainer.withValues(
        alpha: 0.3,
      ),
      side: BorderSide.none,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
    );
  }
}
