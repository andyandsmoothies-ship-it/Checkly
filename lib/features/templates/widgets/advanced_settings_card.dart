import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'expandable_setting_tile.dart';

class AdvancedSettingsCard extends StatelessWidget {
  final String scoringMode;
  final bool ccpOverride;
  final bool riskOverride;
  final bool weightedDensity;
  final bool confirmCorrect;
  final bool progressiveRepeat;
  final TextEditingController deadlineCtrl;
  final TextEditingController reminderCtrl;
  final ValueChanged<String?> onScoringModeChanged;
  final ValueChanged<bool> onCcpChanged;
  final ValueChanged<bool> onRiskChanged;
  final ValueChanged<bool> onDensityChanged;
  final ValueChanged<bool> onCorrectChanged;
  final ValueChanged<bool> onProgressiveChanged;

  const AdvancedSettingsCard({
    super.key,
    required this.scoringMode,
    required this.ccpOverride,
    required this.riskOverride,
    required this.weightedDensity,
    required this.confirmCorrect,
    required this.progressiveRepeat,
    required this.deadlineCtrl,
    required this.reminderCtrl,
    required this.onScoringModeChanged,
    required this.onCcpChanged,
    required this.onRiskChanged,
    required this.onDensityChanged,
    required this.onCorrectChanged,
    required this.onProgressiveChanged,
  });

  bool get _isSurvey => scoringMode == 'survey';
  bool get _isChecklist => scoringMode == 'checklist';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          initiallyExpanded: false,
          leading: Icon(
            Icons.settings,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          title: Text(
            'Advanced Settings',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            // ── GROUP 1: SCORING MODE + SCHEDULING ──
            DropdownButtonFormField<String>(
              initialValue: scoringMode,
              decoration: const InputDecoration(
                labelText: 'Scoring Mode',
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'penalty',
                  child: Text('Penalty (Top-Down)'),
                ),
                DropdownMenuItem(
                  value: 'accumulation',
                  child: Text('Accumulation (Zero-to-Top)'),
                ),
                DropdownMenuItem(
                  value: 'checklist',
                  child: Text('Checklist (Pass/Fail)'),
                ),
                DropdownMenuItem(
                  value: 'survey',
                  child: Text('Survey (No Scoring)'),
                ),
              ],
              onChanged: onScoringModeChanged,
            ),
            const SizedBox(height: 16),

            // Action Plan Deadline
            Row(
              children: [
                const Expanded(flex: 3, child: Text('Action Plan Deadline')),
                SizedBox(
                  width: 60,
                  child: TextFormField(
                    controller: deadlineCtrl,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onEditingComplete: () {
                      final v = int.tryParse(deadlineCtrl.text) ?? 7;
                      deadlineCtrl.text = v.clamp(1, 90).toString();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                const Text('days'),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              child: Text(
                'Number of days to resolve each action plan (1–90).',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),

            // Deadline Reminder
            Row(
              children: [
                const Expanded(flex: 3, child: Text('Deadline\nReminder')),
                const Text('before  '),
                SizedBox(
                  width: 60,
                  child: TextFormField(
                    controller: reminderCtrl,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onEditingComplete: () {
                      final v = int.tryParse(reminderCtrl.text) ?? 2;
                      reminderCtrl.text = v.clamp(1, 30).toString();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                const Text('days'),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Reminder days before deadline (1–30).',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),

            // ── GROUP 2: SCORING TOGGLES (mode-aware) ──
            if (!_isSurvey) ...[
              const Divider(height: 24),

              // Amber warning banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Colors.amber.shade800,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'These settings affect how audits are scored. Change with care.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Weighted Density — hidden for Checklist
              if (!_isChecklist)
                ExpandableSettingTile(
                  title: 'Weighted Density',
                  description:
                      'Each section contributes to the total based on its '
                      'assigned weight (must sum to 100%).',
                  value: weightedDensity,
                  onChanged: onDensityChanged,
                ),

              ExpandableSettingTile(
                title: 'CCP Override',
                description:
                    'Any criteria marked CCP that fails will zero out '
                    'its entire section.',
                value: ccpOverride,
                onChanged: onCcpChanged,
              ),
              ExpandableSettingTile(
                title: 'RISK Override',
                description:
                    'Any criteria marked RISK that fails will zero out '
                    'the entire audit.',
                value: riskOverride,
                onChanged: onRiskChanged,
              ),

              // Progressive Repeat — hidden for Checklist/Accumulation
              if (!_isChecklist && scoringMode != 'accumulation')
                ExpandableSettingTile(
                  title: 'Progressive Repeat Penalty',
                  description:
                      'OFF: deduction = repeats × rate. '
                      'ON: deduction = repeats² × rate (harsher for more repeats).',
                  value: progressiveRepeat,
                  onChanged: onProgressiveChanged,
                ),

              ExpandableSettingTile(
                title: 'Confirm Correct',
                description:
                    'Auditor must tap "Correct" to confirm each passing '
                    'criteria before submitting.',
                value: confirmCorrect,
                onChanged: onCorrectChanged,
              ),
            ],

            // Survey mode info banner
            if (_isSurvey)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Survey mode — responses are collected without scoring.',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
