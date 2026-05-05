/// Dart model matching backend StoreDto.
/// See: server/Features/Stores/Dtos.cs
class StoreDto {
  final String id;
  final String name;
  final String? address;

  final String? areaId;
  final String? areaName;
  final String? managerName;
  final String? areaManagerName;
  final double? gpsLat;
  final double? gpsLng;
  final bool? isActive;
  final DateTime createdAt;

  const StoreDto({
    required this.id,
    required this.name,
    this.address,

    this.areaId,
    this.areaName,
    this.managerName,
    this.areaManagerName,
    this.gpsLat,
    this.gpsLng,
    this.isActive,
    required this.createdAt,
  });

  factory StoreDto.fromJson(Map<String, dynamic> json) => StoreDto(
    id: json['id'] as String,
    name: json['name'] as String,
    address: json['address'] as String?,

    areaId: json['areaId'] as String?,
    areaName: json['areaName'] as String?,
    managerName: json['managerName'] as String?,
    areaManagerName: json['areaManagerName'] as String?,
    gpsLat: (json['gpsLat'] as num?)?.toDouble(),
    gpsLng: (json['gpsLng'] as num?)?.toDouble(),
    isActive: json['isActive'] as bool?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
