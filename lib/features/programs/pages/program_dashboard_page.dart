import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../manager/program_manager.dart';
import '../services/program_api_service.dart'; // DTOs only
import '../model/assignment_status.dart';
import '../../../_shared/theme/app_fonts.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/primitives/stroke_card.dart';
import '../../../_shared/widgets/primitives/pill_chip.dart';
import 'widgets/program_bar_chart.dart';
import 'widgets/program_evidence_viewer_dialog.dart';
import 'widgets/program_kpi_card.dart';
import 'widgets/program_status_icon.dart';

/// HQ-facing view for a specific program's assignment status.
///
/// Online-only: loads live assignment data from [ProgramApiService].
/// Shows total assigned, completion rate, and a filterable list of assignments.
class ProgramDashboardPage extends StatefulWidget {
  final String programId;

  const ProgramDashboardPage({super.key, required this.programId});

  @override
  State<ProgramDashboardPage> createState() => _ProgramDashboardPageState();
}

class _ProgramDashboardPageState extends State<ProgramDashboardPage> {
  final _manager = GetIt.instance<ProgramManager>();

  bool _loading = true;
  String? _error;
  List<ProgramAssignmentDetailDto> _assignments = [];
  ProgramSummaryResponse? _summary;
  String? _statusFilter;



  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summaryRes = await _manager.getDashboardSummary(widget.programId);
      final response = await _manager.getDashboardAssignments(
        widget.programId,
        status: _statusFilter,
      );
      setState(() {
        _summary = summaryRes;
        _assignments = response.items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load dashboard data. Check your connection.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campaign Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError(theme)
          : _buildContent(theme),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _load, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          // ── Summary KPIs ──
          if (_summary != null) ...[
            Row(
              children: [
                ProgramKpiCard(
                  label: 'Total Assigned',
                  value: '${_summary!.total}',
                  icon: Icons.store,
                ),
                const SizedBox(width: 12),
                ProgramKpiCard(
                  label: 'Completion',
                  value: '${_summary!.completionRate}%',
                  icon: Icons.check_circle_outline,
                ),
                const SizedBox(width: 12),
                ProgramKpiCard(
                  label: 'Submitted',
                  value: '${_summary!.submitted}',
                  icon: Icons.task_alt,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ProgramSegmentedBarChart(summary: _summary!),
            const SizedBox(height: 24),
          ],

          // ── Status filter dropdown pill ──
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 12),
            child: Row(
              children: [
                DropdownFilterPill(
                  label: 'Status',
                  value: switch (_statusFilter) {
                    'pending' => 'Pending',
                    'submitted' => 'Submitted',
                    'needs_revision' => 'Needs Rev',
                    'verified' => 'Verified',
                    'overdue' => 'Overdue',
                    _ => 'All',
                  },
                  active: _statusFilter != null,
                  onTap: () => showProgramAssignmentStatusFilterSheet(
                    context: context,
                    currentFilter: _statusFilter,
                    countByFilter: (status) {
                      if (_summary == null) return 0;
                      if (status == null) return _summary!.total;
                      return switch (status) {
                        'pending' => _summary!.pending,
                        'submitted' => _summary!.submitted,
                        'needs_revision' => _summary!.needsRevision,
                        'verified' => _summary!.verified,
                        'overdue' => _summary!.overdue,
                        _ => 0,
                      };
                    },
                    onSelected: (val) {
                      setState(() => _statusFilter = val);
                      _load();
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── Assignment list ──
          if (_assignments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'No assignments match this filter.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            )
          else
            ...List.generate(_assignments.length, (i) {
              final a = _assignments[i];
              return StrokeCard(
                margin: const EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.zero,
                onTap:
                    a.status == AssignmentStatus.submitted &&
                        a.evidence.isNotEmpty
                    ? () => _showEvidence(context, a)
                    : null,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: ProgramStatusIcon(status: a.status),
                  title: Text(
                    a.storeName,
                    style: theme.textTheme.titleMedium?.merge(
                      AppFonts.displayStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        PillChip(
                          label: a.status.toUpperCase(),
                          type: _getPillType(a.status),
                        ),
                        Text(
                          '${a.evidence.length} evidence item(s)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
              );
            }),
        ],
      ),
    );
  }

  void _showEvidence(
    BuildContext context,
    ProgramAssignmentDetailDto assignment,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => ProgramEvidenceViewerDialog(assignment: assignment),
    );
  }

  PillChipType _getPillType(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return PillChipType.yellow;
      case 'submitted':
        return PillChipType.blue;
      case 'needs_revision':
        return PillChipType.red;
      case 'verified':
        return PillChipType.green;
      case 'overdue':
      default:
        return PillChipType.purple;
    }
  }
}

class DropdownFilterPill extends StatelessWidget {
  final String label;
  final String value;
  final bool active;
  final VoidCallback onTap;

  const DropdownFilterPill({
    super.key,
    required this.label,
    required this.value,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.featherGreen : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: active ? AppColors.featherGreen : AppColors.swan,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: $value',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ).copyWith(
                color: active ? Colors.white : AppColors.eel,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: active ? Colors.white : AppColors.eel,
            ),
          ],
        ),
      ),
    );
  }
}

void showProgramAssignmentStatusFilterSheet({
  required BuildContext context,
  required String? currentFilter,
  required int Function(String?) countByFilter,
  required ValueChanged<String?> onSelected,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final statuses = [
        {'id': null, 'label': 'All Assignments', 'count': countByFilter(null)},
        {'id': 'pending', 'label': 'Pending', 'count': countByFilter('pending')},
        {'id': 'submitted', 'label': 'Submitted', 'count': countByFilter('submitted')},
        {'id': 'needs_revision', 'label': 'Needs Revision', 'count': countByFilter('needs_revision')},
        {'id': 'verified', 'label': 'Verified', 'count': countByFilter('verified')},
        {'id': 'overdue', 'label': 'Overdue', 'count': countByFilter('overdue')},
      ];

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter by Status',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.eel,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.maybePop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...statuses.map((status) {
                final isSelected = currentFilter == status['id'];
                return InkWell(
                  onTap: () {
                    onSelected(status['id'] as String?);
                    Navigator.maybePop(ctx);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.featherGreen.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.featherGreen : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              status['label'] as String,
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? AppColors.featherGreen : AppColors.eel,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.featherGreen
                                    : AppColors.swan.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                '${status['count']}',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? Colors.white : AppColors.eel.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.featherGreen,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}
