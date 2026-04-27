import 'dart:convert';
import '../../templates/models/template_dto.dart';
import '../manager/audit_manager.dart';

int groupAnsweredCount(AuditManager manager, GroupDto group) {
  int count = 0;
  for (final c in group.criteria) {
    final a = manager.answers[c.id];
    if (a != null && (a.value != null || a.numericValue != null)) count++;
  }
  for (final child in group.children) {
    count += groupAnsweredCount(manager, child);
  }
  return count;
}

int groupTotalCount(GroupDto group) {
  int count = group.criteria.length;
  for (final child in group.children) {
    count += groupTotalCount(child);
  }
  return count;
}

bool allCriteriaAnswered(AuditManager manager, TemplateTreeDto template) {
  for (final group in template.groups) {
    if (groupAnsweredCount(manager, group) < groupTotalCount(group)) {
      return false;
    }
  }
  return true;
}

List<CriterionDto> getMissingRequired(
  AuditManager manager,
  TemplateTreeDto template,
  bool globalRequired,
) {
  final missing = <CriterionDto>[];

  void checkGroup(GroupDto group) {
    for (final c in group.criteria) {
      bool isRequired = globalRequired;
      if (!isRequired) {
        if (c.metadata != null && c.metadata!.isNotEmpty) {
          try {
            final meta = json.decode(c.metadata!) as Map<String, dynamic>;
            isRequired = meta['isRequired'] == true;
          } catch (_) {}
        }
      }

      if (isRequired) {
        final a = manager.answers[c.id];
        if (a == null || (a.value == null && a.numericValue == null)) {
          missing.add(c);
        }
      }
    }
    for (final child in group.children) {
      checkGroup(child);
    }
  }

  for (final group in template.groups) {
    checkGroup(group);
  }
  return missing;
}

int totalAnswered(AuditManager manager, TemplateTreeDto template) {
  int count = 0;
  for (final group in template.groups) {
    count += groupAnsweredCount(manager, group);
  }
  return count;
}

int totalCriteria(TemplateTreeDto template) {
  int count = 0;
  for (final group in template.groups) {
    count += groupTotalCount(group);
  }
  return count;
}
