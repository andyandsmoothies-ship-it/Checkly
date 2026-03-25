import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../manager/template_manager.dart';
import '../models/editable_group.dart';
import '../widgets/wizard_step_name.dart';
import '../widgets/wizard_step_sections.dart';
import '../widgets/wizard_step_review.dart';
import '../widgets/blueprint_selection_modal.dart';
import '../../../_shared/widgets/unsaved_changes_guard.dart';

final _di = GetIt.instance;

/// Template Creation Wizard — guided 3-step flow for novice admins.
///
/// Step 0: Blueprint selection (inline dialog on entry).
/// Step 1: Name + type.
/// Step 2: Sections + criteria.
/// Step 3: Review + optional advanced settings + Save.
///
/// Produces the same payload as [TemplateBuilderPage] → [TemplateManager.saveTemplate].
class TemplateWizardPage extends StatefulWidget {
  const TemplateWizardPage({super.key});

  @override
  State<TemplateWizardPage> createState() => _TemplateWizardPageState();
}

class _TemplateWizardPageState extends State<TemplateWizardPage> {
  final _pageController = PageController();
  int _currentStep = 0;
  bool _saving = false;
  bool _isDirty = false;

  // ── Form state (mirrors TemplateBuilderPage) ──
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _type = 'qc';
  String _scoringMode = 'penalty';

  // Advanced settings
  bool _ccpOverride = false;
  bool _riskOverride = false;
  bool _weightedDensity = false;
  bool _confirmCorrect = false;
  bool _progressiveRepeat = false;
  final _deadlineCtrl = TextEditingController(text: '7');
  final _reminderCtrl = TextEditingController(text: '2');

  // Sections
  final List<EditableGroup> _sections = [];

  static const _stepTitles = ['Name', 'Sections', 'Review'];

  @override
  void initState() {
    super.initState();
    _titleCtrl.addListener(_markDirty);
    _descCtrl.addListener(_markDirty);
    // Show blueprint selection as first action
    WidgetsBinding.instance.addPostFrameCallback((_) => _showBlueprintModal());
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _deadlineCtrl.dispose();
    _reminderCtrl.dispose();
    for (final s in _sections) {
      s.dispose();
    }
    super.dispose();
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  Future<void> _showBlueprintModal() async {
    final mode = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const BlueprintSelectionModal(),
    );

    if (!mounted) return;

    if (mode == null) {
      // User closed without selecting — exit wizard
      context.pop();
      return;
    }

    setState(() {
      _scoringMode = mode;
      // Default type based on blueprint
      _type = switch (mode) {
        'accumulation' => 'training',
        'survey' => 'general',
        'checklist' => 'general',
        _ => 'qc',
      };
    });
  }

  // ── Navigation ──

