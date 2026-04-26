import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../_shared/widgets/unsaved_changes_guard.dart';
import '../manager/action_plan_manager.dart';
import '../model/action_plan_dto.dart';

/// Bottom sheet that lets the Store Manager submit corrective evidence.
///
/// Owns all local form state: [isDirty], [isSubmitting], [photoPath],
/// [_correctionCtrl], and [_formKey]. The [_callManager] logic is
/// inlined here because it is the only call site within this widget.
class SubmitEvidenceSheet extends StatefulWidget {
  final ActionPlanDto plan;
  final ActionPlanManager manager;
  final String currentUserName;

  const SubmitEvidenceSheet({
    super.key,
    required this.plan,
    required this.manager,
    required this.currentUserName,
  });

  @override
  State<SubmitEvidenceSheet> createState() => _SubmitEvidenceSheetState();
}

class _SubmitEvidenceSheetState extends State<SubmitEvidenceSheet> {
  late final TextEditingController _correctionCtrl;
  final _formKey = GlobalKey<FormState>();

  var _isDirty = false;
  var _isSubmitting = false;
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    _correctionCtrl = TextEditingController(text: widget.plan.evidenceNote);
  }

  @override
  void dispose() {
    _correctionCtrl.dispose();
    super.dispose();
  }

  bool get _computedDirty =>
      _correctionCtrl.text.isNotEmpty || _photoPath != null;

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.manager.submitEvidence(
        widget.plan,
        correctionPlan: widget.plan.correctionPlan ?? '',
        evidenceNote: _correctionCtrl.text.trim(),
        currentUserName: widget.currentUserName,
        photoPath: _photoPath,
      );
      await widget.manager.loadActionPlans();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evidence submitted — awaiting verification'),
          ),
        );
        // Clear dirty state so PopScope.canPop flips to true.
        // Pop is deferred to the NEXT frame via addPostFrameCallback.
        // setState() only schedules a rebuild — it does not flush synchronously.
        // If Navigator.pop fires in the same frame, PopScope still reads the
        // OLD canPop=false and silently blocks the close.
        setState(() {
          _isDirty = false;
          _photoPath = null;
          _correctionCtrl.clear();
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.pop(context);
        });
      }
    } on RoleGuardException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This action requires higher permissions. Please contact your workspace administrator.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return UnsavedChangesGuard(
      isDirty: _isDirty || _computedDirty,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Submit Evidence',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      if (_isSubmitting) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Submission running in background'),
                          ),
                        );
                      }
                      if (_isDirty || _computedDirty) {
                        Navigator.maybePop(context);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: InkWell(
                  onTap: () async {
                    final picker = ImagePicker();
                    final bool isDesktop =
                        !kIsWeb &&
                        (Platform.isWindows ||
                            Platform.isMacOS ||
                            Platform.isLinux);
                    final source = isDesktop
                        ? ImageSource.gallery
                        : ImageSource.camera;
                    final xfile = await picker.pickImage(
                      source: source,
                      maxWidth: 1280,
                      maxHeight: 1280,
                      imageQuality: 80,
                    );
                    if (xfile == null) return;

                    // Rule 1.3: Hard-cap fallback — reject if still > 5 MB after native resize.
                    const maxPhotoBytes = 5 * 1024 * 1024; // 5 MB
                    final fileSize = await File(xfile.path).length();
                    if (fileSize > maxPhotoBytes) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Photo is too complex to compress. Please take a simpler picture.',
                            ),
                          ),
                        );
                      }
                      return;
                    }

                    setState(() {
                      _photoPath = xfile.path;
                      _isDirty = true;
                    });
                  },
                  child: _photoPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_photoPath!),
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: 200,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Upload Photo',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _correctionCtrl,
                decoration: InputDecoration(
                  labelText: 'Note (Action Taken)',
                  border: const OutlineInputBorder(borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                ),
                maxLines: 3,
                onChanged: (_) => _markDirty(),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              // H1 Fix: spinner lives inside the button; modal stays open during the call
              FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 2,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Submit Action'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
