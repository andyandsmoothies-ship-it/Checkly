import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../manager/template_manager.dart';
import '../models/editable_criterion.dart';
import '../models/editable_group.dart';
import '../models/wizard_starter_packs.dart';
import '../widgets/wizard_step_name.dart';
import '../widgets/wizard_step_structure.dart';
import '../widgets/wizard_step_sections.dart';
import '../widgets/wizard_step_review.dart';
import '../widgets/wizard_step_success.dart';
import '../widgets/blueprint_selection_modal.dart';
import '../../../_shared/widgets/unsaved_changes_guard.dart';

final _di = GetIt.instance;

/// Template Creation Wizard — guided 5-step flow for novice admins.
///
/// Step 0: Blueprint selection (inline dialog on entry).
/// Step 1 (Name): Title, description, category.
/// Step 2 (Structure): Toggle starter pack sections.
/// Step 3 (Build): Drill into each section and add/edit criteria.
/// Step 4 (Review): Full summary with quality indicator before saving.
/// Step 5 (Done): Animated success screen with post-save action buttons.
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

  // ── Form state ──
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

  // ── Starter sections (Step 2: toggleable structure) ──
  List<StarterSection> _starterSections = [];

  // ── Actual editable sections (Step 3: criteria builder) ──
  final List<EditableGroup> _sections = [];

  // ── Section cursor in Step 3 ──
  int _currentSectionIndex = 0;

  // ── Success state ──
  String? _savedTemplateId;

  static const _stepTitles = ['Name', 'Structure', 'Build Criteria', 'Review', 'Done'];

  @override
  void initState() {
    super.initState();
    _titleCtrl.addListener(_markDirty);
    _descCtrl.addListener(_markDirty);
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
      context.pop();
      return;
    }

    setState(() {
      _scoringMode = mode;
      _type = switch (mode) {
        'accumulation' => 'training',
        'survey' => 'general',
        'checklist' => 'general',
        _ => 'qc',
      };
      // Pre-load starter structure for this mode
      _starterSections = WizardStarterPacks.forMode(mode);
    });
  }

  // ── Starter pack → EditableGroup conversion ──

  void _applyStarterPack() {
    // Dispose old sections
    for (final s in _sections) {
      s.dispose();
    }
    _sections.clear();

    for (final starter in _starterSections.where((s) => s.enabled)) {
      final group = EditableGroup(title: starter.title);
      group.titleCtrl.text = starter.title;
      for (final sc in starter.criteria) {
        final crit = EditableCriterion(inputType: sc.inputType, points: sc.points);
        crit.labelCtrl.text = sc.label;
        group.criteria.add(crit);
      }
      _sections.add(group);
    }

    _currentSectionIndex = 0;
    _markDirty();
  }

  // ── Navigation ──

  void _nextStep() {
    if (!_validateCurrentStep()) return;

    if (_currentStep == 1) {
      // Transitioning from Structure → Build: materialise the EditableGroups
      _applyStarterPack();
    }

    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0 && _currentStep < 4) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Name
        if (_titleCtrl.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a template title')),
          );
          return false;
        }
        return true;

      case 1: // Structure
        if (_starterSections.every((s) => !s.enabled)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('At least one section must be enabled'),
            ),
          );
          return false;
        }
        return true;

      case 2: // Build Criteria
        if (_sections.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add at least one section')),
          );
          return false;
        }
        for (int i = 0; i < _sections.length; i++) {
          if (_sections[i].criteria.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '"${_sections[i].titleCtrl.text.isEmpty ? 'Section ${i + 1}' : _sections[i].titleCtrl.text}" needs at least one criterion',
                ),
              ),
            );
            return false;
          }
          for (int ci = 0; ci < _sections[i].criteria.length; ci++) {
            if (_sections[i].criteria[ci].labelCtrl.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Criterion ${ci + 1} in section ${i + 1} needs a label',
                  ),
                ),
              );
              return false;
            }
          }
        }
        return true;

      case 3: // Review — trigger save
        return true;

      default:
        return true;
    }
  }

  // ── Payload builders ──

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
    setState(() => _saving = true);
    try {
      final manager = _di<TemplateManager>();
      final templateId = await manager.saveTemplate(
        id: null,
        title: _titleCtrl.text.trim(),
        type: _type,
        description: _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
        scoringLogicConfig: _buildScoringLogicConfig(),
        version: 0,
        groups: _buildGroups(),
      );

      if (mounted) {
        setState(() {
          _saving = false;
          _savedTemplateId = templateId;
          _currentStep = 4;
        });
        _pageController.animateToPage(
          4,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
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

  int get _totalSavedCriteria =>
      _sections.fold(0, (sum, s) => sum + s.criteria.length);

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSavingOrDone = _saving || _currentStep == 4;

    return UnsavedChangesGuard(
      isDirty: _isDirty && _currentStep < 4,
      title: 'Discard wizard?',
      message: 'Your progress will be lost. Are you sure?',
      child: Scaffold(
        appBar: _currentStep == 4
            ? null
            : AppBar(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Guided Creation', style: TextStyle(fontSize: 16)),
                    Text(
                      '${_currentStep + 1} of 5 — ${_stepTitles[_currentStep]}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(4),
                  child: LinearProgressIndicator(
                    value: (_currentStep + 1) / 5,
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
              scoringMode: _scoringMode,
              onTypeChanged: (t) => setState(() {
                _type = t;
                _isDirty = true;
              }),
            ),
            // Step 2: Structure
            WizardStepStructure(
              sections: _starterSections,
              scoringMode: _scoringMode,
              onChanged: _markDirty,
            ),
            // Step 3: Build Criteria (per-section)
            WizardStepSections(
              sections: _sections,
              scoringMode: _scoringMode,
              currentSectionIndex: _currentSectionIndex,
              onChanged: _markDirty,
              onSectionChanged: (i) => setState(() => _currentSectionIndex = i),
            ),
            // Step 4: Review
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
              onProgressiveChanged: (v) => setState(() => _progressiveRepeat = v),
            ),
            // Step 5: Done
            if (_savedTemplateId != null)
              WizardStepSuccess(
                templateId: _savedTemplateId!,
                templateTitle: _titleCtrl.text,
                sectionCount: _sections.length,
                criteriaCount: _totalSavedCriteria,
                onViewTemplate: () =>
                    context.go('/templates/$_savedTemplateId'),
                onOpenBuilder: () =>
                    context.go('/templates/$_savedTemplateId/edit'),
                onDone: () => context.go('/templates'),
              )
            else
              const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: isSavingOrDone
            ? null
            : SafeArea(
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
                        onPressed: _saving ? null : () {
                          if (_currentStep == 3) {
                            _save();
                          } else {
                            _nextStep();
                          }
                        },
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(_currentStep == 3 ? 'Save Template' : 'Next'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
