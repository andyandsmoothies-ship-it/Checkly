import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../_shared/exceptions/app_error.dart';
import '../../../_shared/services/error_display_service.dart';
import '../../../_shared/widgets/section_header.dart';
import '../../../_shared/widgets/unsaved_changes_guard.dart';
import '../manager/template_manager.dart';
import '../models/editable_criterion.dart';
import '../models/editable_group.dart';
import '../models/validation_result.dart';
import '../models/lint_result.dart';
import '../utils/template_payload_mapper.dart';
import '../utils/dart_template_linter.dart';
import '../widgets/ghost_add_button.dart';
import '../widgets/advanced_settings_card.dart';
import '../widgets/metadata_form_card.dart';
import '../widgets/section_editor.dart';
import '../widgets/template_footer.dart';
import '../widgets/template_linter_panel.dart';
import 'widgets/builder_validation_banner.dart';
import 'widgets/live_score_simulator.dart';

part 'template_builder_page_logic.dart';
part 'template_builder_page_validation.dart';
part 'template_builder_page_mutations.dart';

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

  // Linter state
  LintResult _lintResult = LintResult(errors: [], warnings: []);
  bool _bypassLinter = false;
  Timer? _lintTimer;

  // Validation state
  ValidationErrors? _validationErrors;
  final Map<String, GlobalKey> _errorKeys = {};

  // ── Form state ──
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _type = 'qc';

  // Scoring rules
  String _scoreDirection = 'down'; // 'down' | 'up' | 'none'
  bool _isWeighted = true;
  String get _scoringMode => _scoreDirection == 'none'
      ? 'survey'
      : (_scoreDirection == 'up'
            ? 'accumulation'
            : (_isWeighted ? 'penalty' : 'checklist'));

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

  void _triggerLinter() {
    _lintTimer?.cancel();
    _lintTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _lintResult = DartTemplateLinter.lint(
            sections: _sections,
            scoreDirection: _scoreDirection,
            isWeighted: _isWeighted,
            templateType: _type,
            progressiveRepeat: _progressiveRepeat,
          );
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _manager = _di<TemplateManager>();
    // Track text controller changes for dirty state and trigger linter
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
      _triggerLinter();
    }
  }

  void _markDirty() {
    if (!_isDirty && mounted) setState(() => _isDirty = true);
    _triggerLinter();
  }

  @override
  void dispose() {
    _lintTimer?.cancel();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _deadlineCtrl.dispose();
    _reminderCtrl.dispose();
    super.dispose();
  }

  bool _hasCcpOrRisk(EditableGroup group) {
    if (group.criteria.any((c) => c.isCcp || c.isRisk)) {
      return true;
    }
    for (final sub in group.subSections) {
      if (_hasCcpOrRisk(sub)) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 800;

    final isTypeLocked = _sections.any((s) => _hasCcpOrRisk(s));
    if (isTypeLocked && _type != 'qc') {
      _type = 'qc';
    }

    Widget buildMainForm() {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          MetadataFormCard(
            titleCtrl: _titleCtrl,
            descCtrl: _descCtrl,
            type: _type,
            onTypeChanged: (v) => setState(() {
              _type = v ?? _type;
              _triggerLinter();
            }),
            scoreDirection: _scoreDirection,
            onScoreDirectionChanged: (v) => setState(() {
              _scoreDirection = v;
              _triggerLinter();
            }),
            isWeighted: _isWeighted,
            onIsWeightedChanged: (v) => setState(() {
              _isWeighted = v;
              _weightedDensity = v;
              _triggerLinter();
            }),
            isTypeLocked: isTypeLocked,
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
              onCcpChanged: (v) => setState(() {
                _ccpOverride = v;
                _triggerLinter();
              }),
              onRiskChanged: (v) => setState(() {
                _riskOverride = v;
                _triggerLinter();
              }),
              onDensityChanged: (v) => setState(() {
                _weightedDensity = v;
                _isWeighted = v;
                _triggerLinter();
              }),
              onProgressiveChanged: (v) => setState(() {
                _progressiveRepeat = v;
                _triggerLinter();
              }),
              onConfirmChanged: (v) => setState(() {
                _confirmCorrect = v;
                _triggerLinter();
              }),
            ),
          ),

          const SizedBox(height: 16),

          // ── Error Banner ──
          if (_validationErrors?.hasAny == true) ...[
            BuilderValidationBanner(
              errorCount: _validationErrors!.totalCount,
              onDismiss: () => setState(() => _validationErrors = null),
            ),
            const SizedBox(height: 16),
          ],



          // ── Sections Editor (AC-7) ──
          const SectionHeader('SECTIONS'),
          const SizedBox(height: 12),

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
                onChanged: () {
                  setState(() {});
                  _triggerLinter();
                },
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
      );
    }

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
              (!_weightedDensity || (_totalDensity - 100).abs() < 0.01) &&
              (!_lintResult.hasErrors || _bypassLinter),
          saving: _saving,
          onSave: _save,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : (isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: buildMainForm()),
                        const VerticalDivider(width: 1, thickness: 1),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            child: ListView(
                              children: [
                                TemplateLinterPanel(
                                  lintResult: _lintResult,
                                  bypassLinter: _bypassLinter,
                                  onBypassChanged: (v) =>
                                      setState(() => _bypassLinter = v),
                                  onScrollToTarget: (targetId) {
                                    final gk = _errorKeys[targetId];
                                    if (gk?.currentContext != null) {
                                      Scrollable.ensureVisible(
                                        gk!.currentContext!,
                                        duration: const Duration(
                                          milliseconds: 350,
                                        ),
                                        curve: Curves.easeInOut,
                                        alignment: 0.3,
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const VerticalDivider(width: 1, thickness: 1),
                        Expanded(
                          flex: 2,
                          child: LiveScoreSimulator(
                            sections: _sections,
                            scoringMode: _scoringMode,
                            progressiveRepeat: _progressiveRepeat,
                          ),
                        ),
                      ],
                    )
                  : DefaultTabController(
                      length: 3,
                      child: Builder(
                        builder: (context) {
                          return Column(
                            children: [
                              const TabBar(
                                tabs: [
                                  Tab(text: 'Design'),
                                  Tab(text: 'Issues'),
                                  Tab(text: 'Simulator'),
                                ],
                              ),
                              Expanded(
                                child: TabBarView(
                                  children: [
                                    buildMainForm(),
                                    SingleChildScrollView(
                                      padding: const EdgeInsets.all(16),
                                      child: TemplateLinterPanel(
                                        lintResult: _lintResult,
                                        bypassLinter: _bypassLinter,
                                        onBypassChanged: (v) =>
                                            setState(() => _bypassLinter = v),
                                        onScrollToTarget: (targetId) {
                                          DefaultTabController.of(
                                            context,
                                          ).animateTo(0);
                                          Future.delayed(
                                            const Duration(milliseconds: 150),
                                            () {
                                              final gk = _errorKeys[targetId];
                                              if (gk?.currentContext != null) {
                                                Scrollable.ensureVisible(
                                                  gk!.currentContext!,
                                                  duration: const Duration(
                                                    milliseconds: 350,
                                                  ),
                                                  curve: Curves.easeInOut,
                                                  alignment: 0.3,
                                                );
                                              }
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                    LiveScoreSimulator(
                                      sections: _sections,
                                      scoringMode: _scoringMode,
                                      progressiveRepeat: _progressiveRepeat,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    )),
      ),
    );
  }
}
