import 'package:flutter/material.dart';

import '../../../../_shared/theme/app_theme.dart';
import '../../../programs/services/program_api_service.dart';

/// Displays campaign progress for Area Managers.
///
/// Takes a list of [AreaCampaignProgressDto] and displays up to 3 campaigns.
class CampaignProgressWidget extends StatelessWidget {
  final List<AreaCampaignProgressDto> campaigns;

  const CampaignProgressWidget({super.key, required this.campaigns});

  @override
  Widget build(BuildContext context) {
    if (campaigns.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final displayCampaigns = campaigns.take(3).toList();
    final hasMore = campaigns.length > 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Area Campaigns',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...displayCampaigns.map((campaign) {
          final isComplete = campaign.completionRate == 100;
          final color = isComplete
              ? AppTheme.success
              : theme.colorScheme.primary;
          final icon = isComplete ? Icons.check_circle : Icons.data_usage;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              elevation: 0,
              color: color.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: color.withValues(alpha: 0.2)),
              ),
              child: ListTile(
                leading: Icon(icon, color: color),
                title: Text(
                  campaign.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${campaign.completedStores} of ${campaign.totalStores} Stores Completed',
                ),
                trailing: Text(
                  '${campaign.completionRate}%',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          );
        }),
        if (hasMore) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('View All Campaigns (${campaigns.length})'),
            ),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}
