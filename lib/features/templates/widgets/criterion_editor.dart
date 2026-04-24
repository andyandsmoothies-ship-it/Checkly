import 'package:flutter/material.dart';

import '../../../_shared/theme/app_fonts.dart';
import '../models/editable_criterion.dart';
import 'criterion_choice_editor.dart';
import 'criterion_scale_editor.dart';
import 'input_type_bottom_sheet.dart';

class CriterionEditor extends StatelessWidget {
  final EditableCriterion criterion;
  final List<String> errors;
  final String? scoringMode; // optional — filters input type bottom sheet
  final bool globalCcpEnabled;     // gates CCP toggle visibility
  final bool globalRiskEnabled;    // gates Risk toggle visibility
  final bool globalConfirmRequired; // when true, locks Required toggle ON

  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const CriterionEditor({
    super.key,
    required this.criterion,
    this.errors = const [],
    this.scoringMode,
    this.globalCcpEnabled = false,
    this.globalRiskEnabled = false,
    this.globalConfirmRequired = false,
    required this.onRemove,
    required this.onChanged,
  });

  void _openDrawer(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Criterion',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Label
                TextFormField(
                  controller: criterion.labelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Criterion Label',
                    isDense: true,
                  ),
                  onChanged: (_) => onChanged(),
                ),
                const SizedBox(height: 16),

