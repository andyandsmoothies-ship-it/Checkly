part of 'wizard_step_sections.dart';

class WizardModeBanner extends StatelessWidget {
  final String scoringMode;

  const WizardModeBanner({super.key, required this.scoringMode});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (IconData icon, String text, Color color) = switch (scoringMode) {
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
}

class WizardSectionPillNav extends StatelessWidget {
  final List<EditableGroup> sections;
  final int currentIdx;
  final ValueChanged<int> onSectionChanged;

  const WizardSectionPillNav({
    super.key,
    required this.sections,
    required this.currentIdx,
    required this.onSectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final sectionCount = sections.length;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          for (int i = 0; i < sectionCount; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(
                  sections[i].titleCtrl.text.isEmpty
                      ? 'Section ${i + 1}'
                      : sections[i].titleCtrl.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                selected: i == currentIdx,
                onSelected: (_) => onSectionChanged(i),
              ),
            ),
        ],
      ),
    );
  }
}

class WizardSectionProgressHeader extends StatelessWidget {
  final String sectionTitle;
  final int currentIdx;
  final int sectionCount;
  final String countLabel;
  final bool densityEnabled;
  final EditableGroup? section;
  final VoidCallback? onChanged;

  const WizardSectionProgressHeader({
    super.key,
    required this.sectionTitle,
    required this.currentIdx,
    required this.sectionCount,
    required this.countLabel,
    this.densityEnabled = false,
    this.section,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
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
                sectionTitle.isEmpty
                    ? 'Section ${currentIdx + 1}'
                    : sectionTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              // Grammar fix: singular-aware count
              Text(
                countLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (densityEnabled && section != null) ...[
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Weight',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 64,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
                        controller: section!.weightCtrl,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          fontSize: theme.textTheme.bodySmall?.fontSize,
                          color: theme.colorScheme.primary,
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          hintText: '0',
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onTap: () => section!.weightCtrl.selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: section!.weightCtrl.text.length,
                        ),
                        onChanged: (_) => onChanged?.call(),
                      ),
                    ),
                    Text(
                      '%',
                      style: TextStyle(
                        fontSize: theme.textTheme.bodySmall?.fontSize,
                        color: theme.colorScheme.primary,
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class WizardSuggestedCriteria extends StatelessWidget {
  final String scoringMode;
  final String sectionTitle;
  final EditableGroup section;
  final void Function(StarterCriterion) onCriterionSelected;

  const WizardSuggestedCriteria({
    super.key,
    required this.scoringMode,
    required this.sectionTitle,
    required this.section,
    required this.onCriterionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestions = WizardSuggestions.getCriteriaSuggestions(
      scoringMode,
      sectionTitle,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        Text(
          'Suggested criteria:',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions.map((sc) {
            final alreadyAdded = section.criteria.any(
              (c) => c.labelCtrl.text == sc.label,
            );
            return ActionChip(
              label: Text(sc.label),
              avatar: const Icon(Icons.add, size: 16),
              onPressed: alreadyAdded ? null : () => onCriterionSelected(sc),
              backgroundColor: alreadyAdded
                  ? theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    )
                  : theme.colorScheme.secondaryContainer,
              labelStyle: TextStyle(
                color: alreadyAdded
                    ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                    : theme.colorScheme.onSecondaryContainer,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
