import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

import '../../../_shared/exceptions/app_error.dart';
import '../../../_shared/services/error_display_service.dart';
import '../../../_shared/widgets/app_network_image.dart';
import '../../templates/models/template_dto.dart';
import '../manager/audit_manager.dart';

final _di = GetIt.instance;

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
                child: AppNetworkImage(
                  url: answer!.photoUrl!,
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
    try {
      final image = await picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 80,
      );
      if (image == null) return;

      manager.setPhotoUrl(criterion.id, image.path);
    } catch (e) {
      if (!ctx.mounted) return;

      // Handle the Windows/Desktop missing camera delegate error
      if (e is StateError && e.message.contains('cameraDelegate')) {
        _di<ErrorDisplayService>().show(
          const AppError(
            code: 'camera_unsupported',
            message:
                'Camera capture is not supported on this device natively. Please use "Choose from Gallery" instead.',
          ),
        );
      } else {
        _di<ErrorDisplayService>().show(
          AppError(code: 'photo_failed', message: 'Failed to pick image: $e'),
        );
      }
    }
  }
}
