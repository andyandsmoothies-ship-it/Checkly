import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../services/program_api_service.dart';
import '../../../_shared/theme/app_fonts.dart';
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
  final _api = GetIt.instance<ProgramApiService>();

  bool _loading = true;
  String? _error;
  List<ProgramAssignmentDetailDto> _assignments = [];
  ProgramSummaryResponse? _summary;
  String? _statusFilter;

  static const _filterOptions = [
    (label: 'All', value: null),
    (label: 'Pending', value: 'pending'),
    (label: 'Submitted', value: 'submitted'),
    (label: 'Needs Rev', value: 'needs_revision'),
    (label: 'Verified', value: 'verified'),
    (label: 'Overdue', value: 'overdue'),
  ];

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
      final summaryRes = await _api.getProgramSummary(widget.programId);
      final response = await _api.getProgramAssignments(
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
        title: const Text('Program Dashboard'),
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

          // ── Status filter chips ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filterOptions.map((opt) {
                final selected = _statusFilter == opt.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(opt.label),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _statusFilter = opt.value);
                      _load();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

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
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: ProgramStatusIcon(status: a.status),
                  title: Text(
                    a.storeName,
                    style: theme.textTheme.bodyMedium?.merge(
                      AppFonts.displayStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  subtitle: Text(
                    '${a.status.toUpperCase()} · ${a.evidence.length} evidence item(s)',
                  ),
                  trailing: a.status == 'submitted'
                      ? const Icon(Icons.chevron_right)
                      : null,
                  onTap: a.status == 'submitted' && a.evidence.isNotEmpty
                      ? () => _showEvidence(context, a)
                      : null,
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
}
