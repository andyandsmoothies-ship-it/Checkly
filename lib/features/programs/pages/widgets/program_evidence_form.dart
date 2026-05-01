import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// The evidence form for a single program assignment.
///
/// Owns all local form state: [_noteCtrl], [_photoPath], [_isSubmitting].
/// Calls [onSubmit] with the validated note and optional photo path on submit.
///
/// Extracted from [ProgramExecutionPage] to keep that file under 200 lines.
class ProgramEvidenceForm extends StatefulWidget {
  final String assignmentTitle;
  final Future<void> Function(String note, {String? photoPath}) onSubmit;

  const ProgramEvidenceForm({
    super.key,
    required this.assignmentTitle,
    required this.onSubmit,
  });

  @override
  State<ProgramEvidenceForm> createState() => _ProgramEvidenceFormState();
}

class _ProgramEvidenceFormState extends State<ProgramEvidenceForm> {
  final _formKey = GlobalKey<FormState>();
  final _noteCtrl = TextEditingController();
  String? _photoPath;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    // Use gallery on desktop (camera not available), camera on mobile.
    final bool isDesktop =
        !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
    final source = isDesktop ? ImageSource.gallery : ImageSource.camera;

    final xfile = await picker.pickImage(
      source: source,
      // Gotcha: image_picker params must always include resize constraints
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 80,
    );
    if (xfile == null) return;

    // Hard-cap: reject if still > 5 MB after native resize.
    const maxPhotoBytes = 5 * 1024 * 1024;
    final fileSize = await File(xfile.path).length();
    if (fileSize > maxPhotoBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo is too large. Please take a simpler picture.'),
          ),
        );
      }
      return;
    }
    setState(() => _photoPath = xfile.path);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(_noteCtrl.text.trim(), photoPath: _photoPath);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Photo picker ──
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickPhoto,
              child: _photoPath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_photoPath!),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 180,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          color: cs.onSurfaceVariant,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add Photo (optional)',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Note field ──
          TextFormField(
            controller: _noteCtrl,
            decoration: InputDecoration(
              labelText: 'Summary Note *',
              hintText: 'Describe what was done to complete this task...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            ),
            maxLines: 5,
            maxLength: 500,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Note is required';
              if (v.trim().length < 10) {
                return 'Please provide at least 10 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // ── Submit button ──
          FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(_isSubmitting ? 'Submitting…' : 'Submit Evidence'),
          ),
        ],
      ),
    );
  }
}
