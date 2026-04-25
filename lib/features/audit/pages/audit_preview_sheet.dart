import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../model/submission_dto.dart';
import '../manager/history_manager.dart';
import '../widgets/read_only_criterion_row.dart';
import '../widgets/header_card.dart';
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
            // Drag handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

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
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    iconSize: 20,
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

    if (detail.templateSnapshot != null) {
      try {
        final map = jsonDecode(detail.templateSnapshot!);

        if (map['scoringLogicConfig'] != null) {
          try {
            final configMap = map['scoringLogicConfig'] is String
                ? jsonDecode(map['scoringLogicConfig'])
                : map['scoringLogicConfig'];
            scoringMode =
                configMap['mode'] ?? configMap['scoringMode'] ?? 'penalty';
          } catch (_) {}
        }

        if (map['groups'] != null) {
          final rawGroups = (map['groups'] as List<dynamic>)
              .cast<Map<String, dynamic>>();
          final Map<String, GroupDto> groupMap = {};

          for (final rg in rawGroups) {
            final gid = rg['id'] as String;
            final rawCriteria =
                (rg['criteria'] as List<dynamic>?)
                    ?.cast<Map<String, dynamic>>() ??
                [];
            final criteria = rawCriteria
                .map(
                  (c) => CriterionDto(
                    id: c['id'] as String,
                    label: c['label'] as String,
                    inputType: c['inputType'] as String? ?? 'pass_fail',
                    pointsWeight: (c['pointsWeight'] as num?)?.toDouble(),
                    isCcp: c['isCcp'] as bool? ?? false,
                    isRisk: c['isRisk'] as bool? ?? false,
                    minusImpact: (c['minusImpact'] as num?)?.toDouble(),
                    maxDeductionPoints: (c['maxDeductionPoints'] as num?)
                        ?.toDouble(),
                    orderIndex: c['orderIndex'] as int? ?? 0,
                  ),
                )
                .toList();

            groupMap[gid] = GroupDto(
              id: gid,
              title: rg['title'] as String,
              description: rg['description'] as String?,
              weight: (rg['weight'] as num?)?.toDouble(),
              maxDeductionPoints: (rg['maxDeductionPoints'] as num?)
                  ?.toDouble(),
              minusPerFault: (rg['minusPerFault'] as num?)?.toDouble(),
              orderIndex: rg['orderIndex'] as int? ?? 0,
              children: [],
              criteria: criteria,
            );
          }

          rootGroups = [];
          for (final rg in rawGroups) {
            final gid = rg['id'] as String;
            final parentId = rg['parentId'] as String?;
            final group = groupMap[gid]!;

            if (parentId != null && groupMap.containsKey(parentId)) {
              groupMap[parentId]!.children.add(group);
            } else {
              rootGroups.add(group);
            }
          }

          void sortGroups(List<GroupDto> groups) {
            groups.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
            for (final g in groups) {
              g.criteria.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
              sortGroups(g.children);
            }
          }

          sortGroups(rootGroups);
        }
      } catch (e) {
        debugPrint('Snapshot parse error: $e');
      }
    }

    final Map<String, CriterionDto> criteriaMap = {};
    if (rootGroups != null) {
      void walk(GroupDto group) {
        for (final c in group.criteria) {
          criteriaMap[c.id] = c;
        }
        for (final child in group.children) {
          walk(child);
        }
      }

      for (final g in rootGroups) {
        walk(g);
      }
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        // Header card
        HeaderCard(detail: detail, scoringMode: scoringMode),
        const SizedBox(height: 16),

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
            (g) => _buildGroup(
              g,
              {
                for (var a in detail.answers)
                  if (a.criteriaId != null) a.criteriaId!: a,
              },
              scoringMode,
              0,
              theme,
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

  bool _groupHasAnswers(GroupDto group, Map<String, AnswerDto> answersMap) {
    if (group.criteria.any((c) => answersMap.containsKey(c.id))) return true;
    if (group.children.any((child) => _groupHasAnswers(child, answersMap))) {
      return true;
    }
    return false;
  }

  Widget _buildGroup(
    GroupDto group,
    Map<String, AnswerDto> answersMap,
    String scoringMode,
    int depth,
    ThemeData theme,
  ) {
    if (!_groupHasAnswers(group, answersMap)) return const SizedBox.shrink();

    if (depth == 0) {
      // Top-level Visual Folder / Area (e.g., "H - Hospitality")
      // Render as a bold header, followed by its children
      final topLevelCriteria = group.criteria
          .where((c) => answersMap.containsKey(c.id))
          .toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 12, left: 4),
            child: Text(
              group.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          // Directly render criteria if any exist at level 0
          if (topLevelCriteria.isNotEmpty)
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < topLevelCriteria.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ReadOnlyCriterionRow(
                        answer: answersMap[topLevelCriteria[i].id]!,
                        criterion: topLevelCriteria[i],
                        scoringMode: scoringMode,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          // Render children
          ...group.children
              .where((child) => _groupHasAnswers(child, answersMap))
              .map(
                (child) => _buildGroup(
                  child,
                  answersMap,
                  scoringMode,
                  depth + 1,
                  theme,
                ),
              ),
        ],
      );
    } else {
      // Depth >= 1 (e.g., "H1", "H2")
      // Render as a single static Card containing the title and criteria
      final matchingCriteria = group.criteria
          .where((c) => answersMap.containsKey(c.id))
          .toList();

      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Text(
                group.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (matchingCriteria.isNotEmpty) const Divider(height: 1),
            // Criteria Rows
            for (var i = 0; i < matchingCriteria.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ReadOnlyCriterionRow(
                  answer: answersMap[matchingCriteria[i].id]!,
                  criterion: matchingCriteria[i],
                  scoringMode: scoringMode,
                ),
              ),
            ],
            // Nested children (if any)
            if (group.children.any(
              (child) => _groupHasAnswers(child, answersMap),
            )) ...[
              const Divider(height: 1),
              ...group.children
                  .where((child) => _groupHasAnswers(child, answersMap))
                  .map(
                    (child) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildGroup(
                        child,
                        answersMap,
                        scoringMode,
                        depth + 1,
                        theme,
                      ),
                    ),
                  ),
            ],
          ],
        ),
      );
    }
  }
}
