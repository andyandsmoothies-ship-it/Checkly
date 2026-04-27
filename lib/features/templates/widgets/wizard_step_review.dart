import 'package:flutter/material.dart';

import '../models/editable_criterion.dart';
import '../models/editable_group.dart';
import '../widgets/advanced_settings_card.dart';
import '../widgets/review_banners.dart';
import '../widgets/review_section_breakdown.dart';

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
  final bool progressiveRepeat;
  final bool confirmRequired;
  final TextEditingController deadlineCtrl;
  final TextEditingController reminderCtrl;
  final ValueChanged<bool> onCcpChanged;
  final ValueChanged<bool> onRiskChanged;
  final ValueChanged<bool> onDensityChanged;
  final ValueChanged<bool> onProgressiveChanged;
  final ValueChanged<bool> onConfirmChanged;

  /// Called whenever the computed validity changes so the parent can
  /// enable/disable the Save button.
  final ValueChanged<bool> onValidityChanged;

  const WizardStepReview({
    super.key,
    required this.title,
    required this.scoringMode,
    required this.type,
    required this.sections,
    required this.ccpOverride,
    required this.riskOverride,
    required this.weightedDensity,
    required this.progressiveRepeat,
    required this.confirmRequired,
    required this.deadlineCtrl,
    required this.reminderCtrl,
    required this.onCcpChanged,
    required this.onRiskChanged,
    required this.onDensityChanged,
    required this.onProgressiveChanged,
    required this.onConfirmChanged,
    required this.onValidityChanged,
  });

  @override
  State<WizardStepReview> createState() => _WizardStepReviewState();
}

class _WizardStepReviewState extends State<WizardStepReview> {
  bool _showAdvanced = false;
  final _expandedSections = <int>{};

  // Change 4: use recursive countCriteria() so sub-section criteria are included (EDD-5)
  int get _totalCriteria =>
      widget.sections.fold(0, (sum, s) => sum + s.countCriteria());

  bool get _isProductionReady =>
      widget.sections.length >= 3 && _totalCriteria >= 5;

  /// V6 blocking errors — if non-empty, the template CANNOT be saved.
  List<String> get _v6Errors {
    final errors = <String>[];
    if (widget.sections.isEmpty) {
      errors.add('Add at least one section before saving.');
      return errors;
    }
    final isSurvey = widget.scoringMode == 'survey';
    for (int si = 0; si < widget.sections.length; si++) {
      final s = widget.sections[si];
      final sName = s.titleCtrl.text.trim().isEmpty
          ? 'Section ${si + 1}'
          : '"${s.titleCtrl.text.trim()}"';
      // BL-3: section must have criteria OR sub-sections
      if (s.criteria.isEmpty && s.subSections.isEmpty) {
        errors.add('$sName has no criteria.');
        continue;
      }
      // Validate root criteria
      errors.addAll(_validateCriteriaForV6(s.criteria, sName, isSurvey));
      // BL-4: recurse into sub-sections
      for (int subI = 0; subI < s.subSections.length; subI++) {
        final sub = s.subSections[subI];
        final subName = sub.titleCtrl.text.trim().isEmpty
            ? 'Sub-section ${subI + 1} in $sName'
            : '"${sub.titleCtrl.text.trim()}"';
        if (sub.criteria.isEmpty) {
          errors.add('$subName has no criteria.');
          continue;
        }
        errors.addAll(_validateCriteriaForV6(sub.criteria, subName, isSurvey));
      }
    }
    return errors;
  }

  /// Validates choice-option counts and point values for a list of criteria.
  List<String> _validateCriteriaForV6(
    List<EditableCriterion> criteria,
    String parentName,
    bool isSurvey,
  ) {
    final errors = <String>[];
    for (int ci = 0; ci < criteria.length; ci++) {
      final c = criteria[ci];
      final cName = c.labelCtrl.text.trim().isEmpty
          ? 'Criterion ${ci + 1} in $parentName'
          : '"${c.labelCtrl.text.trim()}"';
      final isChoice =
          c.inputType == 'single_choice' || c.inputType == 'multi_choice';
      final isScored = !isSurvey && c.inputType != 'text' && !isChoice;
      if (isChoice && c.choiceOptions.length < 2) {
        errors.add('$cName needs at least 2 options.');
      }
      if (isScored && (double.tryParse(c.pointsCtrl.text) ?? 0) <= 0) {
        errors.add('$cName has 0 points — set a point value.');
      }
    }
    return errors;
  }

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
  void didUpdateWidget(WizardStepReview old) {
    super.didUpdateWidget(old);
    // Notify parent on every rebuild so Save button state stays in sync.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.onValidityChanged(_v6Errors.isEmpty),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.onValidityChanged(_v6Errors.isEmpty),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final v6Errors = _v6Errors;
    final isV6Valid = v6Errors.isEmpty;

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

        // V6 validation badge (blocking errors — red)
        if (!isV6Valid) ReviewValidationBanner(errors: v6Errors),

        // Quality indicator (non-blocking: coverage recommendation)
        ReviewQualityBanner(
          isV6Valid: isV6Valid,
          isProductionReady: _isProductionReady,
          sectionCount: widget.sections.length,
          totalCriteria: _totalCriteria,
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
        ReviewSectionBreakdown(
          sections: widget.sections,
          expandedSections: _expandedSections,
          onToggle: (i) {
            setState(() {
              if (_expandedSections.contains(i)) {
                _expandedSections.remove(i);
              } else {
                _expandedSections.add(i);
              }
            });
          },
        ),

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
            progressiveRepeat: widget.progressiveRepeat,
            confirmRequired: widget.confirmRequired,
            deadlineCtrl: widget.deadlineCtrl,
            reminderCtrl: widget.reminderCtrl,
            onCcpChanged: widget.onCcpChanged,
            onRiskChanged: widget.onRiskChanged,
            onDensityChanged: widget.onDensityChanged,
            onProgressiveChanged: widget.onProgressiveChanged,
            onConfirmChanged: widget.onConfirmChanged,
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
