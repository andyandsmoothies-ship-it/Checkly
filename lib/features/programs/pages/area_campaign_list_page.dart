import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../_shared/theme/app_theme.dart';
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
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final campaign = campaigns[index];
                final isComplete = campaign.completionRate == 100;
                final color = isComplete
                    ? AppTheme.success
                    : theme.colorScheme.primary;
                final icon = isComplete ? Icons.check_circle : Icons.data_usage;

                return Card(
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
                );
              },
            );
          },
        ),
      ),
    );
  }
}
