import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../_shared/exceptions/app_error.dart';
import '../../../../_shared/services/error_display_service.dart';
import '../../../../_shared/constants/app_capabilities.dart';
import '../../../../_shared/services/policy_manager.dart';
import '../../../../_shared/theme/app_colors.dart';
import '../../../../_shared/utils/date_format_utils.dart';
import '../../../../_shared/widgets/primitives/primitives.dart';
import '../manager/template_manager.dart';
import '../models/template_dto.dart';
import 'type_badge.dart';

/// Card widget representing an audit template.
/// Refactored to utilize the [UniversalListCard] primitive.
class TemplateCard extends StatelessWidget {
  final TemplateDto template;

  const TemplateCard({super.key, required this.template});

  Future<void> _handleDuplicate(BuildContext context) async {
    try {
      final cloned = await GetIt.instance<TemplateManager>().duplicateTemplate(
        template.id,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("'${cloned.title}' created as draft")),
        );
      }
    } on DioException catch (e) {
      if (context.mounted) {
        GetIt.instance<ErrorDisplayService>().show(
          AppError.fromDioException(e),
        );
      }
    } catch (_) {
      if (context.mounted) {
        GetIt.instance<ErrorDisplayService>().show(
          const AppError(
            code: 'unknown',
            message: 'Could not duplicate template. Please try again.',
          ),
        );
      }
    }
  }

  Future<void> _handleDelete(BuildContext context) async {
    showDialog(
      context: context,
      builder: (ctx) => BubblyDialog(
        title: const Text('Delete Template'),
        content: Text('Delete "${template.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.maybePop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                color: AppColors.wolf,
              ),
            ),
          ),
          SizedBox(
            width: 100,
            height: 40,
            child: BubblyButton(
              label: 'Delete',
              color: AppColors.cardinal,
              height: 36,
              onPressed: () async {
                Navigator.maybePop(ctx);
                try {
                  await GetIt.instance<TemplateManager>().deleteTemplate(
                    template.id,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Template deleted')),
                    );
                  }
                } on DioException catch (e) {
                  if (context.mounted) {
                    GetIt.instance<ErrorDisplayService>().show(
                      AppError.fromDioException(e),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    GetIt.instance<ErrorDisplayService>().show(
                      const AppError(
                        code: 'unknown',
                        message: 'Could not delete template. Please try again.',
                      ),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextMenu(BuildContext context, bool canEdit, bool canDelete) {
    return PopupMenuButton<String>(
      tooltip: '',
      icon: const Icon(Icons.more_vert, color: AppColors.wolf),
      onSelected: (action) {
        switch (action) {
          case 'edit':
            context.push('/templates/edit/${template.id}');
          case 'duplicate':
            _handleDuplicate(context);
          case 'delete':
            _handleDelete(context);
        }
      },
      itemBuilder: (context) => [
        if (canEdit) ...[
          const PopupMenuItem(
            value: 'edit',
            child: ListTile(
              leading: Icon(Icons.edit, color: AppColors.macaw),
              title: Text(
                'Edit',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.bold,
                ),
              ),
              dense: true,
            ),
          ),
          const PopupMenuItem(
            value: 'duplicate',
            child: ListTile(
              leading: Icon(Icons.copy, color: AppColors.macaw),
              title: Text(
                'Duplicate',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.bold,
                ),
              ),
              dense: true,
            ),
          ),
        ],
        if (canDelete)
          PopupMenuItem(
            value: 'delete',
            child: Builder(
              builder: (ctx) {
                return const ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    color: AppColors.cardinal,
                  ),
                  title: Text(
                    'Delete',
                    style: TextStyle(
                      color: AppColors.cardinal,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  dense: true,
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final policy = GetIt.instance<PolicyManager>();
    final canEdit = policy.can(AppCapabilities.templatesUpdate);
    final canDelete = policy.can(AppCapabilities.templatesDelete);

    return UniversalListCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => context.push('/templates/${template.id}'),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.seaSponge,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.turtle, width: 2),
        ),
        child: const Icon(Icons.assignment, color: AppColors.macaw, size: 20),
      ),
      title: template.title,
      subtitleWidget: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TypeBadge(type: template.type),
                if (!template.isActive) ...[
                  const SizedBox(width: 8),
                  const PillChip(label: 'DRAFT', type: PillChipType.yellow),
                ],
                const SizedBox(width: 8),
                Text(
                  'v${template.version}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    color: AppColors.wolf,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Updated ${timeAgo(template.updatedAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'Nunito',
                color: AppColors.wolf,
              ),
            ),
          ],
        ),
      ),
      trailing: (canEdit || canDelete)
          ? _buildContextMenu(context, canEdit, canDelete)
          : null,
    );
  }
}
