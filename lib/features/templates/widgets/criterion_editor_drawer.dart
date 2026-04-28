import 'package:flutter/material.dart';

import '../models/editable_criterion.dart';
import 'criterion_choice_editor.dart';
import 'criterion_scale_editor.dart';
import 'input_type_bottom_sheet.dart';

class CriterionEditorDrawer extends StatefulWidget {
  final EditableCriterion criterion;
  final String? scoringMode;
  final bool globalCcpEnabled;
  final bool globalRiskEnabled;
  final bool globalConfirmRequired;
  final VoidCallback onChanged;
  final VoidCallback onRequestRebuild;

  const CriterionEditorDrawer({
    super.key,
    required this.criterion,
    this.scoringMode,
    this.globalCcpEnabled = false,
    this.globalRiskEnabled = false,
    this.globalConfirmRequired = false,
    required this.onChanged,
    required this.onRequestRebuild,
  });

  @override
  State<CriterionEditorDrawer> createState() => _CriterionEditorDrawerState();
}

class _CriterionEditorDrawerState extends State<CriterionEditorDrawer> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Label
            TextFormField(
              controller: widget.criterion.labelCtrl,
              decoration: const InputDecoration(
                labelText: 'Criterion Label',
                isDense: true,
              ),
              onChanged: (_) => widget.onChanged(),
            ),
            const SizedBox(height: 16),

            // Gap 3: Description
            TextFormField(
              controller: widget.criterion.descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                isDense: true,
              ),
              maxLines: 3,
              onChanged: (_) => widget.onChanged(),
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
              avatar: Icon(inputTypeIcon(widget.criterion.inputType), size: 18),
              label: Text(inputTypeLabel(widget.criterion.inputType)),
              onPressed: () async {
                Navigator.pop(context);
                final selected = await showModalBottomSheet<String>(
                  context: context,
                  isScrollControlled: true,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.65,
                  ),
                  builder: (_) => InputTypeBottomSheet(
                    currentType: widget.criterion.inputType,
                    scoringMode: widget.scoringMode,
                  ),
                );
                if (selected != null && context.mounted) {
                  widget.criterion.inputType = selected;
                  // Reset irrelevant data when switching types to guarantee
                  // structural data integrity (prevent hidden payload corruption)
                  if (selected == 'text' ||
                      selected == 'single_choice' ||
                      selected == 'multi_choice') {
                    widget.criterion.pointsCtrl.clear();

                    // Critical P0 fix: Scrub CCP/Risk flags if type becomes unscored.
                    // The UI hides the toggles, so the in-memory value MUST be zeroed
                    // manually to avoid sending hidden 'true' flags to the backend.
                    widget.criterion.isCcp = false;
                    widget.criterion.isRisk = false;
                  } else if (widget.criterion.pointsCtrl.text.trim().isEmpty) {
                    // Restore default when switching back to a scored type.
                    widget.criterion.pointsCtrl.text = '10';
                  }

                  // Trim memory bloat to ensure clean structural payloads
                  if (selected != 'scale') {
                    widget.criterion.scaleOptions.clear();
                  }
                  if (selected != 'single_choice' &&
                      selected != 'multi_choice') {
                    widget.criterion.choiceOptions.clear();
                  }

                  if (selected == 'scale') {
                    final maxPts = widget.criterion.scaleOptions.fold<double>(
                      0,
                      (m, o) => (o['points'] as num? ?? 0).toDouble() > m
                          ? (o['points'] as num).toDouble()
                          : m,
                    );
                    widget.criterion.pointsCtrl.text = maxPts.toStringAsFixed(
                      0,
                    );
                  }

                  widget.onChanged();
                  widget.onRequestRebuild();
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
            if (widget.criterion.inputType == 'scale')
              CriterionScaleEditor(
                criterion: widget.criterion,
                onChanged: widget.onChanged,
                onRequestRebuild: widget.onRequestRebuild,
              ),

            // Choice Options editor (for single_choice / multi_choice)
            if (widget.criterion.inputType == 'single_choice' ||
                widget.criterion.inputType == 'multi_choice')
              CriterionChoiceEditor(
                criterion: widget.criterion,
                onChanged: widget.onChanged,
                onRequestRebuild: widget.onRequestRebuild,
              ),

            // Points weight visibility rules:
            //  - survey mode:  ALWAYS HIDDEN (null score — no math applies)
            //  - pass_fail / numeric: editable text field
            //  - scale: read-only (auto-synced from highest option value)
            //  - single_choice / multi_choice / text: HIDDEN (unscored input types)
            if (widget.scoringMode == 'survey')
              const SizedBox.shrink() // Survey mode: no scoring concept exists
            else if (widget.criterion.inputType == 'single_choice' ||
                widget.criterion.inputType == 'multi_choice' ||
                widget.criterion.inputType == 'text')
              const SizedBox.shrink() // No points weight for unscored input types
            else if (widget.criterion.inputType == 'scale')
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Points Weight'),
                trailing: Text(
                  widget.criterion.pointsCtrl.text.isEmpty
                      ? '0'
                      : widget.criterion.pointsCtrl.text,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: Theme.of(context).textTheme.titleMedium?.fontSize,
                  ),
                ),
                subtitle: const Text('Auto-set from highest scale option'),
              )
            else
              TextFormField(
                controller: widget.criterion.pointsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Points Weight',
                  helperText: 'Max score to award or multiplier for faults',
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => widget.onChanged(),
              ),
            if (widget.scoringMode == 'penalty' &&
                widget.criterion.inputType != 'text' &&
                widget.criterion.inputType != 'single_choice' &&
                widget.criterion.inputType != 'multi_choice') ...[
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: widget.criterion.minusImpactCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Minus / Fault',
                        helperText: 'Default: Points Weight',
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => widget.onChanged(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: widget.criterion.maxDeductionCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Max Points Lost',
                        helperText: 'Optional deduction cap',
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => widget.onChanged(),
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
              subtitle: widget.globalConfirmRequired
                  ? const Text('Required by global Confirm Correct setting')
                  : const Text('Auditor must complete this field to submit'),
              value: widget.globalConfirmRequired
                  ? true
                  : widget.criterion.isRequired,
              onChanged: widget.globalConfirmRequired
                  ? null
                  : (v) {
                      setState(() => widget.criterion.isRequired = v);
                      widget.onChanged();
                    },
            ),

            // CCP / Risk toggles — two-gate logic:
            // Gate 1 (BLOCKLIST): survey + checklist always hide both toggles.
            // Gate 2 (ALLOWLIST + data preservation, Gotcha #6):
            //   show iff globalEnabled OR criterion already carries the flag.
            // Gotcha #11: non-scored input types (text/choice) always hide.
            () {
              final inputTypeScored =
                  widget.criterion.inputType != 'text' &&
                  widget.criterion.inputType != 'single_choice' &&
                  widget.criterion.inputType != 'multi_choice';
              final modeAllows =
                  widget.scoringMode != 'survey' &&
                  widget.scoringMode != 'checklist';
              final showCcp =
                  modeAllows &&
                  inputTypeScored &&
                  (widget.globalCcpEnabled || widget.criterion.isCcp);
              final showRisk =
                  modeAllows &&
                  inputTypeScored &&
                  (widget.globalRiskEnabled || widget.criterion.isRisk);

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
                      value: widget.criterion.isCcp,
                      onChanged: (v) {
                        setState(() => widget.criterion.isCcp = v);
                        widget.onChanged();
                      },
                    ),
                  if (showRisk)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Risk'),
                      subtitle: const Text(
                        'Failure zeros the entire audit score',
                      ),
                      value: widget.criterion.isRisk,
                      onChanged: (v) {
                        setState(() => widget.criterion.isRisk = v);
                        widget.onChanged();
                      },
                    ),
                  const SizedBox(height: 8),
                ],
              );
            }(),
          ],
        ),
      ),
    );
  }
}
