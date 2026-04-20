import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

import '../../../_shared/constants/app_capabilities.dart';
import '../../../_shared/services/policy_manager.dart';
import '../../../_shared/theme/app_fonts.dart';
import '../../../_shared/theme/app_theme.dart';
import '../../../_shared/widgets/unsaved_changes_guard.dart';
import '../../auth/manager/auth_manager.dart';
import '../manager/action_plan_manager.dart';
import '../model/action_plan_dto.dart';
import '../widgets/action_timeline.dart';

final _di = GetIt.instance;

/// Action Plan detail page — timeline, info, evidence, role-aware actions.
class ActionPlanDetailPage extends StatefulWidget {
  final String actionPlanId;

  const ActionPlanDetailPage({super.key, required this.actionPlanId});

  @override
  State<ActionPlanDetailPage> createState() => _ActionPlanDetailPageState();
}

class _ActionPlanDetailPageState extends State<ActionPlanDetailPage> {
  late final ActionPlanManager _manager;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _manager = _di<ActionPlanManager>();
    
    // Auto-fetch if not found in current cache (e.g. freshly generated on backend)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final exists = _manager.actionPlans.value.any((p) => p.id == widget.actionPlanId);
      if (!exists) {
        _manager.loadActionPlans();
      }
    });
  }

  String get _userName =>
      _di<AuthManager>().currentUser?.email.split('@').first ?? 'Unknown';

  // ── Submit Evidence (Store Manager) ──
  void _showSubmitEvidenceSheet(ActionPlanDto plan) {
    final correctionCtrl = TextEditingController(text: plan.correctionPlan);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        var isDirty = false;
        var isSubmitting = false;
        String? photoPath;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            // Attach listeners once on first build
            void markDirty() {
              if (!isDirty) setSheetState(() => isDirty = true);
            }

            // Use addListener carefully — only attach once
            // We track via the initial text to detect changes
            final correctionChanged =
                correctionCtrl.text != (plan.correctionPlan ?? '');
            final computedDirty = correctionChanged;

            return UnsavedChangesGuard(
              isDirty: isDirty || computedDirty,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  24 + MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(ctx).colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Submit Evidence',
                            style: Theme.of(ctx).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              if (isSubmitting) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Submission running in background')),
                                );
                              }
                              if (isDirty || computedDirty) {
                                Navigator.maybePop(ctx);
                              } else {
                                Navigator.pop(ctx);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Theme.of(ctx).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Theme.of(ctx).colorScheme.outlineVariant),
                        ),
                        child: InkWell(
                          onTap: () async {
                            final picker = ImagePicker();
                            final bool isDesktop = !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
                            final source = isDesktop ? ImageSource.gallery : ImageSource.camera;
                            final xfile = await picker.pickImage(source: source);
                            if (xfile != null) {
                              setSheetState(() {
                                photoPath = xfile.path;
                                isDirty = true;
                              });
                            }
                          },
                          child: photoPath != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(photoPath!),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 100,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo, color: Theme.of(ctx).colorScheme.onSurfaceVariant),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Upload Photo',
                                      style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: correctionCtrl,
                        decoration: InputDecoration(
                          labelText: 'Note (Action Taken)',
                          border: const OutlineInputBorder(borderSide: BorderSide.none),
                          filled: true,
                          fillColor: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                        ),
                        maxLines: 3,
                        onChanged: (_) => markDirty(),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      // H1 Fix: spinner lives inside the button; modal stays open during the call
                      FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 2,
                          backgroundColor: Theme.of(ctx).colorScheme.primary,
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setSheetState(() => isSubmitting = true);
                                try {
                                  await _callManager(
                                    () => _manager.submitEvidence(
                                      plan,
                                      correctionPlan:
                                          correctionCtrl.text.trim(),
                                      currentUserName: _userName,
                                      photoPath: photoPath,
                                    ),
                                    successMsg:
                                        'Evidence submitted — awaiting verification',
                                  );
                                  if (ctx.mounted) Navigator.pop(ctx);
                                } finally {
                                  if (ctx.mounted) {
                                    setSheetState(() => isSubmitting = false);
                                  }
                                }
                              },
                        child: isSubmitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Submit Action'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Verify & Close (Auditor / Admin) ──
  void _showVerifyDialog(ActionPlanDto plan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verify & Close'),
        content: const Text(
          'Mark this action plan as resolved? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _callManager(
                () => _manager.closePlan(plan, verifierName: _userName),
                successMsg: 'Action plan closed',
              );
            },
            child: const Text('Verify & Close'),
          ),
        ],
      ),
    );
  }

  // ── Reject (Auditor / Admin) ──
  void _showRejectDialog(ActionPlanDto plan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Evidence'),
        content: const Text(
          'Return this plan to open status? The store manager will '
          'need to resubmit evidence.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await _callManager(
                () => _manager.rejectEvidence(plan),
                successMsg: 'Evidence rejected — plan reopened',
              );
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  // ── Shared manager call wrapper ──
  Future<void> _callManager(
    Future<ActionPlanDto> Function() fn, {
    required String successMsg,
  }) async {
    setState(() => _busy = true);
    try {
      await fn();
      await _manager.loadActionPlans();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMsg)));
      }
    } on RoleGuardException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('This action requires higher permissions. Please contact your workspace administrator.')));
      }
    } catch (e) {
      // H2 Fix: Sanitise generic errors — never expose raw Dart exception strings
      // to users. Domain-specific RoleGuardException is handled above.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ── Build role-aware action bar ──
  Widget? _buildActionBar(ActionPlanDto plan) {
    if (_busy) {
      return const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final status = plan.status;
    final canSubmitEvidence = _di<PolicyManager>().can(AppCapabilities.actionPlansWrite);
    final canVerify = _di<PolicyManager>().can(AppCapabilities.actionPlansVerify);

    // Store Manager (or anyone with action_plans:write) submits evidence when open
    if (status == 'open' && canSubmitEvidence) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            onPressed: () => _showSubmitEvidenceSheet(plan),
            icon: const Icon(Icons.upload_file),
            label: const Text('Submit Evidence'),
          ),
        ),
      );
    }

    // Auditor/Admin/AM (action_plans:verify) can verify or reject when pending
    if (status == 'pending_verify' && canVerify) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide(color: Theme.of(context).colorScheme.error),
                  ),
                  onPressed: () => _showRejectDialog(plan),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () => _showVerifyDialog(plan),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Verify & Close'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return null; // No actions for this role/status combo
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: _manager,
      builder: (context, _) {
        final plan = _manager.actionPlans.value
            .cast<ActionPlanDto?>()
            .firstWhere(
              (p) => p?.id == widget.actionPlanId,
              orElse: () => null,
            );

        if (plan == null) {
          if (_manager.isLoading) {
            return Scaffold(
              appBar: AppBar(title: const Text('Action Plan')),
              body: const Center(child: CircularProgressIndicator()),
            );
          }
          return Scaffold(
            appBar: AppBar(title: const Text('Action Plan')),
            body: const Center(child: Text('Action plan not found')),
          );
        }

        final isOverdue = ActionPlanManager.isOverdue(
          plan,
          now: DateTime.now(),
        );

        return Scaffold(
          appBar: AppBar(title: const Text('Action Plan')),
          bottomNavigationBar: _buildActionBar(plan),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Status Timeline ──
              ActionTimeline.fromPlan(plan),
              const SizedBox(height: 16),

              if (plan.rootCause == 'SYSTEM_VOID')
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This action plan was automatically closed because the parent audit was voided.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),

              // ── Info Section ──
              _InfoCard(
                children: [
                  _InfoRow(
                    icon: Icons.label,
                    label: 'Criteria',
                    value: plan.criteriaLabel,
                  ),
                  _InfoRow(
                    icon: Icons.folder,
                    label: 'Section',
                    value: plan.groupTitle,
                  ),
                  if (plan.storeName != null)
                    _InfoRow(
                      icon: Icons.store,
                      label: 'Store',
                      value: plan.storeName!,
                    ),
                  if (plan.storeManagerName != null)
                    _InfoRow(
                      icon: Icons.person,
                      label: 'Manager',
                      value: plan.storeManagerName!,
                    ),
                  if (plan.deadline != null)
                    _InfoRow(
                      icon: Icons.schedule,
                      label: 'Deadline',
                      value:
                          '${plan.deadline!.day}/${plan.deadline!.month}/${plan.deadline!.year}',
                      valueColor: isOverdue ? theme.colorScheme.error : null,
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Root Cause ──
              if (plan.rootCause != null &&
                  plan.rootCause!.isNotEmpty &&
                  plan.rootCause != 'SYSTEM_VOID') ...[
                _SectionHeader(title: 'Root Cause'),
                _FlatBlock(
                  child: Text(
                    plan.rootCause!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Correction Plan ──
              if (plan.correctionPlan != null &&
                  plan.correctionPlan!.isNotEmpty) ...[
                _SectionHeader(title: 'Correction Plan'),
                _FlatBlock(
                  child: Text(
                    plan.correctionPlan!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Evidence ──
              if (plan.evidenceNote != null ||
                  plan.evidencePhotoUrl != null) ...[
                _SectionHeader(title: 'Evidence'),
                _FlatBlock(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (plan.evidenceNote != null)
                        Text(
                          plan.evidenceNote!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                      if (plan.evidencePhotoUrl != null) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: plan.evidencePhotoUrl!.startsWith('/') || plan.evidencePhotoUrl!.startsWith('file://')
                              ? Image.file(
                                  File(plan.evidencePhotoUrl!),
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  plan.evidencePhotoUrl!,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, e, s) => Container(
                                    height: 100,
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    child: const Center(
                                      child: Icon(Icons.broken_image),
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Verifier ──
              if (plan.verifierName != null) ...[
                _SectionHeader(title: 'Verified By'),
                _FlatBlock(
                  child: Row(
                    children: [
                      Icon(Icons.verified, color: AppTheme.success, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        plan.verifierName!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

// ── Info Card ──

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: children),
      ),
    );
  }
}

// ── Flat Block (replaces Card for read-only data sections) ──
// Renders content flush on the page surface with a subtle left accent border.
class _FlatBlock extends StatelessWidget {
  final Widget child;
  const _FlatBlock({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 0, 4),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 3,
          ),
        ),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: AppFonts.serifStyle(
          fontSize: 18,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
