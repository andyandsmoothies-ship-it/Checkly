class ScheduleAuditFormLogic {
  static List<Map<String, dynamic>> filterAuditors({
    required String? selectedStoreId,
    required List<Map<String, dynamic>> allAuditors,
    required List<Map<String, dynamic>> allStores,
  }) {
    if (selectedStoreId == null) return List.from(allAuditors);

    final store = allStores.firstWhere(
      (s) => s['id'] == selectedStoreId,
      orElse: () => <String, dynamic>{},
    );
    final storeAreaId = store['areaId'] as String?;

    return allAuditors.where((u) {
      final role = u['role'] as String?;
      if (role == 'area_manager') {
        final assignedStoreIds =
            (u['assignedStoreIds'] as List<dynamic>?)?.cast<String>() ??
            <String>[];
        return assignedStoreIds.contains(selectedStoreId);
      } else {
        return u['areaId'] == storeAreaId || u['areaId'] == null;
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
    if (role == 'area_manager') {
      final assignedStoreIds =
          (auditor['assignedStoreIds'] as List<dynamic>?)?.cast<String>() ??
          <String>[];
      return allStores
          .where((s) => assignedStoreIds.contains(s['id']))
          .toList();
    } else {
      final auditorAreaId = auditor['areaId'] as String?;
      if (auditorAreaId != null) {
        return allStores.where((s) => s['areaId'] == auditorAreaId).toList();
      } else {
        return List.from(allStores);
      }
    }
  }
}
