import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../_shared/theme/app_theme.dart';
import '../../../_shared/services/gps_service.dart';
import '../../../_shared/utils/date_format_utils.dart';
import '../../stores/manager/store_manager.dart';
import '../../templates/manager/template_manager.dart';
import '../../templates/models/template_dto.dart';
import '../manager/audit_manager.dart';
import '../widgets/audit_score_hud.dart';
import '../widgets/audit_section_card.dart';
import '../widgets/audit_section_nav_bar.dart';

final _di = GetIt.instance;

/// Main audit form page — fills criteria answers and submits.
class AuditFormPage extends StatefulWidget {
  final String templateId;
  final String storeId;

  const AuditFormPage({
    super.key,
    required this.templateId,
    required this.storeId,
  });

  @override
  State<AuditFormPage> createState() => _AuditFormPageState();
}

class _AuditFormPageState extends State<AuditFormPage> {
  bool _isLoading = true;
  bool _scoreExpanded = true;
  int _currentSection = 0;
  bool _hasChanges = false;

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
      await manager.startAudit(tree, widget.storeId);
      manager.addListener(_onManagerChanged);

      // Show resume dialog if draft exists
      if (manager.hasDraft && mounted) {
        final draftAge = manager.pendingDraft?.savedAt != null
            ? timeAgo(manager.pendingDraft!.savedAt)
            : 'recently';
        final resume = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('Resume draft?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You have an unsaved draft for this audit (saved $draftAge). '
                  'Would you like to resume where you left off?',
                ),
                const SizedBox(height: 12),
                Text(
                  'This draft is saved only on this device. It will expire in 14 days.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Discard'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Resume'),
              ),
            ],
          ),
        );
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

  // ── Progress helpers ──

  int _groupAnsweredCount(AuditManager manager, GroupDto group) {
    int count = 0;
    for (final c in group.criteria) {
      final a = manager.answers[c.id];
      if (a != null && (a.value != null || a.numericValue != null)) count++;
    }
    for (final child in group.children) {
      count += _groupAnsweredCount(manager, child);
    }
    return count;
  }

  int _groupTotalCount(GroupDto group) {
    int count = group.criteria.length;
    for (final child in group.children) {
      count += _groupTotalCount(child);
    }
    return count;
  }

  bool _allCriteriaAnswered(AuditManager manager, TemplateTreeDto template) {
    for (final group in template.groups) {
      if (_groupAnsweredCount(manager, group) < _groupTotalCount(group)) {
        return false;
      }
    }
    return true;
  }

  int _totalAnswered(AuditManager manager, TemplateTreeDto template) {
    int count = 0;
    for (final group in template.groups) {
      count += _groupAnsweredCount(manager, group);
    }
    return count;
  }

  int _totalCriteria(TemplateTreeDto template) {
    int count = 0;
    for (final group in template.groups) {
      count += _groupTotalCount(group);
    }
    return count;
  }

  // ── Quick Jump ──

  void _showQuickJump(AuditManager manager, TemplateTreeDto template) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text(
                  'Jump to Section',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(template.groups.length, (i) {
                      final group = template.groups[i];
                      final answered = _groupAnsweredCount(manager, group);
                      final total = _groupTotalCount(group);
                      final isCurrent = i == _currentSection;
                      final isComplete = answered >= total;

                      return ListTile(
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: isComplete
                              ? AppTheme.success.withAlpha(30)
                              : isCurrent
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surfaceContainerHighest,
                          child: isComplete
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: AppTheme.success,
                                )
                              : Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: theme.textTheme.labelSmall?.fontSize,
                                    color: isCurrent
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                        ),
                        title: Text(
                          group.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isCurrent
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          '$answered / $total done',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isComplete
                                ? AppTheme.success
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        selected: isCurrent,
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() => _currentSection = i);
                        },
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // ── Submit ──

  bool _isConfirmRequired(TemplateTreeDto template) {
    if (template.scoringLogicConfig == null ||
        template.scoringLogicConfig!.isEmpty) {
      return false;
    }
    try {
      final config =
          json.decode(template.scoringLogicConfig!) as Map<String, dynamic>;
      // Read from top-level (Flutter) or features map (legacy)
      if (config['confirmCorrect'] == true) return true;
      final features = config['features'] as Map<String, dynamic>?;
      return features?['confirm_required'] == true;
    } catch (_) {
      return false;
    }
  }

  bool _isCcpEnabled(TemplateTreeDto template) {
    if (template.scoringLogicConfig == null ||
        template.scoringLogicConfig!.isEmpty) {
      return true;
    }
    try {
      final config =
          json.decode(template.scoringLogicConfig!) as Map<String, dynamic>;
      if (config.containsKey('ccpOverride')) {
        return config['ccpOverride'] == true;
      }
      final features = config['features'] as Map<String, dynamic>?;
      if (features != null && features.containsKey('ccp_enabled')) {
        return features['ccp_enabled'] == true;
      }
      return true; // default true if not specified
    } catch (_) {
      return true;
    }
  }

  bool _isRiskEnabled(TemplateTreeDto template) {
    if (template.scoringLogicConfig == null ||
        template.scoringLogicConfig!.isEmpty) {
      return true;
    }
    try {
      final config =
          json.decode(template.scoringLogicConfig!) as Map<String, dynamic>;
      if (config.containsKey('riskOverride')) {
        return config['riskOverride'] == true;
      }
      final features = config['features'] as Map<String, dynamic>?;
      if (features != null && features.containsKey('risk_enabled')) {
        return features['risk_enabled'] == true;
      }
      return true; // default true if not specified
    } catch (_) {
      return true;
    }
  }

  Future<void> _onSubmit(AuditManager manager) async {
    final template = manager.template!;
    final answered = _totalAnswered(manager, template);
    final total = _totalCriteria(template);

    // Gap 3: Confirm Required gate
    if (_isConfirmRequired(template) && answered < total) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${total - answered} criteria still need review'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    // Gap 5: GPS proximity warning (non-blocking)
    try {
      final gps = _di<GpsService>();
      final pos = await gps.getCurrentPosition();
      if (pos != null) {
        manager.setGps(pos.latitude, pos.longitude);

        // Check proximity to store
        final storeManager = _di<StoreManager>();
        final stores = storeManager.stores.value;
        final store = stores.where((s) => s.id == manager.storeId).firstOrNull;
        if (store != null && store.gpsLat != null && store.gpsLng != null) {
          final result = gps.checkProximity(
            userLat: pos.latitude,
            userLng: pos.longitude,
            storeLat: store.gpsLat!,
            storeLng: store.gpsLng!,
          );
          if (!result.inRange && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Unverified location — ${result.distance}m from store '
                  '(max ${GpsService.maxDistanceMeters}m)',
                ),
                backgroundColor: AppTheme.warning,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }
    } catch (_) {
      // GPS failure is non-blocking — but user must know
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📍 Location unavailable — submitting without GPS'),
          ),
        );
      }
    }

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Audit?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total > 0 ? answered / total : 0,
                minHeight: 6,
                backgroundColor: Theme.of(
                  ctx,
                ).colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 12),
            Text('Criteria answered: $answered / $total'),
            const SizedBox(height: 4),
            Text(
              manager.liveScore != null
                  ? 'Score: ${manager.liveScore!.toStringAsFixed(1)}%'
                  : 'Survey — No Score',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: manager.liveScore != null && manager.liveScore! >= 80
                    ? AppTheme.success
                    : manager.liveScore != null && manager.liveScore! >= 50
                    ? AppTheme.warning
                    : Theme.of(ctx).colorScheme.error,
              ),
            ),
            if (answered < total) ...[
              const SizedBox(height: 12),
              Text(
                '⚠ ${total - answered} criteria unanswered',
                style: TextStyle(
                  color: Theme.of(ctx).colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await manager.submitAudit();

    if (mounted) {
      if (manager.lastSubmission != null || manager.wasQueuedOffline) {
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
        context.go('/home');
      } else if (manager.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(manager.error!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
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

        final allAnswered = _allCriteriaAnswered(manager, template);
        final confirmRequired = _isConfirmRequired(template);
        final ccpEnabled = _isCcpEnabled(template);
        final riskEnabled = _isRiskEnabled(template);

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
            appBar: AppBar(
              title: Text(template.title, overflow: TextOverflow.ellipsis),
              actions: [
                // Draft saved indicator
                if (manager.draftSavedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Chip(
                      avatar: Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      label: Text(
                        'Saved',
                        style: TextStyle(fontSize: Theme.of(context).textTheme.labelSmall?.fontSize),
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                AuditScoreChip(score: manager.liveScore),
                const SizedBox(width: 8),
              ],
            ),
            body: Column(
              children: [
                // Live score HUD
                GestureDetector(
                  onTap: () => setState(() => _scoreExpanded = !_scoreExpanded),
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

            // Quick Jump FAB (Slice 2)
            floatingActionButton: FloatingActionButton.small(
              onPressed: () => _showQuickJump(manager, template),
              tooltip: 'Jump to section',
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
            ),
          ),
        );
      },
    );
  }
}
