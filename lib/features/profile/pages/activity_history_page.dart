import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../manager/profile_manager.dart';
import '../widgets/activity_card.dart';

final _di = GetIt.instance;

/// Activity History page — shows user's own recent submissions.
class ActivityHistoryPage extends StatefulWidget {
  const ActivityHistoryPage({super.key});

  @override
  State<ActivityHistoryPage> createState() => _ActivityHistoryPageState();
}

class _ActivityHistoryPageState extends State<ActivityHistoryPage> {
  late final ProfileManager _manager;

  @override
  void initState() {
    super.initState();
    _manager = _di<ProfileManager>();
    _manager.loadActivity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Activity')),
      body: ListenableBuilder(
        listenable: _manager,
        builder: (context, _) {
          if (_manager.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_manager.items.isEmpty) {
            return const Center(child: Text('No activity yet'));
          }
          return RefreshIndicator(
            onRefresh: _manager.loadActivity,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _manager.items.length,
              itemBuilder: (context, index) {
                final item = _manager.items[index];
                return ActivityCard(item: item);
              },
            ),
          );
        },
      ),
    );
  }
}
