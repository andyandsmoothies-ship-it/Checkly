/// Dart model matching backend StoreDto.
/// See: server/Features/Stores/Dtos.cs
class StoreDto {
  final String id;
  final String name;
  final String? address;
  final String? areaCode;
  final double? gpsLat;
  final double? gpsLng;
  final bool? isActive;
  final DateTime createdAt;

  const StoreDto({
    required this.id,
    required this.name,
    this.address,
    this.areaCode,
    this.gpsLat,
    this.gpsLng,
    this.isActive,
    required this.createdAt,
  });

  factory StoreDto.fromJson(Map<String, dynamic> json) => StoreDto(
    id: json['id'] as String,
    name: json['name'] as String,
    address: json['address'] as String?,
    areaCode: json['areaCode'] as String?,
    gpsLat: (json['gpsLat'] as num?)?.toDouble(),
    gpsLng: (json['gpsLng'] as num?)?.toDouble(),
    isActive: json['isActive'] as bool?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
