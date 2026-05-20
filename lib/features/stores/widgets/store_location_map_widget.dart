import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Interactive map widget for pinning a store's GPS location.
/// Extracted from [StoreFormSheet] to keep that file within line limits.
///
/// [markerPos] — current pin position (null = no pin, shows Vietnam centre).
/// [mapController] — controller owned by the parent state.
/// [onTap] — called when the user taps the map to move the pin.
/// [isSaving] — when true, pointer events are blocked.
class StoreLocationMapWidget extends StatelessWidget {
  final LatLng? markerPos;
  final MapController mapController;
  final void Function(TapPosition, LatLng) onTap;
  final bool isSaving;

  const StoreLocationMapWidget({
    super.key,
    required this.markerPos,
    required this.mapController,
    required this.onTap,
    required this.isSaving,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 220,
            child: IgnorePointer(
              ignoring: isSaving,
              child: FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: markerPos ?? const LatLng(15.0, 108.0),
                  initialZoom: markerPos != null ? 14.0 : 5.5,
                  onTap: onTap,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.checkly.app',
                  ),
                  if (markerPos != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: markerPos!,
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.location_on,
                            color: Theme.of(context).colorScheme.primary,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap on the map to set store location',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
