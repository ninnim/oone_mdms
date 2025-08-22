import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mdms_clone/core/constants/app_sizes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/address.dart';
import '../../../core/services/google_maps_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/utils/responsive_helper.dart';
import '../common/app_button.dart';
import '../common/app_dialog_header.dart';
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
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.surface, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.location_pin, color: AppColors.surface, size: 24),
          ),
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
    // Responsive sizing
    final isMobile = MediaQuery.of(context).size.width < 768;
    final isTablet =
        MediaQuery.of(context).size.width >= 768 &&
        MediaQuery.of(context).size.width < 1024;

    // Responsive dialog sizing
    final dialogWidth = isMobile
        ? MediaQuery.of(context).size.width * 0.95
        : isTablet
        ? MediaQuery.of(context).size.width * 0.85
        : MediaQuery.of(context).size.width * 0.8;

    final dialogHeight = isMobile
        ? MediaQuery.of(context).size.height * 0.9
        : MediaQuery.of(context).size.height * 0.85;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(isMobile ? 8 : 16),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getCardBorderRadius(context),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Consistent Dialog Header
            AppDialogHeader(
              type: DialogType.edit,
              title: 'Select Location',
              subtitle: 'Choose a location on the map or search for an address',
              onClose: () => Navigator.of(context).pop(),
            ),

            // Search Bar Section
            Container(
              padding: ResponsiveHelper.getPadding(context),
              child: Column(
                children: [
                  _buildSearchField(context),
                  if (_showSuggestions && _searchSuggestions.isNotEmpty)
                    _buildSearchSuggestions(context),
                ],
              ),
            ),

            // Map Section
            Expanded(child: _buildMapSection(context)),

            // Current Address Display
            if (_currentAddress.isNotEmpty)
              _buildCurrentAddressDisplay(context),

            // Footer Actions
            _buildFooterActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Row(
      children: [
        Expanded(
          child: AppInputField.search(
            controller: _searchController,
            hintText: isMobile
                ? 'Search location...'
                : 'Enter address or place names...',
            onChanged: _searchPlaces,
            prefixIcon: Icon(
              Icons.search,
              size: AppSizes.iconSmall,
              color: AppColors.textSecondary,
            ),
            enabled: true,
          ),
        ),
        if (_isSearching) ...[
          SizedBox(width: ResponsiveHelper.getSpacing(context)),
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchSuggestions(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      margin: EdgeInsets.only(top: ResponsiveHelper.getSpacing(context)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getCardBorderRadius(context),
        ),
        border: Border.all(color: AppColors.border),
        boxShadow: [AppSizes.shadowMedium],
      ),
      constraints: BoxConstraints(maxHeight: isMobile ? 150 : 200),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _searchSuggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _searchSuggestions[index];
          return ListTile(
            dense: isMobile,
            leading: Icon(
              Icons.location_on,
              color: AppColors.textSecondary,
              size: isMobile ? 18 : 20,
            ),
            title: Text(
              suggestion.mainText,
              style: TextStyle(
                fontSize: isMobile ? 13 : 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: suggestion.secondaryText.isNotEmpty
                ? Text(
                    suggestion.secondaryText,
                    style: TextStyle(
                      fontSize: isMobile ? 11 : 12,
                      color: AppColors.textSecondary,
                    ),
                  )
                : null,
            onTap: () => _selectSuggestion(suggestion),
          );
        },
      ),
    );
  }

  Widget _buildMapSection(BuildContext context) {
    return Container(
      margin: ResponsiveHelper.getPadding(context),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getCardBorderRadius(context),
        ),
        border: Border.all(color: AppColors.border),
        boxShadow: [AppSizes.shadowSmall],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getCardBorderRadius(context),
        ),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentLocation,
            initialZoom: 13.0,
            onTap: _onMapTap,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.mdms_clone',
            ),
            MarkerLayer(markers: _markers),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentAddressDisplay(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      margin: ResponsiveHelper.getPadding(context),
      padding: EdgeInsets.all(isMobile ? 10 : 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getCardBorderRadius(context),
        ),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.pin_drop,
            color: AppColors.primary,
            size: isMobile ? 18 : 20,
          ),
          SizedBox(width: ResponsiveHelper.getSpacing(context)),
          Expanded(
            child: Text(
              _currentAddress,
              style: TextStyle(
                fontSize: isMobile ? 13 : 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterActions(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      padding: ResponsiveHelper.getPadding(context),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(
            ResponsiveHelper.getCardBorderRadius(context),
          ),
          bottomRight: Radius.circular(
            ResponsiveHelper.getCardBorderRadius(context),
          ),
        ),
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: isMobile
          ? Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    text: _isSaving ? 'Saving...' : 'Save',
                    type: AppButtonType.primary,
                    // size: AppButtonSize.medium,
                    onPressed: _isSaving ? null : _saveLocation,
                    icon: Icon(Icons.save, size: AppSizes.iconSmall),
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getSpacing(context)),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    text: 'Cancel',
                    type: AppButtonType.outline,
                    size: AppButtonSize.medium,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 120,
                  child: AppButton(
                    text: 'Cancel',
                    type: AppButtonType.outline,
                    size: AppButtonSize.medium,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getSpacing(context)),
                SizedBox(
                  width: 140,
                  child: AppButton(
                    text: _isSaving ? 'Saving...' : 'Save',
                    type: AppButtonType.primary,

                    /// size: AppButtonSize.medium,
                    onPressed: _isSaving ? null : _saveLocation,
                    icon: Icon(Icons.save, size: AppSizes.iconSmall),
                  ),
                ),
              ],
            ),
    );
  }
}
