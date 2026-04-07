import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../_shared/widgets/section_header.dart';
import '../../../_shared/widgets/unsaved_changes_guard.dart';
import '../manager/template_manager.dart';
import '../models/editable_criterion.dart';
import '../models/editable_group.dart';
import '../models/validation_result.dart';
import '../widgets/ghost_add_button.dart';
import '../widgets/advanced_settings_card.dart';
import '../widgets/metadata_form_card.dart';
import '../widgets/section_editor.dart';
import '../widgets/template_footer.dart';

final _di = GetIt.instance;

/// Template Builder — create/edit template with metadata, scoring rules,
/// and section/criteria management.
class TemplateBuilderPage extends StatefulWidget {
  final String templateId;
  const TemplateBuilderPage({super.key, required this.templateId});

  @override
  State<TemplateBuilderPage> createState() => _TemplateBuilderPageState();
}

class _TemplateBuilderPageState extends State<TemplateBuilderPage> {
  late final TemplateManager _manager;
  bool get _isNew => widget.templateId.isEmpty || widget.templateId == 'new';

  bool _loading = true;
  bool _saving = false;
  bool _isDirty = false;

  // Validation state
  ValidationErrors? _validationErrors;
  final Map<String, GlobalKey> _errorKeys = {};

  // ── Form state ──
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _type = 'qc';

  // Scoring rules
  String _scoringMode = 'penalty'; // 'penalty' | 'accumulation' | 'checklist'
  bool _ccpOverride = false;
  bool _riskOverride = false;
  bool _weightedDensity = false;
  bool _confirmCorrect = false;
  bool _progressiveRepeat = false;
  final _deadlineCtrl = TextEditingController(text: '7');
  final _reminderCtrl = TextEditingController(text: '2');

  // Sections (mutable list for editing)
  List<EditableGroup> _sections = [];
  int _version = 0;

