import 'package:flutter/material.dart';
import 'package:checkly/_shared/theme/app_colors.dart';
import 'package:checkly/_shared/widgets/primitives/bubbly_button.dart';

/// Wizard Step 5 (Done): Post-save success screen.
///
/// Shows an animated checkmark, template summary, and three action buttons:
/// - View Template (navigator to detail page)
/// - Open in Template Builder (navigator to builder)
/// - Done (return to list)
class WizardStepSuccess extends StatefulWidget {
  final String templateId;
  final String templateTitle;
  final int sectionCount;
  final int criteriaCount;

  /// Navigate to the template detail page.
  final VoidCallback onViewTemplate;

  /// Navigate to the template builder for advanced editing.
  final VoidCallback onOpenBuilder;

  /// Return to the template list.
  final VoidCallback onDone;

  const WizardStepSuccess({
    super.key,
    required this.templateId,
    required this.templateTitle,
    required this.sectionCount,
    required this.criteriaCount,
    required this.onViewTemplate,
    required this.onOpenBuilder,
    required this.onDone,
  });

  @override
  State<WizardStepSuccess> createState() => _WizardStepSuccessState();
}

class _WizardStepSuccessState extends State<WizardStepSuccess>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 24),

        // Animated checkmark
        Center(
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                size: 56,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Title + subtitle
        FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              Text(
                'Template Created!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.templateTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Summary chips
        FadeTransition(
          opacity: _fadeAnim,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SummaryChip(
                icon: Icons.folder_outlined,
                label: '${widget.sectionCount} sections',
              ),
              const SizedBox(width: 12),
              _SummaryChip(
                icon: Icons.checklist,
                label: '${widget.criteriaCount} criteria',
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),

        // Action buttons
        FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Your template is ready to use. What would you like to do next?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: BubblyButton(
                  label: 'View Template',
                  color: AppColors.featherGreen,
                  onPressed: widget.onViewTemplate,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 50,
                child: BubblyButton(
                  label: 'Advanced Edit (Template Builder)',
                  color: AppColors.macaw,
                  onPressed: widget.onOpenBuilder,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: widget.onDone,
                child: const Text('Return to Templates'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SummaryChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSecondaryContainer),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
