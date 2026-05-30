import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../templates/models/template_dto.dart';

class AuditSnapshotResult {
  final List<GroupDto>? rootGroups;
  final Map<String, CriterionDto> criteriaMap;
  final String scoringMode;

  const AuditSnapshotResult({
    required this.rootGroups,
    required this.criteriaMap,
    required this.scoringMode,
  });
}

class AuditSnapshotParser {
  static AuditSnapshotResult parseSnapshot(String snapshotJson) {
    List<GroupDto>? rootGroups;
    String scoringMode = 'penalty';
    final Map<String, CriterionDto> criteriaMap = {};

    try {
      final map = jsonDecode(snapshotJson);

      if (map['scoringLogicConfig'] != null) {
        try {
          final configMap = map['scoringLogicConfig'] is String
              ? jsonDecode(map['scoringLogicConfig'])
              : map['scoringLogicConfig'];
          if (configMap is Map<String, dynamic>) {
            final scoreDirection = configMap['scoreDirection'] as String?;
            final isWeighted = configMap['isWeighted'] as bool? ?? false;

            if (scoreDirection != null) {
              if (scoreDirection == 'none') {
                scoringMode = 'survey';
              } else if (scoreDirection == 'up') {
                scoringMode = 'accumulation';
              } else if (scoreDirection == 'down') {
                scoringMode = isWeighted ? 'penalty' : 'checklist';
              }
            } else {
              scoringMode =
                  configMap['mode'] ?? configMap['scoringMode'] ?? 'penalty';
            }
          }
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
            maxDeductionPoints: (rg['maxDeductionPoints'] as num?)?.toDouble(),
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

    return AuditSnapshotResult(
      rootGroups: rootGroups,
      criteriaMap: criteriaMap,
      scoringMode: scoringMode,
    );
  }
}
