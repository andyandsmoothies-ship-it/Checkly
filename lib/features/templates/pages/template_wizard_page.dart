import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../_shared/exceptions/app_error.dart';
import '../../../_shared/services/error_display_service.dart';
import '../../../_shared/services/scoring_mode.dart';
import '../manager/template_manager.dart';
import '../models/editable_group.dart';
import '../widgets/wizard_step_name.dart';
import '../widgets/wizard_step_structure.dart';
import '../widgets/wizard_step_sections.dart';
import '../widgets/wizard_step_review.dart';
import '../widgets/wizard_step_success.dart';
import '../widgets/blueprint_selection_modal.dart';
import '../../../_shared/widgets/unsaved_changes_guard.dart';
import '../widgets/wizard_navigation_bar.dart';
import 'wizard_payload_builder.dart';
import 'wizard_validators.dart';

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
  bool _progressiveRepeat = false;
  bool _confirmCorrect = false;
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

  static const _stepTitles = [
    'Name',
    'Structure',
    'Build Criteria',
    'Review',
    'Done',
  ];

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
    if (!validateWizardStep(
      context,
      _currentStep,
      title: _titleCtrl.text,
      sections: _sections,
    )) {
      return;
    }

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

  // ── Validators extracted to wizard_validators.dart ──

  // ── Payload builders extracted to wizard_payload_builder.dart ──

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final manager = _di<TemplateManager>();
      final templateId = await manager.saveTemplate(
        id: null,
        title: _titleCtrl.text.trim(),
        type: _type,
        description: _descCtrl.text.trim().isNotEmpty
            ? _descCtrl.text.trim()
            : null,
        scoringLogicConfig: buildScoringLogicConfig(
          scoringMode: _scoringMode,
          ccpOverride: _ccpOverride,
          riskOverride: _riskOverride,
          weightedDensity: _weightedDensity,
          progressiveRepeat: _progressiveRepeat,
          confirmCorrect: _confirmCorrect,
          deadlineDays: _deadlineCtrl.text,
          reminderDays: _reminderCtrl.text,
        ),
        version: 0,
        groups: buildGroups(_sections, _confirmCorrect),
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
    } on DioException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _di<ErrorDisplayService>().show(AppError.fromDioException(e));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _di<ErrorDisplayService>().show(
          const AppError(
            code: 'unknown',
            message:
                'We hit a snag saving this. Your progress is kept safely on your device. Please check your network connection to sync.',
          ),
        );
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
                      Text(
                        'Guided Creation',
                        style: theme.textTheme.titleMedium,
                      ),
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
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
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
                confirmRequired: _confirmCorrect,
                onChanged: _markDirty,
                onSectionChanged: (i) =>
                    setState(() => _currentSectionIndex = i),
              ),
              // Step 4: Review
              WizardStepReview(
                title: _titleCtrl.text,
                scoringMode: ScoringMode.values.firstWhere(
                  (e) => e.name == _scoringMode,
                  orElse: () => ScoringMode.penalty,
                ),
                type: _type,
                sections: _sections,
                ccpOverride: _ccpOverride,
                riskOverride: _riskOverride,
                weightedDensity: _weightedDensity,
                progressiveRepeat: _progressiveRepeat,
                confirmRequired: _confirmCorrect,
                deadlineCtrl: _deadlineCtrl,
                reminderCtrl: _reminderCtrl,
                onCcpChanged: (v) => setState(() => _ccpOverride = v),
                onRiskChanged: (v) => setState(() => _riskOverride = v),
                onDensityChanged: (v) => setState(() => _weightedDensity = v),
                onProgressiveChanged: (v) =>
                    setState(() => _progressiveRepeat = v),
                onConfirmChanged: (v) => setState(() => _confirmCorrect = v),
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
              : WizardNavigationBar(
                  currentStep: _currentStep,
                  isSaving: _saving,
                  templateIsValid: _templateIsValid,
                  onPrev: _prevStep,
                  onNext: _nextStep,
                  onSave: _save,
                ),
        ),
      ),
    );
  }
}
