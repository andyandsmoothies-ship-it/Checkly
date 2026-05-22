import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import '../../../_shared/widgets/primitives/stroke_card.dart';
import '../../../_shared/theme/app_theme.dart';
import '../model/action_plan_dto.dart';

/// Step status for the action plan timeline.
enum TimelineStepStatus { done, current, pending }

/// A single timeline step.
class TimelineStep {
  final String title;
  final String? subtitle;
  final TimelineStepStatus status;

  const TimelineStep({
    required this.title,
    this.subtitle,
    required this.status,
  });
}

/// Vertical 3-step timeline for action plan progression:
///   Identified → Evidence Submitted → Verified & Closed.
///
/// Colors: green=done, blue=current, grey=pending.
class ActionTimeline extends StatelessWidget {
  final List<TimelineStep> steps;

  const ActionTimeline({super.key, required this.steps});

  /// Convenience factory from action plan DTO.
  factory ActionTimeline.fromPlan(ActionPlanDto plan) {
    final steps = <TimelineStep>[];
    TimelineStepStatus s1, s2, s3;

    switch (plan.status.toLowerCase()) {
      case 'closed' || 'verified':
        s1 = TimelineStepStatus.done;
        s2 = TimelineStepStatus.done;
        s3 = TimelineStepStatus.done;
      case 'pending_verify':
        s1 = TimelineStepStatus.done;
        s2 = TimelineStepStatus.done;
        s3 = TimelineStepStatus.current;
      case 'open':
      default:
        s1 = TimelineStepStatus.done;
        s2 = TimelineStepStatus.current;
        s3 = TimelineStepStatus.pending;
    }

    String fmt(DateTime d) =>
        DateFormat('MMM d, yyyy h:mm a').format(d.toLocal());

    steps.addAll([
      TimelineStep(
        title: 'Identified',
        subtitle: plan.sourceTitle != null
            ? "${plan.sourceTitle} · ${fmt(plan.createdAt)}"
            : fmt(plan.createdAt),
        status: s1,
      ),
      TimelineStep(
        title: 'Evidence Submitted',
        subtitle: plan.evidenceSubmittedAt != null
            ? "by ${plan.evidenceSubmittedByName ?? 'Unknown'} · ${fmt(plan.evidenceSubmittedAt!)}"
            : null,
        status: s2,
      ),
      TimelineStep(
        title: 'Verified & Closed',
        subtitle: plan.closedAt != null
            ? "by ${plan.verifierName ?? 'Unknown'} · ${fmt(plan.closedAt!)}"
            : null,
        status: s3,
      ),
    ]);

    return ActionTimeline(steps: steps);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StrokeCard(
      color: theme.colorScheme.surfaceContainer,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < steps.length; i++) ...[
            _TimelineRow(step: steps[i], isLast: i == steps.length - 1),
          ],
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final TimelineStep step;
  final bool isLast;

  const _TimelineRow({required this.step, required this.isLast});

  Color _dotColor(ThemeData theme) => switch (step.status) {
    TimelineStepStatus.done => AppTheme.success,
    TimelineStepStatus.current => AppTheme.info,
    TimelineStepStatus.pending => theme.colorScheme.outlineVariant,
  };

  IconData _dotIcon() => switch (step.status) {
    TimelineStepStatus.done => Icons.check_circle,
    TimelineStepStatus.current => Icons.radio_button_checked,
    TimelineStepStatus.pending => Icons.radio_button_off,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _dotColor(theme);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + connecting line
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Icon(_dotIcon(), color: color, size: 22),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: color.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Text
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: step.status == TimelineStepStatus.current
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: step.status == TimelineStepStatus.pending
                          ? theme.colorScheme.onSurfaceVariant
                          : null,
                    ),
                  ),
                  if (step.subtitle != null)
                    Text(
                      step.subtitle!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
