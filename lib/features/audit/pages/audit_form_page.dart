import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../_shared/theme/app_theme.dart';
import '../../../_shared/services/gps_service.dart';
import 'package:image_picker/image_picker.dart';
import '../../stores/manager/store_manager.dart';
import '../../templates/manager/template_manager.dart';
import '../../templates/model/template_dto.dart';
import '../manager/audit_manager.dart';

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
  int _currentSection = 0;

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
      _di<AuditManager>().startAudit(tree, widget.storeId);
    }

    if (mounted) setState(() => _isLoading = false);
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
              ...List.generate(template.groups.length, (i) {
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
                              fontSize: 13,
                              color: isCurrent
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                  ),
                  title: Text(
                    group.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    '$answered / $total',
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
      // GPS failure is non-blocking
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
              'Score: ${manager.liveScore.toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: manager.liveScore >= 80
                    ? AppTheme.success
                    : manager.liveScore >= 50
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

        return Scaffold(
          appBar: AppBar(
            title: Text(template.title, overflow: TextOverflow.ellipsis),
            actions: [
              _ScoreChip(score: manager.liveScore),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              // Live score HUD
              _ScoreHud(score: manager.liveScore),

              // Current section only
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    if (template.groups.isNotEmpty &&
                        _currentSection < template.groups.length)
                      _SectionCard(
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
            ],
          ),

          // Quick Jump FAB (Slice 2)
          floatingActionButton: FloatingActionButton.small(
            onPressed: () => _showQuickJump(manager, template),
            tooltip: 'Jump to section',
            child: const Icon(Icons.grid_view),
          ),

          // Sticky section navigation bar with always-visible Submit (Slice 1)
          bottomNavigationBar: _SectionNavBar(
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
        );
      },
    );
  }
}

// ============================================================
// Live Score HUD
// ============================================================

class _ScoreHud extends StatelessWidget {
  final double score;
  const _ScoreHud({required this.score});

  Color _scoreColor(ThemeData theme) {
    if (score >= 80) return AppTheme.success;
    if (score >= 50) return AppTheme.warning;
    return theme.colorScheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _scoreColor(theme);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(Icons.speed, color: color, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Live Score',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '${score.toStringAsFixed(2)}%',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: 52,
            height: 52,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 5,
              color: color,
              backgroundColor: color.withAlpha(30),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final double score;
  const _ScoreChip({required this.score});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        '${score.toStringAsFixed(1)}%',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      visualDensity: VisualDensity.compact,
    );
  }
}

// ============================================================
// Section Card
// ============================================================

class _SectionCard extends StatelessWidget {
  final GroupDto group;
  final AuditManager manager;
  final int depth;
  final bool confirmRequired;
  final bool ccpEnabled;
  final bool riskEnabled;

