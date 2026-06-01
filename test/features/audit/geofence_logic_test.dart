import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:geolocator/geolocator.dart';

import 'package:checkly/_shared/services/geofence_service.dart';
import 'package:checkly/_shared/services/gps_service.dart';

class MockGpsService extends Mock implements GpsService {}

void main() {
  late MockGpsService mockGpsService;
  late GeofenceService geofenceService;

  setUp(() {
    mockGpsService = MockGpsService();
    geofenceService = GeofenceService(mockGpsService);
  });

  group('GeofenceService - Strict Mode (TC-GEOFENCE-01)', () {
    test('Scenario A: Out of Range blocks submission', () async {
      // Arrange: mock GPS to return user coordinates that are out of range
      final userPos = Position(
        latitude: 21.033333,
        longitude: 105.800000,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 10.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );

      when(() => mockGpsService.getCurrentPosition()).thenAnswer((_) async => userPos);
      when(() => mockGpsService.checkProximity(
        userLat: 21.033333,
        userLng: 105.800000,
        storeLat: 21.028511,
        storeLng: 105.804817,
        maxDistance: 200,
      )).thenReturn((inRange: false, distance: 750));

      // Act
      final result = await geofenceService.validate(
        storeLat: 21.028511,
        storeLng: 105.804817,
        geofenceMode: 'strict',
        geofenceRadiusMeters: 200,
      );

      // Assert
      expect(result.allowed, isFalse);
      expect(result.mustBlock, isTrue);
      expect(result.mustWarn, isFalse);
      expect(result.distanceMeters, 750);
      expect(result.error, isNull);
    });

    test('Scenario B: GPS Unavailable blocks submission with error message', () async {
      // Arrange: mock GPS to return null (unavailable/permissions denied)
      when(() => mockGpsService.getCurrentPosition()).thenAnswer((_) async => null);

      // Act
      final result = await geofenceService.validate(
        storeLat: 21.028511,
        storeLng: 105.804817,
        geofenceMode: 'strict',
        geofenceRadiusMeters: 200,
      );

      // Assert
      expect(result.allowed, isFalse);
      expect(result.mustBlock, isTrue);
      expect(result.mustWarn, isFalse);
      expect(result.distanceMeters, isNull);
      expect(result.error, 'GPS location is unavailable');
    });

    test('Scenario C: Store location missing blocks submission with error message', () async {
      // Act
      final result = await geofenceService.validate(
        storeLat: null,
        storeLng: null,
        geofenceMode: 'strict',
        geofenceRadiusMeters: 200,
      );

      // Assert
      expect(result.allowed, isFalse);
      expect(result.mustBlock, isTrue);
      expect(result.mustWarn, isFalse);
      expect(result.distanceMeters, isNull);
      expect(result.error, 'Store location is missing');
    });
  });

  group('GeofenceService - Lax Mode (TC-GEOFENCE-02)', () {
    test('Scenario A: Out of Range warns but allows bypass', () async {
      // Arrange: mock GPS to return user coordinates that are out of range
      final userPos = Position(
        latitude: 21.033333,
        longitude: 105.800000,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 10.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );

      when(() => mockGpsService.getCurrentPosition()).thenAnswer((_) async => userPos);
      when(() => mockGpsService.checkProximity(
        userLat: 21.033333,
        userLng: 105.800000,
        storeLat: 21.028511,
        storeLng: 105.804817,
        maxDistance: 200,
      )).thenReturn((inRange: false, distance: 750));

      // Act
      final result = await geofenceService.validate(
        storeLat: 21.028511,
        storeLng: 105.804817,
        geofenceMode: 'lax',
        geofenceRadiusMeters: 200,
      );

      // Assert
      expect(result.allowed, isTrue);
      expect(result.mustBlock, isFalse);
      expect(result.mustWarn, isTrue);
      expect(result.distanceMeters, 750);
      expect(result.error, isNull);
    });

    test('Scenario B: GPS Unavailable warns but allows bypass', () async {
      // Arrange: mock GPS to return null (unavailable/permissions denied)
      when(() => mockGpsService.getCurrentPosition()).thenAnswer((_) async => null);

      // Act
      final result = await geofenceService.validate(
        storeLat: 21.028511,
        storeLng: 105.804817,
        geofenceMode: 'lax',
        geofenceRadiusMeters: 200,
      );

      // Assert
      expect(result.allowed, isTrue);
      expect(result.mustBlock, isFalse);
      expect(result.mustWarn, isTrue);
      expect(result.distanceMeters, isNull);
      expect(result.error, 'GPS location is unavailable');
    });

    test('Scenario C: Store location missing warns but allows bypass', () async {
      // Act
      final result = await geofenceService.validate(
        storeLat: null,
        storeLng: null,
        geofenceMode: 'lax',
        geofenceRadiusMeters: 200,
      );

      // Assert
      expect(result.allowed, isTrue);
      expect(result.mustBlock, isFalse);
      expect(result.mustWarn, isTrue);
      expect(result.distanceMeters, isNull);
      expect(result.error, 'Store location is missing');
    });
  });

  group('GeofenceService - None Mode', () {
    test('Skips geofence check and allows submission unconditionally', () async {
      // Act
      final result = await geofenceService.validate(
        storeLat: 21.028511,
        storeLng: 105.804817,
        geofenceMode: 'none',
        geofenceRadiusMeters: 200,
      );

      // Assert
      expect(result.allowed, isTrue);
      expect(result.mustBlock, isFalse);
      expect(result.mustWarn, isFalse);
      expect(result.distanceMeters, isNull);
      expect(result.error, isNull);

      // Verify that GpsService was never called
      verifyNever(() => mockGpsService.getCurrentPosition());
    });
  });

  group('GeofenceService - Successful In-Range Proximity', () {
    test('Strict Mode: allows submission without warning or blocks', () async {
      // Arrange: mock GPS to return user coordinates that are within range
      final userPos = Position(
        latitude: 21.028600,
        longitude: 105.804900,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 10.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );

      when(() => mockGpsService.getCurrentPosition()).thenAnswer((_) async => userPos);
      when(() => mockGpsService.checkProximity(
        userLat: 21.028600,
        userLng: 105.804900,
        storeLat: 21.028511,
        storeLng: 105.804817,
        maxDistance: 200,
      )).thenReturn((inRange: true, distance: 15));

      // Act
      final result = await geofenceService.validate(
        storeLat: 21.028511,
        storeLng: 105.804817,
        geofenceMode: 'strict',
        geofenceRadiusMeters: 200,
      );

      // Assert
      expect(result.allowed, isTrue);
      expect(result.mustBlock, isFalse);
      expect(result.mustWarn, isFalse);
      expect(result.distanceMeters, 15);
      expect(result.error, isNull);
    });

    test('Lax Mode: allows submission without warning or blocks', () async {
      // Arrange: mock GPS to return user coordinates that are within range
      final userPos = Position(
        latitude: 21.028600,
        longitude: 105.804900,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 10.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );

      when(() => mockGpsService.getCurrentPosition()).thenAnswer((_) async => userPos);
      when(() => mockGpsService.checkProximity(
        userLat: 21.028600,
        userLng: 105.804900,
        storeLat: 21.028511,
        storeLng: 105.804817,
        maxDistance: 200,
      )).thenReturn((inRange: true, distance: 15));

      // Act
      final result = await geofenceService.validate(
        storeLat: 21.028511,
        storeLng: 105.804817,
        geofenceMode: 'lax',
        geofenceRadiusMeters: 200,
      );

      // Assert
      expect(result.allowed, isTrue);
      expect(result.mustBlock, isFalse);
      expect(result.mustWarn, isFalse);
      expect(result.distanceMeters, 15);
      expect(result.error, isNull);
    });
  });
}
