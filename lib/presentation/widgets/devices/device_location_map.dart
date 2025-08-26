import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/models/address.dart';
import '../../../core/constants/app_colors.dart';
import '../../themes/app_theme.dart';

class DeviceLocationMap extends StatefulWidget {
  final Address? address;
  final bool readOnly;

  const DeviceLocationMap({super.key, this.address, this.readOnly = true});

  @override
  State<DeviceLocationMap> createState() => _DeviceLocationMapState();
}

class _DeviceLocationMapState extends State<DeviceLocationMap> {
  @override
  Widget build(BuildContext context) {
    if (widget.address?.latitude == null || widget.address?.longitude == null) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: context.surfaceVariantColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.borderColor),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off,
                size: 48,
                color: context.textSecondaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                'No location data available',
                style: TextStyle(
                  color: context.textSecondaryColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final position = LatLng(
      widget.address!.latitude!,
      widget.address!.longitude!,
    );

    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: kIsWeb
            ? _buildWebMapFallback()
            : FlutterMap(
                options: MapOptions(
                  initialCenter: position,
                  initialZoom: 15,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.mdms_clone',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: position,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_pin,
                          color: AppColors.primary,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildWebMapFallback() {
    return Container(
      width: double.infinity,
      height: 300,
      color: context.surfaceVariantColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map, size: 48, color: context.textSecondaryColor),
          const SizedBox(height: 8),
          Text(
            'Map View',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: context.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 4),
          if (widget.address?.latitude != null &&
              widget.address?.longitude != null)
            Text(
              'Lat: ${widget.address!.latitude!.toStringAsFixed(6)}, '
              'Lng: ${widget.address!.longitude!.toStringAsFixed(6)}',
              style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
            ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              final lat = widget.address!.latitude!;
              final lng = widget.address!.longitude!;
              // For web, we can open Google Maps in a new tab
              // This is just a placeholder - you could implement actual map opening
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Location: $lat, $lng'),
                  action: SnackBarAction(
                    label: 'Copy',
                    onPressed: () {
                      // Copy coordinates to clipboard
                    },
                  ),
                ),
              );
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open in Maps'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563eb),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}
