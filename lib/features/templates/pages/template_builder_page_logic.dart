// ignore_for_file: invalid_use_of_protected_member
part of 'template_builder_page.dart';

extension _TemplateBuilderLogic on _TemplateBuilderPageState {
  Future<void> _loadExistingTemplate() async {
    await _manager.loadTemplateTree(widget.templateId);
    final tree = _manager.selectedTemplate.value;
    if (tree != null) {
      _titleCtrl.text = tree.title;
      _descCtrl.text = tree.description ?? '';
      _type = tree.type;
      _version = tree.version;
      _sections = tree.groups.map((g) => EditableGroup.fromDto(g)).toList();

      // Parse scoring config
      if (tree.scoringLogicConfig != null &&
          tree.scoringLogicConfig!.isNotEmpty) {
        try {
          final config =
              json.decode(tree.scoringLogicConfig!) as Map<String, dynamic>;
          _ccpOverride = config['ccpOverride'] == true;
          _riskOverride = config['riskOverride'] == true;
          _weightedDensity = config['weightedDensity'] == true;
          _confirmCorrect = config['confirmCorrect'] == true;
          _progressiveRepeat = config['progressiveRepeat'] == true;
          _scoringMode = (config['scoringMode'] as String?) ?? 'penalty';
          if (config['deadlineDays'] != null) {
            _deadlineCtrl.text = config['deadlineDays'].toString();
          }
          if (config['reminderDays'] != null) {
            _reminderCtrl.text = config['reminderDays'].toString();
          }
        } catch (e) {
          debugPrint('ScoringLogicConfig parse error: $e');
        }
      }
    }
    setState(() {
      _loading = false;
      _isDirty = false; // Initial load is not a user edit
    });
  }

