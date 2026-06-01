import '../utils/audit_snapshot_parser.dart';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../model/submission_detail_dto.dart';
import '../manager/history_manager.dart';
import '../widgets/audit_preview_group_builder.dart';
import '../widgets/read_only_criterion_row.dart';
import '../widgets/header_card.dart';
import '../widgets/dynamic_section_summary.dart';
import '../../templates/models/template_dto.dart';

/// Read-only slide-up sheet showing the full detail of a completed or voided audit.
/// Fetches [SubmissionDetailDto] via [HistoryManager.loadDetail] on open.
/// Must NOT import AuditManager or AuditCriterionCard.
class AuditPreviewSheet extends StatefulWidget {
  final String submissionId;

  const AuditPreviewSheet({super.key, required this.submissionId});

  @override
  State<AuditPreviewSheet> createState() => _AuditPreviewSheetState();
}

class _AuditPreviewSheetState extends State<AuditPreviewSheet> {
  late final HistoryManager _manager;

  @override
  void initState() {
    super.initState();
    _manager = GetIt.instance<HistoryManager>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _manager.loadDetail(widget.submissionId);
    });
  }

  Future<void> _retry() => _manager.loadDetail(widget.submissionId);

  // Map raw detailError to a user-friendly message matching the original UX.
  String _friendlyError(String raw) {
    if (raw.contains('SocketException')) {
      return 'Requires an internet connection.';
    }
    final match = RegExp(r'statusCode: (\d+)').firstMatch(raw);
    if (match != null) return 'Could not load audit (${match.group(1)}).';
    return 'Unexpected error: $raw';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Title row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Audit Preview',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: theme.colorScheme.outlineVariant),

            // Body
            Expanded(
              child: ListenableBuilder(
                listenable: _manager,
                builder: (context, _) => _buildBody(context, scrollController),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ScrollController scrollController) {
    final theme = Theme.of(context);

    if (_manager.isDetailLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_manager.detailError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off_outlined,
                size: 40,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                _friendlyError(_manager.detailError!),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(onPressed: _retry, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final detail = _manager.selectedDetail.value;
    if (detail == null) return const SizedBox.shrink();

    List<GroupDto>? rootGroups;
    String scoringMode = 'penalty';
    Map<String, CriterionDto> criteriaMap = {};

    if (detail.templateSnapshot != null) {
      final parsed = AuditSnapshotParser.parseSnapshot(
        detail.templateSnapshot!,
      );
      rootGroups = parsed.rootGroups;
      scoringMode = parsed.scoringMode;
      criteriaMap = parsed.criteriaMap;
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        // Header card
        HeaderCard(detail: detail, scoringMode: scoringMode),
        const SizedBox(height: 16),

        // Dynamic Section Summary
        if (rootGroups != null && detail.answers.isNotEmpty)
          DynamicSectionSummary(
            rootGroups: rootGroups,
            answersMap: {
              for (var a in detail.answers)
                if (a.criteriaId != null) a.criteriaId!: a,
            },
            scoringMode: scoringMode,
          ),

        // Legacy guard
        if (detail.templateSnapshot == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Legacy audit — section details unavailable.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

        // Answers
        if (detail.answers.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No answers recorded for this audit.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else if (rootGroups != null)
          ...rootGroups.map(
            (g) => AuditPreviewGroupBuilder(
              group: g,
              answersMap: {
                for (var a in detail.answers)
                  if (a.criteriaId != null) a.criteriaId!: a,
              },
              scoringMode: scoringMode,
              depth: 0,
            ),
          )
        else
          ...detail.answers.map(
            (answer) => ReadOnlyCriterionRow(
              answer: answer,
              criterion: criteriaMap[answer.criteriaId],
              scoringMode: scoringMode,
            ),
          ),
      ],
    );
  }
}
