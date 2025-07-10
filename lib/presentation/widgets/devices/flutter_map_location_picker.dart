import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/models/address.dart';
import '../../../core/constants/app_colors.dart';

class FlutterMapLocationPicker extends StatefulWidget {
  final Address? initialAddress;
  final Function(double lat, double lng, String address)? onLocationChanged;
  final bool readOnly;

  const FlutterMapLocationPicker({
    super.key,
    this.initialAddress,
    this.onLocationChanged,
    this.readOnly = false,
  });

  @override
  State<FlutterMapLocationPicker> createState() =>
      _FlutterMapLocationPickerState();
}

class _FlutterMapLocationPickerState extends State<FlutterMapLocationPicker> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  LatLng _currentLocation = const LatLng(
    11.5564,
    104.9282,
  ); // Default to Phnom Penh
  List<Marker> _markers = [];
  bool _isLoadingCurrentLocation = false;

  @override
  void initState() {
    super.initState();

    // Initialize with provided address or default location
    if (widget.initialAddress?.latitude != null &&
        widget.initialAddress?.longitude != null) {
      _currentLocation = LatLng(
        widget.initialAddress!.latitude!,
        widget.initialAddress!.longitude!,
      );
      _updateMarker(_currentLocation);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateMarker(LatLng position) {
    setState(() {
      _markers = [
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
      ];
      _currentLocation = position;
    });

    // Call the callback if provided
    if (widget.onLocationChanged != null) {
      widget.onLocationChanged!(
        position.latitude,
        position.longitude,
        'Selected Location', // You could implement reverse geocoding here
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingCurrentLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      Position position = await Geolocator.getCurrentPosition();
      LatLng currentLatLng = LatLng(position.latitude, position.longitude);

      _updateMarker(currentLatLng);
      _mapController.move(currentLatLng, 15.0);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingCurrentLocation = false;
      });
    }
  }

  void _onTap(TapPosition tapPosition, LatLng point) {
    if (!widget.readOnly) {
      _updateMarker(point);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // Search and controls header
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search location...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    enabled: !widget.readOnly,
                    onSubmitted: _searchLocation,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: widget.readOnly ? null : _getCurrentLocation,
                  icon: _isLoadingCurrentLocation
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  tooltip: 'Use current location',
                ),
              ],
            ),
          ),
          // Map
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentLocation,
                  initialZoom: 15.0,
                  onTap: _onTap,
                  interactionOptions: InteractionOptions(
                    flags: widget.readOnly
                        ? InteractiveFlag.pinchZoom | InteractiveFlag.drag
                        : InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.mdms_clone',
                  ),
                  MarkerLayer(markers: _markers),
                ],
              ),
            ),
          ),
          // Location info footer
          if (_markers.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Lat: ${_currentLocation.latitude.toStringAsFixed(6)}, '
                      'Lng: ${_currentLocation.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _searchLocation(String query) {
    // For now, just show a message. You could implement a geocoding service here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Search functionality would require a geocoding service'),
      ),
    );
  }
}
