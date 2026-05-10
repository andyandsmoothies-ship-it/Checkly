import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';

import '../../../../_shared/constants/app_capabilities.dart';
import '../../../../_shared/services/policy_manager.dart';
import '../../../../_shared/theme/app_theme.dart';
import '../../../../_shared/utils/date_format_utils.dart';
import '../manager/template_manager.dart';
import '../models/template_dto.dart';
import 'type_badge.dart';

class TemplateCard extends StatelessWidget {
  final TemplateDto template;

  const TemplateCard({super.key, required this.template});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final policy = GetIt.instance<PolicyManager>();
    final canStart = policy.can(AppCapabilities.submissionsCreate);
    final canEdit = policy.can(AppCapabilities.templatesUpdate);
    final canDelete = policy.can(AppCapabilities.templatesDelete);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/templates/${template.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.assignment, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        TypeBadge(type: template.type),
                        const SizedBox(width: 8),
                        Text(
                          'v${template.version}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (!template.isActive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.softPeach,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'DRAFT',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Updated time (Fix 2)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Updated ${timeAgo(template.updatedAt)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Context menu
              PopupMenuButton<String>(
                tooltip: '',
                icon: Icon(
                  Icons.more_vert,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onSelected: (action) {
                  switch (action) {
                    case 'start':
                      context.push('/stores/select?templateId=${template.id}');
                    case 'edit':
                      context.push('/templates/edit/${template.id}');
                    case 'duplicate':
                      () async {
                        try {
                          final cloned = await GetIt.instance<TemplateManager>()
                              .duplicateTemplate(template.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "'${cloned.title}' created as draft",
                                ),
                              ),
                            );
                          }
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Could not duplicate template. Please try again.',
                                ),
                              ),
                            );
                          }
                        }
                      }();
                    case 'delete':
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Template'),
                          content: Text(
                            'Delete "${template.title}"? This cannot be undone.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                try {
                                  await GetIt.instance<TemplateManager>()
                                      .deleteTemplate(template.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Template deleted'),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'We hit a snag removing this item. If it remains stuck on your screen, please restart the app.',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                  }
                },
                itemBuilder: (context) => [
                  if (canStart)
                    const PopupMenuItem(
                      value: 'start',
                      child: ListTile(
                        leading: Icon(Icons.play_arrow),
                        title: Text('Quick Start'),
                        dense: true,
                      ),
                    ),
                  if (canEdit) ...[
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit'),
                        dense: true,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: ListTile(
                        leading: Icon(Icons.copy),
                        title: Text('Duplicate'),
                        dense: true,
                      ),
                    ),
                  ],
                  if (canDelete)
                    PopupMenuItem(
                      value: 'delete',
                      child: Builder(
                        builder: (ctx) {
                          final errorColor = Theme.of(ctx).colorScheme.error;
                          return ListTile(
                            leading: Icon(
                              Icons.delete_outline,
                              color: errorColor,
                            ),
                            title: Text(
                              'Delete',
                              style: TextStyle(color: errorColor),
                            ),
                            dense: true,
                          );
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
