import '../../../_shared/constants/user_persona.dart';

class ScheduleAuditFormLogic {
  static List<Map<String, dynamic>> filterAuditors({
    required String? selectedStoreId,
    required List<Map<String, dynamic>> allAuditors,
    required List<Map<String, dynamic>> allStores,
  }) {
    if (selectedStoreId == null) return List.from(allAuditors);

    return allAuditors.where((u) {
      final role = u['role'] as String?;
      if (UserPersona.fromRole(role) == UserPersona.areaManager) {
        final assignedStoreIds =
            (u['assignedStoreIds'] as List<dynamic>?)?.cast<String>() ??
            <String>[];
        return assignedStoreIds.contains(selectedStoreId);
      } else {
        return true;
      }
    }).toList();
  }

  static List<Map<String, dynamic>> filterStores({
    required String? selectedAuditorId,
    required List<Map<String, dynamic>> allStores,
    required List<Map<String, dynamic>> allAuditors,
  }) {
    if (selectedAuditorId == null) return List.from(allStores);

    final auditor = allAuditors.firstWhere(
      (u) => u['id'] == selectedAuditorId,
      orElse: () => <String, dynamic>{},
    );

    final role = auditor['role'] as String?;
    if (UserPersona.fromRole(role) == UserPersona.areaManager) {
      final assignedStoreIds =
          (auditor['assignedStoreIds'] as List<dynamic>?)?.cast<String>() ??
          <String>[];
      return allStores
          .where((s) => assignedStoreIds.contains(s['id']))
          .toList();
    } else {
      return List.from(allStores);
    }
  }
}
