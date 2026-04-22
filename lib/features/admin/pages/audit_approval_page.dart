import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../../../_shared/theme/app_fonts.dart';
import '../../../_shared/theme/app_theme.dart';
import '../../../_shared/widgets/checkly_empty_state.dart';
import '../../audit/model/submission_dto.dart';
import '../../audit/services/submission_api_service.dart';
import '../../audit/utils/score_formatter.dart';
import '../manager/admin_audit_manager.dart';

final _di = GetIt.instance;

/// Audit Approval page — admin reviews submitted audits.
/// Tab bar: Pending | Approved | Rejected with counts.
class AuditApprovalPage extends StatefulWidget {
  const AuditApprovalPage({super.key});

  @override
  State<AuditApprovalPage> createState() => _AuditApprovalPageState();
}

class _AuditApprovalPageState extends State<AuditApprovalPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final AdminAuditManager _manager;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _manager = _di<AdminAuditManager>();
    _manager.addListener(_onManagerChanged);
    _manager.loadApprovals();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _search.dispose();
    _manager.removeListener(_onManagerChanged);
    super.dispose();
  }

  void _onManagerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadSubmissions() => _manager.loadApprovals();

  List<SubmissionDto> _filtered(String? reviewStatus) {
    var items = _manager.submissions;
    if (reviewStatus != null) {
      items = items.where((i) => i.reviewStatus == reviewStatus).toList();
    } else {
      // Pending = null review status
      items = items.where((i) => i.reviewStatus == null).toList();
    }
    final query = _search.text.toLowerCase();
    if (query.isNotEmpty) {
      items = items
          .where(
            (i) =>
                (i.storeName ?? '').toLowerCase().contains(query) ||
                (i.templateTitle ?? '').toLowerCase().contains(query) ||
                (i.auditorName ?? '').toLowerCase().contains(query),
          )
          .toList();
    }
    return items;
  }

  // ── Actions ──

  Future<void> _approve(SubmissionDto item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Audit'),
        content: Text(
          'Approve audit for ${item.storeName ?? "unknown store"}?\n\n'
          'Score: ${() { final s = ScoreFormatter.format(scoringMode: item.scoringMode, rawEarned: item.rawEarnedPoints, rawMax: item.rawMaxPoints, totalScore: item.totalScore, isWeighted: item.isWeighted); return s.isEmpty ? "N/A" : s; }()}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.success),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _di<SubmissionApiService>().reviewSubmission(
        item.id,
        status: 'approved',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audit approved ✓'),
            backgroundColor: AppTheme.success,
          ),
        );
        _loadSubmissions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected issue occurred. Please check your connection or restart the app.'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }
  }

  Future<void> _reject(SubmissionDto item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Audit'),
        content: Text(
          'Reject audit for ${item.storeName ?? "unknown store"}?\n\n'
          'The auditor will be notified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _di<SubmissionApiService>().reviewSubmission(
        item.id,
        status: 'rejected',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Audit rejected'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        _loadSubmissions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected issue occurred. Please check your connection or restart the app.'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }
  }

  void _showReviewSheet(SubmissionDto item) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('dd/MM/yyyy – HH:mm').format(item.createdAt);
    final scoreStr = () { final s = ScoreFormatter.format(scoringMode: item.scoringMode, rawEarned: item.rawEarnedPoints, rawMax: item.rawMaxPoints, totalScore: item.totalScore, isWeighted: item.isWeighted); return s.isEmpty ? '—' : s; }();
    final scoreColor = item.totalScore != null
        ? (item.totalScore! >= 80
              ? AppTheme.success
              : item.totalScore! >= 60
              ? AppTheme.warning
              : theme.colorScheme.error)
        : (item.isVoided ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurfaceVariant);

    final isVoided = item.isVoided;
    final isPending = item.reviewStatus == null && !isVoided;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'Audit Review',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),

              // Score circle
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scoreColor.withValues(alpha: 0.1),
                    border: Border.all(
                      color: scoreColor.withValues(alpha: 0.3),
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      scoreStr,
                      style: AppFonts.serifStyle(
                        fontSize: theme.textTheme.headlineSmall?.fontSize,
                        fontWeight: FontWeight.w700,
                        color: scoreColor,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Metadata rows
              _metadataRow(Icons.store, 'Store', item.storeName ?? '—'),
              _metadataRow(
                Icons.description_outlined,
                'Template',
                item.templateTitle ?? '—',
              ),
              _metadataRow(
                Icons.person_outline,
                'Auditor',
                item.auditorName ?? '—',
              ),
              _metadataRow(Icons.calendar_today, 'Date', dateStr),
              if (item.notes != null && item.notes!.isNotEmpty)
                _metadataRow(Icons.notes, 'Notes', item.notes!),

              if (isVoided) ...[
                const SizedBox(height: 12),
                _metadataRow(
                  Icons.block_flipped,
                  'Status',
                  'VOIDED',
                ),
                if (item.voidReason != null)
                  _metadataRow(Icons.info_outline, 'Reason', item.voidReason!),
                if (item.voidedAt != null)
                  _metadataRow(
                    Icons.access_time,
                    'Voided On',
                    DateFormat('dd/MM/yyyy HH:mm').format(item.voidedAt!),
                  ),
              ],

              // Review status badge
              if (item.reviewStatus != null) ...[
                const SizedBox(height: 12),
                _metadataRow(
                  item.reviewStatus == 'approved'
                      ? Icons.check_circle
                      : item.reviewStatus == 'rejected'
                      ? Icons.cancel
                      : Icons.flag,
                  'Status',
                  '${item.reviewStatus!.substring(0, 1).toUpperCase()}${item.reviewStatus!.substring(1)}',
                ),
                if (item.approverName != null)
                  _metadataRow(
                    Icons.admin_panel_settings,
                    'By',
                    item.approverName!,
                  ),
                if (item.approvedAt != null)
                  _metadataRow(
                    Icons.access_time,
                    'On',
                    DateFormat('dd/MM/yyyy HH:mm').format(item.approvedAt!),
                  ),
              ],

              // Actions for pending items
              if (isPending) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _reject(item);
                        },
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _approve(item);
                        },
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Approve'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _metadataRow(IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          SizedBox(
            width: 68,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final pending = _filtered(null);
    final approved = _filtered('approved');
    final rejected = _filtered('rejected');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Approvals'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Pending (${pending.length})'),
            Tab(text: 'Approved (${approved.length})'),
            Tab(text: 'Rejected (${rejected.length})'),
          ],
        ),
      ),
      body: _manager.isApprovalsLoading
          ? const Center(child: CircularProgressIndicator())
          : _manager.approvalsError != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Error loading audits',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(_manager.approvalsError!, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _loadSubmissions,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      hintText: 'Search by store, template, or auditor...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _search.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _search.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(pending, showActions: true),
                      _buildList(approved),
                      _buildList(rejected),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildList(List<SubmissionDto> items, {bool showActions = false}) {
    if (items.isEmpty) {
      return const ChecklyEmptyState(
        icon: Icons.inbox_outlined,
        title: 'No audits here',
        subtitle: 'This queue is clear.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSubmissions,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _ReviewCard(
            item: item,
            showActions: showActions,
            onApprove: () => _approve(item),
            onReject: () => _reject(item),
            onTap: () => _showReviewSheet(item),
          );
        },
      ),
    );
  }
}

