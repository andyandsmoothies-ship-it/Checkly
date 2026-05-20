import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../../_shared/exceptions/app_error.dart';
import '../../../_shared/services/error_display_service.dart';

import '../../../_shared/theme/app_fonts.dart';
import '../../../_shared/theme/app_theme.dart';
import '../../audit/model/create_submission_request.dart';
import '../../audit/services/submission_api_service.dart';
import '../manager/admin_audit_manager.dart';
import '../widgets/dropdown_card.dart';
import 'schedule_audit_date_picker.dart';
import 'schedule_audit_form_logic.dart';

final _di = GetIt.instance;

/// Reusable form for scheduling (delegating) audits.
/// Used both in the standalone [ScheduleAuditPage] and as a bottom sheet
/// from the FAB speed-dial on the Audits page.
class ScheduleAuditForm extends StatefulWidget {
  /// Called after a successful submission. Use to pop/close the container.
  final VoidCallback? onSuccess;

  const ScheduleAuditForm({super.key, this.onSuccess});

  @override
  State<ScheduleAuditForm> createState() => _ScheduleAuditFormState();
}

class _ScheduleAuditFormState extends State<ScheduleAuditForm> {
  // Data sources — master lists (role-filtered, but not cross-filtered)
  List<Map<String, dynamic>> _templates = [];
  List<Map<String, dynamic>> _allStores = [];
  List<Map<String, dynamic>> _allAuditors = [];
  bool _isLoadingData = true;

  // Displayed lists — cross-filtered based on the other dropdown's selection
  List<Map<String, dynamic>> _stores = [];
  List<Map<String, dynamic>> _auditors = [];

  // Form state
  String? _selectedTemplateId;
  String? _selectedStoreId;
  String? _selectedAuditorId;
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 1));
  bool _isSubmitting = false;

  late final AdminAuditManager _manager;

  @override
  void initState() {
    super.initState();
    _manager = _di<AdminAuditManager>();
    _manager.addListener(_onManagerChanged);

    // Check if data is already available (e.g. from tests or prior loads)
    if (_manager.scheduleData != null) {
      _isLoadingData = false;
      _templates = _manager.scheduleData!.templates;
      _allStores = _manager.scheduleData!.allStores;
      _allAuditors = _manager.scheduleData!.allAuditors;
      _stores = List.from(_allStores);
      _auditors = List.from(_allAuditors);
    } else {
      _manager.loadScheduleData();
    }
  }

  @override
  void dispose() {
    _manager.removeListener(_onManagerChanged);
    super.dispose();
  }

  void _onManagerChanged() {
    if (!mounted) return;
    final data = _manager.scheduleData;
    if (data != null) {
      setState(() {
        _templates = data.templates;
        _allStores = data.allStores;
        _allAuditors = data.allAuditors;
        // Initially show all (no cross-filter yet)
        _stores = List.from(_allStores);
        _auditors = List.from(_allAuditors);
        _isLoadingData = false;
      });
    } else if (_manager.scheduleError != null) {
      setState(() => _isLoadingData = false);
      _di<ErrorDisplayService>().show(
        const AppError(
          code: 'network_error',
          message:
              'We couldn\'t load the latest data. Please check your internet connection and refresh.',
        ),
      );
    }
  }

  /// Recompute displayed lists based on current selections.
  void _applyCrossFilter() {
    setState(() {
      _auditors = ScheduleAuditFormLogic.filterAuditors(
        selectedStoreId: _selectedStoreId,
        allAuditors: _allAuditors,
        allStores: _allStores,
      );

      _stores = ScheduleAuditFormLogic.filterStores(
        selectedAuditorId: _selectedAuditorId,
        allStores: _allStores,
        allAuditors: _allAuditors,
      );

      // Clear selection if it's no longer in the filtered list
      if (_selectedStoreId != null &&
          !_stores.any((s) => s['id'] == _selectedStoreId)) {
        _selectedStoreId = null;
      }
      if (_selectedAuditorId != null &&
          !_auditors.any((u) => u['id'] == _selectedAuditorId)) {
        _selectedAuditorId = null;
      }
    });
  }

  void _onStoreChanged(String? v) {
    _selectedStoreId = v;
    _applyCrossFilter();
  }

  void _onAuditorChanged(String? v) {
    _selectedAuditorId = v;
    _applyCrossFilter();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _scheduledDate = picked);
    }
  }

  Future<void> _submit() async {
    if (_selectedTemplateId == null ||
        _selectedStoreId == null ||
        _selectedAuditorId == null) {
      _di<ErrorDisplayService>().show(
        const AppError(
          code: 'validation_error',
          message: 'Please fill all fields',
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _di<SubmissionApiService>().createSubmission(
        CreateSubmissionRequest(
          templateId: _selectedTemplateId!,
          storeId: _selectedStoreId!,
          status: 'scheduled',
          scheduledAt: _scheduledDate.toUtc(),
          assignToAuditorId: _selectedAuditorId,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Audit scheduled successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
        widget.onSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        if (e is DioException) {
          _di<ErrorDisplayService>().show(AppError.fromDioException(e));
        } else {
          _di<ErrorDisplayService>().show(const AppError(code: 'unknown'));
        }
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoadingData) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Text(
          'Delegate an audit to a specific auditor',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),

        // Template picker
        DropdownCard(
          icon: Icons.description_outlined,
          label: 'TEMPLATE',
          hint: 'Select a template',
          value: _selectedTemplateId,
          itemIcon: Icons.description_outlined,
          items: _templates
              .map(
                (t) => (
                  id: t['id'] as String,
                  label: t['title'] as String,
                  subtitle: null as String?,
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _selectedTemplateId = v),
        ),
        const SizedBox(height: 12),

        // Store picker
        DropdownCard(
          icon: Icons.store_outlined,
          label: 'STORE',
          hint: 'Select a store',
          value: _selectedStoreId,
          itemIcon: Icons.store_outlined,
          items: _stores
              .map(
                (s) => (
                  id: s['id'] as String,
                  label: s['name'] as String,
                  subtitle: null as String?,
                ),
              )
              .toList(),
          onChanged: _onStoreChanged,
        ),
        const SizedBox(height: 12),

        // Auditor picker
        DropdownCard(
          icon: Icons.person_outlined,
          label: 'AUDITOR',
          hint: 'Assign an auditor',
          value: _selectedAuditorId,
          itemIcon: Icons.person_outlined,
          items: _auditors
              .map(
                (u) => (
                  id: u['id'] as String,
                  label:
                      u['fullName'] as String? ??
                      u['email'] as String? ??
                      'Unknown',
                  subtitle: u['email'] as String?,
                ),
              )
              .toList(),
          onChanged: _onAuditorChanged,
        ),
        const SizedBox(height: 12),

        // Date picker
        ScheduleAuditDatePicker(
          scheduledDate: _scheduledDate,
          onTap: _pickDate,
        ),
        const SizedBox(height: 32),

        // Submit button
        FilledButton.icon(
          onPressed: _isSubmitting ? null : _submit,
          icon: _isSubmitting
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                )
              : const Icon(Icons.send),
          label: Text(
            _isSubmitting ? 'Scheduling...' : 'Schedule Audit',
            style: AppFonts.displayStyle(
              fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
