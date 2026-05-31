import 'package:flutter/material.dart';
import '../../../_shared/widgets/primitives/stroke_card.dart';

import '../../../_shared/theme/app_colors.dart';

class BlueprintSelectionModal extends StatelessWidget {
  const BlueprintSelectionModal({super.key});

  static const _blueprints = [
    (
      mode: 'penalty',
      icon: Icons.grading_outlined,
      title: 'Audit & Inspection',
      tag: 'Best for compliance',
      subtitle: 'Deduct Points (Weighted): Start with a perfect 100% score. Points are deducted for mistakes. Different sections can have different weight/importance.',
      color: BlueprintColors.audit,
    ),
    (
      mode: 'accumulation',
      icon: Icons.assignment_turned_in_outlined,
      title: 'Scored Assessment',
      tag: 'Best for evaluations',
      subtitle: 'Earn Points (Weighted): Start at 0% score. Points are earned for correct answers. Different sections can have different weight/importance.',
      color: BlueprintColors.assessment,
    ),
    (
      mode: 'accumulation_unweighted',
      icon: Icons.assignment_outlined,
      title: 'Simple Scored Assessment',
      tag: 'Best for training & quizzes',
      subtitle: 'Earn Points (Simple): Start at 0% score. Points are earned for correct answers. The final score is a simple percentage of all correct answers.',
      color: BlueprintColors.simpleAssessment,
    ),
    (
      mode: 'checklist',
      icon: Icons.fact_check_outlined,
      title: 'Basic Checklist',
      tag: 'Best for daily routines',
      subtitle: 'Deduct Points (Simple): Start with a perfect 100% score. Each failed item takes away the exact same amount of points from the total.',
      color: BlueprintColors.checklist,
    ),
    (
      mode: 'survey',
      icon: Icons.dynamic_form_outlined,
      title: 'Form & Survey',
      tag: 'Best for data collection',
      subtitle: 'No Scoring (Survey): Gather answers without calculating any score. Perfect for general feedback, notes, and custom data collection.',
      color: BlueprintColors.survey,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('What are you building?'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose a blueprint to get started with sensible defaults.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: size.width > 600
                      ? GridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.8,
                          children: _blueprints.map((bp) {
                            return _BlueprintCard(
                              icon: bp.icon,
                              title: bp.title,
                              tag: bp.tag,
                              subtitle: bp.subtitle,
                              color: bp.color,
                              onTap: () => Navigator.pop(context, bp.mode),
                            );
                          }).toList(),
                        )
                      : ListView.separated(
                          itemCount: _blueprints.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final bp = _blueprints[index];
                            return _BlueprintCard(
                              icon: bp.icon,
                              title: bp.title,
                              tag: bp.tag,
                              subtitle: bp.subtitle,
                              color: bp.color,
                              onTap: () => Navigator.pop(context, bp.mode),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BlueprintCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String tag;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _BlueprintCard({
    required this.icon,
    required this.title,
    required this.tag,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StrokeCard(
      borderColor: color.withValues(alpha: 0.3),
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tag,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
