import 'package:flutter/material.dart';

import '../models/editable_group.dart';
import '../widgets/advanced_settings_card.dart';

/// Wizard Step 3: Review & optional advanced settings before saving.
class WizardStepReview extends StatefulWidget {
  final String title;
  final String scoringMode;
  final String type;
  final List<EditableGroup> sections;

  // Advanced settings (passed through to AdvancedSettingsCard)
  final bool ccpOverride;
  final bool riskOverride;
  final bool weightedDensity;
  final bool confirmCorrect;
  final bool progressiveRepeat;
  final TextEditingController deadlineCtrl;
  final TextEditingController reminderCtrl;
  final ValueChanged<bool> onCcpChanged;
  final ValueChanged<bool> onRiskChanged;
  final ValueChanged<bool> onDensityChanged;
  final ValueChanged<bool> onCorrectChanged;
  final ValueChanged<bool> onProgressiveChanged;

  const WizardStepReview({
    super.key,
    required this.title,
    required this.scoringMode,
    required this.type,
    required this.sections,
    required this.ccpOverride,
    required this.riskOverride,
    required this.weightedDensity,
    required this.confirmCorrect,
    required this.progressiveRepeat,
    required this.deadlineCtrl,
    required this.reminderCtrl,
    required this.onCcpChanged,
    required this.onRiskChanged,
    required this.onDensityChanged,
    required this.onCorrectChanged,
    required this.onProgressiveChanged,
  });

  @override
  State<WizardStepReview> createState() => _WizardStepReviewState();
}

class _WizardStepReviewState extends State<WizardStepReview> {
  bool _showAdvanced = false;
  final _expandedSections = <int>{};

  int get _totalCriteria =>
      widget.sections.fold(0, (sum, s) => sum + s.criteria.length);

  bool get _isProductionReady =>
      widget.sections.length >= 3 && _totalCriteria >= 5;

  String get _modeLabel {
    switch (widget.scoringMode) {
      case 'penalty':
        return 'Compliance Audit (Penalty)';
      case 'accumulation':
        return 'Training Assessment (Accumulation)';
      case 'checklist':
        return 'Custom Checklist';
      case 'survey':
        return 'Feedback Survey';
      default:
        return widget.scoringMode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Review & Save',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Check your template before saving. You can always edit it later.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),

        // Quality indicator
        if (_isProductionReady)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${widget.sections.length} sections, $_totalCriteria criteria — Production ready',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_outlined, color: Colors.orange.shade700, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Consider adding more — aim for 3+ sections with 5+ criteria for a thorough audit.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // Summary card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ReviewRow(
                  icon: Icons.title,
                  label: 'Title',
                  value: widget.title.isEmpty ? '(no title)' : widget.title,
                ),
                const Divider(height: 20),
                _ReviewRow(
                  icon: Icons.category_outlined,
                  label: 'Type',
                  value: widget.type.toUpperCase(),
                ),
                const Divider(height: 20),
                _ReviewRow(
                  icon: Icons.score_outlined,
                  label: 'Mode',
                  value: _modeLabel,
                ),
                const Divider(height: 20),
                _ReviewRow(
                  icon: Icons.folder_outlined,
                  label: 'Sections',
                  value: '${widget.sections.length} section(s)',
                ),
                const Divider(height: 20),
                _ReviewRow(
                  icon: Icons.checklist,
                  label: 'Criteria',
                  value: '$_totalCriteria total',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Tappable section breakdown
        if (widget.sections.isNotEmpty) ...[
          Text(
            'Sections',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...widget.sections.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            final isExpanded = _expandedSections.contains(i);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => setState(() {
                  if (isExpanded) {
                    _expandedSections.remove(i);
                  } else {
                    _expandedSections.add(i);
                  }
                }),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              s.titleCtrl.text.isEmpty ? 'Section ${i + 1}' : s.titleCtrl.text,
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            '${s.criteria.length} criteria',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                      if (isExpanded && s.criteria.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ...s.criteria.map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 4, left: 8),
                          child: Row(
                            children: [
                              Icon(Icons.circle, size: 5, color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 8),
                              Expanded(child: Text(c.labelCtrl.text, style: theme.textTheme.bodySmall)),
                            ],
                          ),
                        )),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],

        // Optional advanced settings
        OutlinedButton.icon(
          onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
          icon: Icon(_showAdvanced ? Icons.expand_less : Icons.tune),
          label: Text(
            _showAdvanced
                ? 'Hide Advanced Settings'
                : 'Advanced Settings (optional)',
          ),
        ),
        if (_showAdvanced) ...[
          const SizedBox(height: 16),
          AdvancedSettingsCard(
            scoringMode: widget.scoringMode,
            ccpOverride: widget.ccpOverride,
            riskOverride: widget.riskOverride,
            weightedDensity: widget.weightedDensity,
            confirmCorrect: widget.confirmCorrect,
            progressiveRepeat: widget.progressiveRepeat,
            deadlineCtrl: widget.deadlineCtrl,
            reminderCtrl: widget.reminderCtrl,
            onScoringModeChanged: (_) {},
            onCcpChanged: widget.onCcpChanged,
            onRiskChanged: widget.onRiskChanged,
            onDensityChanged: widget.onDensityChanged,
            onCorrectChanged: widget.onCorrectChanged,
            onProgressiveChanged: widget.onProgressiveChanged,
          ),
        ],
        const SizedBox(height: 16),
        Center(
          child: TextButton.icon(
            onPressed: null, // handled via success screen
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Continue editing in Template Builder'),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ReviewRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