  void _nextStep() {
    if (!_validateCurrentStep()) return;
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _save();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Name step
        if (_titleCtrl.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a template title')),
          );
          return false;
        }
        return true;
      case 1: // Sections step
        if (_sections.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add at least one section')),
          );
          return false;
        }
        // Validate each section has a name and at least one criterion
        for (int i = 0; i < _sections.length; i++) {
          if (_sections[i].titleCtrl.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Section ${i + 1} needs a name')),
            );
            return false;
          }
          if (_sections[i].criteria.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Section ${i + 1} needs at least one criterion'),
              ),
            );
            return false;
          }
          for (int ci = 0; ci < _sections[i].criteria.length; ci++) {
            if (_sections[i].criteria[ci].labelCtrl.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Criterion ${ci + 1} in Section ${i + 1} needs a label',
                  ),
                ),
              );
              return false;
            }
          }
        }
        return true;
      default:
        return true;
    }
  }

  // ── Build payload (mirrors TemplateBuilderPage._buildGroupsRecursive) ──

  List<Map<String, dynamic>> _buildGroups() {
    return _sections.asMap().entries.map((e) {
      final i = e.key;
      final s = e.value;
      return <String, dynamic>{
        'title': s.titleCtrl.text,
        if (s.descCtrl.text.isNotEmpty) 'description': s.descCtrl.text,
        'orderIndex': i,
        'children': <dynamic>[],
        'criteria': s.criteria.asMap().entries.map((ce) {
          final ci = ce.key;
          final c = ce.value;
          return <String, dynamic>{
            'label': c.labelCtrl.text,
            if (c.descCtrl.text.isNotEmpty) 'description': c.descCtrl.text,
            'inputType': c.inputType,
            if (c.inputType != 'text' &&
                c.inputType != 'single_choice' &&
                c.inputType != 'multi_choice')
              'pointsWeight': double.tryParse(c.pointsCtrl.text),
            'isCcp': false,
            'isRisk': false,
            'orderIndex': ci,
          };
        }).toList(),
      };
    }).toList();
  }

  String _buildScoringLogicConfig() {
    return json.encode({
      'scoringMode': _scoringMode,
      'ccpOverride': _ccpOverride,
      'riskOverride': _riskOverride,
      'weightedDensity': _weightedDensity,
      'confirmCorrect': _confirmCorrect,
      'progressiveRepeat': _progressiveRepeat,
      'deadlineDays': int.tryParse(_deadlineCtrl.text) ?? 7,
      'reminderDays': int.tryParse(_reminderCtrl.text) ?? 2,
    });
  }

  Future<void> _save() async {
    if (!_validateCurrentStep()) return;

    setState(() => _saving = true);
    try {
      final manager = _di<TemplateManager>();
      await manager.saveTemplate(
        id: null,
        title: _titleCtrl.text.trim(),
        type: _type,
        description: _descCtrl.text.trim().isNotEmpty
            ? _descCtrl.text.trim()
            : null,
        scoringLogicConfig: _buildScoringLogicConfig(),
        version: 0,
        groups: _buildGroups(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template created successfully!')),
        );
        context.go('/templates');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return UnsavedChangesGuard(
      isDirty: _isDirty,
      title: 'Discard wizard?',
      message: 'Your progress will be lost. Are you sure?',
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Guided Creation', style: TextStyle(fontSize: 16)),
              Text(
                'Step ${_currentStep + 1} of 3 — ${_stepTitles[_currentStep]}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / 3,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // Step 1: Name
            WizardStepName(
              titleCtrl: _titleCtrl,
              descCtrl: _descCtrl,
              selectedType: _type,
              onTypeChanged: (t) => setState(() {
                _type = t;
                _isDirty = true;
              }),
            ),
            // Step 2: Sections
            WizardStepSections(
              sections: _sections,
              scoringMode: _scoringMode,
              onChanged: _markDirty,
            ),
            // Step 3: Review
            WizardStepReview(
              title: _titleCtrl.text,
              scoringMode: _scoringMode,
              type: _type,
              sections: _sections,
              ccpOverride: _ccpOverride,
              riskOverride: _riskOverride,
              weightedDensity: _weightedDensity,
              confirmCorrect: _confirmCorrect,
              progressiveRepeat: _progressiveRepeat,
              deadlineCtrl: _deadlineCtrl,
              reminderCtrl: _reminderCtrl,
              onCcpChanged: (v) => setState(() => _ccpOverride = v),
              onRiskChanged: (v) => setState(() => _riskOverride = v),
              onDensityChanged: (v) => setState(() => _weightedDensity = v),
              onCorrectChanged: (v) => setState(() => _confirmCorrect = v),
              onProgressiveChanged: (v) =>
                  setState(() => _progressiveRepeat = v),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Row(
              children: [
                if (_currentStep > 0)
                  OutlinedButton(
                    onPressed: _saving ? null : _prevStep,
                    child: const Text('Back'),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: _saving ? null : _nextStep,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_currentStep < 2 ? 'Next' : 'Save Template'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
