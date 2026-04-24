import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/theme/app_theme.dart';
import 'expandable_setting_tile.dart';

class AdvancedSettingsCard extends StatefulWidget {
  final String scoringMode;
  final bool ccpOverride;
  final bool riskOverride;
  final bool weightedDensity;
  final bool progressiveRepeat;
  final TextEditingController deadlineCtrl;
  final TextEditingController reminderCtrl;
  final bool confirmRequired;
  final ValueChanged<bool> onCcpChanged;
  final ValueChanged<bool> onRiskChanged;
  final ValueChanged<bool> onDensityChanged;
  final ValueChanged<bool> onProgressiveChanged;
  final ValueChanged<bool> onConfirmChanged;

  const AdvancedSettingsCard({
    super.key,
    required this.scoringMode,
    required this.ccpOverride,
    required this.riskOverride,
    required this.weightedDensity,
    required this.progressiveRepeat,
    required this.deadlineCtrl,
    required this.reminderCtrl,
    required this.onCcpChanged,
    required this.onRiskChanged,
    required this.onDensityChanged,
    required this.onProgressiveChanged,
    required this.confirmRequired,
    required this.onConfirmChanged,
  });

  @override
  State<AdvancedSettingsCard> createState() => _AdvancedSettingsCardState();
}

class _AdvancedSettingsCardState extends State<AdvancedSettingsCard> {
  bool _expanded = false;

  bool get _isSurvey => widget.scoringMode == 'survey';
  bool get _isChecklist => widget.scoringMode == 'checklist';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row (acts like ExpansionTile header) ──
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
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
              trailing: AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.expand_more,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              onTap: () => setState(() => _expanded = !_expanded),
            ),
            // ── Expanded content ──
            if (_expanded)
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── GROUP 1: SCHEDULING ──

                    // Action Plan Deadline
                    Row(
                      children: [
                        const Expanded(flex: 3, child: Text('Action Plan Deadline')),
                        SizedBox(
                          width: 60,
                          child: TextFormField(
                            controller: widget.deadlineCtrl,
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
                              final v = int.tryParse(widget.deadlineCtrl.text) ?? 7;
                              widget.deadlineCtrl.text = v.clamp(1, 90).toString();
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
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
                            controller: widget.reminderCtrl,
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
                              final v = int.tryParse(widget.reminderCtrl.text) ?? 2;
                              widget.reminderCtrl.text = v.clamp(1, 30).toString();
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
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
                          color: AppColors.warningContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: AppTheme.warning,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'These settings affect how audits are scored. Change with care.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.warning,
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
                          value: widget.weightedDensity,
                          onChanged: widget.onDensityChanged,
                        ),

                      ExpandableSettingTile(
                        title: 'CCP Override',
                        description:
                            'Any criteria marked CCP that fails will zero out '
                            'its entire section.',
                        value: widget.ccpOverride,
                        onChanged: widget.onCcpChanged,
                      ),
                      ExpandableSettingTile(
                        title: 'RISK Override',
                        description:
                            'Any criteria marked RISK that fails will zero out '
                            'the entire audit.',
                        value: widget.riskOverride,
                        onChanged: widget.onRiskChanged,
                      ),

                      // Progressive Repeat — hidden for Checklist/Accumulation
                      if (!_isChecklist && widget.scoringMode != 'accumulation')
                        ExpandableSettingTile(
                          title: 'Progressive Repeat Penalty',
                          description:
                              'OFF: deduction = repeats × rate. '
                              'ON: deduction = repeats² × rate (harsher for more repeats).',
                          value: widget.progressiveRepeat,
                          onChanged: widget.onProgressiveChanged,
                        ),

                      SwitchListTile(
                        title: const Text('Require Confirmation'),
                        value: widget.confirmRequired,
                        onChanged: widget.onConfirmChanged,
                        contentPadding: EdgeInsets.zero,
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
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
          ],
        ),
      ),
    );
  }
}