// ── Card widget ──

class _ReviewCard extends StatelessWidget {
  final SubmissionDto item;
  final bool showActions;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onTap;

  const _ReviewCard({
    required this.item,
    this.showActions = false,
    required this.onApprove,
    required this.onReject,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreStr = () { final s = ScoreFormatter.format(scoringMode: item.scoringMode, rawEarned: item.rawEarnedPoints, rawMax: item.rawMaxPoints, totalScore: item.totalScore, isWeighted: item.isWeighted); return s.isEmpty ? '—' : s; }();
    final scoreColor = item.totalScore != null
        ? (item.totalScore! >= 80
              ? AppTheme.success
              : item.totalScore! >= 60
              ? AppTheme.warning
              : theme.colorScheme.error)
        : theme.colorScheme.onSurfaceVariant;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Score badge
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: scoreColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        scoreStr,
                        style: AppFonts.serifStyle(
                          fontSize: theme.textTheme.bodyMedium?.fontSize,
                          fontWeight: FontWeight.w700,
                          color: scoreColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.storeName ?? 'Unknown Store',
                          style: AppFonts.displayStyle(
                            fontSize: Theme.of(context).textTheme.titleSmall?.fontSize,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.templateTitle ?? 'Audit',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Chevron
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),

              // Metadata row
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.auditorName ?? '—',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.calendar_today,
                    size: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yyyy').format(item.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              // Review metadata for approved/rejected
              if (item.reviewStatus != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      item.reviewStatus == 'approved'
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined,
                      size: 13,
                      color: item.reviewStatus == 'approved'
                          ? AppTheme.success
                          : theme.colorScheme.error,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${item.reviewStatus == "approved" ? "Approved" : "Rejected"}'
                        '${item.approverName != null ? " by ${item.approverName}" : ""}'
                        '${item.approvedAt != null ? " • ${DateFormat("dd/MM HH:mm").format(item.approvedAt!)}" : ""}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: item.reviewStatus == 'approved'
                              ? AppTheme.success
                              : theme.colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              // Actions for pending
              if (showActions) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.success,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
