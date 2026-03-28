import 'package:flutter/material.dart';

class BlueprintSelectionModal extends StatelessWidget {
  const BlueprintSelectionModal({super.key});

  static const _blueprints = [
    (
      mode: 'penalty',
      icon: Icons.grading_outlined,
      title: 'Audit & Inspection',
      tag: 'Best for compliance',
      subtitle: 'Starts at 100% and deducts points for every fault found.',
      color: Color(0xFF1565C0),
    ),
    (
      mode: 'accumulation',
      icon: Icons.assignment_turned_in_outlined,
      title: 'Scored Assessment',
      tag: 'Best for evaluations',
      subtitle: 'Builds from zero by earning points for each success.',
      color: Color(0xFF2E7D32),
    ),
    (
      mode: 'survey',
      icon: Icons.dynamic_form_outlined,
      title: 'Form & Survey',
      tag: 'Best for data collection',
      subtitle: 'Captures responses with no scores or grades calculated.',
      color: Color(0xFF7B1FA2),
    ),
    (
      mode: 'checklist',
      icon: Icons.fact_check_outlined,
      title: 'Basic Checklist',
      tag: 'Best for daily routines',
      subtitle: 'Simple pass/fail checks with a completion report.',
      color: Color(0xFFE65100),
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
                  child: GridView.count(
                    crossAxisCount: size.width > 600 ? 2 : 1,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: size.width > 600 ? 1.8 : 2.6,
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

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                      maxLines: 2,
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
        ),
      ),
    );
  }
}
