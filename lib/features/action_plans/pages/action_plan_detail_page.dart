import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../_shared/theme/app_theme.dart';
import '../manager/action_plan_manager.dart';
import '../model/action_plan_dto.dart';
import '../widgets/action_timeline.dart';

final _di = GetIt.instance;

/// Action Plan detail page — timeline, info, evidence, role-aware actions.
class ActionPlanDetailPage extends StatelessWidget {
  final String actionPlanId;

  const ActionPlanDetailPage({super.key, required this.actionPlanId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final manager = _di<ActionPlanManager>();

    return ListenableBuilder(
      listenable: manager,
      builder: (context, _) {
        final plan = manager.actionPlans.value
            .cast<ActionPlanDto?>()
            .firstWhere((p) => p?.id == actionPlanId, orElse: () => null);

        if (plan == null) {
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
          appBar: AppBar(title: Text(plan.criteriaLabel)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Status Timeline ──
              ActionTimeline.fromStatus(plan.status),
              const SizedBox(height: 24),

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
              if (plan.rootCause != null && plan.rootCause!.isNotEmpty) ...[
                _SectionHeader(title: 'Root Cause'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      plan.rootCause!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Correction Plan ──
              if (plan.correctionPlan != null &&
                  plan.correctionPlan!.isNotEmpty) ...[
                _SectionHeader(title: 'Correction Plan'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      plan.correctionPlan!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Evidence ──
              if (plan.evidenceNote != null ||
                  plan.evidencePhotoUrl != null) ...[
                _SectionHeader(title: 'Evidence'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (plan.evidenceNote != null)
                          Text(
                            plan.evidenceNote!,
                            style: theme.textTheme.bodyMedium,
                          ),
                        if (plan.evidencePhotoUrl != null) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              plan.evidencePhotoUrl!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                height: 100,
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
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
                ),
                const SizedBox(height: 16),
              ],

              // ── Verifier ──
              if (plan.verifierName != null) ...[
                _SectionHeader(title: 'Verified By'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.verified, color: AppTheme.success),
                        const SizedBox(width: 8),
                        Text(
                          plan.verifierName!,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
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
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
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
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
