import 'dart:math';

import 'package:geolocator/geolocator.dart';

/// Lightweight GPS service — position + proximity check.
class GpsService {
  /// Max distance in meters before showing a warning.
  static const int maxDistanceMeters = 200;

  /// Gets the current GPS position, requesting permission if needed.
  /// Returns null if permission denied or unavailable.
  Future<Position?> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// Checks if [userLat],[userLng] is within [maxDistance] meters
  /// of [storeLat],[storeLng]. Uses Haversine formula.
  ({bool inRange, int? distance}) checkProximity({
    required double userLat,
    required double userLng,
    required double storeLat,
    required double storeLng,
    int maxDistance = maxDistanceMeters,
  }) {
    final d = _haversine(userLat, userLng, storeLat, storeLng);
    return (inRange: d <= maxDistance, distance: d.round());
  }

  /// Haversine distance in meters.
  static double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0; // Earth radius in meters
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  static double _toRadians(double degrees) => degrees * pi / 180;
}
