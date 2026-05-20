import 'package:flutter/material.dart';

import '../../../_shared/theme/app_theme.dart';
import '../../../_shared/widgets/app_network_image.dart';
import '../model/action_plan_dto.dart';
import '../model/stale_conflict.dart';
import 'action_timeline.dart';
import 'flat_block.dart';
import 'info_card.dart';
import 'info_row.dart';
import '../../../_shared/widgets/section_header.dart';
import 'stale_conflict_banner.dart';

class ActionPlanDetailList extends StatelessWidget {
  final ActionPlanDto plan;
  final StaleConflict? staleConflict;
  final VoidCallback onDismissConflict;
  final bool isOverdue;

  const ActionPlanDetailList({
    super.key,
    required this.plan,
    required this.staleConflict,
    required this.onDismissConflict,
    required this.isOverdue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (staleConflict != null) ...[
          StaleConflictBanner(
            correctionPlan: staleConflict!.correctionPlan,
            evidenceNote: staleConflict!.evidenceNote,
            onDismiss: onDismissConflict,
          ),
          const SizedBox(height: 16),
        ],

        // ── Status Timeline ──
        ActionTimeline.fromPlan(plan),
        const SizedBox(height: 16),

        if (plan.rootCause == 'SYSTEM_VOID')
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
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
        InfoCard(
          children: [
            InfoRow(
              icon: Icons.label,
              label: 'Criteria',
              value: plan.criteriaLabel,
            ),
            InfoRow(
              icon: Icons.folder,
              label: 'Section',
              value: plan.groupTitle,
            ),
            if (plan.sourceTitle != null)
              InfoRow(
                icon: Icons.assignment_outlined,
                label: 'Source',
                value: plan.sourceTitle!,
              ),
            if (plan.storeName != null)
              InfoRow(
                icon: Icons.store,
                label: 'Store',
                value: plan.storeName!,
              ),
            if (plan.storeManagerName != null)
              InfoRow(
                icon: Icons.person,
                label: 'Manager',
                value: plan.storeManagerName!,
              ),
            if (plan.deadline != null)
              InfoRow(
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
        if (plan.rootCause != 'SYSTEM_VOID') ...[
          const SectionHeader(
            'Root Cause',
            variant: SectionHeaderVariant.sub,
            padding: EdgeInsets.only(bottom: 8),
          ),
          FlatBlock(
            child: Text(
              (plan.rootCause != null && plan.rootCause!.isNotEmpty)
                  ? plan.rootCause!
                  : 'No root cause identified.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: (plan.rootCause != null && plan.rootCause!.isNotEmpty)
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.8)
                    : theme.colorScheme.onSurfaceVariant,
                fontStyle:
                    (plan.rootCause != null && plan.rootCause!.isNotEmpty)
                    ? FontStyle.normal
                    : FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── Correction Plan ──
        if (plan.rootCause != 'SYSTEM_VOID') ...[
          const SectionHeader(
            'Correction Plan',
            variant: SectionHeaderVariant.sub,
            padding: EdgeInsets.only(bottom: 8),
          ),
          FlatBlock(
            child: Text(
              (plan.correctionPlan != null && plan.correctionPlan!.isNotEmpty)
                  ? plan.correctionPlan!
                  : 'No specific correction steps prescribed.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    (plan.correctionPlan != null &&
                        plan.correctionPlan!.isNotEmpty)
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.8)
                    : theme.colorScheme.onSurfaceVariant,
                fontStyle:
                    (plan.correctionPlan != null &&
                        plan.correctionPlan!.isNotEmpty)
                    ? FontStyle.normal
                    : FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── Evidence ──
        if (plan.evidenceNote != null || plan.evidencePhotoUrl != null) ...[
          const SectionHeader(
            'Evidence',
            variant: SectionHeaderVariant.sub,
            padding: EdgeInsets.only(bottom: 8),
          ),
          FlatBlock(
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
                    child: AppNetworkImage(
                      url: plan.evidencePhotoUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, s) => Container(
                        height: 100,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(child: Icon(Icons.broken_image)),
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
          const SectionHeader(
            'Verified By',
            variant: SectionHeaderVariant.sub,
            padding: EdgeInsets.only(bottom: 8),
          ),
          FlatBlock(
            child: Row(
              children: [
                Icon(Icons.verified, color: AppTheme.success, size: 18),
                const SizedBox(width: 8),
                Text(plan.verifierName!, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],

        const SizedBox(height: 32),
      ],
    );
  }
}
