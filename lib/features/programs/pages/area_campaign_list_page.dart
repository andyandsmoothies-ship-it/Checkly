import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../_shared/widgets/primitives/stroke_card.dart';
import '../../../_shared/widgets/primitives/pill_chip.dart';
import '../../../_shared/widgets/primitives/quest_progress_bar.dart';
import '../services/program_api_service.dart';

/// Full-screen list of an area manager's campaigns.
///
/// Fetches the latest campaign progress from the API and displays it
/// in a refreshable list.
class AreaCampaignListPage extends StatefulWidget {
  const AreaCampaignListPage({super.key});

  @override
  State<AreaCampaignListPage> createState() => _AreaCampaignListPageState();
}

class _AreaCampaignListPageState extends State<AreaCampaignListPage> {
  late Future<List<AreaCampaignProgressDto>> _future;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _future = GetIt.I<ProgramApiService>().getAreaCampaignProgress();
  }

  Future<void> _onRefresh() async {
    setState(() {
      _loadData();
    });
    try {
      await _future;
    } catch (_) {
      // Ignored for refresh indicator
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Area Campaigns')),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: FutureBuilder<List<AreaCampaignProgressDto>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Text(
                        'Failed to load campaigns.\nPull to refresh.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            final campaigns = snapshot.data;
            if (campaigns == null || campaigns.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Text(
                        'No area campaigns at this time.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: campaigns.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final campaign = campaigns[index];
                final isComplete = campaign.completionRate == 100;

                return StrokeCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  campaign.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${campaign.completedStores} of ${campaign.totalStores} Stores Completed',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          PillChip(
                            label: '${campaign.completionRate}%',
                            type: isComplete
                                ? PillChipType.green
                                : PillChipType.yellow,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      QuestProgressBar(
                        value: campaign.completionRate / 100.0,
                        height: 16.0,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
