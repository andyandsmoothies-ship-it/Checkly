import 'package:flutter/material.dart';

import '../../../_shared/theme/app_fonts.dart';
import '../models/editable_criterion.dart';
import 'criterion_editor_drawer.dart';
import 'input_type_bottom_sheet.dart';

class CriterionEditor extends StatelessWidget {
  final EditableCriterion criterion;
  final List<String> errors;
  final String? scoringMode; // optional — filters input type bottom sheet
  final bool globalCcpEnabled; // gates CCP toggle visibility
  final bool globalRiskEnabled; // gates Risk toggle visibility
  final bool globalConfirmRequired; // when true, locks Required toggle ON

  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const CriterionEditor({
    super.key,
    required this.criterion,
    this.errors = const [],
    this.scoringMode,
    this.globalCcpEnabled = false,
    this.globalRiskEnabled = false,
    this.globalConfirmRequired = false,
    required this.onRemove,
    required this.onChanged,
  });

  void _openDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (_) => CriterionEditorDrawer(
        criterion: criterion,
        scoringMode: scoringMode,
        globalCcpEnabled: globalCcpEnabled,
        globalRiskEnabled: globalRiskEnabled,
        globalConfirmRequired: globalConfirmRequired,
        onChanged: onChanged,
        onRequestRebuild: () {
          Navigator.pop(context);
          Future.microtask(() {
            if (context.mounted) _openDrawer(context);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasErrors = errors.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMainRow(context, theme, hasErrors),
          if (hasErrors) _buildErrorMessages(theme),
        ],
      ),
    );
  }

  Widget _buildMainRow(BuildContext context, ThemeData theme, bool hasErrors) {
    return InkWell(
      onTap: () => _openDrawer(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: hasErrors
              ? theme.colorScheme.errorContainer.withValues(alpha: 0.3)
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: hasErrors
              ? Border.all(color: theme.colorScheme.error, width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.drag_indicator,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    criterion.labelCtrl.text.isEmpty
                        ? 'Untitled criterion'
                        : criterion.labelCtrl.text,
                    style: TextStyle(
                      fontSize: theme.textTheme.bodySmall?.fontSize,
                      color: criterion.labelCtrl.text.isEmpty
                          ? theme.colorScheme.onSurfaceVariant
                          : null,
                      fontStyle: criterion.labelCtrl.text.isEmpty
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (criterion.pointsCtrl.text.isNotEmpty &&
                          scoringMode != 'survey' &&
                          criterion.inputType != 'text' &&
                          criterion.inputType != 'single_choice' &&
                          criterion.inputType != 'multi_choice') ...[
                        Text(
                          '${criterion.pointsCtrl.text}pt',
                          style: AppFonts.serifStyle(
                            fontSize: theme.textTheme.labelSmall?.fontSize,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              inputTypeIcon(criterion.inputType),
                              size: 10,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              inputTypeLabel(criterion.inputType).toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Inline delete — PWA parity
            IconButton(
              onPressed: onRemove,
              icon: Icon(
                Icons.delete_outline,
                size: 18,
                color: theme.colorScheme.error,
              ),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessages(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: errors
            .map(
              (msg) => Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 12,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      msg,
                      style: TextStyle(
                        fontSize: theme.textTheme.labelSmall?.fontSize,
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}
