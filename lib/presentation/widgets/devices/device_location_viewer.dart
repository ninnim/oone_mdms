import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/models/address.dart';
// import '../../../core/constants/app_colors.dart';
import '../../themes/app_theme.dart';
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
  bool _markersInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_markersInitialized) {
      _createMarker();
      _markersInitialized = true;
    }
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
  }

  void _createMarker() {
    _markers = [
      Marker(
        point: _deviceLocation,
        width: 50,
        height: 50,
        child: Container(
          decoration: BoxDecoration(
            color: context.primaryColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? context.surfaceColor
                  : Colors.white,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: context.shadowColor,
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
                  urlTemplate: Theme.of(context).brightness == Brightness.dark
                      ? 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png'
                      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.mdms_clone',
                ),
                MarkerLayer(markers: _markers),
              ],
            )
          : Container(
              decoration: BoxDecoration(
                color: context.surfaceVariantColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_off,
                      size: 64,
                      color: context.textSecondaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Location Not Available',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No GPS coordinates are set for this device',
                      style: TextStyle(
                        fontSize: 14,
                        color: context.textSecondaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
