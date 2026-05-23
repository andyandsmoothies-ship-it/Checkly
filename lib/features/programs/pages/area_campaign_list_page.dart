import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../_shared/widgets/primitives/universal_list_card.dart';
import '../../../_shared/widgets/primitives/pill_chip.dart';
import '../../../_shared/widgets/primitives/quest_progress_bar.dart';
import '../../../_shared/widgets/checkly_empty_state.dart';
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
                    child: const ChecklyEmptyState(
                      icon: Icons.cloud_off,
                      title: 'Unable to Load Campaigns',
                      subtitle:
                          'Failed to load campaigns. Please pull to refresh.',
                      emoji: '⚠️',
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
                    child: const ChecklyEmptyState(
                      icon: Icons.campaign_outlined,
                      title: 'No Campaigns Found',
                      subtitle: 'No area campaigns at this time.',
                      emoji: '📂',
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

                return UniversalListCard(
                  title: campaign.title,
                  titleStyle: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  subtitle:
                      '${campaign.completedStores} of ${campaign.totalStores} Stores Completed',
                  subtitleWidget: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: QuestProgressBar(
                      value: campaign.completionRate / 100.0,
                      height: 16.0,
                    ),
                  ),
                  trailing: PillChip(
                    label: '${campaign.completionRate}%',
                    type: isComplete ? PillChipType.green : PillChipType.yellow,
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
