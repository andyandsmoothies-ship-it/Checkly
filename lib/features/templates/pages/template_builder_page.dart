import 'dart:convert';
import 'package:flutter/material.dart';
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
  bool _ccpOverride = false;
  bool _riskOverride = false;
  bool _weightedDensity = false;
  bool _confirmCorrect = false;
  bool _progressiveRepeat = false;
  final _deadlineCtrl = TextEditingController(text: '7');
  final _reminderCtrl = TextEditingController(text: '2');

  // Sections (mutable list for editing)
  List<_EditableGroup> _sections = [];

  @override
  void initState() {
    super.initState();
    _manager = _di<TemplateManager>();
    if (!_isNew) {
      _loadExistingTemplate();
    } else {
      _loading = false;
    }
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
          if (config['deadlineDays'] != null) {
            _deadlineCtrl.text = config['deadlineDays'].toString();
          }
          if (config['reminderDays'] != null) {
            _reminderCtrl.text = config['reminderDays'].toString();
          }
        } catch (_) {}
      }
    }
    setState(() => _loading = false);
  }

  String _buildScoringConfig() {
    return json.encode({
      'ccpOverride': _ccpOverride,
      'riskOverride': _riskOverride,
      'weightedDensity': _weightedDensity,
      'confirmCorrect': _confirmCorrect,
      'progressiveRepeat': _progressiveRepeat,
      'deadlineDays': int.tryParse(_deadlineCtrl.text) ?? 7,
      'reminderDays': int.tryParse(_reminderCtrl.text) ?? 2,
    });
  }

  List<GroupDto> _buildGroups() {
    return _sections.asMap().entries.map((e) {
      final i = e.key;
      final s = e.value;
      return GroupDto(
        id: s.id,
        title: s.titleCtrl.text,
        description: s.descCtrl.text.isEmpty ? null : s.descCtrl.text,
        weight: double.tryParse(s.weightCtrl.text),
        orderIndex: i,
        children: const [],
        criteria: s.criteria.asMap().entries.map((ce) {
          final ci = ce.key;
          final c = ce.value;
          return CriterionDto(
            id: c.id,
            label: c.labelCtrl.text,
            inputType: c.inputType,
            pointsWeight: double.tryParse(c.pointsCtrl.text),
            isCcp: c.isCcp,
            isRisk: c.isRisk,
            orderIndex: ci,
          );
        }).toList(),
      );
    }).toList();
  }

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
      await _manager.saveTemplate(
        id: _isNew ? null : widget.templateId,
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
  }

  void _removeSection(int index) {
    setState(() {
      _sections[index].dispose();
      _sections.removeAt(index);
    });
  }

  void _addCriterion(int sectionIndex) {
    setState(() {
      _sections[sectionIndex].criteria.add(_EditableCriterion());
    });
  }

  void _removeCriterion(int sectionIndex, int criterionIndex) {
    setState(() {
      _sections[sectionIndex].criteria[criterionIndex].dispose();
      _sections[sectionIndex].criteria.removeAt(criterionIndex);
    });
  }

  // ── Computed values ──
  int get _totalPoints {
    var pts = 0;
    for (final s in _sections) {
      for (final c in s.criteria) {
        pts += (double.tryParse(c.pointsCtrl.text) ?? 0).toInt();
      }
    }
    return pts;
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

                // ── Scoring Rules Card (AC-6) ──
                _ScoringRulesCard(
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
                      onRemoveSection: () => _removeSection(i),
                      onAddCriterion: () => _addCriterion(i),
                      onRemoveCriterion: (ci) => _removeCriterion(i, ci),
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
  List<_EditableCriterion> criteria;

  _EditableGroup({
    this.id = '',
    String title = '',
    String description = '',
    String weight = '',
    List<_EditableCriterion>? criteria,
  }) : titleCtrl = TextEditingController(text: title),
       descCtrl = TextEditingController(text: description),
       weightCtrl = TextEditingController(text: weight),
       criteria = criteria ?? [];

  factory _EditableGroup.fromDto(GroupDto dto) => _EditableGroup(
    id: dto.id,
    title: dto.title,
    description: dto.description ?? '',
    weight: dto.weight?.toString() ?? '',
    criteria: dto.criteria.map((c) => _EditableCriterion.fromDto(c)).toList(),
  );

  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    weightCtrl.dispose();
    for (final c in criteria) {
      c.dispose();
    }
  }
}

class _EditableCriterion {
  final String id;
  final TextEditingController labelCtrl;
  final TextEditingController pointsCtrl;
  String inputType;
  bool isCcp;
  bool isRisk;

  _EditableCriterion({
    this.id = '',
    String label = '',
    String points = '',
    this.inputType = 'pass_fail',
    this.isCcp = false,
    this.isRisk = false,
  }) : labelCtrl = TextEditingController(text: label),
       pointsCtrl = TextEditingController(text: points);