                // Gap 3: Description
                TextFormField(
                  controller: criterion.descCtrl,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    isDense: true,
                  ),
                  maxLines: 3,
                  onChanged: (_) => onChanged(),
                ),
                const SizedBox(height: 16),

                // Input Type selector — tap chip to open bottom sheet
                Text(
                  'Input Type',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                ActionChip(
                  avatar: Icon(inputTypeIcon(criterion.inputType), size: 18),
                  label: Text(inputTypeLabel(criterion.inputType)),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final selected = await showModalBottomSheet<String>(
                      context: context,
                      isScrollControlled: true,
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.65,
                      ),
                      builder: (_) => InputTypeBottomSheet(
                        currentType: criterion.inputType,
                        scoringMode: scoringMode,
                      ),
                    );
                    if (selected != null && context.mounted) {
                      criterion.inputType = selected;
                      // Reset irrelevant data when switching types to guarantee 
                      // structural data integrity (prevent hidden payload corruption)
                      if (selected == 'text' ||
                          selected == 'single_choice' ||
                          selected == 'multi_choice') {
                        criterion.pointsCtrl.clear();
                        
                        // Critical P0 fix: Scrub CCP/Risk flags if type becomes unscored. 
                        // The UI hides the toggles, so the in-memory value MUST be zeroed 
                        // manually to avoid sending hidden 'true' flags to the backend.
                        criterion.isCcp = false;
                        criterion.isRisk = false;
                      } else if (criterion.pointsCtrl.text.trim().isEmpty) {
                        // Restore default when switching back to a scored type.
                        criterion.pointsCtrl.text = '10';
                      }

                      // Trim memory bloat to ensure clean structural payloads
                      if (selected != 'scale') criterion.scaleOptions.clear();
                      if (selected != 'single_choice' && selected != 'multi_choice') {
                        criterion.choiceOptions.clear();
                      }

                      if (selected == 'scale') {
                        final maxPts = criterion.scaleOptions.fold<double>(
                          0,
                          (m, o) => (o['points'] as num? ?? 0).toDouble() > m
                              ? (o['points'] as num).toDouble()
                              : m,
                        );
                        criterion.pointsCtrl.text = maxPts.toStringAsFixed(0);
                      }

                      onChanged();
                      _openDrawer(context);
                    }
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  'Determines how the auditor will grade this item',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),

                // Scale Options editor (only for scale type)
                if (criterion.inputType == 'scale')
                  CriterionScaleEditor(
                    criterion: criterion,
                    onChanged: onChanged,
                    onRequestRebuild: () {
                      Navigator.pop(ctx);
                      Future.microtask(() {
                        if (context.mounted) _openDrawer(context);
                      });
                    },
                  ),

                // Choice Options editor (for single_choice / multi_choice)
                if (criterion.inputType == 'single_choice' ||
                    criterion.inputType == 'multi_choice')
                  CriterionChoiceEditor(
                    criterion: criterion,
                    onChanged: onChanged,
                    onRequestRebuild: () {
                      Navigator.pop(ctx);
                      Future.microtask(() {
                        if (context.mounted) _openDrawer(context);
                      });
                    },
                  ),

                // Points weight visibility rules:
                //  - survey mode:  ALWAYS HIDDEN (null score — no math applies)
                //  - pass_fail / numeric: editable text field
                //  - scale: read-only (auto-synced from highest option value)
                //  - single_choice / multi_choice / text: HIDDEN (unscored input types)
                if (scoringMode == 'survey')
                  const SizedBox.shrink() // Survey mode: no scoring concept exists
                else if (criterion.inputType == 'single_choice' ||
                    criterion.inputType == 'multi_choice' ||
                    criterion.inputType == 'text')
                  const SizedBox.shrink() // No points weight for unscored input types
                else if (criterion.inputType == 'scale')
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Points Weight'),
                    trailing: Text(
                      criterion.pointsCtrl.text.isEmpty
                          ? '0'
                          : criterion.pointsCtrl.text,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: Theme.of(ctx).textTheme.titleMedium?.fontSize,
                      ),
                    ),
                    subtitle: const Text('Auto-set from highest scale option'),
                  )
                else
                  TextFormField(
                    controller: criterion.pointsCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Points Weight',
                      helperText: 'Max score to award or multiplier for faults',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => onChanged(),
                  ),
                if (scoringMode == 'penalty' &&
                    criterion.inputType != 'text' &&
                    criterion.inputType != 'single_choice' &&
                    criterion.inputType != 'multi_choice') ...[
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: criterion.minusImpactCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Minus / Fault',
                            helperText: 'Default: Points Weight',
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => onChanged(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: criterion.maxDeductionCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Max Points Lost',
                            helperText: 'Optional deduction cap',
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => onChanged(),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),

                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Required'),
                  subtitle: globalConfirmRequired
                      ? const Text('Required by global Confirm Correct setting')
                      : const Text('Auditor must complete this field to submit'),
                  value: globalConfirmRequired ? true : criterion.isRequired,
                  onChanged: globalConfirmRequired
                      ? null
                      : (v) {
                          setSheetState(() => criterion.isRequired = v);
                          onChanged();
                        },
                ),

                // CCP / Risk toggles — two-gate logic:
                // Gate 1 (BLOCKLIST): survey + checklist always hide both toggles.
                // Gate 2 (ALLOWLIST + data preservation, Gotcha #6):
                //   show iff globalEnabled OR criterion already carries the flag.
                // Gotcha #11: non-scored input types (text/choice) always hide.
                () {
                  final inputTypeScored =
                      criterion.inputType != 'text' &&
                      criterion.inputType != 'single_choice' &&
                      criterion.inputType != 'multi_choice';
                  final modeAllows =
                      scoringMode != 'survey' && scoringMode != 'checklist';
                  final showCcp = modeAllows &&
                      inputTypeScored &&
                      (globalCcpEnabled || criterion.isCcp);
                  final showRisk = modeAllows &&
                      inputTypeScored &&
                      (globalRiskEnabled || criterion.isRisk);

                  if (!showCcp && !showRisk) return const SizedBox.shrink();

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Divider(),
                      if (showCcp)
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Critical Control Point (CCP)'),
                          subtitle: const Text(
                            'Failure zeros this entire section score',
                          ),
                          value: criterion.isCcp,
                          onChanged: (v) {
                            setSheetState(() => criterion.isCcp = v);
                            onChanged();
                          },
                        ),
                      if (showRisk)
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Risk'),
                          subtitle:
                              const Text('Failure zeros the entire audit score'),
                          value: criterion.isRisk,
                          onChanged: (v) {
                            setSheetState(() => criterion.isRisk = v);
                            onChanged();
                          },
                        ),
                      const SizedBox(height: 8),
                    ],
                  );
                }(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasErrors = errors.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _openDrawer(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: hasErrors
                    ? theme.colorScheme.errorContainer.withValues(alpha: 0.3)
                    : theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: hasErrors
                    ? Border.all(color: theme.colorScheme.error, width: 1.5)
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.drag_indicator,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          criterion.labelCtrl.text.isEmpty
                              ? 'Untitled criterion'
                              : criterion.labelCtrl.text,
                          style: TextStyle(
                            fontSize: theme.textTheme.bodySmall?.fontSize,
                            color: criterion.labelCtrl.text.isEmpty
                                ? theme.colorScheme.onSurfaceVariant
                                : null,
                            fontStyle: criterion.labelCtrl.text.isEmpty
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (criterion.pointsCtrl.text.isNotEmpty &&
                                scoringMode != 'survey' &&
                                criterion.inputType != 'text' &&
                                criterion.inputType != 'single_choice' &&
                                criterion.inputType != 'multi_choice') ...[
                              Text(
                                '${criterion.pointsCtrl.text}pt',
                                style: AppFonts.serifStyle(
                                  fontSize: theme.textTheme.labelSmall?.fontSize,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer.withValues(
                                  alpha: 0.5,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    inputTypeIcon(criterion.inputType),
                                    size: 10,
                                    color: theme.colorScheme.onSecondaryContainer,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    inputTypeLabel(criterion.inputType).toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Inline delete — PWA parity
                  IconButton(
                    onPressed: onRemove,
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: theme.colorScheme.error,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          // Inline error messages
          if (hasErrors)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: errors
                    .map(
                      (msg) => Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 12,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              msg,
                              style: TextStyle(
                                fontSize: theme.textTheme.labelSmall?.fontSize,
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
        ],
      ),
    );
  }
}
