import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/models/address.dart';
import '../../../core/services/google_api_service.dart';

class GoogleMapLocationPicker extends StatefulWidget {
  final Address? initialAddress;
  final Function(double lat, double lng, String address)? onLocationChanged;
  final bool readOnly;

  const GoogleMapLocationPicker({
    super.key,
    this.initialAddress,
    this.onLocationChanged,
    this.readOnly = false,
  });

  @override
  State<GoogleMapLocationPicker> createState() =>
      _GoogleMapLocationPickerState();
}

class _GoogleMapLocationPickerState extends State<GoogleMapLocationPicker> {
  late GoogleMapController _mapController;
  late GoogleApiService _googleApiService;
  final TextEditingController _searchController = TextEditingController();

  LatLng _currentLocation = const LatLng(
    11.5564,
    104.9282,
  ); // Default to Phnom Penh
  Set<Marker> _markers = {};
  bool _isSearching = false;
  List<PlaceSearchResult> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _googleApiService = GoogleApiService();

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

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (widget.initialAddress?.latitude != null &&
        widget.initialAddress?.longitude != null) {
      _updateMarker(_currentLocation);
    }
  }

  void _updateMarker(LatLng position) {
    setState(() {
      _currentLocation = position;
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: position,
          draggable: !widget.readOnly,
          onDragEnd: (newPosition) {
            _onLocationChanged(newPosition);
          },
          infoWindow: const InfoWindow(
            title: 'Selected Location',
            snippet: 'Drag to move',
          ),
        ),
      };
    });
  }

  void _onMapTap(LatLng position) {
    if (widget.readOnly) return;
    _onLocationChanged(position);
  }

  void _onLocationChanged(LatLng position) {
    _updateMarker(position);
    _mapController.animateCamera(CameraUpdate.newLatLng(position));

    // Reverse geocode to get address
    _reverseGeocode(position);

    // Notify parent
    if (widget.onLocationChanged != null) {
      widget.onLocationChanged!(position.latitude, position.longitude, '');
    }
  }

  void _reverseGeocode(LatLng position) async {
    try {
      final result = await _googleApiService.geocodeLocation(
        position.latitude,
        position.longitude,
      );

      if (result != null && widget.onLocationChanged != null) {
        widget.onLocationChanged!(
          position.latitude,
          position.longitude,
          result.formattedAddress,
        );
      }
    } catch (e) {
      print('Error reverse geocoding: $e');
    }
  }

  void _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _googleApiService.searchPlaces(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      print('Error searching places: $e');
    }
  }

  void _selectPlace(PlaceSearchResult place) async {
    setState(() {
      _searchResults = [];
      _searchController.text = place.description;
    });

    try {
      final details = await _googleApiService.getPlaceDetails(place.placeId);
      if (details != null) {
        final position = LatLng(details.lat, details.lng);
        _onLocationChanged(position);
      }
    } catch (e) {
      print('Error getting place details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search TextField
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search location...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _isSearching
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchResults = [];
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  // Debounce search
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (_searchController.text == value) {
                      _searchPlaces(value);
                    }
                  });
                },
              ),

              // Search Results
              if (_searchResults.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final result = _searchResults[index];
                      return ListTile(
                        leading: const Icon(Icons.location_on),
                        title: Text(result.mainText),
                        subtitle: Text(result.secondaryText),
                        onTap: () => _selectPlace(result),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),

        // Google Map
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE1E5E9)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                onTap: _onMapTap,
                initialCameraPosition: CameraPosition(
                  target: _currentLocation,
                  zoom: 15,
                ),
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: true,
                mapToolbarEnabled: false,
                compassEnabled: true,
                rotateGesturesEnabled: true,
                scrollGesturesEnabled: true,
                zoomGesturesEnabled: true,
                tiltGesturesEnabled: true,
              ),
            ),
          ),
        ),

        // Coordinates display
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.my_location, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Lat: ${_currentLocation.latitude.toStringAsFixed(6)}, Lng: ${_currentLocation.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
