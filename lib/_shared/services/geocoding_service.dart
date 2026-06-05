import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';
import 'connectivity_service.dart';

class GeocodedAddress {
  final String? province;
  final String? district;
  final String? ward;
  final String? street;
  final String? displayName;

  const GeocodedAddress({
    this.province,
    this.district,
    this.ward,
    this.street,
    this.displayName,
  });
}

class GeocodingException implements Exception {
  final String message;
  final bool isRateLimited;
  const GeocodingException(this.message, {this.isRateLimited = false});
  
  @override
  String toString() => message;
}

abstract class GeocodingService {
  Future<LatLng?> geocode(String address);
  Future<GeocodedAddress?> reverseGeocode(LatLng location);
}

class RealGeocodingService implements GeocodingService {
  final Dio dio;
  final ConnectivityService connectivityService;

  DateTime? _lastRequestTime;

  RealGeocodingService({
    required this.dio,
    required this.connectivityService,
  });

  void _checkThrottle() {
    final now = DateTime.now();
    if (_lastRequestTime != null) {
      final diff = now.difference(_lastRequestTime!);
      if (diff < const Duration(milliseconds: 1500)) {
        throw const GeocodingException('Too many requests. Please wait 1.5 seconds.');
      }
    }
    _lastRequestTime = now;
  }

  Options _getOptions() {
    return Options(
      headers: {
        'User-Agent': 'Checkly-Mobile-App/1.0 (contact@checkly.com)',
      },
    );
  }

  @override
  Future<LatLng?> geocode(String address) async {
    if (!connectivityService.isOnline) {
      throw const GeocodingException('Device is offline');
    }
    _checkThrottle();

    try {
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': address,
          'format': 'json',
          'limit': 1,
        },
        options: _getOptions(),
      );

      final data = response.data;
      if (data is List && data.isNotEmpty) {
        final first = data.first;
        if (first is Map) {
          final latStr = first['lat'];
          final lonStr = first['lon'];
          if (latStr != null && lonStr != null) {
            final lat = double.tryParse(latStr.toString());
            final lon = double.tryParse(lonStr.toString());
            if (lat != null && lon != null) {
              return LatLng(lat, lon);
            }
          }
        }
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        throw const GeocodingException(
          'Too many map requests. Please wait a moment or enter the coordinates manually.',
          isRateLimited: true,
        );
      }
      throw GeocodingException(e.message ?? 'Network error occurred during geocoding.');
    } catch (e) {
      if (e is GeocodingException) rethrow;
      throw GeocodingException(e.toString());
    }
  }

  @override
  Future<GeocodedAddress?> reverseGeocode(LatLng location) async {
    if (!connectivityService.isOnline) {
      throw const GeocodingException('Device is offline');
    }
    _checkThrottle();

    try {
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': location.latitude,
          'lon': location.longitude,
          'format': 'json',
        },
        options: _getOptions(),
      );

      final data = response.data;
      if (data is Map) {
        if (data.containsKey('error')) {
          return null;
        }
        final address = data['address'];
        if (address is Map) {
          final province = address['city'] ?? address['province'] ?? address['state'];
          final district = address['suburb'] ?? address['district'] ?? address['county'];
          final road = address['road'] ?? address['street'];
          final displayName = data['display_name'];

          if (province != null) {
            return GeocodedAddress(
              province: province.toString(),
              district: district?.toString(),
              street: road?.toString(),
              displayName: displayName?.toString(),
            );
          }
        }
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        throw const GeocodingException(
          'Too many map requests. Please wait a moment or enter the coordinates manually.',
          isRateLimited: true,
        );
      }
      throw GeocodingException(e.message ?? 'Network error occurred during reverse geocoding.');
    } catch (e) {
      if (e is GeocodingException) rethrow;
      throw GeocodingException(e.toString());
    }
  }

  @visibleForTesting
  void clearThrottle() {
    _lastRequestTime = null;
  }
}
