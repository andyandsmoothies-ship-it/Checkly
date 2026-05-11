import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../_shared/theme/app_fonts.dart';
import '../../../_shared/theme/app_theme.dart';
import '../../../_shared/widgets/unsaved_changes_guard.dart';
import '../../../_shared/exceptions/app_error.dart';
import '../../../_shared/services/error_display_service.dart';
import '../services/admin_api_service.dart';

class AreaCreateSheet extends StatefulWidget {
  final VoidCallback onSuccess;

  const AreaCreateSheet({super.key, required this.onSuccess});

  @override
  State<AreaCreateSheet> createState() => _AreaCreateSheetState();
}

class _AreaCreateSheetState extends State<AreaCreateSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isDirty = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    if (name.isEmpty) {
      GetIt.I<ErrorDisplayService>().show(
        const AppError(
          code: 'validation_error',
          message: 'Area name is required',
        ),
      );
      return;
    }
    try {
      await GetIt.I<AdminApiService>().createArea(
        name: name,
        description: desc.isNotEmpty ? desc : null,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Area created'),
            backgroundColor: AppTheme.success,
          ),
        );
        widget.onSuccess();
      }
    } on DioException catch (e) {
      if (mounted) {
        GetIt.I<ErrorDisplayService>().show(AppError.fromDioException(e));
      }
    } catch (e) {
      if (mounted) {
        GetIt.I<ErrorDisplayService>().show(const AppError(code: 'unknown'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return UnsavedChangesGuard(
      isDirty: _isDirty,
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
                  'New Area',
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
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Area Name *',
                hintText: 'e.g. Mekong Delta',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => _markDirty(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Optional description of this area',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => _markDirty(),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _save, child: const Text('Create Area')),
          ],
        ),
      ),
    );
  }
}

class AreaEditSheet extends StatefulWidget {
  final Map<String, dynamic> area;
  final VoidCallback onSuccess;

  const AreaEditSheet({super.key, required this.area, required this.onSuccess});

  @override
  State<AreaEditSheet> createState() => _AreaEditSheetState();
}

class _AreaEditSheetState extends State<AreaEditSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: widget.area['name'] as String? ?? '',
    );
    _descCtrl = TextEditingController(
      text: widget.area['description'] as String? ?? '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    if (name.isEmpty) {
      GetIt.I<ErrorDisplayService>().show(
        const AppError(code: 'validation_error', message: 'Name is required'),
      );
      return;
    }
    try {
      await GetIt.I<AdminApiService>().updateArea(
        widget.area['id'] as String,
        name: name,
        description: desc,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Area updated'),
            backgroundColor: AppTheme.success,
          ),
        );
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        if (e is DioException) {
          GetIt.I<ErrorDisplayService>().show(AppError.fromDioException(e));
        } else {
          GetIt.I<ErrorDisplayService>().show(const AppError(code: 'unknown'));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return UnsavedChangesGuard(
      isDirty: _isDirty,
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
                  'Edit Area',
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
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Area Name *',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => _markDirty(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => _markDirty(),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _save, child: const Text('Save Changes')),
          ],
        ),
      ),
    );
  }
}
