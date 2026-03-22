import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../_shared/widgets/section_header.dart';
import '../../../_shared/widgets/unsaved_changes_guard.dart';
import '../manager/template_manager.dart';
import '../model/template_dto.dart';
import '../models/editable_criterion.dart';
import '../models/editable_group.dart';
import '../widgets/advanced_settings_card.dart';
import '../widgets/blueprint_selection_modal.dart';
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

  // Deletion tracking — IDs of removed groups/criteria to delete on save
  final List<String> _deletedGroupIds = [];
  final List<String> _deletedCriteriaIds = [];

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
      // Intent-driven wizard: show blueprint selection for new templates
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showBlueprintModal();
      });
    }
  }

  /// Show the blueprint selection modal and auto-configure on selection.
  Future<void> _showBlueprintModal() async {
    final selected = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const BlueprintSelectionModal(),
    );
    if (selected == null || !mounted) {
      if (mounted) context.pop();
      return;
    }

    setState(() {
      _scoringMode = selected;
      // Reset all feature flags to mode-appropriate defaults
      _ccpOverride = selected == 'penalty';
      _riskOverride = selected == 'penalty';
      _progressiveRepeat = false;
      _confirmCorrect = false;
      _weightedDensity = false;

      // Smart scaffolding: inject 1 section + 1 criterion
      final defaultInputType = _recommendedInputType(selected);
      final sectionTitle = switch (selected) {
        'survey' => 'General Feedback',
        'checklist' => 'Checklist Items',
        'accumulation' => 'Assessment Criteria',
        _ => 'Inspection Items',
      };
      _sections = [
        EditableGroup(
          title: sectionTitle,
          criteria: [EditableCriterion(inputType: defaultInputType)],
        ),
      ];
    });
  }

  /// Returns the recommended input type for a given blueprint mode.
  static String _recommendedInputType(String mode) {
    return switch (mode) {
      'survey' => 'single_choice',
      'checklist' => 'pass_fail',
      'accumulation' => 'scale',
      _ => 'numeric', // penalty default
    };
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

  List<GroupDto> _buildGroupsRecursive(List<EditableGroup> groups) {
    return groups.asMap().entries.map((e) {
      final i = e.key;
      final s = e.value;
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
      return GroupDto(
        id: s.id,
        title: s.titleCtrl.text,
        description: s.descCtrl.text.isEmpty ? null : s.descCtrl.text,
        weight: double.tryParse(s.weightCtrl.text),
        // Dual-write: column fields + metadata JSON for PWA backward compat
        maxDeductionPoints: double.tryParse(s.maxPointsCtrl.text),
        minusPerFault: double.tryParse(s.minusPerFaultCtrl.text),
        orderIndex: i,
        metadata: metadata,
        children: _buildGroupsRecursive(s.subSections),
        criteria: s.criteria.asMap().entries.map((ce) {
          final ci = ce.key;
          final c = ce.value;
          return CriterionDto(
            id: c.id,
            label: c.labelCtrl.text,
            description: c.descCtrl.text.isEmpty ? null : c.descCtrl.text,
            inputType: c.inputType,
            pointsWeight: double.tryParse(c.pointsCtrl.text),
            isCcp: false,
            isRisk: false,
            orderIndex: ci,
            metadata: c.inputType == 'scale' && c.scaleOptions.isNotEmpty
                ? json.encode({'scaleOptions': c.scaleOptions})
                : (c.inputType == 'single_choice' ||
                          c.inputType == 'multi_choice') &&
                      c.choiceOptions.isNotEmpty
                ? json.encode({'options': c.choiceOptions})
                : null,
          );
        }).toList(),
      );
    }).toList();
  }

  List<GroupDto> _buildGroups() => _buildGroupsRecursive(_sections);

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a template title')),
      );
      return;
    }

    // Rule 1: Must have at least one section
    if (_sections.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Add at least one section')));
      return;
    }

    // Rule 1b: All sections/sub-sections must have a title
    bool hasEmptyTitle(List<EditableGroup> groups) {
      for (final g in groups) {
        if (g.titleCtrl.text.trim().isEmpty) return true;
        if (hasEmptyTitle(g.subSections)) return true;
      }
      return false;
    }

    if (hasEmptyTitle(_sections)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All sections and sub-sections must have a title'),
        ),
      );
      return;
    }

    // Validate scale criteria have at least 2 options
    bool hasInvalidScale(List<EditableGroup> groups) {
      for (final g in groups) {
        for (final c in g.criteria) {
          if (c.inputType == 'scale' && c.scaleOptions.length < 2) return true;
        }
        if (hasInvalidScale(g.subSections)) return true;
      }
      return false;
    }

    if (hasInvalidScale(_sections)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scale criteria must have at least 2 options'),
        ),
      );
      return;
    }

    // Validate choice criteria have at least 2 options
    bool hasInvalidChoice(List<EditableGroup> groups) {
      for (final g in groups) {
        for (final c in g.criteria) {
          if ((c.inputType == 'single_choice' ||
                  c.inputType == 'multi_choice') &&
              c.choiceOptions.length < 2) {
            return true;
          }
        }
        if (hasInvalidChoice(g.subSections)) return true;
      }
      return false;
    }

    if (hasInvalidChoice(_sections)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choice criteria must have at least 2 options'),
        ),
      );
      return;
    }

    // V4: Every section must have at least one criterion
    bool hasEmptySection(List<EditableGroup> groups) {
      for (final g in groups) {
        if (g.criteria.isEmpty && g.subSections.isEmpty) return true;
        if (hasEmptySection(g.subSections)) return true;
      }
      return false;
    }

    if (hasEmptySection(_sections)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Every section must have at least one criterion'),
        ),
      );
      return;
    }

    // Rules 2 & 3: Density validation (only when weighted density enabled)
    if (_weightedDensity) {
      if (_sections.any(
        (s) => (double.tryParse(s.weightCtrl.text) ?? 0) <= 0,
      )) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All sections must have a weight greater than 0%'),
          ),
        );
        return;
      }
      if ((_totalDensity - 100).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Section weights must sum to exactly 100%'),
          ),
        );
        return;
      }
    }

    setState(() => _saving = true);
    try {
      // 1. Process deletions first (criteria before groups)
      final templateId = _isNew ? null : widget.templateId;
      if (templateId != null) {
        for (final cId in _deletedCriteriaIds) {
          try {
            await _manager.deleteCriterion(templateId, cId);
          } catch (e) {
            debugPrint('Delete criterion $cId: $e');
          } // Ignore already-deleted
        }
        for (final gId in _deletedGroupIds) {
          try {
            await _manager.deleteGroup(templateId, gId);
          } catch (e) {
            debugPrint('Delete group $gId: $e');
          } // Ignore already-deleted
        }
      }
      _deletedCriteriaIds.clear();
      _deletedGroupIds.clear();

      // 2. Save template + groups
      await _manager.saveTemplate(
        id: templateId,
        title: _titleCtrl.text.trim(),
        type: _type,
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        scoringLogicConfig: _buildScoringConfig(),
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
    _collectDeletionIds(_sections[index]);
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
    _collectDeletionIds(_sections[sectionIndex].subSections[subIndex]);
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
    if (c.id.isNotEmpty) _deletedCriteriaIds.add(c.id);
    setState(() {
      c.dispose();
      group.criteria.removeAt(criterionIndex);
      _isDirty = true;
    });
  }

  /// Recursively collect IDs of a group and all its children/criteria for deletion.
  void _collectDeletionIds(EditableGroup group) {
    if (group.id.isNotEmpty) _deletedGroupIds.add(group.id);
    for (final c in group.criteria) {
      if (c.id.isNotEmpty) _deletedCriteriaIds.add(c.id);
    }
    for (final sub in group.subSections) {
      _collectDeletionIds(sub);
    }
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
                  AdvancedSettingsCard(
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

                  const SizedBox(height: 16),

                  // ── Sections Editor (AC-7) ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SectionHeader('SECTIONS'),
                      TextButton.icon(
                        onPressed: _addSection,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Section'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_sections.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No sections yet. Tap "Add Section" to start building.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._sections.asMap().entries.map((e) {
                      final i = e.key;
                      final section = e.value;
                      return SectionEditor(
                        index: i,
                        section: section,
                        depth: 0,

                        densityEnabled: _weightedDensity,
                        onRemoveSection: () => _removeSection(i),
                        onAddCriterion: (inputType) =>
                            _addCriterionToGroup(section, inputType),
                        onRemoveCriterion: (ci) =>
                            _removeCriterionFromGroup(section, ci),
                        onAddSubSection: () => _addSubSection(i),
                        onRemoveSubSection: (si) => _removeSubSection(i, si),
                        onChanged: () => setState(() {}),
                      );
                    }),

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
