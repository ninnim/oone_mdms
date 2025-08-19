import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/models/address.dart';
import '../../../core/constants/app_colors.dart';
import '../common/app_card.dart';

class DeviceLocationViewer extends StatefulWidget {
  final Address? address;
  final String? addressText;

  const DeviceLocationViewer({super.key, this.address, this.addressText});

  @override
  State<DeviceLocationViewer> createState() => _DeviceLocationViewerState();
}

class _DeviceLocationViewerState extends State<DeviceLocationViewer> {
  final MapController _mapController = MapController();
  late LatLng _deviceLocation;
  List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  void _initializeLocation() {
    // Use device coordinates if available, otherwise default to Phnom Penh
    if (widget.address?.latitude != null && widget.address?.longitude != null) {
      _deviceLocation = LatLng(
        widget.address!.latitude!,
        widget.address!.longitude!,
      );
    } else {
      // Default location (Phnom Penh, Cambodia)
      _deviceLocation = const LatLng(11.5564, 104.9282);
    }

    _createMarker();
  }

  void _createMarker() {
    _markers = [
      Marker(
        point: _deviceLocation,
        width: 50,
        height: 50,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.router, color: Colors.white, size: 24),
        ),
      ),
    ];
  }

  bool get _hasValidLocation {
    return widget.address?.latitude != null &&
        widget.address?.longitude != null;
  }

  String get _locationText {
    if (!_hasValidLocation) {
      return 'Location not available';
    }

    return widget.addressText?.isNotEmpty == true
        ? widget.addressText!
        : widget.address!.street ?? 'Unknown address';
  }

  String get _coordinatesText {
    if (!_hasValidLocation) {
      return 'Coordinates not available';
    }

    return '${widget.address!.latitude!.toStringAsFixed(6)}, ${widget.address!.longitude!.toStringAsFixed(6)}';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: _hasValidLocation
          ? FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _deviceLocation,
                initialZoom: 15.0,
                interactionOptions: const InteractionOptions(
                  flags:
                      InteractiveFlag.pinchZoom |
                      InteractiveFlag.drag |
                      InteractiveFlag.doubleTapZoom,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.mdms_clone',
                ),
                MarkerLayer(markers: _markers),
              ],
            )
          : Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_off,
                      size: 64,
                      color: const Color(0xFF9CA3AF),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Location Not Available',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No GPS coordinates are set for this device',
                      style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
