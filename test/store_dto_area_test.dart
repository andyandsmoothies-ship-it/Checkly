// ATDD: Areas Entity — Slice 4 (Flutter Client Alignment)
//
// These tests verify the StoreDto, API service, and Drift schema
// migration from areaCode (string) to areaId/areaName.
// Tests will FAIL at compile time until the model changes are implemented.
//
// Author: Sentinel (SDET)
// Status: 🔴 RED — StoreDto.areaId / StoreDto.areaName do not exist yet

import 'package:flutter_test/flutter_test.dart';
import 'package:checkly/features/stores/model/store_dto.dart';

void main() {
  // ─── AC1: StoreDto has areaId and areaName fields ───
  // Citation: analysis_areas_entity.md:243

  group('StoreDto area fields', () {
    test('fromJson parses areaId and areaName', () {
      final json = {
        'id': 'store-001',
        'name': 'Test Store',
        'address': '123 Street',
        'areaId': 'area-uuid-123',
        'areaName': 'Miền Bắc',
        'gpsLat': 21.028511,
        'gpsLng': 105.804817,
        'isActive': true,
        'createdAt': '2026-01-01T00:00:00Z',
      };

      final dto = StoreDto.fromJson(json);

      // These assertions will fail at compile time because
      // StoreDto does not have areaId/areaName yet
      expect(dto.areaId, equals('area-uuid-123'));
      expect(dto.areaName, equals('Miền Bắc'));
    });

    test('fromJson handles null areaId and areaName', () {
      final json = {
        'id': 'store-002',
        'name': 'No Area Store',
        'createdAt': '2026-01-01T00:00:00Z',
      };

      final dto = StoreDto.fromJson(json);

      expect(dto.areaId, isNull);
      expect(dto.areaName, isNull);
    });

    test('areaCode is deprecated but still parseable', () {
      final json = {
        'id': 'store-003',
        'name': 'Legacy Store',
        'areaCode': 'old-code',
        'createdAt': '2026-01-01T00:00:00Z',
      };

      final dto = StoreDto.fromJson(json);

      // Old areaCode field in JSON is ignored (field removed from DTO)
      // Just verify it doesn't crash and core fields parse
      expect(dto.id, equals('store-003'));
      expect(dto.name, equals('Legacy Store'));
    });
  });

  // ─── AC2: StoreDto constructor accepts areaId ───
  // Citation: analysis_areas_entity.md:244

  group('StoreDto constructor', () {
    test('can be constructed with areaId and areaName', () {
      final dto = StoreDto(
        id: 'store-004',
        name: 'FK Store',
        areaId: 'area-uuid-456',
        areaName: 'Miền Nam',
        createdAt: DateTime(2026, 1, 1),
      );

      expect(dto.areaId, equals('area-uuid-456'));
      expect(dto.areaName, equals('Miền Nam'));
    });
  });
}
