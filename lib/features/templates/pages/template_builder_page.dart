import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../_shared/theme/app_theme.dart';
import '../../../_shared/theme/app_fonts.dart';
import '../../../_shared/widgets/section_header.dart';
import '../manager/template_manager.dart';
import '../model/template_dto.dart';

final _di = GetIt.instance;

/// Template types matching PWA constants.
const _templateTypes = ['qc', 'training', 'general'];

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
  List<_EditableGroup> _sections = [];

  // Deletion tracking — IDs of removed groups/criteria to delete on save
  final List<String> _deletedGroupIds = [];
  final List<String> _deletedCriteriaIds = [];

  @override
  void initState() {
    super.initState();
    _manager = _di<TemplateManager>();
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
      builder: (_) => const _BlueprintSelectionModal(),
    );
    if (selected == null || !mounted) return;

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
        _EditableGroup(
          title: sectionTitle,
          criteria: [_EditableCriterion(inputType: defaultInputType)],
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
      _sections = tree.groups.map((g) => _EditableGroup.fromDto(g)).toList();

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
    setState(() => _loading = false);
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

  List<GroupDto> _buildGroupsRecursive(List<_EditableGroup> groups) {
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
    bool hasEmptyTitle(List<_EditableGroup> groups) {
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
    bool hasInvalidScale(List<_EditableGroup> groups) {
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
    bool hasInvalidChoice(List<_EditableGroup> groups) {
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
    bool hasEmptySection(List<_EditableGroup> groups) {
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
      _sections.add(_EditableGroup());
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
    });
  }

  void _addSubSection(int sectionIndex) {
    setState(() {
      _sections[sectionIndex].subSections.add(_EditableGroup());
    });
  }

  void _removeSubSection(int sectionIndex, int subIndex) {
    _collectDeletionIds(_sections[sectionIndex].subSections[subIndex]);
    setState(() {
      _sections[sectionIndex].subSections[subIndex].dispose();
      _sections[sectionIndex].subSections.removeAt(subIndex);
    });
  }

  void _addCriterionToGroup(_EditableGroup group) {
    setState(() {
      group.criteria.add(_EditableCriterion());
    });
  }

  void _removeCriterionFromGroup(_EditableGroup group, int criterionIndex) {
    final c = group.criteria[criterionIndex];
    if (c.id.isNotEmpty) _deletedCriteriaIds.add(c.id);
    setState(() {
      c.dispose();
      group.criteria.removeAt(criterionIndex);
    });
  }

  /// Recursively collect IDs of a group and all its children/criteria for deletion.
  void _collectDeletionIds(_EditableGroup group) {
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
    int sumMaxPoints(List<_EditableGroup> groups) {
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

    return Scaffold(
      appBar: AppBar(title: Text(_isNew ? 'New Template' : 'Edit Template')),
      bottomNavigationBar: _TemplateFooter(
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
                _MetadataFormCard(
                  titleCtrl: _titleCtrl,
                  descCtrl: _descCtrl,
                  type: _type,
                  onTypeChanged: (v) => setState(() => _type = v ?? _type),
                ),

                const SizedBox(height: 16),

                // ── Advanced Settings Card (AC-6) ──
                _AdvancedSettingsCard(
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
                  onDensityChanged: (v) => setState(() => _weightedDensity = v),
                  onCorrectChanged: (v) => setState(() => _confirmCorrect = v),
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
                    return _SectionEditor(
                      index: i,
                      section: section,
                      depth: 0,

                      densityEnabled: _weightedDensity,
                      onRemoveSection: () => _removeSection(i),
                      onAddCriterion: () => _addCriterionToGroup(section),
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
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EDITABLE DATA CLASSES
// ═══════════════════════════════════════════════════════════════

class _EditableGroup {
  final String id;
  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final TextEditingController weightCtrl;
  final TextEditingController maxPointsCtrl;
  final TextEditingController minusPerFaultCtrl;
  List<_EditableCriterion> criteria;
  List<_EditableGroup> subSections;

  _EditableGroup({
    this.id = '',
    String title = '',
    String description = '',
    String weight = '',
    String maxPoints = '',
    String minusPerFault = '',
    List<_EditableCriterion>? criteria,
    List<_EditableGroup>? subSections,
  }) : titleCtrl = TextEditingController(text: title),
       descCtrl = TextEditingController(text: description),
       weightCtrl = TextEditingController(text: weight),
       maxPointsCtrl = TextEditingController(text: maxPoints),
       minusPerFaultCtrl = TextEditingController(text: minusPerFault),
       criteria = criteria ?? [],
       subSections = subSections ?? [];

  factory _EditableGroup.fromDto(GroupDto dto) {
    // Parse metadata for sub-section fields
    String maxPts = '';
    String minusPf = '';
    if (dto.metadata != null && dto.metadata!.isNotEmpty) {
      try {
        final meta = json.decode(dto.metadata!) as Map<String, dynamic>;
        if (meta['subsection_max_points'] != null) {
          maxPts = meta['subsection_max_points'].toString();
        }
        if (meta['minus_per_fault'] != null) {
          minusPf = meta['minus_per_fault'].toString();
        }
      } catch (e) {
        debugPrint('Group metadata parse: $e');
      }
    }
    return _EditableGroup(
      id: dto.id,
      title: dto.title,
      description: dto.description ?? '',
      weight: dto.weight?.toString() ?? '',
      maxPoints: maxPts,
      minusPerFault: minusPf,
      criteria: dto.criteria.map((c) => _EditableCriterion.fromDto(c)).toList(),
      subSections: dto.children.map((g) => _EditableGroup.fromDto(g)).toList(),
    );
  }

  /// Recursive count of sub-sections.
  int countSubs() {
    var count = subSections.length;
    for (final s in subSections) {
      count += s.countSubs();
    }
    return count;
  }

  /// Recursive count of criteria.
  int countCriteria() {
    var count = criteria.length;
    for (final s in subSections) {
      count += s.countCriteria();
    }
    return count;
  }

  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    weightCtrl.dispose();
    maxPointsCtrl.dispose();
    minusPerFaultCtrl.dispose();
    for (final c in criteria) {
      c.dispose();
    }
    for (final s in subSections) {
      s.dispose();
    }
  }
}

class _EditableCriterion {
  final String id;
  final TextEditingController labelCtrl;
  final TextEditingController descCtrl;
  final TextEditingController pointsCtrl;
  String inputType;
  List<Map<String, dynamic>> scaleOptions;
  List<String> choiceOptions;

  _EditableCriterion({
    this.id = '',
    String label = '',
    String description = '',
    String points = '',
    this.inputType = 'numeric',
    List<Map<String, dynamic>>? scaleOptions,
    List<String>? choiceOptions,
  }) : labelCtrl = TextEditingController(text: label),
       descCtrl = TextEditingController(text: description),
       pointsCtrl = TextEditingController(text: points),
       scaleOptions = scaleOptions ?? [],
       choiceOptions = choiceOptions ?? [];

  factory _EditableCriterion.fromDto(CriterionDto dto) {
    List<Map<String, dynamic>> options = [];
    List<String> choices = [];
    if (dto.metadata != null && dto.inputType == 'scale') {
      try {
        final meta = json.decode(dto.metadata!) as Map<String, dynamic>;
        options =
            (meta['scaleOptions'] as List?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [];
      } catch (e) {
        debugPrint('Criterion metadata parse: $e');
      }
    } else if (dto.metadata != null &&
        (dto.inputType == 'single_choice' || dto.inputType == 'multi_choice')) {
      try {
        final meta = json.decode(dto.metadata!) as Map<String, dynamic>;
        choices = (meta['options'] as List?)?.cast<String>() ?? [];
      } catch (e) {
        debugPrint('Criterion metadata parse: $e');
      }
    }
    return _EditableCriterion(
      id: dto.id,
      label: dto.label,
      description: dto.description ?? '',
      points: dto.pointsWeight?.toString() ?? '',
      inputType: dto.inputType,
      scaleOptions: options,
      choiceOptions: choices,
    );
  }

  void dispose() {
    labelCtrl.dispose();
    descCtrl.dispose();
    pointsCtrl.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════
// AC-5: METADATA FORM CARD
// ═══════════════════════════════════════════════════════════════

class _MetadataFormCard extends StatelessWidget {
  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final String type;
  final ValueChanged<String?> onTypeChanged;

  const _MetadataFormCard({
    required this.titleCtrl,
    required this.descCtrl,
    required this.type,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader('TEMPLATE METADATA'),
            const SizedBox(height: 12),
            TextFormField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Template Title',
                hintText: 'e.g. Weekly Food Safety Check',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe what this template audits',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _templateTypes.contains(type) ? type : 'qc',
              decoration: const InputDecoration(labelText: 'Template Type'),
              borderRadius: BorderRadius.circular(12),
              items: _templateTypes
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(t.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: onTypeChanged,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// AC-6: ADVANCED SETTINGS CARD (Progressive Disclosure)
// ═══════════════════════════════════════════════════════════════

class _AdvancedSettingsCard extends StatelessWidget {
  final String scoringMode;
  final bool ccpOverride;
  final bool riskOverride;
  final bool weightedDensity;
  final bool confirmCorrect;
  final bool progressiveRepeat;
  final TextEditingController deadlineCtrl;
  final TextEditingController reminderCtrl;
  final ValueChanged<String?> onScoringModeChanged;
  final ValueChanged<bool> onCcpChanged;
  final ValueChanged<bool> onRiskChanged;
  final ValueChanged<bool> onDensityChanged;
  final ValueChanged<bool> onCorrectChanged;
  final ValueChanged<bool> onProgressiveChanged;

  const _AdvancedSettingsCard({
    required this.scoringMode,
    required this.ccpOverride,
    required this.riskOverride,
    required this.weightedDensity,
    required this.confirmCorrect,
    required this.progressiveRepeat,
    required this.deadlineCtrl,
    required this.reminderCtrl,
    required this.onScoringModeChanged,
    required this.onCcpChanged,
    required this.onRiskChanged,
    required this.onDensityChanged,
    required this.onCorrectChanged,
    required this.onProgressiveChanged,
  });

  bool get _isSurvey => scoringMode == 'survey';
  bool get _isChecklist => scoringMode == 'checklist';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          initiallyExpanded: false,
          leading: Icon(
            Icons.settings,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          title: Text(
            'Advanced Settings',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            // ── GROUP 1: SCORING MODE + SCHEDULING ──
            DropdownButtonFormField<String>(
              initialValue: scoringMode,
              decoration: const InputDecoration(
                labelText: 'Scoring Mode',
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'penalty',
                  child: Text('Penalty (Top-Down)'),
                ),
                DropdownMenuItem(
                  value: 'accumulation',
                  child: Text('Accumulation (Zero-to-Top)'),
                ),
                DropdownMenuItem(
                  value: 'checklist',
                  child: Text('Checklist (Pass/Fail)'),
                ),
                DropdownMenuItem(
                  value: 'survey',
                  child: Text('Survey (No Scoring)'),
                ),
              ],
              onChanged: onScoringModeChanged,
            ),
            const SizedBox(height: 16),

            // Action Plan Deadline
            Row(
              children: [
                const Expanded(flex: 3, child: Text('Action Plan Deadline')),
                SizedBox(
                  width: 60,
                  child: TextFormField(
                    controller: deadlineCtrl,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onEditingComplete: () {
                      final v = int.tryParse(deadlineCtrl.text) ?? 7;
                      deadlineCtrl.text = v.clamp(1, 90).toString();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                const Text('days'),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              child: Text(
                'Number of days to resolve each action plan (1–90).',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),

            // Deadline Reminder
            Row(
              children: [
                const Expanded(flex: 3, child: Text('Deadline\nReminder')),
                const Text('before  '),
                SizedBox(
                  width: 60,
                  child: TextFormField(
                    controller: reminderCtrl,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onEditingComplete: () {
                      final v = int.tryParse(reminderCtrl.text) ?? 2;
                      reminderCtrl.text = v.clamp(1, 30).toString();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                const Text('days'),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Reminder days before deadline (1–30).',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),

            // ── GROUP 2: SCORING TOGGLES (mode-aware) ──
            if (!_isSurvey) ...[
              const Divider(height: 24),

              // Amber warning banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Colors.amber.shade800,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'These settings affect how audits are scored. Change with care.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Weighted Density — hidden for Checklist
              if (!_isChecklist)
                _ExpandableSettingTile(
                  title: 'Weighted Density',
                  description:
                      'Each section contributes to the total based on its '
                      'assigned weight (must sum to 100%).',
                  value: weightedDensity,
                  onChanged: onDensityChanged,
                ),

              _ExpandableSettingTile(
                title: 'CCP Override',
                description:
                    'Any criteria marked CCP that fails will zero out '
                    'its entire section.',
                value: ccpOverride,
                onChanged: onCcpChanged,
              ),
              _ExpandableSettingTile(
                title: 'RISK Override',
                description:
                    'Any criteria marked RISK that fails will zero out '
                    'the entire audit.',
                value: riskOverride,
                onChanged: onRiskChanged,
              ),

              // Progressive Repeat — hidden for Checklist/Accumulation
              if (!_isChecklist && scoringMode != 'accumulation')
                _ExpandableSettingTile(
                  title: 'Progressive Repeat Penalty',
                  description:
                      'OFF: deduction = repeats × rate. '
                      'ON: deduction = repeats² × rate (harsher for more repeats).',
                  value: progressiveRepeat,
                  onChanged: onProgressiveChanged,
                ),

              _ExpandableSettingTile(
                title: 'Confirm Correct',
                description:
                    'Auditor must tap "Correct" to confirm each passing '
                    'criteria before submitting.',
                value: confirmCorrect,
                onChanged: onCorrectChanged,
              ),
            ],

            // Survey mode info banner
            if (_isSurvey)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Survey mode — responses are collected without scoring.',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// AC-7: SECTION EDITOR — recursive, supports sub-sections (Gap 1)
// ═══════════════════════════════════════════════════════════════

class _SectionEditor extends StatelessWidget {
  final int index;
  final _EditableGroup section;
  final int depth;

  final bool densityEnabled;
  final VoidCallback onRemoveSection;
  final VoidCallback onAddCriterion;
  final ValueChanged<int> onRemoveCriterion;
  final VoidCallback? onAddSubSection;
  final ValueChanged<int>? onRemoveSubSection;
  final VoidCallback onChanged;

  const _SectionEditor({
    required this.index,
    required this.section,
    this.depth = 0,

    this.densityEnabled = true,
    required this.onRemoveSection,
    required this.onAddCriterion,
    required this.onRemoveCriterion,
    this.onAddSubSection,
    this.onRemoveSubSection,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRoot = depth == 0;

    // Gap 6: count badge
    final subCount = section.countSubs();
    final critCount = section.countCriteria();

    return Card(
      margin: EdgeInsets.only(
        bottom: 12,
        left: isRoot ? 0 : 16, // Gap 1: indent sub-sections
      ),
      shape: isRoot
          ? null
          : RoundedRectangleBorder(
              side: BorderSide(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          title: Row(
            children: [
              // Gap 9: Inline editable title in header
              Expanded(
                child: TextField(
                  controller: section.titleCtrl,
                  decoration: InputDecoration(
                    hintText: isRoot
                        ? 'Section ${index + 1}'
                        : 'Sub-section ${index + 1}',
                    hintStyle: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.38,
                      ),
                      fontStyle: FontStyle.italic,
                    ),
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
              // Gap 6: count badge (XS • YC) — root sections only
              if (isRoot)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.sageGray.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${subCount}S • ${critCount}C',
                    style: AppFonts.serifStyle(
                      fontSize: 10,
                      color: AppTheme.charcoal.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              // Inline editable weight input in header (PWA parity)
              if (densityEnabled && isRoot)
                Container(
                  width: 64,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: section.weightCtrl,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: AppFonts.serifStyle(
                            fontSize: 12,
                            color: theme.colorScheme.primary,
                          ),
                          decoration: const InputDecoration(
                            hintText: '0',
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onTap: () =>
                              section.weightCtrl.selection = TextSelection(
                                baseOffset: 0,
                                extentOffset: section.weightCtrl.text.length,
                              ),
                          onChanged: (_) => onChanged(),
                        ),
                      ),
                      Text(
                        '%',
                        style: AppFonts.serifStyle(
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: onRemoveSection,
          ),
          children: [
            // Sub-section metadata (non-root sections always show Max Points)
            if (!isRoot) ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: section.maxPointsCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Max Points',
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => onChanged(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: section.minusPerFaultCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Minus / Fault',
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => onChanged(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Criteria list
            ...section.criteria.asMap().entries.map((e) {
              final ci = e.key;
              final c = e.value;
              return _CriteriaEditor(
                criterion: c,

                onRemove: () => onRemoveCriterion(ci),
                onChanged: onChanged,
              );
            }),

            // Add Criteria — hidden if root already has sub-sections
            if (isRoot && section.subSections.isEmpty || !isRoot)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onAddCriterion,
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Add Criteria'),
                  style: TextButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ),

            // Gap 1: Sub-sections
            if (isRoot) ...[
              const Divider(),
              ...section.subSections.asMap().entries.map((e) {
                final si = e.key;
                final sub = e.value;
                return _SectionEditor(
                  index: si,
                  section: sub,
                  depth: depth + 1,

                  densityEnabled: densityEnabled,

                  onRemoveSection: () => onRemoveSubSection?.call(si),
                  onAddCriterion: () {
                    sub.criteria.add(_EditableCriterion());
                    onChanged();
                  },
                  onRemoveCriterion: (ci) {
                    sub.criteria[ci].dispose();
                    sub.criteria.removeAt(ci);
                    onChanged();
                  },
                  onChanged: onChanged,
                );
              }),
              if (section.criteria.isEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: onAddSubSection,
                    icon: const Icon(Icons.subdirectory_arrow_right, size: 14),
                    label: const Text('Add Sub-Section'),
                    style: TextButton.styleFrom(
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CRITERIA EDITOR — tap to open bottom sheet (Gap 5)
// ═══════════════════════════════════════════════════════════════

class _CriteriaEditor extends StatelessWidget {
  final _EditableCriterion criterion;

  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _CriteriaEditor({
    required this.criterion,

    required this.onRemove,
    required this.onChanged,
  });

  void _openDrawer(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Criterion',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Label
                TextFormField(
                  controller: criterion.labelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Criterion Label',
                    isDense: true,
                  ),
                  onChanged: (_) => onChanged(),
                ),
                const SizedBox(height: 16),

                // Gap 3: Description
                TextFormField(
                  controller: criterion.descCtrl,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    isDense: true,
                  ),
                  maxLines: 3,
                  onChanged: (_) => onChanged(),
                ),
                const SizedBox(height: 16),

                // Input Type selector — tap chip to open bottom sheet
                Text(
                  'Input Type',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                ActionChip(
                  avatar: Icon(_inputTypeIcon(criterion.inputType), size: 18),
                  label: Text(_inputTypeLabel(criterion.inputType)),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final selected = await showModalBottomSheet<String>(
                      context: context,
                      isScrollControlled: true,
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.65,
                      ),
                      builder: (_) => _InputTypeBottomSheet(
                        currentType: criterion.inputType,
                      ),
                    );
                    if (selected != null && context.mounted) {
                      criterion.inputType = selected;
                      onChanged();
                      _openDrawer(context);
                    }
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  'Determines how the auditor will grade this item',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 16),

                // Scale Options editor (only for scale type)
                if (criterion.inputType == 'scale') ...[
                  const Text(
                    'Scale Options',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Define maturity levels and their respective points (e.g. 1=Poor, 5=Excellent)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...criterion.scaleOptions.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final opt = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              initialValue: opt['label'] as String? ?? '',
                              decoration: InputDecoration(
                                labelText: 'Label ${idx + 1}',
                                isDense: true,
                              ),
                              onChanged: (v) {
                                criterion.scaleOptions[idx]['label'] = v;
                                onChanged();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              initialValue:
                                  (opt['points'] as num?)?.toString() ?? '0',
                              decoration: const InputDecoration(
                                labelText: 'Pts',
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (v) {
                                criterion.scaleOptions[idx]['points'] =
                                    double.tryParse(v) ?? 0;
                                // Auto-sync pointsWeight to highest
                                final maxPts = criterion.scaleOptions
                                    .fold<double>(
                                      0,
                                      (m, o) =>
                                          (o['points'] as num? ?? 0)
                                                  .toDouble() >
                                              m
                                          ? (o['points'] as num).toDouble()
                                          : m,
                                    );
                                criterion.pointsCtrl.text = maxPts
                                    .toStringAsFixed(0);
                                onChanged();
                              },
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.remove_circle_outline,
                              size: 18,
                              color: Colors.red.shade400,
                            ),
                            onPressed: () {
                              criterion.scaleOptions.removeAt(idx);
                              onChanged();
                              Navigator.pop(ctx);
                              Future.microtask(() {
                                if (context.mounted) _openDrawer(context);
                              });
                            },
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: () {
                      criterion.scaleOptions.add({'label': '', 'points': 0});
                      onChanged();
                      Navigator.pop(ctx);
                      Future.microtask(() {
                        if (context.mounted) _openDrawer(context);
                      });
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Option'),
                  ),
                  const SizedBox(height: 8),
                ],

                // Choice Options editor (for single_choice / multi_choice)
                if (criterion.inputType == 'single_choice' ||
                    criterion.inputType == 'multi_choice') ...[
                  const Text(
                    'Choice Options',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'List the specific options the auditor can select from',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...criterion.choiceOptions.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final label = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: label,
                              decoration: InputDecoration(
                                labelText: 'Option ${idx + 1}',
                                isDense: true,
                              ),
                              onChanged: (v) {
                                criterion.choiceOptions[idx] = v;
                                onChanged();
                              },
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.remove_circle_outline,
                              size: 18,
                              color: Colors.red.shade400,
                            ),
                            onPressed: () {
                              criterion.choiceOptions.removeAt(idx);
                              onChanged();
                              Navigator.pop(ctx);
                              Future.microtask(() {
                                if (context.mounted) _openDrawer(context);
                              });
                            },
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: () {
                      criterion.choiceOptions.add('');
                      onChanged();
                      Navigator.pop(ctx);
                      Future.microtask(() {
                        if (context.mounted) _openDrawer(context);
                      });
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Option'),
                  ),
                  const SizedBox(height: 8),
                ],

                // Points weight:
                //  - pass_fail / numeric: editable text field
                //  - scale: read-only (auto-synced from highest option value)
                //  - single_choice / multi_choice: HIDDEN (survey-only, no scoring)
                if (criterion.inputType == 'single_choice' ||
                    criterion.inputType == 'multi_choice')
                  const SizedBox.shrink() // No points weight for survey inputs
                else if (criterion.inputType == 'scale')
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Points Weight'),
                    trailing: Text(
                      criterion.pointsCtrl.text.isEmpty
                          ? '0'
                          : criterion.pointsCtrl.text,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: const Text('Auto-set from highest scale option'),
                  )
                else
                  TextFormField(
                    controller: criterion.pointsCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Points Weight',
                      helperText: 'Max score to award or multiplier for faults',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => onChanged(),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _openDrawer(context),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.drag_indicator, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  criterion.labelCtrl.text.isEmpty
                      ? 'Untitled criterion'
                      : criterion.labelCtrl.text,
                  style: TextStyle(
                    fontSize: 13,
                    color: criterion.labelCtrl.text.isEmpty
                        ? theme.colorScheme.onSurfaceVariant
                        : null,
                    fontStyle: criterion.labelCtrl.text.isEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ),
              // Points/CCP/RISK badges (always visible)
              if (criterion.pointsCtrl.text.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  '${criterion.pointsCtrl.text}pt',
                  style: AppFonts.serifStyle(
                    fontSize: 11,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
              // Input type badge
              if (criterion.inputType == 'scale') ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'LOW → HIGH',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
                ),
              ],
              if (criterion.inputType == 'pass_fail') ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'YES · NO',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
              if (criterion.inputType == 'numeric') ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '0 · 1 · 2',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
              if (criterion.inputType == 'single_choice') ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '1 OF N',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.purple.shade700,
                    ),
                  ),
                ),
              ],
              if (criterion.inputType == 'multi_choice') ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'N OF N',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.purple.shade700,
                    ),
                  ),
                ),
              ],

              // Inline delete — PWA parity
              IconButton(
                onPressed: onRemove,
                icon: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.red.shade400,
                ),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
              const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// AC-8: FIXED FOOTER
// ═══════════════════════════════════════════════════════════════

class _TemplateFooter extends StatelessWidget {
  final int totalPoints;
  final double totalDensity;
  final bool densityEnabled;
  final bool canSave;
  final bool saving;
  final VoidCallback onSave;

  const _TemplateFooter({
    required this.totalPoints,
    required this.totalDensity,
    required this.densityEnabled,
    required this.canSave,
    required this.saving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: AppTheme.sageGray.withValues(alpha: 0.3)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // PTS badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.oatmeal,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$totalPoints PTS',
                style: AppFonts.serifStyle(
                  fontSize: 14,
                  color: AppTheme.charcoal,
                ),
              ),
            ),
            // Density badge — only shown when density enabled (Rule 6)
            if (densityEnabled) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: (totalDensity - 100).abs() < 0.01
                      ? AppTheme.success.withValues(alpha: 0.15)
                      : AppTheme.softPeach,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${totalDensity.toStringAsFixed(1)}%',
                  style: AppFonts.serifStyle(
                    fontSize: 14,
                    color: (totalDensity - 100).abs() < 0.01
                        ? AppTheme.success
                        : AppTheme.charcoal,
                  ),
                ),
              ),
            ],
            const Spacer(),
            // Save button — disabled when canSave is false (Rule 1)
            FilledButton.icon(
              onPressed: (saving || !canSave) ? null : onSave,
              icon: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(saving ? 'Saving...' : 'Save Template'),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BLUEPRINT SELECTION MODAL (Intent-Driven Wizard)
// ═══════════════════════════════════════════════════════════════

class _BlueprintSelectionModal extends StatelessWidget {
  const _BlueprintSelectionModal();

  static const _blueprints = [
    (
      mode: 'penalty',
      icon: Icons.verified_outlined,
      title: 'Compliance Audit',
      subtitle: 'Start at 100% — deduct for faults found',
      color: Color(0xFF1565C0),
    ),
    (
      mode: 'accumulation',
      icon: Icons.trending_up,
      title: 'Training Assessment',
      subtitle: 'Start at 0% — earn points for correct answers',
      color: Color(0xFF2E7D32),
    ),
    (
      mode: 'survey',
      icon: Icons.forum_outlined,
      title: 'Feedback Survey',
      subtitle: 'Collect responses without scoring',
      color: Color(0xFF7B1FA2),
    ),
    (
      mode: 'checklist',
      icon: Icons.checklist,
      title: 'Custom Checklist',
      subtitle: 'Simple pass/fail checks for daily tasks',
      color: Color(0xFFE65100),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('What are you building?'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose a blueprint to get started with sensible defaults.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: size.width > 600 ? 2 : 1,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: size.width > 600 ? 2.2 : 3.2,
                    children: _blueprints.map((bp) {
                      return _BlueprintCard(
                        icon: bp.icon,
                        title: bp.title,
                        subtitle: bp.subtitle,
                        color: bp.color,
                        onTap: () => Navigator.pop(context, bp.mode),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BlueprintCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _BlueprintCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// INPUT TYPE BOTTOM SHEET (Guided Input Selector)
// ═══════════════════════════════════════════════════════════════

/// Lookup helpers for input type display.
IconData _inputTypeIcon(String type) => switch (type) {
  'pass_fail' => Icons.check_circle_outline,
  'numeric' => Icons.pin_outlined,
  'scale' => Icons.linear_scale,
  'single_choice' => Icons.radio_button_checked,
  'multi_choice' => Icons.checklist,
  _ => Icons.help_outline,
};

String _inputTypeLabel(String type) => switch (type) {
  'pass_fail' => 'Pass / Fail',
  'numeric' => 'Fault Count',
  'scale' => 'Scored Choices',
  'single_choice' => 'Single Choice',
  'multi_choice' => 'Multi Choice',
  _ => type,
};

class _InputTypeBottomSheet extends StatelessWidget {
  final String currentType;

  const _InputTypeBottomSheet({required this.currentType});

  static const _types = [
    (
      value: 'pass_fail',
      icon: Icons.check_circle_outline,
      title: 'Pass / Fail',
      desc: 'Binary check — e.g., "Is the floor clean?"',
    ),
    (
      value: 'numeric',
      icon: Icons.pin_outlined,
      title: 'Fault Count',
      desc: 'Count occurrences — e.g., "How many expired items?"',
    ),
    (
      value: 'scale',
      icon: Icons.linear_scale,
      title: 'Scored Choices',
      desc: 'Maturity scale — e.g., Poor / Fair / Good / Excellent',
    ),
    (
      value: 'single_choice',
      icon: Icons.radio_button_checked,
      title: 'Single Choice',
      desc: 'Pick one — e.g., "Which shift?"',
    ),
    (
      value: 'multi_choice',
      icon: Icons.checklist,
      title: 'Multi Choice',
      desc: 'Pick many — e.g., "Select all that apply"',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Select Input Type',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: _types.length,
                separatorBuilder: (_, _) => const SizedBox(height: 4),
                itemBuilder: (_, i) {
                  final t = _types[i];
                  final isSelected = t.value == currentType;

                  return Card(
                    elevation: 0,
                    color: isSelected
                        ? theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.4,
                          )
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isSelected
                          ? BorderSide(
                              color: theme.colorScheme.primary,
                              width: 1.5,
                            )
                          : BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.pop(context, t.value),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              t.icon,
                              size: 22,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.title,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    t.desc,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EXPANDABLE SETTING TILE (Accordion Pattern)
// ═══════════════════════════════════════════════════════════════

/// A setting row with title + switch, and a hidden description that
/// expands on tap. Implements the "Pro Interface" accordion pattern.
class _ExpandableSettingTile extends StatefulWidget {
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _ExpandableSettingTile({
    required this.title,
    required this.description,
    required this.value,
    this.onChanged,
  });

  @override
  State<_ExpandableSettingTile> createState() => _ExpandableSettingTileState();
}

class _ExpandableSettingTileState extends State<_ExpandableSettingTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Collapsed row: title + chevron + switch ──
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                // Title + chevron
                Expanded(
                  child: Row(
                    children: [
                      Text(widget.title, style: theme.textTheme.bodyLarge),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.expand_more,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Switch (always accessible)
                Switch(value: widget.value, onChanged: widget.onChanged),
              ],
            ),
          ),
        ),

        // ── Expanded description ──
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 48, 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
          ),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}
