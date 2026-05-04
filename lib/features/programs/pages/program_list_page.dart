import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';

import '../services/program_api_service.dart';
import '../../../_shared/constants/app_capabilities.dart';
import '../../../_shared/services/policy_manager.dart';
import '../../../_shared/theme/app_fonts.dart';

/// HQ-facing list of all programs.
///
/// Online-only: relies on live data from [ProgramApiService].
/// DioException states are handled with a user-facing error banner.
class ProgramListPage extends StatefulWidget {
  const ProgramListPage({super.key});

  @override
  State<ProgramListPage> createState() => _ProgramListPageState();
}

class _ProgramListPageState extends State<ProgramListPage> {
  final _api = GetIt.instance<ProgramApiService>();

  bool _loading = true;
  String? _error;
  List<dynamic> _programs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _api.getPrograms();
      final items = result['items'] as List<dynamic>? ?? [];
      setState(() {
        _programs = items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error =
            'Could not load programs. Check your connection and try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canCreate = GetIt.instance<PolicyManager>().can(
      AppCapabilities.programsCreate,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Programs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(theme),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              key: const Key('create_program_fab'),
              tooltip: 'New Program',
              onPressed: () async {
                await context.push('/programs/new');
                _load();
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _load, child: const Text('Try Again')),
            ],
          ),
        ),
      );
    }
    if (_programs.isEmpty) {
      return Center(
        child: Text(
          'No programs found.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _programs.length,
        separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final p = _programs[i] as Map<String, dynamic>;
          final id = p['id'] as String? ?? '';
          final title = p['title'] as String? ?? '';
          final category = p['category'] as String? ?? '';
          final status = p['status'] as String? ?? '';
          final total = p['totalAssigned'] as int? ?? 0;
          return Card(
            child: ListTile(
              leading: const Icon(Icons.campaign_outlined),
              title: Text(
                title,
                style: AppFonts.displayStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text('$category · $status · $total stores'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/programs/review/$id'),
            ),
          );
        },
      ),
    );
  }
}
