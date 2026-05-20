/// Dart model matching backend StoreDto.
/// See: server/Features/Stores/Dtos.cs
class StoreDto {
  final String id;
  final String name;
  final String? address;

  final String? managerName;
  final double? gpsLat;
  final double? gpsLng;
  final bool? isActive;
  final DateTime createdAt;

  // SL-1: Structured address fields
  final String? addressProvince;
  final String? addressDistrict;
  final String? addressWard;
  final String? addressStreet;

  const StoreDto({
    required this.id,
    required this.name,
    this.address,

    this.managerName,
    this.gpsLat,
    this.gpsLng,
    this.isActive,
    required this.createdAt,
    // SL-1: Structured address fields
    this.addressProvince,
    this.addressDistrict,
    this.addressWard,
    this.addressStreet,
  });

  factory StoreDto.fromJson(Map<String, dynamic> json) => StoreDto(
    id: json['id'] as String,
    name: json['name'] as String,
    address: json['address'] as String?,

    managerName: json['managerName'] as String?,
    gpsLat: (json['gpsLat'] as num?)?.toDouble(),
    gpsLng: (json['gpsLng'] as num?)?.toDouble(),
    isActive: json['isActive'] as bool?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    // SL-1: Structured address fields
    addressProvince: json['addressProvince'] as String?,
    addressDistrict: json['addressDistrict'] as String?,
    addressWard: json['addressWard'] as String?,
    addressStreet: json['addressStreet'] as String?,
  );
}
