// ignore_for_file: invalid_use_of_protected_member
part of 'template_builder_page.dart';

extension _TemplateBuilderValidation on _TemplateBuilderPageState {
  // ── Unified validation ──
  ValidationErrors _validate() {
    final errors = ValidationErrors();
    _errorKeys.clear();

    // Template-level checks
    if (_titleCtrl.text.trim().isEmpty) {
      errors.add('template', 'Please enter a template title');
    }
    if (_sections.isEmpty) {
      errors.add('template', 'Add at least one section');
    }

    // Section & criteria checks (recursive)
    _validateGroups(_sections, 'section:', errors);

    // V5: Ghost template guard
    if (_scoringMode != 'survey' && _sections.isNotEmpty) {
      bool hasScoringCriterion(List<EditableGroup> groups) {
        for (final g in groups) {
          for (final c in g.criteria) {
            if (c.inputType == 'pass_fail' ||
                c.inputType == 'numeric' ||
                c.inputType == 'scale') {
              return true;
            }
          }
          if (hasScoringCriterion(g.subSections)) return true;
        }
        return false;
      }

      if (!hasScoringCriterion(_sections)) {
        errors.add(
          'template',
          'Scored templates must have at least one scoring criterion',
        );
      }
    }

    // Density sum check
    if (_weightedDensity && (_totalDensity - 100).abs() > 0.01) {
      _errorKeys.putIfAbsent('density', () => GlobalKey());
      errors.add('density', 'Section weights must sum to exactly 100%');
    }

    return errors;
  }

  // ── Validation helpers ──

  /// Recursively validates [groups] and populates [errors].
  /// Extracted from [_validate] to make it independently testable.
  void _validateGroups(
    List<EditableGroup> groups,
    String prefix,
    ValidationErrors errors,
  ) {
    for (var i = 0; i < groups.length; i++) {
      final g = groups[i];
      final sKey = '$prefix$i';
      _errorKeys.putIfAbsent(sKey, () => GlobalKey());

      if (g.titleCtrl.text.trim().isEmpty) {
        errors.add(sKey, 'Section title is required');
      }
      if (g.criteria.isEmpty && g.subSections.isEmpty) {
        errors.add(sKey, 'Section must have at least one criterion');
      }

      // Density: weight > 0 (root sections only, when enabled)
      if (_weightedDensity && prefix == 'section:') {
        if ((double.tryParse(g.weightCtrl.text) ?? 0) <= 0) {
          errors.add(sKey, 'Section weight must be greater than 0%');
        }
      }

      // Criteria checks
      for (var ci = 0; ci < g.criteria.length; ci++) {
        final c = g.criteria[ci];
        final cKey = '$sKey:c:$ci';
        _errorKeys.putIfAbsent(cKey, () => GlobalKey());

        if (c.inputType == 'scale' && c.scaleOptions.length < 2) {
          errors.add(cKey, 'Scale criteria must have at least 2 options');
        }
        if ((c.inputType == 'single_choice' || c.inputType == 'multi_choice') &&
            c.choiceOptions.length < 2) {
          errors.add(cKey, 'Choice criteria must have at least 2 options');
        }
        // V6: Pointless criteria (numeric + scale only)
        if (_scoringMode != 'survey' &&
            (c.inputType == 'numeric' || c.inputType == 'scale')) {
          if ((double.tryParse(c.pointsCtrl.text) ?? 0) <= 0) {
            errors.add(cKey, 'Scoring criteria must have points > 0');
          }
        }
      }

      // Recurse into sub-sections
      _validateGroups(g.subSections, '$sKey:sub:', errors);
    }
  }

  void _scrollToFirstError() {
    final firstKey = _validationErrors?.firstKey;
    if (firstKey == null) return;
    final gk = _errorKeys[firstKey];
    if (gk?.currentContext != null) {
      Scrollable.ensureVisible(
        gk!.currentContext!,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: 0.3,
      );
    }
  }
}
