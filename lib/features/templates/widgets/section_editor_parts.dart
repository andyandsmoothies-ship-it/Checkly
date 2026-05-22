part of 'section_editor.dart';

class SectionEditorHeader extends StatelessWidget {
  final EditableGroup section;
  final int index;
  final bool isRoot;
  final bool densityEnabled;
  final int subCount;
  final int critCount;
  final VoidCallback onChanged;

  const SectionEditorHeader({
    super.key,
    required this.section,
    required this.index,
    required this.isRoot,
    required this.densityEnabled,
    required this.subCount,
    required this.critCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
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
                color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
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
        // Gap 6: count badge (XS • YC) — root sections only
        if (isRoot)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.sageGray.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${subCount}S • ${critCount}C',
              style: AppFonts.serifStyle(
                fontSize: Theme.of(context).textTheme.labelSmall?.fontSize,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        const SizedBox(width: 4),
        // Inline editable weight input in header (PWA parity)
        if (densityEnabled && isRoot)
          Container(
            width: 64,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                      fontSize: theme.textTheme.bodySmall?.fontSize,
                      color: theme.colorScheme.primary,
                    ),
                    decoration: const InputDecoration(
                      hintText: '0',
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onTap: () => section.weightCtrl.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: section.weightCtrl.text.length,
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                Text(
                  '%',
                  style: AppFonts.serifStyle(
                    fontSize: theme.textTheme.bodySmall?.fontSize,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class SectionErrorMessages extends StatelessWidget {
  final List<String> errors;

  const SectionErrorMessages({super.key, required this.errors});

  @override
  Widget build(BuildContext context) {
    if (errors.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: errors
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
                        fontSize: theme.textTheme.bodySmall?.fontSize,
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
    );
  }
}

class SectionCriteriaList extends StatelessWidget {
  final EditableGroup section;
  final String sKey;
  final ValidationErrors? errors;
  final Map<String, GlobalKey>? errorKeys;
  final String? scoringMode;
  final bool globalCcpEnabled;
  final bool globalRiskEnabled;
  final bool globalConfirmRequired;
  final ValueChanged<int> onRemoveCriterion;
  final VoidCallback onChanged;
  final ValueChanged<String> onAddCriterion;

  const SectionCriteriaList({
    super.key,
    required this.section,
    required this.sKey,
    this.errors,
    this.errorKeys,
    this.scoringMode,
    required this.globalCcpEnabled,
    required this.globalRiskEnabled,
    required this.globalConfirmRequired,
    required this.onRemoveCriterion,
    required this.onChanged,
    required this.onAddCriterion,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
              globalConfirmRequired: globalConfirmRequired,
              onRemove: () => onRemoveCriterion(ci),
              onChanged: onChanged,
            ),
          );
        }),
        GhostAddButton(
          label: 'Add Criterion',
          icon: Icons.add,
          onPressed: () => onAddCriterion('pass_fail'),
          tintColor: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }
}

class SectionSubSections extends StatelessWidget {
  final EditableGroup section;
  final String sKey;
  final int depth;
  final bool densityEnabled;
  final ValidationErrors? errors;
  final Map<String, GlobalKey>? errorKeys;
  final ValueChanged<int>? onRemoveSubSection;
  final VoidCallback onChanged;

  const SectionSubSections({
    super.key,
    required this.section,
    required this.sKey,
    required this.depth,
    required this.densityEnabled,
    this.errors,
    this.errorKeys,
    this.onRemoveSubSection,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (section.subSections.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
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
      ],
    );
  }
}
