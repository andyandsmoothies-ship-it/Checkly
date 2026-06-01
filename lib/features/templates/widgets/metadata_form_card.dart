import 'package:flutter/material.dart';
import 'package:checkly/_shared/widgets/primitives/stroke_card.dart';
import 'package:checkly/_shared/theme/app_colors.dart';

import '../../../_shared/widgets/section_header.dart';

import '../models/template_constants.dart';

class MetadataFormCard extends StatelessWidget {
  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final String type;
  final ValueChanged<String?> onTypeChanged;
  final String scoreDirection;
  final ValueChanged<String> onScoreDirectionChanged;
  final bool isWeighted;
  final ValueChanged<bool> onIsWeightedChanged;
  final bool isTypeLocked;

  const MetadataFormCard({
    super.key,
    required this.titleCtrl,
    required this.descCtrl,
    required this.type,
    required this.onTypeChanged,
    required this.scoreDirection,
    required this.onScoreDirectionChanged,
    required this.isWeighted,
    required this.onIsWeightedChanged,
    this.isTypeLocked = false,
  });

  Widget _buildBlueprintInfoBox(BuildContext context) {
    final (title, subtitle, icon, color) = switch (scoreDirection) {
      'none' => (
        'No Scoring (Survey)',
        'No Scoring (Survey): Gather answers without calculating any score. Perfect for general feedback, notes, and custom data collection.',
        Icons.dynamic_form_outlined,
        BlueprintColors.survey,
      ),
      'up' when isWeighted => (
        'Scored Assessment',
        'Earn Points (Weighted): Start at 0% score. Points are earned for correct answers. Different sections can have different weight/importance.',
        Icons.assignment_turned_in_outlined,
        BlueprintColors.assessment,
      ),
      'up' when !isWeighted => (
        'Simple Scored Assessment',
        'Earn Points (Simple): Start at 0% score. Points are earned for correct answers. The final score is a simple percentage of all correct answers.',
        Icons.assignment_outlined,
        BlueprintColors.simpleAssessment,
      ),
      'down' when isWeighted => (
        'Audit & Inspection',
        'Deduct Points (Weighted): Start with a perfect 100% score. Points are deducted for mistakes. Different sections can have different weight/importance.',
        Icons.grading_outlined,
        BlueprintColors.audit,
      ),
      'down' when !isWeighted => (
        'Basic Checklist',
        'Deduct Points (Simple): Start with a perfect 100% score. Each failed item takes away the exact same amount of points from the total.',
        Icons.fact_check_outlined,
        BlueprintColors.checklist,
      ),
      _ => (
        'Unknown Mode',
        'Select a scoring mode to see how it works.',
        Icons.help_outline,
        Colors.grey,
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StrokeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader('TEMPLATE METADATA'),
          const SizedBox(height: 12),
          TextFormField(
            controller: titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Template Title',
              hintText: 'e.g. Weekly Food Safety Check',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: descCtrl,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Describe what this template audits',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: () {
              final normalized = type
                  .toLowerCase()
                  .trim()
                  .replaceAll('_', ' ')
                  .replaceAll('taskforce', 'task force');
              return TemplateConstants.categoryTypes.any(
                    (t) => t.$1 == normalized,
                  )
                  ? normalized
                  : 'qc';
            }(),
            decoration: const InputDecoration(labelText: 'Category'),
            borderRadius: BorderRadius.circular(12),
            items: TemplateConstants.categoryTypes
                .map((t) => DropdownMenuItem(value: t.$1, child: Text(t.$2)))
                .toList(),
            onChanged: isTypeLocked ? null : onTypeChanged,
          ),
          if (isTypeLocked) ...[
            const SizedBox(height: 8),
            StrokeCard(
              color: AppColors.warningContainer,
              borderColor: AppColors.warningText.withValues(alpha: 0.3),
              borderRadius: 12,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warningText,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Locked to Quality Control because active Critical Control Points (CCP) or Fatal Risks are specified.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.warningText,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Score Direction',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _CustomOptionButton(
                label: 'Deduct Points',
                sublabel: 'Starts at 100%',
                icon: Icons.arrow_downward_rounded,
                isSelected: scoreDirection == 'down',
                activeColor: BlueprintColors.audit,
                onTap: () => onScoreDirectionChanged('down'),
              ),
              const SizedBox(width: 8),
              _CustomOptionButton(
                label: 'Earn Points',
                sublabel: 'Starts at 0%',
                icon: Icons.arrow_upward_rounded,
                isSelected: scoreDirection == 'up',
                activeColor: BlueprintColors.assessment,
                onTap: () => onScoreDirectionChanged('up'),
              ),
              const SizedBox(width: 8),
              _CustomOptionButton(
                label: 'No Score',
                sublabel: 'Data collection',
                icon: Icons.assignment_outlined,
                isSelected: scoreDirection == 'none',
                activeColor: BlueprintColors.survey,
                onTap: () => onScoreDirectionChanged('none'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Weighted Scoring'),
            subtitle: Text(
              scoreDirection == 'none'
                  ? '💡 Scoring is disabled for surveys.'
                  : (isWeighted
                        ? '💡 Sections and questions have different importance (weights) to calculate the score.'
                        : '💡 All sections and questions have equal importance in the final score.'),
            ),
            contentPadding: EdgeInsets.zero,
            value: scoreDirection == 'none' ? false : isWeighted,
            onChanged: scoreDirection == 'none'
                ? null
                : (val) => onIsWeightedChanged(val),
          ),
          const SizedBox(height: 8),
          _buildBlueprintInfoBox(context),
        ],
      ),
    );
  }
}

class _CustomOptionButton extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _CustomOptionButton({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    final borderColor = isSelected
        ? activeColor
        : (isLight ? AppColors.swan : AppColors.swan.withAlpha(40));

    final backgroundColor = isSelected
        ? activeColor.withValues(alpha: 0.08)
        : (isLight ? AppColors.snow : Colors.transparent);

    final textColor = isSelected
        ? activeColor
        : theme.textTheme.bodyMedium?.color;

    final iconColor = isSelected
        ? activeColor
        : theme.iconTheme.color?.withValues(alpha: 0.6);

    return Expanded(
      child: StrokeCard(
        color: backgroundColor,
        borderColor: borderColor,
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withValues(alpha: 0.12)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: isSelected
                    ? activeColor.withValues(alpha: 0.8)
                    : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