  factory _EditableCriterion.fromDto(CriterionDto dto) => _EditableCriterion(
    id: dto.id,
    label: dto.label,
    points: dto.pointsWeight?.toString() ?? '',
    inputType: dto.inputType,
    isCcp: dto.isCcp,
    isRisk: dto.isRisk,
  );

  void dispose() {
    labelCtrl.dispose();
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
// AC-6: SCORING RULES CARD
// ═══════════════════════════════════════════════════════════════

class _ScoringRulesCard extends StatelessWidget {
  final bool ccpOverride;
  final bool riskOverride;
  final bool weightedDensity;
  final bool confirmCorrect;
  final bool progressiveRepeat;
  final TextEditingController deadlineCtrl;
  final TextEditingController reminderCtrl;
  final ValueChanged<bool> onCcpChanged;
  final ValueChanged<bool> onRiskChanged;
  final ValueChanged<bool> onDensityChanged;
  final ValueChanged<bool> onCorrectChanged;
  final ValueChanged<bool> onProgressiveChanged;

  const _ScoringRulesCard({
    required this.ccpOverride,
    required this.riskOverride,
    required this.weightedDensity,
    required this.confirmCorrect,
    required this.progressiveRepeat,
    required this.deadlineCtrl,
    required this.reminderCtrl,
    required this.onCcpChanged,
    required this.onRiskChanged,
    required this.onDensityChanged,
    required this.onCorrectChanged,
    required this.onProgressiveChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader('SCORING RULES'),
            const SizedBox(height: 12),

            // 5 toggles
            SwitchListTile(
              title: const Text('CCP Override'),
              subtitle: const Text(
                'Critical Control Point failures immediately flag the audit',
              ),
              value: ccpOverride,
              onChanged: onCcpChanged,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('RISK Override'),
              subtitle: const Text(
                'Risk-flagged criteria apply penalty multipliers',
              ),
              value: riskOverride,
              onChanged: onRiskChanged,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Weighted Density'),
              subtitle: const Text(
                'Section weights affect overall score proportionally',
              ),
              value: weightedDensity,
              onChanged: onDensityChanged,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Confirm Correct'),
              subtitle: const Text(
                'Require explicit confirmation of passing items',
              ),
              value: confirmCorrect,
              onChanged: onCorrectChanged,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Progressive Repeat Penalty'),
              subtitle: const Text(
                'n² escalation for repeated faults across audits',
              ),
              value: progressiveRepeat,
              onChanged: onProgressiveChanged,
              contentPadding: EdgeInsets.zero,
            ),

            const Divider(height: 24),

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
              padding: const EdgeInsets.only(top: 4, bottom: 16),
              child: Text(
                'Number of days the store manager has to resolve each action plan (1–90).',
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
                'Send a reminder notification to the store manager this many days before the deadline (1–30).',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// AC-7: SECTION EDITOR
// ═══════════════════════════════════════════════════════════════

class _SectionEditor extends StatelessWidget {
  final int index;
  final _EditableGroup section;
  final VoidCallback onRemoveSection;
  final VoidCallback onAddCriterion;
  final ValueChanged<int> onRemoveCriterion;
  final VoidCallback onChanged;

  const _SectionEditor({
    required this.index,
    required this.section,
    required this.onRemoveSection,
    required this.onAddCriterion,
    required this.onRemoveCriterion,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
              Expanded(
                child: Text(
                  section.titleCtrl.text.isEmpty
                      ? 'Section ${index + 1}'
                      : section.titleCtrl.text,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (section.weightCtrl.text.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${section.weightCtrl.text}%',
                    style: AppFonts.serifStyle(
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: onRemoveSection,
          ),
          children: [
            // Title & Weight
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: section.titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Section Title',
                      isDense: true,
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: section.weightCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Weight %',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

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

            // Add Criteria button
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
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// AC-7: CRITERIA EDITOR (inline row)
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Label
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: criterion.labelCtrl,
              decoration: const InputDecoration(
                hintText: 'Criterion label',
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 8),
          // Points
          SizedBox(
            width: 50,
            child: TextFormField(
              controller: criterion.pointsCtrl,
              decoration: const InputDecoration(hintText: 'Pts', isDense: true),
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 13),
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 4),
          // CCP badge
          _ToggleBadge(
            label: 'CCP',
            active: criterion.isCcp,
            onTap: () {
              criterion.isCcp = !criterion.isCcp;
              onChanged();
            },
          ),
          const SizedBox(width: 4),
          // RISK badge
          _ToggleBadge(
            label: 'RISK',
            active: criterion.isRisk,
            onTap: () {
              criterion.isRisk = !criterion.isRisk;
              onChanged();
            },
          ),
          // Delete
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: onRemove,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

/// Small toggle badge for CCP/RISK flags on criteria.
class _ToggleBadge extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToggleBadge({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.warning.withValues(alpha: 0.2)
              : AppTheme.sageGray.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: active
                ? AppTheme.warning
                : AppTheme.sageGray.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: active ? AppTheme.warning : AppTheme.sageGray,
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
