import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../_shared/theme/app_fonts.dart';
import '../../../_shared/theme/app_theme.dart';
import '../../audit/model/submission_dto.dart';
import '../../audit/services/submission_api_service.dart';
import '../../auth/manager/auth_manager.dart';
import '../../stores/services/store_api_service.dart';
import '../../templates/services/template_api_service.dart';
import '../services/admin_api_service.dart';

final _di = GetIt.instance;

/// Admin page to schedule (delegate) an audit to a specific auditor.
/// Wraps [ScheduleAuditForm] in a Scaffold.
class ScheduleAuditPage extends StatelessWidget {
  const ScheduleAuditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule Audit')),
      body: ScheduleAuditForm(onSuccess: () => context.pop()),
    );
  }
}

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final templatesFuture = _di<TemplateApiService>().getTemplates();
      final storesFuture = _di<StoreApiService>().getStores();
      final auditorsFuture = _di<AdminApiService>().getUsers();

      final results = await Future.wait([
        templatesFuture,
        storesFuture,
        auditorsFuture,
      ]);

      final templates = results[0] as List<dynamic>;
      final stores = results[1] as List<dynamic>;
      final users = results[2] as List<Map<String, dynamic>>;

      if (mounted) {
        // Determine current user's role and area for filtering
        final currentUserId = _di<AuthManager>().currentUser?.userId;
        final currentUserRole =
            _di<AuthManager>().currentUser?.role ?? 'auditor';
        Map<String, dynamic>? currentUserRecord;
        if (currentUserId != null) {
          currentUserRecord = users.cast<Map<String, dynamic>?>().firstWhere(
            (u) => u?['id'] == currentUserId,
            orElse: () => null,
          );
        }
        final myAreaId = currentUserRecord?['areaId'] as String?;

        // Build template list
        final templateList = templates
            .map(
              (t) => {
                'id': (t is Map) ? t['id'] : t.id,
                'title': (t is Map) ? t['title'] : t.title,
              },
            )
            .toList();

        // Build store list (with areaId for filtering)
        var storeList = stores
            .map(
              (s) => {
                'id': (s is Map) ? s['id'] : s.id,
                'name': (s is Map) ? s['name'] : s.name,
                'areaId': (s is Map) ? s['areaId'] : null,
              },
            )
            .toList();

        // Base auditor filter: only auditors and admins (keep areaId)
        var auditorList = users
            .where((u) => u['role'] == 'auditor' || u['role'] == 'admin')
            .toList();

        // Role-based filtering for area_manager
        if (currentUserRole == 'area_manager' && myAreaId != null) {
          storeList = storeList.where((s) => s['areaId'] == myAreaId).toList();
          auditorList = auditorList
              .where((u) => u['areaId'] == myAreaId || u['areaId'] == null)
              .toList();
        } else if (currentUserRole == 'area_manager' && myAreaId == null) {
          // Safety: AM with no area sees nothing
          storeList = [];
          auditorList = [];
        }

        setState(() {
          _templates = templateList;
          _allStores = storeList;
          _allAuditors = auditorList;
          // Initially show all (no cross-filter yet)
          _stores = List.from(_allStores);
          _auditors = List.from(_allAuditors);
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
      }
    }
  }

  /// Recompute displayed lists based on current selections.
  void _applyCrossFilter() {
    setState(() {
      if (_selectedStoreId != null) {
        // Find the selected store's areaId
        final store = _allStores.firstWhere(
          (s) => s['id'] == _selectedStoreId,
          orElse: () => <String, dynamic>{},
        );
        final storeAreaId = store['areaId'] as String?;

        if (storeAreaId != null) {
          _auditors = _allAuditors
              .where((u) => u['areaId'] == storeAreaId || u['areaId'] == null)
              .toList();
        } else {
          _auditors = List.from(_allAuditors);
        }
      } else {
        _auditors = List.from(_allAuditors);
      }

      if (_selectedAuditorId != null) {
        // Find the selected auditor's areaId
        final auditor = _allAuditors.firstWhere(
          (u) => u['id'] == _selectedAuditorId,
          orElse: () => <String, dynamic>{},
        );
        final auditorAreaId = auditor['areaId'] as String?;

        if (auditorAreaId != null) {
          _stores = _allStores
              .where((s) => s['areaId'] == auditorAreaId)
              .toList();
        } else {
          // Floating auditor (no area) — show all stores
          _stores = List.from(_allStores);
        }
      } else {
        _stores = List.from(_allStores);
      }

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _di<SubmissionApiService>().createSubmission(
        CreateSubmissionRequest(
          templateId: _selectedTemplateId!,
          storeId: _selectedStoreId!,
          status: 'scheduled',
          scheduledAt: _scheduledDate,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to schedule: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
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
        _DropdownCard(
          icon: Icons.description_outlined,
          label: 'TEMPLATE',
          hint: 'Select a template',
          value: _selectedTemplateId,
          items: _templates
              .map(
                (t) => DropdownMenuItem<String>(
                  value: t['id'] as String,
                  child: Text(
                    t['title'] as String,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _selectedTemplateId = v),
        ),
        const SizedBox(height: 12),

        // Store picker
        _DropdownCard(
          icon: Icons.store_outlined,
          label: 'STORE',
          hint: 'Select a store',
          value: _selectedStoreId,
          items: _stores
              .map(
                (s) => DropdownMenuItem<String>(
                  value: s['id'] as String,
                  child: Text(
                    s['name'] as String,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: _onStoreChanged,
        ),
        const SizedBox(height: 12),

        // Auditor picker
        _DropdownCard(
          icon: Icons.person_outlined,
          label: 'AUDITOR',
          hint: 'Assign an auditor',
          value: _selectedAuditorId,
          items: _auditors
              .map(
                (u) => DropdownMenuItem<String>(
                  value: u['id'] as String,
                  child: Text(
                    u['fullName'] as String? ??
                        u['email'] as String? ??
                        'Unknown',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: _onAuditorChanged,
        ),
        const SizedBox(height: 12),

        // Date picker
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SCHEDULED DATE',
                  style: AppFonts.displayStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charcoal.withValues(alpha: 0.4),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTheme.sageGray.withValues(alpha: 0.5),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${_scheduledDate.day}/${_scheduledDate.month}/${_scheduledDate.year}',
                          style: theme.textTheme.bodyLarge,
                        ),
                        const Spacer(),
                        Icon(
                          Icons.edit,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Submit button
        FilledButton.icon(
          onPressed: _isSubmitting ? null : _submit,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send),
          label: Text(
            _isSubmitting ? 'Scheduling...' : 'Schedule Audit',
            style: AppFonts.displayStyle(
              fontSize: 14,
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

// ── Reusable dropdown card ──

class _DropdownCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const _DropdownCard({
    required this.icon,
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppFonts.displayStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charcoal.withValues(alpha: 0.4),
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: value,
              borderRadius: BorderRadius.circular(12),
              decoration: InputDecoration(
                hintText: hint,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              items: items,
              onChanged: onChanged,
              isExpanded: true,
            ),
          ],
        ),
      ),
    );
  }
}
