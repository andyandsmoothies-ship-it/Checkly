import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../manager/template_manager.dart';
import '../models/editable_criterion.dart';
import '../models/editable_group.dart';
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
/// Step 2 (Structure): Add/name sections via action chips.
/// Step 3 (Build): Drill into each section and add criteria via action chips.
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

  // ── Actual editable sections ──
  final List<EditableGroup> _sections = [];

  // ── Section cursor in Step 3 ──
  int _currentSectionIndex = 0;

  // ── Success state ──
  String? _savedTemplateId;

  // ── Review validity (V6 gate from WizardStepReview) ──
  bool _templateIsValid = true;

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
      // Slate 1 fix: start blank — user adds sections themselves
    });
  }

  // ── Navigation ──

  void _nextStep() {
    if (!_validateCurrentStep()) return;

    if (_currentStep == 1) {
      // Transitioning from Structure → Build: reset section cursor
      _currentSectionIndex = 0;
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
        if (_sections.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please add at least one section.')),
          );
          return false;
        }
        for (int i = 0; i < _sections.length; i++) {
          if (_sections[i].titleCtrl.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Please name Section ${i + 1}')),
            );
            return false;
          }
        }
        return true;

      case 2: // Build Criteria
        for (int i = 0; i < _sections.length; i++) {
          final sec = _sections[i];
          final secName = sec.titleCtrl.text.isEmpty ? 'Section ${i + 1}' : '"${sec.titleCtrl.text}"';
          // BL-3: section is valid if it has criteria OR sub-sections.
          if (sec.criteria.isEmpty && sec.subSections.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$secName needs at least one criterion')),
            );
            return false;
          }
          // Validate root criteria
          final rootError = _validateCriteriaList(sec.criteria, secName);
          if (rootError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(rootError), duration: const Duration(seconds: 4)),
            );
            return false;
          }
          // BL-3: every sub-section must have >= 1 criterion
          for (int si = 0; si < sec.subSections.length; si++) {
            final sub = sec.subSections[si];
            final subName = sub.titleCtrl.text.isEmpty ? 'Sub-section ${si + 1} in $secName' : '"${sub.titleCtrl.text}"';
            if (sub.criteria.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$subName has no criteria')),
              );
              return false;
            }
            final subError = _validateCriteriaList(sub.criteria, subName);
            if (subError != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(subError), duration: const Duration(seconds: 4)),
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

  // ── Validation helpers ──

  /// Validates [criteria] labels and V6 choice-option rules.
  /// Returns the first error message or null if all pass.
  String? _validateCriteriaList(List<EditableCriterion> criteria, String parentName) {
    for (int ci = 0; ci < criteria.length; ci++) {
      final c = criteria[ci];
      if (c.labelCtrl.text.trim().isEmpty) {
        return 'Criterion ${ci + 1} in $parentName needs a label';
      }
      if ((c.inputType == 'single_choice' || c.inputType == 'multi_choice') &&
          c.choiceOptions.length < 2) {
        final label = c.labelCtrl.text.trim().isNotEmpty
            ? '"${c.labelCtrl.text.trim()}"'
            : 'Criterion ${ci + 1}';
        return '$label needs at least 2 choices. Tap it to add options.';
      }
    }
    return null;
  }

  // ── Payload builders ──

  /// Serialises [EditableCriterion] to the server's expected shape.
  /// BL-2 / Gotcha #11: excludes pointsWeight for text/choice types at ALL depths.
  Map<String, dynamic> _buildCriterion(EditableCriterion c, int ci) {
    final bool isChoiceType =
        c.inputType == 'single_choice' || c.inputType == 'multi_choice';
    final bool isScaleType = c.inputType == 'scale';
    return <String, dynamic>{
      'label': c.labelCtrl.text,
      if (c.descCtrl.text.isNotEmpty) 'description': c.descCtrl.text,
      'inputType': c.inputType,
      if (!isChoiceType && c.inputType != 'text')
        'pointsWeight': double.tryParse(c.pointsCtrl.text),
      'isCcp': c.isCcp,
      'isRisk': c.isRisk,
      'orderIndex': ci,
      if (isChoiceType && c.choiceOptions.isNotEmpty)
        'metadata': json.encode({'options': c.choiceOptions}),
      if (isScaleType && c.scaleOptions.isNotEmpty)
        'metadata': json.encode({'scaleOptions': c.scaleOptions}),
    };
  }

  /// Recursively serialises a [List<EditableGroup>] into the server's group shape.
  /// BL-1: matches `template_builder_page.dart` shape — {title, orderIndex, children, criteria}.
  List<Map<String, dynamic>> _buildGroupsRecursive(List<EditableGroup> groups) {
    return groups.asMap().entries.map((e) {
      final i = e.key;
      final s = e.value;
      // P2: Mutual-exclusivity invariant — a group must NOT contain both flat
      // criteria AND nested sub-sections. The UI enforces this; this assert
      // guards against corrupted payloads that bypass the UI guard.
      assert(
        s.criteria.isEmpty || s.subSections.isEmpty,
        'Group "${s.titleCtrl.text}" violates mutual-exclusivity: '
        'has ${s.criteria.length} criteria AND ${s.subSections.length} sub-sections.',
      );
      return <String, dynamic>{
        'title': s.titleCtrl.text,
        if (s.descCtrl.text.isNotEmpty) 'description': s.descCtrl.text,
        'orderIndex': i,
        'children': _buildGroupsRecursive(s.subSections),
        'criteria': s.criteria
            .asMap()
            .entries
            .map((ce) => _buildCriterion(ce.value, ce.key))
            .toList(),
      };
    }).toList();
  }

  List<Map<String, dynamic>> _buildGroups() => _buildGroupsRecursive(_sections);

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
      child: PopScope(
        // Intercept hardware back & swipe: steps 1–3 navigate within wizard,
        // only step 0 and step 4 (done) allow actual route pop.
        canPop: _currentStep == 0 || _currentStep == 4,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _prevStep();
        },
        child: Scaffold(
          appBar: _currentStep == 4
              ? null
              : AppBar(
                  // Custom leading: steps 1–3 call _prevStep; step 0 pops route.
                  leading: _currentStep == 0
                      ? const BackButton()
                      : BackButton(onPressed: _prevStep),
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
                sections: _sections,
                scoringMode: _scoringMode,
                onChanged: _markDirty,
              ),
              // Step 3: Build Criteria (per-section)
              WizardStepSections(
                sections: _sections,
                scoringMode: _scoringMode,
                currentSectionIndex: _currentSectionIndex,
                ccpEnabled: _ccpOverride,
                riskEnabled: _riskOverride,
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
                onValidityChanged: (isValid) {
                  if (_templateIsValid != isValid) {
                    setState(() => _templateIsValid = isValid);
                  }
                },
              ),
              // Step 5: Done
              if (_savedTemplateId != null)
                WizardStepSuccess(
                  templateId: _savedTemplateId!,
                  templateTitle: _titleCtrl.text,
                  sectionCount: _sections.length,
                  criteriaCount: _totalSavedCriteria,
                  onViewTemplate: () {
                    // Restore the Shell (list page) first, then push the detail
                    // page onto its navigator. Using go() alone skips the
                    // ShellRoute (no footer, no back button). Gotcha #1.
                    // Capture router before async gap to satisfy
                    // use_build_context_synchronously.
                    final router = GoRouter.of(context);
                    router.go('/templates');
                    Future.microtask(
                      () => router.push('/templates/$_savedTemplateId'),
                    );
                  },
                  onOpenBuilder: () {
                    final router = GoRouter.of(context);
                    router.go('/templates');
                    Future.microtask(
                      () => router.push('/templates/edit/$_savedTemplateId'),
                    );
                  },
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
                          onPressed: (_saving || (_currentStep == 3 && !_templateIsValid))
                              ? null
                              : () {
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
      ),
    );
  }
}