  String _buildScoringConfig() {
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
      // Build metadata JSON for sub-section fields
      String? metadata;
      if (s.maxPointsCtrl.text.isNotEmpty ||
          s.minusPerFaultCtrl.text.isNotEmpty) {
        metadata = json.encode({
          if (s.maxPointsCtrl.text.isNotEmpty)
            'subsection_max_points': double.tryParse(s.maxPointsCtrl.text),
          if (s.minusPerFaultCtrl.text.isNotEmpty)
            'minus_per_fault': double.tryParse(s.minusPerFaultCtrl.text),
        });
      }
      return <String, dynamic>{
        if (s.id.isNotEmpty) 'id': s.id,
        'title': s.titleCtrl.text,
        if (s.descCtrl.text.isNotEmpty) 'description': s.descCtrl.text,
        if (double.tryParse(s.weightCtrl.text) != null)
          'weight': double.tryParse(s.weightCtrl.text),
        if (double.tryParse(s.maxPointsCtrl.text) != null)
          'maxDeductionPoints': double.tryParse(s.maxPointsCtrl.text),
        if (double.tryParse(s.minusPerFaultCtrl.text) != null)
          'minusPerFault': double.tryParse(s.minusPerFaultCtrl.text),
        'orderIndex': i,
        'metadata': metadata,
        'children': _buildGroupsRecursive(s.subSections),
        'criteria': s.criteria.asMap().entries.map((ce) {
          final ci = ce.key;
          final c = ce.value;

          final meta = <String, dynamic>{};
          if (c.isRequired || _confirmCorrect) meta['isRequired'] = true;
          if (c.inputType == 'scale' && c.scaleOptions.isNotEmpty) {
            meta['scaleOptions'] = c.scaleOptions;
          }
          if ((c.inputType == 'single_choice' ||
                  c.inputType == 'multi_choice') &&
              c.choiceOptions.isNotEmpty) {
            meta['options'] = c.choiceOptions;
          }

          return <String, dynamic>{
            if (c.id.isNotEmpty) 'id': c.id,
            'label': c.labelCtrl.text,
            if (c.descCtrl.text.isNotEmpty) 'description': c.descCtrl.text,
            'inputType': c.inputType,
            if (c.inputType != 'text' &&
                c.inputType != 'single_choice' &&
                c.inputType != 'multi_choice')
              'pointsWeight': double.tryParse(c.pointsCtrl.text),
            if (c.inputType != 'text' &&
                c.inputType != 'single_choice' &&
                c.inputType != 'multi_choice' &&
                c.minusImpactCtrl.text.isNotEmpty)
              'minusImpact': double.tryParse(c.minusImpactCtrl.text),
            if (c.inputType != 'text' &&
                c.inputType != 'single_choice' &&
                c.inputType != 'multi_choice' &&
                c.maxDeductionCtrl.text.isNotEmpty)
              'maxDeductionPoints': double.tryParse(c.maxDeductionCtrl.text),
            'isCcp': c.isCcp,
            'isRisk': c.isRisk,
            'orderIndex': ci,
            if (meta.isNotEmpty) 'metadata': json.encode(meta),
          };
        }).toList(),
      };
    }).toList();
  }

  List<Map<String, dynamic>> _buildGroups() => _buildGroupsRecursive(_sections);

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

  Future<void> _save() async {
    final errors = _validate();
    if (errors.hasAny) {
      setState(() => _validationErrors = errors);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollToFirstError(),
      );
      return;
    }
    setState(() {
      _validationErrors = null;
      _saving = true;
    });

    final templateId = _isNew ? null : widget.templateId;

    try {
      // Save template + groups atomically (server handles delete reconciliation)
      await _manager.saveTemplate(
        id: templateId,
        title: _titleCtrl.text.trim(),
        type: _type,
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        scoringLogicConfig: _buildScoringConfig(),
        version: _version,
        groups: _buildGroups(),
      );

      if (mounted) {
        setState(() => _isDirty = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isNew ? 'Template created!' : 'Template saved!'),
          ),
        );
        context.pop();
      }
    } on DioException catch (e) {
      if (mounted) {
        _di<ErrorDisplayService>().show(AppError.fromDioException(e));
      }
    } catch (e) {
      if (mounted) {
        _di<ErrorDisplayService>().show(
          const AppError(
            code: 'unknown',
            message:
                'We hit a snag saving this. Your progress is kept safely on your device. Please check your network connection to sync.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Section/Criteria mutation helpers ──
  void _addSection() {
    setState(() {
      _sections.add(EditableGroup());
      _isDirty = true;
    });
  }

  void _removeSection(int index) {
    setState(() {
      _sections[index].dispose();
      _sections.removeAt(index);
      _isDirty = true;
    });
  }

  void _addSubSection(int sectionIndex) {
    setState(() {
      _sections[sectionIndex].subSections.add(EditableGroup());
      _isDirty = true;
    });
  }

  void _removeSubSection(int sectionIndex, int subIndex) {
    setState(() {
      _sections[sectionIndex].subSections[subIndex].dispose();
      _sections[sectionIndex].subSections.removeAt(subIndex);
      _isDirty = true;
    });
  }

  void _addCriterionToGroup(
    EditableGroup group, [
    String inputType = 'pass_fail',
  ]) {
    setState(() {
      group.criteria.add(EditableCriterion(inputType: inputType));
      _isDirty = true;
    });
  }

  void _removeCriterionFromGroup(EditableGroup group, int criterionIndex) {
    final c = group.criteria[criterionIndex];
    setState(() {
      c.dispose();
      group.criteria.removeAt(criterionIndex);
      _isDirty = true;
    });
  }

  // ── Computed values ──
  int get _totalPoints {
    int sumMaxPoints(List<EditableGroup> groups) {
      var pts = 0;
      for (final g in groups) {
        // Sum criteria directly attached to this group
        for (final c in g.criteria) {
          if (c.inputType != 'text' &&
              c.inputType != 'single_choice' &&
              c.inputType != 'multi_choice') {
            pts += (double.tryParse(c.pointsCtrl.text) ?? 0).toInt();
          }
        }
        // Add recursive sub-sections
        pts += sumMaxPoints(g.subSections);
      }
      return pts;
    }

    return sumMaxPoints(_sections);
  }

  double get _totalDensity {
    var d = 0.0;
    for (final s in _sections) {
      d += double.tryParse(s.weightCtrl.text) ?? 0;
    }
    return d;
  }
}
