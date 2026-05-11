import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';

import '../../../_shared/exceptions/app_error.dart';
import '../../../_shared/services/error_display_service.dart';
import '../../../_shared/theme/app_theme.dart';
import '../../../_shared/widgets/checkly_empty_state.dart';
import '../../audit/model/submission_dto.dart';
import '../../audit/services/submission_api_service.dart';
import '../../audit/utils/score_formatter.dart';
import '../manager/admin_audit_manager.dart';
import 'widgets/audit_review_sheet.dart';
import 'widgets/review_card.dart';
import '../../../_shared/constants/review_status.dart';

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
          'Score: ${() {
            final s = ScoreFormatter.format(scoringMode: item.scoringMode, rawEarned: item.rawEarnedPoints, rawMax: item.rawMaxPoints, totalScore: item.totalScore, isWeighted: item.isWeighted);
            return s.isEmpty ? "N/A" : s;
          }()}',
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
        status: ReviewStatus.approved,
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
    } on DioException catch (e) {
      _di<ErrorDisplayService>().show(AppError.fromDioException(e));
    } catch (_) {
      _di<ErrorDisplayService>().show(const AppError(code: 'unknown'));
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
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _di<SubmissionApiService>().reviewSubmission(
        item.id,
        status: ReviewStatus.rejected,
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
    } on DioException catch (e) {
      _di<ErrorDisplayService>().show(AppError.fromDioException(e));
    } catch (_) {
      _di<ErrorDisplayService>().show(const AppError(code: 'unknown'));
    }
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final pending = _filtered(null);
    final approved = _filtered(ReviewStatus.approved);
    final rejected = _filtered(ReviewStatus.rejected);

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
                  Text(
                    _manager.approvalsError!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
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
          return ReviewCard(
            item: item,
            showActions: showActions,
            onApprove: () => _approve(item),
            onReject: () => _reject(item),
            onTap: () => showAuditReviewSheet(
              context: context,
              item: item,
              onApprove: () => _approve(item),
              onReject: () => _reject(item),
            ),
          );
        },
      ),
    );
  }
}
