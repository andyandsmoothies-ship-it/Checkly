import 'package:flutter/material.dart';

class BlueprintSelectionModal extends StatelessWidget {
  const BlueprintSelectionModal({super.key});

  static const _blueprints = [
    (
      mode: 'penalty',
      icon: Icons.verified_outlined,
      title: 'Compliance Audit',
      subtitle: 'Start at 100% — deduct for faults found',
      color: Color(0xFF1565C0),
    ),
    (
      mode: 'accumulation',
      icon: Icons.trending_up,
      title: 'Training Assessment',
      subtitle: 'Start at 0% — earn points for correct answers',
      color: Color(0xFF2E7D32),
    ),
    (
      mode: 'survey',
      icon: Icons.forum_outlined,
      title: 'Feedback Survey',
      subtitle: 'Collect responses without scoring',
      color: Color(0xFF7B1FA2),
    ),
    (
      mode: 'checklist',
      icon: Icons.checklist,
      title: 'Custom Checklist',
      subtitle: 'Simple pass/fail checks for daily tasks',
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
                    childAspectRatio: size.width > 600 ? 2.2 : 3.2,
                    children: _blueprints.map((bp) {
                      return _BlueprintCard(
                        icon: bp.icon,
                        title: bp.title,
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
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _BlueprintCard({
    required this.icon,
    required this.title,
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
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
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
