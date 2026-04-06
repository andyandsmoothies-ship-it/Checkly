// Dart models matching backend Template DTOs.
// See: server/Features/Templates/Dtos.cs

import 'dart:convert';

String? _parseJsonString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  try {
    return jsonEncode(value);
  } catch (_) {
    return value.toString();
  }
}

/// Lightweight template for list views.
class TemplateDto {
  final String id;
  final String title;
  final String? description;
  final String type;
  final int version;
  final String? scoringLogicConfig;
  final String? displayNoun;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TemplateDto({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    required this.version,
    this.scoringLogicConfig,
    this.displayNoun,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TemplateDto.fromJson(Map<String, dynamic> json) => TemplateDto(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String?,
    type: json['type'] as String,
    version: json['version'] as int,
    scoringLogicConfig: _parseJsonString(json['scoringLogicConfig']),
    displayNoun: json['displayNoun'] as String?,
    isActive: json['isActive'] as bool,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

/// Full template tree with nested groups and criteria.
class TemplateTreeDto {
  final String id;
  final String title;
  final String? description;
  final String type;
  final int version;
  final String? scoringLogicConfig;
  final String? displayNoun;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<GroupDto> groups;

  const TemplateTreeDto({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    required this.version,
    this.scoringLogicConfig,
    this.displayNoun,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.groups,
  });

  factory TemplateTreeDto.fromJson(Map<String, dynamic> json) =>
      TemplateTreeDto(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        type: json['type'] as String,
        version: json['version'] as int,
        scoringLogicConfig: _parseJsonString(json['scoringLogicConfig']),
        displayNoun: json['displayNoun'] as String?,
        isActive: json['isActive'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        groups: (json['groups'] as List<dynamic>)
            .map((g) => GroupDto.fromJson(g as Map<String, dynamic>))
            .toList(),
      );
}

/// Self-referencing group (section/subsection) with criteria.
class GroupDto {
  final String id;
  final String title;
  final String? description;
  final double? weight;
  final double? maxDeductionPoints;
  final double? minusPerFault;
  final int orderIndex;
  final String? metadata;
  final List<GroupDto> children;
  final List<CriterionDto> criteria;

  const GroupDto({
    required this.id,
    required this.title,
    this.description,
    this.weight,
    this.maxDeductionPoints,
    this.minusPerFault,
    required this.orderIndex,
    this.metadata,
    required this.children,
    required this.criteria,
  });

  factory GroupDto.fromJson(Map<String, dynamic> json) => GroupDto(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String?,
    weight: (json['weight'] as num?)?.toDouble(),
    maxDeductionPoints: (json['maxDeductionPoints'] as num?)?.toDouble(),
    minusPerFault: (json['minusPerFault'] as num?)?.toDouble(),
    orderIndex: json['orderIndex'] as int,
    metadata: _parseJsonString(json['metadata']),
    children:
        (json['children'] as List<dynamic>?)
            ?.map((g) => GroupDto.fromJson(g as Map<String, dynamic>))
            .toList() ??
        [],
    criteria:
        (json['criteria'] as List<dynamic>?)
            ?.map((c) => CriterionDto.fromJson(c as Map<String, dynamic>))
            .toList() ??
        [],
  );
}

/// Individual audit criterion (question).
class CriterionDto {
  final String id;
  final String label;
  final String? description;
  final String inputType; // 'pass_fail', 'scale', 'numeric'
  final double? pointsWeight;
  final bool isCcp;
  final bool isRisk;
  final double? minusImpact;
  final int orderIndex;
  final String? metadata;

  const CriterionDto({
    required this.id,
    required this.label,
    this.description,
    required this.inputType,
    this.pointsWeight,
    required this.isCcp,
    required this.isRisk,
    this.minusImpact,
    required this.orderIndex,
    this.metadata,
  });

  factory CriterionDto.fromJson(Map<String, dynamic> json) => CriterionDto(
    id: json['id'] as String,
    label: json['label'] as String,
    description: json['description'] as String?,
    inputType: json['inputType'] as String,
    pointsWeight: (json['pointsWeight'] as num?)?.toDouble(),
    isCcp: json['isCcp'] as bool,
    isRisk: json['isRisk'] as bool,
    minusImpact: (json['minusImpact'] as num?)?.toDouble(),
    orderIndex: json['orderIndex'] as int,
    metadata: _parseJsonString(json['metadata']),
  );
}
