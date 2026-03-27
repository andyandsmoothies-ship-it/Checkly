import 'package:flutter/material.dart';

import '../models/editable_criterion.dart';
import '../models/editable_group.dart';
import '../models/wizard_starter_packs.dart';
import 'section_editor.dart';

/// Wizard Step 3: Build criteria per section.
/// Shows ONE section at a time with pill navigation at the top.
/// Delegates criteria editing and sub-section management to [SectionEditor].
class WizardStepSections extends StatefulWidget {
  final List<EditableGroup> sections;
  final String scoringMode;
  final int currentSectionIndex;
  final VoidCallback onChanged;
  final ValueChanged<int> onSectionChanged;

  const WizardStepSections({
    super.key,
    required this.sections,
    required this.scoringMode,
    required this.currentSectionIndex,
    required this.onChanged,
    required this.onSectionChanged,
  });

  @override
  State<WizardStepSections> createState() => _WizardStepSectionsState();
}

class _WizardStepSectionsState extends State<WizardStepSections> {
  /// Default input type based on scoring mode (BL-DEFAULT).
  String get _defaultInputType {
    switch (widget.scoringMode) {
      case 'accumulation':
        return 'scale';
      case 'survey':
        return 'single_choice';
      case 'checklist':
      case 'penalty':
      default:
        return 'pass_fail';
    }
  }

  /// Adds a sub-section to the current section (BL-DISPOSE: dispose on remove).
  void _addSubSection(EditableGroup section) {
    setState(() {
      section.subSections.add(EditableGroup());
    });
    widget.onChanged();
  }

  /// Removes and disposes a sub-section (BL-DISPOSE).
  void _removeSubSection(EditableGroup section, int si) {
    setState(() {
      section.subSections[si].dispose();
      section.subSections.removeAt(si);
    });
    widget.onChanged();
  }

