import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';

import '../services/program_api_service.dart';
import '../../../_shared/constants/app_capabilities.dart';
import '../../../_shared/services/policy_manager.dart';
import '../../../_shared/widgets/permission_guard.dart';
import '../../../_shared/theme/app_fonts.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/primitives/universal_list_card.dart';
import '../../../_shared/widgets/primitives/pill_chip.dart';
import '../../../_shared/widgets/checkly_empty_state.dart';

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
            'Could not load campaigns. Check your connection and try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campaigns'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(theme),
      floatingActionButton: PermissionGuard(
        capability: AppCapabilities.programsCreate,
        child: FloatingActionButton(
          key: const Key('create_program_fab'),
          tooltip: 'New Campaign',
          backgroundColor: AppColors.featherGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const CircleBorder(),
          onPressed: () async {
            await context.push('/programs/new');
            _load();
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    final canReview = GetIt.instance<PolicyManager>().can(
      AppCapabilities.programsReview,
    );

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ChecklyEmptyState(
        icon: Icons.cloud_off,
        title: 'Unable to Load Campaigns',
        subtitle: _error!,
        emoji: '⚠️',
        actionButton: ElevatedButton(
          onPressed: _load,
          child: const Text('Try Again'),
        ),
      );
    }
    if (_programs.isEmpty) {
      return ChecklyEmptyState(
        icon: Icons.campaign_outlined,
        title: 'No Campaigns Found',
        subtitle: 'There are no active or scheduled campaigns at this time.',
        emoji: '📂',
        actionButton: ElevatedButton(
          onPressed: _load,
          child: const Text('Refresh'),
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
          return UniversalListCard(
            title: title,
            titleStyle: theme.textTheme.titleMedium?.merge(
              AppFonts.displayStyle(fontWeight: FontWeight.w700),
            ),
            onTap: canReview
                ? () => context.push('/programs/review/$id')
                : null,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.5,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.campaign_outlined,
                color: theme.colorScheme.primary,
              ),
            ),
            badges: [
              PillChip(label: category.toUpperCase(), type: PillChipType.blue),
              PillChip(
                label: status.toUpperCase(),
                type: status.toLowerCase() == 'active'
                    ? PillChipType.green
                    : PillChipType.purple,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 2, top: 4),
                child: Text(
                  '$total stores',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            trailing: canReview ? const Icon(Icons.chevron_right) : null,
          );
        },
      ),
    );
  }
}
