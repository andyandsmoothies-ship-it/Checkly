import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:checkly/_shared/theme/app_colors.dart';
import 'package:checkly/_shared/widgets/primitives/bubbly_button.dart';
import '../../../_shared/exceptions/app_error.dart';
import '../../../_shared/services/error_display_service.dart';
import '../manager/user_group_manager.dart';

class CreateGroupSheet extends StatefulWidget {
  final UserGroupManager manager;
  const CreateGroupSheet({super.key, required this.manager});

  @override
  State<CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<CreateGroupSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Create User Group',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Group Name *',
                hintText: 'e.g. Northern Region Auditors',
              ),
              textInputAction: TextInputAction.next,
              maxLength: 200,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Group name is required.';
                }
                if (v.trim().length > 200) {
                  return 'Name must not exceed 200 characters.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Brief description of this group',
              ),
              textInputAction: TextInputAction.done,
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: BubblyButton(
                label: 'Create Group',
                color: AppColors.featherGreen,
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final name = _nameCtrl.text.trim();
    final desc = _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim();

    final success = await widget.manager.createGroup(name, desc);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Group "$name" created.')));
    } else {
      GetIt.instance<ErrorDisplayService>().show(
        AppError(
          code: 'unknown',
          message: widget.manager.error ?? 'Failed to create group.',
        ),
      );
    }
  }
}
