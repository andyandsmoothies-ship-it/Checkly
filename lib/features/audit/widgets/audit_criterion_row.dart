import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../_shared/theme/app_theme.dart';
import '../../templates/models/template_dto.dart';
import '../manager/audit_manager.dart';
import 'audit_criterion_sheet.dart';

// ============================================================
// Criterion Row — compact list item (Bottom Sheet pattern)
// ============================================================

/// Returns true for input types that participate in scoring.
bool _isScored(String? inputType) =>
    inputType != 'text' &&
    inputType != 'single_choice' &&
    inputType != 'multi_choice';

class AuditCriterionRow extends StatelessWidget {
  final CriterionDto criterion;
  final AuditManager manager;
  final bool confirmRequired;
  final bool ccpEnabled;
  final bool riskEnabled;

  const AuditCriterionRow({
    super.key,
    required this.criterion,
    required this.manager,
    this.confirmRequired = false,
    this.ccpEnabled = true,
    this.riskEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final answer = manager.answers[criterion.id];
    final faults = (answer?.numericValue ?? 0).toInt();
    final repeats = answer?.repeatedFaultCount ?? 0;
    final isCcp = answer?.isCcp ?? false;
    final isRisk = answer?.isRisk ?? false;
    final hasNote = answer?.note != null && answer!.note!.isNotEmpty;
    final hasPhoto = answer?.photoUrl != null;
    final isConfirmed = answer?.value == 'conform';
    final isNonConform = answer?.value == 'non_conform';

    // Determine overall status
    final bool isAnswered =
        answer?.value != null || (answer?.numericValue != null);

    return InkWell(
      onTap: () => showAuditCriterionSheet(
        context,
        criterion: criterion,
        manager: manager,
        confirmRequired: confirmRequired,
        ccpEnabled: ccpEnabled,
        riskEnabled: riskEnabled,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Leading status icon
            Icon(
              isConfirmed || (isAnswered && faults == 0 && !isNonConform)
                  ? Icons.check_circle
                  : faults > 0 || isNonConform
                  ? Icons.error_outline
                  : Icons.radio_button_unchecked,
              size: 20,
              color: isConfirmed || (isAnswered && faults == 0 && !isNonConform)
                  ? AppTheme.success
                  : faults > 0 || isNonConform
                  ? theme.colorScheme.error
                  : theme.colorScheme.outlineVariant,
            ),
            const SizedBox(width: 12),

            // Label
            Expanded(
              child: Text(
                criterion.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),

            // Status badges (compact)
            Wrap(
              spacing: 4,
              children: [
                if (_isScored(criterion.inputType)) ...[
                  if (faults > 0)
                    AuditStatusBadge(
                      label: 'F:$faults',
                      color: theme.colorScheme.error,
                    ),
                  if (repeats > 0)
                    AuditStatusBadge(
                      label: 'R:$repeats',
                      color: AppTheme.warning,
                    ),
                  if (isCcp)
                    AuditStatusBadge(
                      label: 'CCP',
                      color: theme.colorScheme.error,
                    ),
                  if (isRisk)
                    AuditStatusBadge(label: 'RISK', color: AppTheme.warning),
                ],

                if (hasNote)
                  Icon(Icons.notes, size: 16, color: theme.colorScheme.primary),
                if (hasPhoto)
                  Icon(
                    Icons.camera_alt,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
              ],
            ),

            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: theme.colorScheme.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Small colored badge for status indicators on the compact row.
class AuditStatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const AuditStatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Photo capture button and preview for the bottom sheet.
class AuditPhotoSection extends StatelessWidget {
  final CriterionDto criterion;
  final AuditManager manager;

  const AuditPhotoSection({
    super.key,
    required this.criterion,
    required this.manager,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final answer = manager.answers[criterion.id];
    final hasPhoto = answer?.photoUrl != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _pickPhoto(context),
            icon: Icon(
              hasPhoto ? Icons.camera_alt : Icons.camera_alt_outlined,
              size: 18,
            ),
            label: Text(hasPhoto ? 'Change Photo' : 'Add Photo'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        if (hasPhoto) ...[
          const SizedBox(height: 8),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(answer!.photoUrl!),
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, e, s) => Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.broken_image_outlined, size: 24),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () => manager.setPhotoUrl(criterion.id, null),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _pickPhoto(BuildContext ctx) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: ctx,
      builder: (bCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(bCtx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(bCtx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 80,
    );
    if (image == null) return;

    manager.setPhotoUrl(criterion.id, image.path);
  }
}

/// Prominent CCP/RISK toggle button (PWA-style).
class AuditCcpRiskButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const AuditCcpRiskButton({
    super.key,
    required this.label,
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: active ? activeColor : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: active
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: active
                      ? Colors.white
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
