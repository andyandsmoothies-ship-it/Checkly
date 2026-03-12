import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../_shared/database/database_service.dart';
import '../../../_shared/theme/app_theme.dart';

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
  final _search = TextEditingController();

  // Simple data from cache — in production this would call the API
  List<_AuditReviewItem> _allItems = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSubmissions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadSubmissions() async {
    final db = _di<DatabaseService>().db;
    final subs = await db.select(db.cachedSubmissions).get();
    setState(() {
      _allItems = subs
          .map(
            (s) => _AuditReviewItem(
              id: s.id,
              storeName: s.storeName ?? 'Unknown Store',
              templateTitle: s.templateTitle ?? 'Audit',
              score: s.totalScore,
              date: s.createdAt,
              reviewStatus: s.reviewStatus,
            ),
          )
          .toList();
    });
  }

  List<_AuditReviewItem> _filtered(String? status) {
    var items = _allItems;
    if (status != null) {
      items = items.where((i) => i.reviewStatus == status).toList();
    } else {
      // Pending = null review status + completed
      items = items.where((i) => i.reviewStatus == null).toList();
    }
    final query = _search.text.toLowerCase();
    if (query.isNotEmpty) {
      items = items
          .where(
            (i) =>
                i.storeName.toLowerCase().contains(query) ||
                i.templateTitle.toLowerCase().contains(query),
          )
          .toList();
    }
    return items;
  }

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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Search audits...',
                prefixIcon: const Icon(Icons.search),
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

  Widget _buildList(List<_AuditReviewItem> items, {bool showActions = false}) {
    if (items.isEmpty) {
      return const Center(child: Text('No audits found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _ReviewCard(item: item, showActions: showActions);
      },
    );
  }
}

class _AuditReviewItem {
  final String id;
  final String storeName;
  final String templateTitle;
  final double? score;
  final DateTime date;
  final String? reviewStatus;

  _AuditReviewItem({
    required this.id,
    required this.storeName,
    required this.templateTitle,
    this.score,
    required this.date,
    this.reviewStatus,
  });
}

class _ReviewCard extends StatelessWidget {
  final _AuditReviewItem item;
  final bool showActions;

  const _ReviewCard({required this.item, this.showActions = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreStr = item.score != null
        ? '${item.score!.toStringAsFixed(1)}%'
        : '—';
    final scoreColor = item.score != null
        ? (item.score! >= 80
              ? AppTheme.success
              : item.score! >= 60
              ? AppTheme.warning
              : theme.colorScheme.error)
        : theme.colorScheme.onSurfaceVariant;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.storeName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.templateTitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    scoreStr,
                    style: TextStyle(
                      color: scoreColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${item.date.day}/${item.date.month}/${item.date.year}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (showActions) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () {},
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
    );
  }
}