  const _SectionCard({
    required this.group,
    required this.manager,
    this.depth = 0,
    this.confirmRequired = false,
    this.ccpEnabled = true,
    this.riskEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sectionScore = depth == 0 ? manager.sectionScores[group.id] : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Row(
          children: [
            Expanded(
              child: Text(
                group.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            // Section score display (top-level only)
            if (depth == 0 && sectionScore != null) ...[
              if (sectionScore.hasCcpFailure)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'CCP',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 9,
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: sectionScore.hasCcpFailure
                      ? theme.colorScheme.errorContainer
                      : theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${sectionScore.score.toStringAsFixed(0)} / ${sectionScore.maxPoints.toStringAsFixed(0)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: sectionScore.hasCcpFailure
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            if (depth == 0 && group.weight != null && group.weight! > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${group.weight!.toStringAsFixed(0)}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        children: [
          ...group.criteria.map(
            (c) => _CriterionRow(
              criterion: c,
              manager: manager,
              confirmRequired: confirmRequired,
              ccpEnabled: ccpEnabled,
              riskEnabled: riskEnabled,
            ),
          ),
          ...group.children.map(
            (g) => Padding(
              padding: const EdgeInsets.only(left: 12),
              child: _SectionCard(
                group: g,
                manager: manager,
                depth: depth + 1,
                confirmRequired: confirmRequired,
                ccpEnabled: ccpEnabled,
                riskEnabled: riskEnabled,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Criterion Row — compact list item (Bottom Sheet pattern)
// ============================================================

class _CriterionRow extends StatelessWidget {
  final CriterionDto criterion;
  final AuditManager manager;
  final bool confirmRequired;
  final bool ccpEnabled;
  final bool riskEnabled;

  const _CriterionRow({
    required this.criterion,
    required this.manager,
    this.confirmRequired = false,
    this.ccpEnabled = true,
    this.riskEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final answer = manager.answers[criterion.id];
    final faults = (answer?.numericValue ?? 0).toInt();
    final repeats = answer?.repeatedFaultCount ?? 0;
    final isCcp = answer?.isCcp ?? false;
    final isRisk = answer?.isRisk ?? false;
    final hasNote = answer?.note != null && answer!.note!.isNotEmpty;
    final hasPhoto = answer?.photoUrl != null;
    final isConfirmed = answer?.value == 'conform';
    final isNonConform = answer?.value == 'non_conform';

    // Determine overall status
    final bool isAnswered =
        answer?.value != null || (answer?.numericValue != null);

    return InkWell(
      onTap: () => _showCriterionSheet(
        context,
        criterion: criterion,
        manager: manager,
        confirmRequired: confirmRequired,
        ccpEnabled: ccpEnabled,
        riskEnabled: riskEnabled,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Leading status icon
            Icon(
              isConfirmed || (isAnswered && faults == 0 && !isNonConform)
                  ? Icons.check_circle
                  : faults > 0 || isNonConform
                  ? Icons.error_outline
                  : Icons.radio_button_unchecked,
              size: 20,
              color: isConfirmed || (isAnswered && faults == 0 && !isNonConform)
                  ? AppTheme.success
                  : faults > 0 || isNonConform
                  ? theme.colorScheme.error
                  : theme.colorScheme.outlineVariant,
            ),
            const SizedBox(width: 12),

            // Label
            Expanded(
              child: Text(
                criterion.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),

            // Status badges (compact)
            Wrap(
              spacing: 4,
              children: [
                if (faults > 0)
                  _StatusBadge(
                    label: 'F:$faults',
                    color: theme.colorScheme.error,
                  ),
                if (repeats > 0)
                  _StatusBadge(label: 'R:$repeats', color: AppTheme.warning),
                if (isCcp)
                  _StatusBadge(label: 'CCP', color: theme.colorScheme.error),
                if (isRisk)
                  _StatusBadge(label: 'RISK', color: AppTheme.warning),
                if (hasNote)
                  Icon(Icons.notes, size: 16, color: theme.colorScheme.primary),
                if (hasPhoto)
                  Icon(
                    Icons.camera_alt,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
              ],
            ),

            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: theme.colorScheme.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Small colored badge for status indicators on the compact row.
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ============================================================
// Criterion Bottom Sheet — full editing controls
// ============================================================

Future<void> _showCriterionSheet(
  BuildContext context, {
  required CriterionDto criterion,
  required AuditManager manager,
  required bool confirmRequired,
  required bool ccpEnabled,
  required bool riskEnabled,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) {
      return ListenableBuilder(
        listenable: manager,
        builder: (ctx, _) {
          final theme = Theme.of(ctx);
          final answer = manager.answers[criterion.id];
          final hasFaults = (answer?.numericValue ?? 0) > 0;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Title
                      Text(
                        criterion.label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Input based on type
                      if (criterion.inputType == 'pass_fail')
                        _PassFailInput(
                          value: answer?.value,
                          onChanged: (v) =>
                              manager.setAnswer(criterion.id, value: v),
                        )
                      else ...[
                        // Faults + Repeats on same row
                        Row(
                          children: [
                            _NumericInput(
                              label: 'Faults:',
                              value: answer?.numericValue,
                              onChanged: (v) => manager.setAnswer(
                                criterion.id,
                                numericValue: v,
                              ),
                            ),
                            const Spacer(),
                            _NumericInput(
                              label: 'Repeats:',
                              value: (answer?.repeatedFaultCount ?? 0)
                                  .toDouble(),
                              activeColor: (answer?.repeatedFaultCount ?? 0) > 0
                                  ? AppTheme.warning
                                  : null,
                              onChanged: (v) => manager.setRepeatedFaultCount(
                                criterion.id,
                                v.toInt(),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Confirm Correct button
                      if (confirmRequired && !hasFaults) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: answer?.value == 'conform'
                                ? null
                                : () => manager.setAnswer(
                                    criterion.id,
                                    value: 'conform',
                                  ),
                            icon: Icon(
                              answer?.value == 'conform'
                                  ? Icons.check_circle
                                  : Icons.check_circle_outline,
                              size: 18,
                            ),
                            label: Text(
                              answer?.value == 'conform'
                                  ? 'Standard Verified'
                                  : 'Confirm Correct',
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: answer?.value == 'conform'
                                  ? AppTheme.success
                                  : theme.colorScheme.surfaceContainerHighest,
                              foregroundColor: answer?.value == 'conform'
                                  ? Colors.white
                                  : theme.colorScheme.onSurfaceVariant,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],

                      // CCP / RISK toggle buttons
                      if (ccpEnabled || riskEnabled) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (ccpEnabled)
                              Expanded(
                                child: _CcpRiskButton(
                                  label: 'CCP',
                                  icon: Icons.shield,
                                  active: answer?.isCcp ?? false,
                                  activeColor: theme.colorScheme.error,
                                  onTap: () {
                                    final newVal = !(answer?.isCcp ?? false);
                                    manager.setCcp(criterion.id, newVal);
                                  },
                                ),
                              ),
                            if (ccpEnabled && riskEnabled)
                              const SizedBox(width: 8),
                            if (riskEnabled)
                              Expanded(
                                child: _CcpRiskButton(
                                  label: 'RISK',
                                  icon: Icons.warning_amber_rounded,
                                  active: answer?.isRisk ?? false,
                                  activeColor: AppTheme.warning,
                                  onTap: () {
                                    final newVal = !(answer?.isRisk ?? false);
                                    manager.setRisk(criterion.id, newVal);
                                  },
                                ),
                              ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),

                      // Note field
                      TextFormField(
                        initialValue: answer?.note,
                        decoration: InputDecoration(
                          labelText: 'Note',
                          hintText: 'Add note...',
                          prefixIcon: const Icon(Icons.notes, size: 20),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        maxLines: 3,
                        style: theme.textTheme.bodySmall,
                        onChanged: (v) => manager.setNote(criterion.id, v),
                      ),

                      const SizedBox(height: 12),

                      // Photo button + preview
                      _PhotoSection(criterion: criterion, manager: manager),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

/// Photo capture button and preview for the bottom sheet.
class _PhotoSection extends StatelessWidget {
  final CriterionDto criterion;
  final AuditManager manager;

  const _PhotoSection({required this.criterion, required this.manager});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final answer = manager.answers[criterion.id];
    final hasPhoto = answer?.photoUrl != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _pickPhoto(context),
            icon: Icon(
              hasPhoto ? Icons.camera_alt : Icons.camera_alt_outlined,
              size: 18,
            ),
            label: Text(hasPhoto ? 'Change Photo' : 'Add Photo'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        if (hasPhoto) ...[
          const SizedBox(height: 8),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(answer!.photoUrl!),
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, e, s) => Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.broken_image_outlined, size: 24),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () => manager.setPhotoUrl(criterion.id, null),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _pickPhoto(BuildContext ctx) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: ctx,
      builder: (bCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(bCtx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(bCtx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 80,
    );
    if (image == null) return;

    manager.setPhotoUrl(criterion.id, image.path);
  }
}

/// Prominent CCP/RISK toggle button (PWA-style).
class _CcpRiskButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _CcpRiskButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: active ? activeColor : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: active
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: active
                      ? Colors.white
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Input widgets
// ============================================================

class _PassFailInput extends StatelessWidget {
  final String? value;
  final ValueChanged<String> onChanged;

  const _PassFailInput({this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'conform', label: Text('Conform')),
        ButtonSegment(value: 'non_conform', label: Text('Non-Conform')),
        ButtonSegment(value: 'na', label: Text('N/A')),
      ],
      selected: value != null ? {value!} : {},
      onSelectionChanged: (s) => onChanged(s.first),
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStateProperty.all(
          theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _NumericInput extends StatefulWidget {
  final String label;
  final double? value;
  final Color? activeColor;
  final ValueChanged<double> onChanged;

  const _NumericInput({
    this.label = 'Faults:',
    this.value,
    this.activeColor,
    required this.onChanged,
  });

  @override
  State<_NumericInput> createState() => _NumericInputState();
}

class _NumericInputState extends State<_NumericInput> {
  late double _count;

  @override
  void initState() {
    super.initState();
    _count = widget.value ?? 0;
  }

  @override
  void didUpdateWidget(_NumericInput old) {
    super.didUpdateWidget(old);
    _count = widget.value ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = _count > 0;
    final textColor = isActive && widget.activeColor != null
        ? widget.activeColor!
        : null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: textColor ?? theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          onPressed: _count > 0
              ? () {
                  setState(() => _count = max(0, _count - 1));
                  widget.onChanged(_count);
                }
              : null,
          icon: const Icon(Icons.remove, size: 18),
          visualDensity: VisualDensity.compact,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            _count.toInt().toString(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
        IconButton.filledTonal(
          onPressed: () {
            setState(() => _count++);
            widget.onChanged(_count);
          },
          icon: const Icon(Icons.add, size: 18),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

// ============================================================
// Section Navigation Bar — Submit always visible (Slice 1)
// ============================================================

class _SectionNavBar extends StatelessWidget {
  final int currentSection;
  final int totalSections;
  final bool allAnswered;
  final bool isSubmitting;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback onSubmit;

  const _SectionNavBar({
    required this.currentSection,
    required this.totalSections,
    required this.allAnswered,
    required this.isSubmitting,
    required this.onPrev,
    required this.onNext,
    required this.onSubmit,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Prev button
            IconButton.filledTonal(
              onPressed: onPrev,
              icon: const Icon(Icons.chevron_left, size: 22),
              tooltip: 'Previous section',
            ),

            const SizedBox(width: 4),

            // Section counter
            Text(
              '${currentSection + 1}/$totalSections',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(width: 4),

            // Next button
            IconButton.filledTonal(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right, size: 22),
              tooltip: 'Next section',
            ),

            const Spacer(),

            // Submit button — ALWAYS visible (Slice 1)
            FilledButton.icon(
              onPressed: !isSubmitting ? onSubmit : null,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send, size: 18),
              label: Text(isSubmitting ? 'Submitting...' : 'Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