  void _showBatchAdd(BuildContext context, EditableGroup section) {
    final ctrl = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Batch Add Criteria',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter one criterion per line (max 20).',
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              maxLines: 8,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Handwashing station available\nFloor cleanliness\nWaste disposal...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final lines = ctrl.text
                    .split('\n')
                    .map((l) => l.trim())
                    .where((l) => l.isNotEmpty)
                    .toList();
                final capped = lines.length > 20;
                final toAdd = lines.take(20).toList();
                setState(() {
                  for (final label in toAdd) {
                    final c = EditableCriterion(
                      inputType: _defaultInputType,
                      points: '10',
                    );
                    c.labelCtrl.text = label;
                    section.criteria.add(c);
                  }
                });
                widget.onChanged();
                Navigator.pop(ctx);
                if (capped && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Maximum 20 criteria per batch. Additional lines were ignored.',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Add Criteria'),
            ),
          ],
        ),
      ),
    );
  }

  /// Grammar-correct count label: '1 criterion' / 'N criteria' with sub-section variant.
  String _buildCountLabel(EditableGroup section, bool hasSubSections) {
    final c = hasSubSections ? section.countCriteria() : section.criteria.length;
    final cLabel = c == 1 ? 'criterion' : 'criteria';
    if (hasSubSections) {
      final s = section.subSections.length;
      final sLabel = s == 1 ? 'sub-section' : 'sub-sections';
      return '$c $cLabel \u2022 $s $sLabel';
    }
    return '$c $cLabel';
  }

  /// Returns a contextual guidance banner for modes that restrict wizard
  /// capabilities. Returns [SizedBox.shrink] for unrestricted modes (penalty,
  /// accumulation) to avoid noise for experienced users.
  Widget _buildModeBanner(BuildContext context) {
    final theme = Theme.of(context);
    final (IconData icon, String text, Color color) = switch (widget.scoringMode) {
      'survey' => (
          Icons.forum_outlined,
          'Survey Mode — Sub-sections and scoring logic are disabled. Add questions to collect responses.',
          theme.colorScheme.secondary,
        ),
      'checklist' => (
          Icons.checklist_rounded,
          'Checklist Mode — Keep it flat with Pass / Fail or choice inputs. Advanced math is disabled.',
          theme.colorScheme.primary,
        ),
      _ => (Icons.info_outline, '', Colors.transparent),
    };

    // No banner for penalty / accumulation modes (or unknown modes)
    if (text.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sectionCount = widget.sections.length;
    final currentIdx = widget.currentSectionIndex.clamp(0, sectionCount - 1);

    if (sectionCount == 0) {
      return const Center(child: Text('No sections to build.'));
    }

    final section = widget.sections[currentIdx];
    final hasSubSections = section.subSections.isNotEmpty;

    return Column(
      children: [
        // Section pill navigation
        if (sectionCount > 1)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                for (int i = 0; i < sectionCount; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        widget.sections[i].titleCtrl.text.isEmpty
                            ? 'Section ${i + 1}'
                            : widget.sections[i].titleCtrl.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      selected: i == currentIdx,
                      onSelected: (_) => widget.onSectionChanged(i),
                    ),
                  ),
              ],
            ),
          ),

        // Section content area
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            children: [
              _buildModeBanner(context),
              // Section progress header with recursive count (Change 3)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Section ${currentIdx + 1} of $sectionCount',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          section.titleCtrl.text.isEmpty
                              ? 'Section ${currentIdx + 1}'
                              : section.titleCtrl.text,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        // Grammar fix: singular-aware count
                        Text(
                          _buildCountLabel(section, hasSubSections),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // UX Fix (H10): Provide explicit guidance for what a criterion is
              Text(
                'Add the specific checks or questions for this section. Keep it simple with a single list, or use sub-sections to group related items (e.g., \'Indoor\' and \'Outdoor\').',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),


              // Change 4: Delegate to SectionEditor(depth: 0) with isWizardMode:true
              // so it renders a clean Column body without the duplicate
              // title / badge / delete header (H8, H2, H3 UX fix).
              SectionEditor(
                key: ValueKey(section),
                index: currentIdx,
                section: section,
                depth: 0,
                densityEnabled: false,
                isWizardMode: true,
                onRemoveSection: () {
                  // No-op: wizard manages section removal via Step 2 (Structure)
                },
                // BL-DEFAULT: override SectionEditor's 'pass_fail' with scoring-mode-aware default
                onAddCriterion: (_) {
                  setState(() {
                    section.criteria.add(EditableCriterion(
                      inputType: _defaultInputType,
                      points: '10',
                    ));
                  });
                  widget.onChanged();
                },
                onRemoveCriterion: (ci) {
                  setState(() {
                    section.criteria[ci].dispose();
                    section.criteria.removeAt(ci);
                  });
                  widget.onChanged();
                },
                // BL-DISPOSE: sub-section management via local helpers
                onAddSubSection: () => _addSubSection(section),
                onRemoveSubSection: (si) => _removeSubSection(section, si),
                onChanged: () {
                  setState(() {});
                  widget.onChanged();
                },
              ),

              // H6 fix: Batch Add grouped with the other Add actions (below SectionEditor)
              if (!hasSubSections)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: OutlinedButton.icon(
                    onPressed: () => _showBatchAdd(context, section),
                    icon: const Icon(Icons.playlist_add, size: 18),
                    label: const Text('Add Multiple Criteria'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),

              // Suggested criteria chips — visible when using root criteria path
              if (!hasSubSections) ...[
                const Divider(height: 32),
                Text(
                  'Suggested criteria:',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Builder(
                  builder: (ctx) {
                    final suggestions = WizardSuggestions.getCriteriaSuggestions(
                        widget.scoringMode, section.titleCtrl.text);
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: suggestions.map((sc) {
                        final alreadyAdded = section.criteria
                            .any((c) => c.labelCtrl.text == sc.label);
                        return ActionChip(
                          label: Text(sc.label),
                          avatar: const Icon(Icons.add, size: 16),
                          onPressed: alreadyAdded ? null : () {
                            setState(() {
                              final c = EditableCriterion(
                                  inputType: sc.inputType, points: sc.points);
                              c.labelCtrl.text = sc.label;
                              // Q1: pre-populate two options so the V6 choice guard
                              // doesn't block save for survey single_choice chips.
                              if (sc.inputType == 'single_choice' ||
                                  sc.inputType == 'multi_choice') {
                                c.choiceOptions = ['Yes', 'No'];
                              }
                              section.criteria.add(c);
                            });
                            widget.onChanged();
                          },
                          backgroundColor: alreadyAdded
                              ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                              : theme.colorScheme.secondaryContainer,
                          labelStyle: TextStyle(
                            color: alreadyAdded
                                ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                                : theme.colorScheme.onSecondaryContainer,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
