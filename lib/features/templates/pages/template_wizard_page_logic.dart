// ignore_for_file: invalid_use_of_protected_member
part of 'template_wizard_page.dart';

extension _TemplateWizardLogic on _TemplateWizardPageState {
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
          scoreDirection: _scoringMode == 'survey'
              ? 'none'
              : (_scoringMode == 'accumulation' ? 'up' : 'down'),
          isWeighted: _scoringMode == 'penalty',
          ccpOverride: _ccpOverride,
          riskOverride: _riskOverride,
          weightedDensity: _weightedDensity,
          progressiveRepeat: _progressiveRepeat,
          confirmCorrect: _confirmCorrect,
          deadlineDays: _deadlineCtrl.text,
          reminderDays: _reminderCtrl.text,
        ),
        version: 0,
        groups: buildGroupsPayload(
          groups: _sections,
          confirmCorrect: _confirmCorrect,
          isEditMode: false,
        ),
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
}
