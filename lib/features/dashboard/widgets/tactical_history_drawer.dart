import 'package:flutter/material.dart';
import '../../../_shared/utils/date_format_utils.dart';
import 'package:go_router/go_router.dart';

import '../../../_shared/theme/app_theme.dart';

/// Bottom sheet showing the last audits for a tapped category.
/// Used on the dashboard page when a category card is tapped.
class TacticalHistoryDrawer extends StatelessWidget {
  final String categoryName;
  final List<Map<String, dynamic>> audits;

  const TacticalHistoryDrawer({
    super.key,
    required this.categoryName,
    required this.audits,
  });

  /// Opens the drawer as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required String categoryName,
    required List<Map<String, dynamic>> audits,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          TacticalHistoryDrawer(categoryName: categoryName, audits: audits),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.85,
      minChildSize: 0.3,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.history, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$categoryName — Recent Audits',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Audit list
            Expanded(
              child: audits.isEmpty
                  ? Center(
                      child: Text(
                        'No audits for this category yet',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: audits.length,
                      itemBuilder: (context, index) {
                        final audit = audits[index];
                        return _AuditCard(
                          audit: audit,
                          onTap: () {
                            Navigator.pop(context);
                            final id = audit['id'] as String?;
                            if (id != null) {
                              context.push('/activity/$id');
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Audit Card ───

class _AuditCard extends StatelessWidget {
  final Map<String, dynamic> audit;
  final VoidCallback onTap;

  const _AuditCard({required this.audit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = audit['totalScore'] as double?;
    final storeName = audit['storeName'] as String? ?? 'Unknown Store';
    final createdAt = audit['createdAt'] as String?;
    final status = audit['status'] as String? ?? 'draft';

    final scoreColor = score != null
        ? (score >= 80
              ? AppTheme.success
              : score >= 50
              ? AppTheme.warning
              : Colors.red)
        : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: scoreColor.withValues(alpha: 0.15),
          child: Text(
            score != null ? '${score.toInt()}' : '—',
            style: TextStyle(
              color: scoreColor,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        title: Text(
          storeName,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${_capitalize(status)}${createdAt != null ? ' • ${_formatDate(createdAt)}' : ''}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, size: 18),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  String _formatDate(String raw) {
    final local = DateTime.tryParse(raw)?.toLocal();
    if (local == null) return raw;
    return formatDate(local);
  }
}