  @override
  void initState() {
    super.initState();
    _manager = _di<TemplateManager>();
    // Track text controller changes for dirty state
    _titleCtrl.addListener(_markDirty);
    _descCtrl.addListener(_markDirty);
    _deadlineCtrl.addListener(_markDirty);
    _reminderCtrl.addListener(_markDirty);
    if (!_isNew) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExistingTemplate();
      });
    } else {
      _loading = false;
      // Classic Builder: start with an empty canvas.
      // The Blueprint modal is intentionally NOT shown here — the user
      // already declared their intent by choosing "Classic Builder".
    }
  }

  void _markDirty() {
    if (!_isDirty && mounted) setState(() => _isDirty = true);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _deadlineCtrl.dispose();
    _reminderCtrl.dispose();
    super.dispose();
  }

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
        'metadata': ?metadata,
        'children': _buildGroupsRecursive(s.subSections),
        'criteria': s.criteria.asMap().entries.map((ce) {
          final ci = ce.key;
          final c = ce.value;
          return <String, dynamic>{
            if (c.id.isNotEmpty) 'id': c.id,
            'label': c.labelCtrl.text,
            if (c.descCtrl.text.isNotEmpty) 'description': c.descCtrl.text,
            'inputType': c.inputType,
            if (c.inputType != 'text' &&
                c.inputType != 'single_choice' &&
                c.inputType != 'multi_choice')
              'pointsWeight': double.tryParse(c.pointsCtrl.text),
            'isCcp': c.isCcp,
            'isRisk': c.isRisk,
            'orderIndex': ci,
            if (c.inputType == 'scale' && c.scaleOptions.isNotEmpty)
              'metadata': json.encode({'scaleOptions': c.scaleOptions}),
            if ((c.inputType == 'single_choice' ||
                    c.inputType == 'multi_choice') &&
                c.choiceOptions.isNotEmpty)
              'metadata': json.encode({'options': c.choiceOptions}),
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
    void validateGroups(List<EditableGroup> groups, String prefix) {
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
          if ((c.inputType == 'single_choice' ||
                  c.inputType == 'multi_choice') &&
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
        validateGroups(g.subSections, '$sKey:sub:');
      }
    }

    validateGroups(_sections, 'section:');

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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
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
    // Auto-scroll to the new section after frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // The new section is at the bottom of the ScrollView
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
        final mp = double.tryParse(g.maxPointsCtrl.text) ?? 0;
        pts += mp.toInt();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return UnsavedChangesGuard(
      isDirty: _isDirty,
      child: Scaffold(
        appBar: AppBar(title: Text(_isNew ? 'New Template' : 'Edit Template')),
        bottomNavigationBar: TemplateFooter(
          totalPoints: _totalPoints,
          totalDensity: _totalDensity,
          densityEnabled: _weightedDensity,
          canSave:
              _titleCtrl.text.trim().isNotEmpty &&
              _sections.isNotEmpty &&
              (!_weightedDensity || (_totalDensity - 100).abs() < 0.01),
          saving: _saving,
          onSave: _save,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Metadata Card (AC-5) ──
                  MetadataFormCard(
                    titleCtrl: _titleCtrl,
                    descCtrl: _descCtrl,
                    type: _type,
                    onTypeChanged: (v) => setState(() => _type = v ?? _type),
                  ),

                  const SizedBox(height: 16),

                  // ── Blueprint Guide Banner (onboarding) ──
                  _BlueprintGuideBanner(scoringMode: _scoringMode),

                  const SizedBox(height: 16),
                  KeyedSubtree(
                    key: _errorKeys['density'] ?? ValueKey('settings'),
                    child: AdvancedSettingsCard(
                      scoringMode: _scoringMode,
                      ccpOverride: _ccpOverride,
                      riskOverride: _riskOverride,
                      weightedDensity: _weightedDensity,
                      confirmCorrect: _confirmCorrect,
                      progressiveRepeat: _progressiveRepeat,
                      deadlineCtrl: _deadlineCtrl,
                      reminderCtrl: _reminderCtrl,
                      onScoringModeChanged: (v) =>
                          setState(() => _scoringMode = v ?? _scoringMode),
                      onCcpChanged: (v) => setState(() => _ccpOverride = v),
                      onRiskChanged: (v) => setState(() => _riskOverride = v),
                      onDensityChanged: (v) =>
                          setState(() => _weightedDensity = v),
                      onCorrectChanged: (v) =>
                          setState(() => _confirmCorrect = v),
                      onProgressiveChanged: (v) =>
                          setState(() => _progressiveRepeat = v),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Error Banner ──
                  if (_validationErrors?.hasAny == true)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: theme.colorScheme.error.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 20,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${_validationErrors!.totalCount} issue${_validationErrors!.totalCount == 1 ? '' : 's'} found. Fix before saving.',
                              style: TextStyle(
                                fontSize: theme.textTheme.bodySmall?.fontSize,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () =>
                                setState(() => _validationErrors = null),
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),

                  // ── Sections Editor (AC-7) ──
                  const SectionHeader('SECTIONS'),
                  const SizedBox(height: 8),

                  ..._sections.asMap().entries.map((e) {
                    final i = e.key;
                    final section = e.value;
                    final sKey = 'section:$i';
                    return KeyedSubtree(
                      key: _errorKeys[sKey] ?? (_errorKeys[sKey] = GlobalKey()),
                      child: SectionEditor(
                        index: i,
                        section: section,
                        depth: 0,
                        densityEnabled: _weightedDensity,
                        errors: _validationErrors,
                        errorKeyPrefix: sKey,
                        errorKeys: _errorKeys,
                        scoringMode: _scoringMode,
                        globalCcpEnabled: _ccpOverride,
                        globalRiskEnabled: _riskOverride,
                        onRemoveSection: () => _removeSection(i),
                        onAddCriterion: (inputType) =>
                            _addCriterionToGroup(section, inputType),
                        onRemoveCriterion: (ci) =>
                            _removeCriterionFromGroup(section, ci),
                        onAddSubSection: () => _addSubSection(i),
                        onRemoveSubSection: (si) => _removeSubSection(i, si),
                        onChanged: () => setState(() {}),
                      ),
                    );
                  }),

                  // "Add Section" ghost card at the bottom
                  GhostAddButton(
                    label: 'Add Section',
                    icon: Icons.add,
                    onPressed: _addSection,
                    tintColor: theme.colorScheme.outline,
                  ),

                  const SizedBox(height: 80), // Footer clearance
                ],
              ),
      ),
    );
  }
}

/// Informational banner that explains how the selected scoring mode works.
class _BlueprintGuideBanner extends StatelessWidget {
  final String scoringMode;

  const _BlueprintGuideBanner({required this.scoringMode});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (String emoji, String text) = switch (scoringMode) {
      'penalty' => (
        '💡',
        'How it works: Your audit starts with a perfect score. '
            'Each fault deducts points. Use Pass/Fail or Fault Count '
            'inputs for best results.',
      ),
      'accumulation' => (
        '💡',
        'How it works: Your audit starts at zero. '
            'Each correct answer adds points. Use Scored Choices or '
            'Scale inputs for best results.',
      ),
      'checklist' => (
        '✅',
        'How it works: Simple pass/fail compliance checks with no '
            'point scoring. The report shows compliance status for each item.',
      ),
      'survey' => (
        '📊',
        'How it works: Collect responses without scoring. '
            'Results are aggregated for analysis. Use Single Choice '
            'or Multi Choice inputs.',
      ),
      _ => ('💡', 'Select a scoring mode to see how it works.'),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
