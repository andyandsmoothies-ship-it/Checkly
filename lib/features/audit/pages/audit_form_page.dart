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
      return true;
    }
    try {
      final config =
          json.decode(template.scoringLogicConfig!) as Map<String, dynamic>;
      final features = config['features'] as Map<String, dynamic>?;
      return features?['confirm_required'] != false;
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

  const _SectionCard({
    required this.group,
    required this.manager,
    this.depth = 0,
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
            (c) => _CriterionTile(criterion: c, manager: manager),
          ),
          ...group.children.map(
            (g) => Padding(
              padding: const EdgeInsets.only(left: 12),
              child: _SectionCard(group: g, manager: manager, depth: depth + 1),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Criterion Tile — answer input (Slice 3: enriched)
// ============================================================

class _CriterionTile extends StatefulWidget {
  final CriterionDto criterion;
  final AuditManager manager;

  const _CriterionTile({required this.criterion, required this.manager});

  @override
  State<_CriterionTile> createState() => _CriterionTileState();
}

class _CriterionTileState extends State<_CriterionTile> {
  bool _showNote = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final answer = widget.manager.answers[widget.criterion.id];
    final isNonConform = answer?.value == 'non_conform';
    final hasFaults = (answer?.numericValue ?? 0) > 0;
    final hasNote = answer?.note != null && answer!.note!.isNotEmpty;

    // Auto-expand note on non-conform or faults
    final noteVisible = _showNote || isNonConform || hasFaults || hasNote;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            widget.criterion.label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),

          // Input based on type
          if (widget.criterion.inputType == 'pass_fail')
            _PassFailInput(
              value: answer?.value,
              onChanged: (v) =>
                  widget.manager.setAnswer(widget.criterion.id, value: v),
            )
          else
            _NumericInput(
              value: answer?.numericValue,
              onChanged: (v) => widget.manager.setAnswer(
                widget.criterion.id,
                numericValue: v,
              ),
            ),

          const SizedBox(height: 8),

          // CCP / RISK toggle buttons (PWA-style prominent)
          Row(
            children: [
              Expanded(
                child: _CcpRiskButton(
                  label: 'CCP',
                  icon: Icons.shield,
                  active: answer?.isCcp ?? false,
                  activeColor: theme.colorScheme.error,
                  onTap: () {
                    final newVal = !(answer?.isCcp ?? false);
                    widget.manager.setCcp(widget.criterion.id, newVal);
                    setState(() {
                      if (newVal) _showNote = true;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CcpRiskButton(
                  label: 'RISK',
                  icon: Icons.warning_amber_rounded,
                  active: answer?.isRisk ?? false,
                  activeColor: AppTheme.warning,
                  onTap: () {
                    final newVal = !(answer?.isRisk ?? false);
                    widget.manager.setRisk(widget.criterion.id, newVal);
                    setState(() {
                      if (newVal) _showNote = true;
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Action row: Note / Photo / Repeat
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Note toggle
              _ActionChip(
                icon: Icons.notes,
                label: 'Note',
                active: noteVisible,
                onTap: () => setState(() => _showNote = !_showNote),
              ),

              // Photo capture
              _ActionChip(
                icon: Icons.camera_alt_outlined,
                label: answer?.photoUrl != null ? 'Photo ✓' : 'Photo',
                active: answer?.photoUrl != null,
                onTap: () => _pickPhoto(context),
              ),

              // Repeated faults stepper (Gap 7)
              if (isNonConform || hasFaults) ...[
                const SizedBox(width: 8),
                _ToggleChip(
                  label: 'Repeat',
                  icon: Icons.repeat,
                  color: (answer?.repeatedFaultCount ?? 0) > 0
                      ? AppTheme.warning
                      : theme.colorScheme.onSurfaceVariant,
                  active: (answer?.repeatedFaultCount ?? 0) > 0,
                ),
                _RepeatStepper(
                  count: answer?.repeatedFaultCount ?? 0,
                  onChanged: (c) => widget.manager.setRepeatedFaultCount(
                    widget.criterion.id,
                    c,
                  ),
                ),
              ],
            ],
          ),

          // Note field (expandable)
          if (noteVisible) ...[
            const SizedBox(height: 8),
            TextFormField(
              initialValue: answer?.note,
              decoration: InputDecoration(
                hintText: 'Add note...',
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              maxLines: 2,
              style: theme.textTheme.bodySmall,
              onChanged: (v) => widget.manager.setNote(widget.criterion.id, v),
            ),
          ],

          // Photo preview thumbnail
          if (answer?.photoUrl != null) ...[
            const SizedBox(height: 8),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(answer!.photoUrl!),
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, e, s) => Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(Icons.broken_image_outlined, size: 24),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () =>
                        widget.manager.setPhotoUrl(widget.criterion.id, null),
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

          const SizedBox(height: 4),
          const Divider(),
        ],
      ),
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

    widget.manager.setPhotoUrl(widget.criterion.id, image.path);
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

/// Toggle chip for CCP/RISK status indicators.
class _ToggleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool active;

  const _ToggleChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? color.withAlpha(25) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: active ? color.withAlpha(120) : Colors.grey.withAlpha(60),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: active ? color : Colors.grey),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: active ? color : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tappable action chip for Note/Photo/Repeat toggles.
class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = active
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? theme.colorScheme.primaryContainer.withAlpha(120)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active
                ? theme.colorScheme.primary.withAlpha(80)
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Repeat stepper (Gap 7)
// ============================================================

class _RepeatStepper extends StatelessWidget {
  final int count;
  final ValueChanged<int> onChanged;

  const _RepeatStepper({required this.count, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: count > 0 ? () => onChanged(count - 1) : null,
          icon: const Icon(Icons.remove, size: 16),
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          padding: EdgeInsets.zero,
        ),
        Text(
          '$count',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: count > 0 ? AppTheme.warning : null,
          ),
        ),
        IconButton(
          onPressed: () => onChanged(count + 1),
          icon: const Icon(Icons.add, size: 16),
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          padding: EdgeInsets.zero,
        ),
      ],
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
  final double? value;
  final ValueChanged<double> onChanged;

  const _NumericInput({this.value, required this.onChanged});

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

    return Row(
      children: [
        Text(
          'Faults:',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 12),
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
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            _count.toInt().toString(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
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
