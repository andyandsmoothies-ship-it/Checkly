import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../programs/services/program_api_service.dart';
import '../../../../_shared/constants/app_capabilities.dart';
import '../../../../_shared/widgets/permission_guard.dart';

/// Admin-facing widget displaying the top active campaigns.
///
/// Removes active campaigns from the hidden status row and elevates them to
/// a first-class feature on the dashboard using rich cards.
class AdminActiveCampaignsWidget extends StatefulWidget {
  const AdminActiveCampaignsWidget({super.key});

  @override
  State<AdminActiveCampaignsWidget> createState() =>
      _AdminActiveCampaignsWidgetState();
}

class _AdminActiveCampaignsWidgetState
    extends State<AdminActiveCampaignsWidget> {
  final _api = GetIt.instance<ProgramApiService>();

  bool _loading = true;
  String? _error;
  List<dynamic> _campaigns = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _api.getPrograms(page: 1);
      final items = result['items'] as List<dynamic>? ?? [];

      // Filter for active campaigns and take top 3
      final activeItems = items
          .where((p) => p['status'] != 'completed' && p['status'] != 'archived')
          .take(3)
          .toList();

      if (!mounted) return;
      setState(() {
        _campaigns = activeItems;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load active campaigns.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return const SizedBox.shrink(); // Hide silently on dashboard failure
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Campaigns',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_campaigns.isNotEmpty)
                TextButton(
                  onPressed: () => context.push('/programs'),
                  child: const Text('View All'),
                ),
            ],
          ),
        ),
        if (_campaigns.isNotEmpty)
          SizedBox(
            height: 140, // Horizontal card height
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _campaigns.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final c = _campaigns[index] as Map<String, dynamic>;
                final id = c['id'] as String? ?? '';
                final title = c['title'] as String? ?? '';
                final total = c['totalAssigned'] as int? ?? 0;
                final category = c['category'] as String? ?? '';

                return SizedBox(
                  width: 260,
                  child: Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => context.push('/programs/review/$id'),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.tertiaryContainer
                                        .withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.campaign_outlined,
                                    color: theme.colorScheme.tertiary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$total stores',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    category.toUpperCase(),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                'No active campaigns',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        PermissionGuard(
          capability: AppCapabilities.programsCreate,
          child: FilledButton.icon(
            onPressed: () => context.push('/programs/new'),
            icon: const Icon(Icons.add),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'NEW CAMPAIGN',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
