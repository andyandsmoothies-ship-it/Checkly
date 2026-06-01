// ignore_for_file: pbac_fab
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../_shared/exceptions/app_error.dart';
import '../../../_shared/services/error_display_service.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/theme/app_theme.dart';
import '../../../_shared/utils/date_format_utils.dart';
import '../../dashboard/manager/dashboard_manager.dart';
import '../../templates/manager/template_manager.dart';
import '../../templates/models/template_dto.dart';
import '../../../_shared/constants/app_capabilities.dart';
import '../manager/audit_manager.dart';

import '../../../_shared/services/gps_service.dart';
import '../../../_shared/services/geofence_service.dart';
import '../../stores/manager/store_manager.dart';

import '../utils/audit_progress_utils.dart';
import '../services/scoring_input_mapper.dart';
import '../widgets/audit_form_app_bar.dart';
import '../widgets/audit_form_dialogs.dart';
import '../widgets/audit_quick_jump_sheet.dart';
import '../widgets/audit_score_hud.dart';
import '../widgets/audit_section_card.dart';
import '../widgets/audit_section_nav_bar.dart';

final _di = GetIt.instance;

/// Main audit form page — fills criteria answers and submits.
class AuditFormPage extends StatefulWidget {
  final String templateId;
  final String storeId;

  /// When true, skips the "Resume draft?" dialog and restores immediately.
  /// Set by the Dashboard "Resume" action to bypass the confirmation popup.
  final bool autoResume;

  /// When non-null, identifies the server-side submission ID to finalize.
  /// Passed by the Activity screen when resuming a scheduled/server-draft audit.
  final String? targetSubmissionId;

  /// When non-null, indicates this audit fulfills a ProgramAssignment.
  final String? programAssignmentId;

  const AuditFormPage({
    super.key,
    required this.templateId,
    required this.storeId,
    this.autoResume = false,
    this.targetSubmissionId,
    this.programAssignmentId,
  });

  @override
  State<AuditFormPage> createState() => _AuditFormPageState();
}

