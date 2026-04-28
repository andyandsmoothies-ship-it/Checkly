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
import 'widgets/builder_validation_banner.dart';

part 'template_builder_page_logic.dart';

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
                    scoringMode: _scoringMode,
                    onScoringModeChanged: (v) =>
                        setState(() => _scoringMode = v ?? _scoringMode),
                  ),

                  const SizedBox(height: 16),
                  KeyedSubtree(
                    key: _errorKeys['density'] ?? ValueKey('settings'),
                    child: AdvancedSettingsCard(
                      scoringMode: _scoringMode,
                      ccpOverride: _ccpOverride,
                      riskOverride: _riskOverride,
                      weightedDensity: _weightedDensity,
                      progressiveRepeat: _progressiveRepeat,
                      confirmRequired: _confirmCorrect,
                      deadlineCtrl: _deadlineCtrl,
                      reminderCtrl: _reminderCtrl,
                      onCcpChanged: (v) => setState(() => _ccpOverride = v),
                      onRiskChanged: (v) => setState(() => _riskOverride = v),
                      onDensityChanged: (v) =>
                          setState(() => _weightedDensity = v),
                      onProgressiveChanged: (v) =>
                          setState(() => _progressiveRepeat = v),
                      onConfirmChanged: (v) =>
                          setState(() => _confirmCorrect = v),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Error Banner ──
                  if (_validationErrors?.hasAny == true)
                    BuilderValidationBanner(
                      errorCount: _validationErrors!.totalCount,
                      onDismiss: () => setState(() => _validationErrors = null),
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
                        globalConfirmRequired: _confirmCorrect,
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
