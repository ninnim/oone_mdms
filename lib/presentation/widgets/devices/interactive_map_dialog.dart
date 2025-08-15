

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mdms_clone/core/constants/app_sizes.dart';
import '../../../core/models/address.dart';
import '../../../core/services/google_maps_service.dart';
import '../../../core/services/service_locator.dart';
import '../common/app_button.dart';
import '../common/app_input_field.dart';
import '../common/app_toast.dart';

class InteractiveMapDialog extends StatefulWidget {
  final Address? initialAddress;
  final Function(Address address) onLocationSelected;

  const InteractiveMapDialog({
    super.key,
    this.initialAddress,
    required this.onLocationSelected,
  });

  @override
  State<InteractiveMapDialog> createState() => _InteractiveMapDialogState();
}

class _InteractiveMapDialogState extends State<InteractiveMapDialog> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  late GoogleMapsService _googleMapsService;
  Timer? _debounceTimer;

  LatLng _currentLocation = const LatLng(
    11.5564,
    104.9282,
  ); // Default to Phnom Penh
  List<Marker> _markers = [];
  List<PlaceSuggestion> _searchSuggestions = [];
  bool _isSearching = false;
  bool _showSuggestions = false;
  bool _isSaving = false;
  String _currentAddress = '';

  @override
  void initState() {
    super.initState();

    // Initialize Google Maps service
    final serviceLocator = ServiceLocator();
    _googleMapsService = GoogleMapsService(serviceLocator.apiService);

    // Set initial location if provided
    if (widget.initialAddress?.latitude != null &&
        widget.initialAddress?.longitude != null) {
      _currentLocation = LatLng(
        widget.initialAddress!.latitude!,
        widget.initialAddress!.longitude!,
      );
      _currentAddress = widget.initialAddress!.street ?? '';
      _searchController.text = _currentAddress;
    }

    _updateMarker(_currentLocation);

    // Load initial address if not provided
    if (_currentAddress.isEmpty) {
      _loadAddressFromCoordinates(
        _currentLocation.latitude,
        _currentLocation.longitude,
      );
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _updateMarker(LatLng position) {
    setState(() {
      _currentLocation = position;
      _markers = [
        Marker(
          point: position,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
        ),
      ];
    });
  }

  void _searchPlaces(String query) {
    // Cancel any existing timer
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _searchSuggestions = [];
        _showSuggestions = false;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // Set a new timer for 500ms
    _debounceTimer = Timer(const Duration(milliseconds: 600), () async {
      try {
        final suggestions = await _googleMapsService.searchPlaces(query);

        if (mounted) {
          setState(() {
            _searchSuggestions = suggestions;
            _showSuggestions = suggestions.isNotEmpty;
            _isSearching = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSearching = false;
            _showSuggestions = false;
          });
          AppToast.showError(
            context,
            title: 'Search Error',
            error: 'Failed to search places: $e',
          );
        }
      }
    });
  }

  Future<void> _selectSuggestion(PlaceSuggestion suggestion) async {
    setState(() {
      _showSuggestions = false;
      _searchController.text = suggestion.description;
      _isSearching = true;
    });

    try {
      final placeDetails = await _googleMapsService.getPlaceDetails(
        suggestion.placeId,
      );

      if (placeDetails != null && mounted) {
        final newLocation = LatLng(
          placeDetails.latitude,
          placeDetails.longitude,
        );

        setState(() {
          _currentAddress = placeDetails.formattedAddress;
          _isSearching = false;
        });

        _updateMarker(newLocation);
        _mapController.move(newLocation, 15.0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        AppToast.showError(
          context,
          title: 'Location Error',
          error: 'Failed to get location details: $e',
        );
      }
    }
  }

  Future<void> _loadAddressFromCoordinates(double lat, double lng) async {
    try {
      final address = await _googleMapsService.reverseGeocode(lat, lng);

      if (address != null && mounted) {
        setState(() {
          _currentAddress = address;
          if (_searchController.text.isEmpty) {
            _searchController.text = address;
          }
        });
      }
    } catch (e) {
      print('Error loading address: $e');
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    _updateMarker(point);
    _loadAddressFromCoordinates(point.latitude, point.longitude);
  }

  Future<void> _saveLocation() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Ensure we have the latest address
      if (_currentAddress.isEmpty) {
        await _loadAddressFromCoordinates(
          _currentLocation.latitude,
          _currentLocation.longitude,
        );
      }

      final address = Address(
        id: widget.initialAddress?.id ?? '',
        street: _currentAddress,
        city: '',
        state: '',
        postalCode: '',
        country: '',
        latitude: _currentLocation.latitude,
        longitude: _currentLocation.longitude,
      );

      widget.onLocationSelected(address);

      if (mounted) {
        Navigator.of(context).pop();
        AppToast.showSuccess(
          context,
          title: 'Location Updated',
          message: 'Location has been updated successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(
          context,
          title: 'Save Error',
          error: 'Failed to save location: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppSizes.spacing16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE1E5E9), width: 1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Color(0xFF2563eb),
                    size: AppSizes.iconMedium,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Select Location',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeLarge,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1e293b),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF8F9FA),
                      foregroundColor: const Color(0xFF64748b),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: AppSizes.inputWidth,
                        child: AppInputField(
                          controller: _searchController,
                          hintText: 'Enter address or place name...',
                          onChanged: _searchPlaces,
                          suffixIcon: _isSearching
                              ? const SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.search),
                        ),
                      ),
                    ],
                  ),

                  // Search Suggestions
                  if (_showSuggestions && _searchSuggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchSuggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = _searchSuggestions[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.location_on,
                              color: Color(0xFF64748b),
                              size: 20,
                            ),
                            title: Text(
                              suggestion.mainText,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1e293b),
                              ),
                            ),
                            subtitle: suggestion.secondaryText.isNotEmpty
                                ? Text(
                                    suggestion.secondaryText,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748b),
                                    ),
                                  )
                                : null,
                            onTap: () => _selectSuggestion(suggestion),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

            // Map
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentLocation,
                      initialZoom: 13.0,
                      onTap: _onMapTap,
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
            ),

            // Current Address Display
            if (_currentAddress.isNotEmpty)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.pin_drop,
                      color: Color(0xFF2563eb),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _currentAddress,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(
                  top: BorderSide(color: Color(0xFFE1E5E9), width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 100,
                    child: AppButton(
                      text: 'Cancel',
                      type: AppButtonType.outline,
                      size: AppButtonSize.small,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 100,
                    child: AppButton(
                      size: AppButtonSize.small,
                      text: _isSaving ? 'Saving...' : 'Save',
                      type: AppButtonType.primary,
                      onPressed: _isSaving ? null : _saveLocation,
                      icon:  Icon(Icons.save, size: AppSizes.iconSmall),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