class _AuditFormPageState extends State<AuditFormPage> {
  bool _isLoading = true;
  bool _scoreExpanded = true;
  int _currentSection = 0;
  bool _hasChanges = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadAndStartAudit();
  }

  Future<void> _loadAndStartAudit() async {
    final templateManager = _di<TemplateManager>();
    await templateManager.loadTemplateTree(widget.templateId);
    final tree = templateManager.selectedTemplate.value;

    if (tree != null) {
      final manager = _di<AuditManager>();
      await manager.startAudit(
        tree,
        widget.storeId,
        targetSubmissionId: widget.targetSubmissionId,
        programAssignmentId: widget.programAssignmentId,
      );
      manager.addListener(_onManagerChanged);

      // Auto-resume path: skip dialog, restore immediately (from Dashboard action)
      if (widget.autoResume && manager.hasDraft && mounted) {
        manager.restoreDraft();
      } else if (manager.hasDraft && mounted) {
        // Manual path: show confirmation dialog with draft age + device warning
        final draftAge = manager.pendingDraft?.savedAt != null
            ? timeAgo(manager.pendingDraft!.savedAt)
            : 'recently';
        final resume = await showResumeDraftDialog(context, draftAge);
        if (resume == true) {
          manager.restoreDraft();
        } else {
          manager.discardDraft();
        }
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _onManagerChanged() {
    if (!_hasChanges && mounted) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  void dispose() {
    _di<AuditManager>().removeListener(_onManagerChanged);
    super.dispose();
  }

  // ── Quick Jump ──

  void _showQuickJump(AuditManager manager, TemplateTreeDto template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AuditQuickJumpSheet(
        manager: manager,
        template: template,
        currentSection: _currentSection,
        onSectionSelected: (i) => setState(() => _currentSection = i),
      ),
    );
  }

  // ── Submit ──

  Future<void> _onSubmit(AuditManager manager) async {
    final template = manager.template!;
    final answered = totalAnswered(manager, template);
    final total = totalCriteria(template);

    // Gap 3: Confirm Required gate (now logically ORs global and individual flags)
    final missingRequired = getMissingRequired(
      manager,
      template,
      ScoringInputMapper.isConfirmRequired(template),
    );
    if (missingRequired.isNotEmpty) {
      if (mounted) {
        _di<ErrorDisplayService>().show(
          AppError(
            code: 'validation_error',
            message:
                '${missingRequired.length} required criteria still need review',
          ),
        );
      }
      return;
    }

    // ── STEP 1: Confirm dialog FIRST (instant, no GPS wait) ──────────────
    if (!mounted) return;
    final confirm = await showSubmitConfirmDialog(
      context,
      answered: answered,
      total: total,
      liveScore: manager.liveScore,
    );

    if (confirm != true) return;

    if (!mounted) return;

    // ── STEP 2: Lock UI, run GPS, then submit ────────────────────────────
    setState(() => _isSubmitting = true);
    try {
      // 1. Resolve Store GPS location
      final storeManager = _di<StoreManager>();
      final stores = storeManager.stores.value;
      final store = stores.where((s) => s.id == manager.storeId).firstOrNull;

      // 2. Perform Geofence Validation via GeofenceService
      final geofenceService = _di<GeofenceService>();
      final geofenceResult = await geofenceService.validate(
        storeLat: store?.gpsLat,
        storeLng: store?.gpsLng,
        geofenceMode: template.geofenceMode,
        geofenceRadiusMeters: template.geofenceRadiusMeters,
      );

      // 3. Handle Strict mode blocking
      if (geofenceResult.mustBlock) {
        if (mounted) {
          await showGeofenceBlockDialog(
            context: context,
            distanceMeters: geofenceResult.distanceMeters,
            allowedRadius: template.geofenceRadiusMeters,
            gpsFailed: geofenceResult.error != null,
          );
        }
        return;
      }

      // 4. Handle Lax mode warning/bypass
      if (geofenceResult.mustWarn) {
        if (mounted) {
          final bypass = await showGeofenceWarningDialog(
            context: context,
            distanceMeters: geofenceResult.distanceMeters,
            allowedRadius: template.geofenceRadiusMeters,
            gpsFailed: geofenceResult.error != null,
          );
          if (bypass != true) {
            return;
          }
          manager.setGeofenceBypass(
            isBypassed: true,
            distanceMetersOff: geofenceResult.distanceMeters,
          );
        }
      }

      // 5. Capture precise user GPS coordinates for audit outbox pinning
      try {
        final pos = await _di<GpsService>().getCurrentPosition();
        if (pos != null) {
          manager.setGps(pos.latitude, pos.longitude);
        }
      } catch (_) {}

      await manager.submitAudit();

      if (mounted) {
        if (manager.error == null) {
          setState(() => _hasChanges = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                manager.wasQueuedOffline
                    ? 'Audit queued — will sync when online'
                    : 'Audit submitted successfully!',
              ),
              backgroundColor: AppTheme.success,
            ),
          );
          // Force cache reload — StatefulShellRoute keeps tabs alive so
          // initState() doesn't re-fire. Trigger manually before navigating.
          if (_di.isRegistered<DashboardManager>()) {
            _di<DashboardManager>().loadStats();
          }
          context.go('/home');
        } else {
          _di<ErrorDisplayService>().show(
            AppError(code: 'submission_failed', message: manager.error!),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading Audit...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final manager = _di<AuditManager>();

    return ListenableBuilder(
      listenable: manager,
      builder: (context, _) {
        final template = manager.template;
        if (template == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Audit')),
            body: const Center(child: Text('Template not found')),
          );
        }

        final allAnswered = allCriteriaAnswered(manager, template);
        final confirmRequired = ScoringInputMapper.isConfirmRequired(template);
        final ccpEnabled = ScoringInputMapper.isCcpEnabled(template);
        final riskEnabled = ScoringInputMapper.isRiskEnabled(template);

        final requiredCapability = widget.programAssignmentId != null
            ? AppCapabilities.programsExecute
            : AppCapabilities.submissionsCreate;

        return PopScope(
          canPop: !_hasChanges,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) {
              _di<AuditManager>().forceSave();
              return;
            }
            final shouldLeave = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Leave audit?'),
                content: const Text(
                  'Your progress has not been submitted. '
                  'Are you sure you want to leave?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Stay'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Leave'),
                  ),
                ],
              ),
            );
            if (shouldLeave == true && context.mounted) {
              await _di<AuditManager>().forceSave();
              if (context.mounted) Navigator.pop(context);
            }
          },
          child: Scaffold(
            appBar: AuditFormAppBar(
              templateTitle: template.title,
              riskEnabled: riskEnabled,
              manager: manager,
            ),
            body: AbsorbPointer(
              absorbing: _isSubmitting,
              child: Stack(
                children: [
                  Column(
                    children: [
                      // Live score HUD
                      GestureDetector(
                        onTap: () =>
                            setState(() => _scoreExpanded = !_scoreExpanded),
                        child: AnimatedCrossFade(
                          duration: const Duration(milliseconds: 200),
                          crossFadeState: _scoreExpanded
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,
                          firstChild: AuditScoreHud(
                            score: manager.liveScore,
                            sectionScores: manager.sectionScores,
                          ),
                          secondChild: AuditCollapsedScoreHud(
                            score: manager.liveScore,
                            sectionScores: manager.sectionScores,
                          ),
                        ),
                      ),

                      // Current section only (F7: swipe gesture navigation)
                      Expanded(
                        child: GestureDetector(
                          onHorizontalDragEnd: (details) {
                            if (details.primaryVelocity == null) return;
                            if (details.primaryVelocity! < -200 &&
                                _currentSection < template.groups.length - 1) {
                              setState(() => _currentSection++);
                            } else if (details.primaryVelocity! > 200 &&
                                _currentSection > 0) {
                              setState(() => _currentSection--);
                            }
                          },
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            children: [
                              if (template.groups.isNotEmpty &&
                                  _currentSection < template.groups.length)
                                AuditSectionCard(
                                  group: template.groups[_currentSection],
                                  manager: manager,
                                  depth: 0,
                                  confirmRequired: confirmRequired,
                                  ccpEnabled: ccpEnabled,
                                  riskEnabled: riskEnabled,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_isSubmitting)
                    ColoredBox(
                      color: Theme.of(context).colorScheme.scrim.withAlpha(66),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),

            // Quick Jump FAB (Slice 2)
            floatingActionButton: FloatingActionButton.small(
              onPressed: () => _showQuickJump(manager, template),
              tooltip: 'Jump to section',
              backgroundColor: AppColors.featherGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const CircleBorder(),
              child: const Icon(Icons.grid_view),
            ),

            // Sticky section navigation bar with always-visible Submit (Slice 1)
            bottomNavigationBar: AuditSectionNavBar(
              currentSection: _currentSection,
              totalSections: template.groups.length,
              allAnswered: allAnswered,
              isSubmitting: manager.isSubmitting,
              onPrev: _currentSection > 0
                  ? () => setState(() => _currentSection--)
                  : null,
              onNext: _currentSection < template.groups.length - 1
                  ? () => setState(() => _currentSection++)
                  : null,
              onSubmit: () => _onSubmit(manager),
              requiredCapability: requiredCapability,
            ),
          ),
        );
      },
    );
  }
}
