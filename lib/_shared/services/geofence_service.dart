import 'package:checkly/_shared/services/gps_service.dart';

class GeofenceValidationResult {
  final bool allowed;
  final bool mustBlock;
  final bool mustWarn;
  final int? distanceMeters;
  final String? error;

  const GeofenceValidationResult({
    required this.allowed,
    this.mustBlock = false,
    this.mustWarn = false,
    this.distanceMeters,
    this.error,
  });
}

class GeofenceMode {
  static const String strict = 'strict';
  static const String lax = 'lax';
  static const String none = 'none';
}

class GeofenceService {
  final GpsService _gpsService;

  GeofenceService(this._gpsService);

  Future<GeofenceValidationResult> validate({
    required double? storeLat,
    required double? storeLng,
    required String geofenceMode,
    required int geofenceRadiusMeters,
  }) async {
    if (geofenceMode == GeofenceMode.none) {
      return const GeofenceValidationResult(
        allowed: true,
        mustBlock: false,
        mustWarn: false,
      );
    }

    final isStrict = geofenceMode == GeofenceMode.strict;

    if (storeLat == null || storeLng == null) {
      const errorMsg = 'Store location is missing';
      return GeofenceValidationResult(
        allowed: !isStrict,
        mustBlock: isStrict,
        mustWarn: !isStrict,
        error: errorMsg,
      );
    }

    final userPosition = await _gpsService.getCurrentPosition();
    if (userPosition == null) {
      const errorMsg = 'GPS location is unavailable';
      return GeofenceValidationResult(
        allowed: !isStrict,
        mustBlock: isStrict,
        mustWarn: !isStrict,
        error: errorMsg,
      );
    }

    final proximity = _gpsService.checkProximity(
      userLat: userPosition.latitude,
      userLng: userPosition.longitude,
      storeLat: storeLat,
      storeLng: storeLng,
      maxDistance: geofenceRadiusMeters,
    );

    if (proximity.inRange) {
      return GeofenceValidationResult(
        allowed: true,
        mustBlock: false,
        mustWarn: false,
        distanceMeters: proximity.distance,
      );
    } else {
      return GeofenceValidationResult(
        allowed: !isStrict,
        mustBlock: isStrict,
        mustWarn: !isStrict,
        distanceMeters: proximity.distance,
      );
    }
  }
}
