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

  int get _totalCriteria =>
      widget.sections.fold(0, (sum, s) => sum + s.criteria.length);

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
                  value: '$_totalCriteria criterion/criteria total',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

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
