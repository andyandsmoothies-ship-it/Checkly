import 'dart:convert';

import 'package:flutter/material.dart';

import '../model/template_dto.dart';
import 'editable_criterion.dart';

class EditableGroup {
  final String id;
  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final TextEditingController weightCtrl;
  final TextEditingController maxPointsCtrl;
  final TextEditingController minusPerFaultCtrl;
  List<EditableCriterion> criteria;
  List<EditableGroup> subSections;

  EditableGroup({
    this.id = '',
    String title = '',
    String description = '',
    String weight = '',
    String maxPoints = '',
    String minusPerFault = '',
    List<EditableCriterion>? criteria,
    List<EditableGroup>? subSections,
  }) : titleCtrl = TextEditingController(text: title),
       descCtrl = TextEditingController(text: description),
       weightCtrl = TextEditingController(text: weight),
       maxPointsCtrl = TextEditingController(text: maxPoints),
       minusPerFaultCtrl = TextEditingController(text: minusPerFault),
       criteria = criteria ?? [],
       subSections = subSections ?? [];

  factory EditableGroup.fromDto(GroupDto dto) {
    // Parse metadata for sub-section fields
    String maxPts = '';
    String minusPf = '';
    if (dto.metadata != null && dto.metadata!.isNotEmpty) {
      try {
        final meta = json.decode(dto.metadata!) as Map<String, dynamic>;
        if (meta['subsection_max_points'] != null) {
          maxPts = meta['subsection_max_points'].toString();
        }
        if (meta['minus_per_fault'] != null) {
          minusPf = meta['minus_per_fault'].toString();
        }
      } catch (e) {
        debugPrint('Group metadata parse: $e');
      }
    }
    return EditableGroup(
      id: dto.id,
      title: dto.title,
      description: dto.description ?? '',
      weight: dto.weight?.toString() ?? '',
      maxPoints: maxPts,
      minusPerFault: minusPf,
      criteria: dto.criteria.map((c) => EditableCriterion.fromDto(c)).toList(),
      subSections: dto.children.map((g) => EditableGroup.fromDto(g)).toList(),
    );
  }

  /// Recursive count of sub-sections.
  int countSubs() {
    var count = subSections.length;
    for (final s in subSections) {
      count += s.countSubs();
    }
    return count;
  }

  /// Recursive count of criteria.
  int countCriteria() {
    var count = criteria.length;
    for (final s in subSections) {
      count += s.countCriteria();
    }
    return count;
  }

  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    weightCtrl.dispose();
    maxPointsCtrl.dispose();
    minusPerFaultCtrl.dispose();
    for (final c in criteria) {
      c.dispose();
    }
    for (final s in subSections) {
      s.dispose();
    }
  }
}
