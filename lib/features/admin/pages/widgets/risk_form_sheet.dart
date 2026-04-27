import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../_shared/theme/app_theme.dart';
import '../../../../_shared/theme/app_fonts.dart';
import '../../../../_shared/widgets/unsaved_changes_guard.dart';
import '../../services/admin_api_service.dart';

final _di = GetIt.instance;

void showRiskFormSheet({
  required BuildContext context,
  Map<String, dynamic>? risk,
  required VoidCallback onSaved,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    isDismissible: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => RiskFormSheet(risk: risk, onSaved: onSaved),
  );
}

class RiskFormSheet extends StatefulWidget {
  final Map<String, dynamic>? risk;
  final VoidCallback onSaved;

  const RiskFormSheet({super.key, this.risk, required this.onSaved});

  @override
  State<RiskFormSheet> createState() => _RiskFormSheetState();
}

class _RiskFormSheetState extends State<RiskFormSheet> {
  late final TextEditingController _labelCtrl;
  late final TextEditingController _descCtrl;
  late final bool isEdit;
  late final bool isActive;
  bool isDirty = false;

  @override
  void initState() {
    super.initState();
    isEdit = widget.risk != null;
    isActive = widget.risk?['isActive'] as bool? ?? true;
    _labelCtrl = TextEditingController(
      text: widget.risk?['label'] as String? ?? '',
    );
    _descCtrl = TextEditingController(
      text: widget.risk?['description'] as String? ?? '',
    );
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void markDirty() {
    if (!isDirty) {
      setState(() => isDirty = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return UnsavedChangesGuard(
      isDirty: isDirty,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          24,
          16,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit ? 'Edit Global Risk' : 'New Global Risk',
                  style: AppFonts.displayStyle(
                    fontSize: Theme.of(context).textTheme.titleLarge?.fontSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.maybePop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _labelCtrl,
              decoration: InputDecoration(
                labelText: 'Risk Label *',
                hintText: isEdit ? null : 'e.g. Critical Food Safety Violation',
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => markDirty(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: isEdit
                    ? null
                    : 'When should an auditor trigger this risk?',
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => markDirty(),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () async {
                final label = _labelCtrl.text.trim();
                final desc = _descCtrl.text.trim();

                if (isEdit) {
                  if (label.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Label is required')),
                    );
                    return;
                  }
                  try {
                    await _di<AdminApiService>().updateGlobalRisk(
                      widget.risk!['id'] as String,
                      label: label,
                      description: desc,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Global risk updated'),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                      widget.onSaved();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'An unexpected issue occurred. Please check your connection.',
                          ),
                        ),
                      );
                    }
                  }
                } else {
                  if (label.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Risk label is required')),
                    );
                    return;
                  }
                  try {
                    await _di<AdminApiService>().createGlobalRisk(
                      label: label,
                      description: desc.isNotEmpty ? desc : null,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Global risk created'),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                      widget.onSaved();
                    }
                  } on DioException catch (e) {
                    if (context.mounted) {
                      final msg =
                          e.response?.data?['message'] ??
                          'Failed to create global risk';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(msg.toString()),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                  }
                }
              },
              child: Text(isEdit ? 'Save Changes' : 'Create Risk'),
            ),
            if (isEdit && isActive) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(color: Theme.of(context).colorScheme.error),
                ),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogCtx) => AlertDialog(
                      title: const Text('Deactivate Risk?'),
                      content: const Text(
                        'This risk will no longer appear during new audits. '
                        'Historical audit data referencing this risk will not be affected.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogCtx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(dialogCtx).pop(true),
                          child: Text(
                            'Deactivate',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    try {
                      await _di<AdminApiService>().deleteGlobalRisk(
                        widget.risk!['id'] as String,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Risk deactivated')),
                        );
                        widget.onSaved();
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'An unexpected issue occurred. Please check your connection.',
                            ),
                          ),
                        );
                      }
                    }
                  }
                },
                child: const Text('Deactivate Risk'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
