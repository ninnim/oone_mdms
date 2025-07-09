import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/address.dart';
import 'app_button.dart';
import 'app_input_field.dart';
import 'app_card.dart';

class LocationPicker extends StatefulWidget {
  final Address? initialAddress;
  final Function(Address) onLocationSelected;
  final bool allowManualEntry;

  const LocationPicker({
    super.key,
    this.initialAddress,
    required this.onLocationSelected,
    this.allowManualEntry = true,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker>
    with TickerProviderStateMixin {
  late TabController _tabController;
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  Address? _selectedAddress;
  bool _isLoadingLocation = false;

  // Form controllers for manual entry
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.allowManualEntry ? 3 : 2,
      vsync: this,
    );

    if (widget.initialAddress != null) {
      _selectedAddress = widget.initialAddress;
      _populateFormFields();
      if (widget.initialAddress!.latitude != null &&
          widget.initialAddress!.longitude != null) {
        _selectedLocation = LatLng(
          widget.initialAddress!.latitude!,
          widget.initialAddress!.longitude!,
        );
      }
    }
  }

  void _populateFormFields() {
    if (widget.initialAddress != null) {
      _streetController.text = widget.initialAddress!.street ?? '';
      _cityController.text = widget.initialAddress!.city ?? '';
      _stateController.text = widget.initialAddress!.state ?? '';
      _postalCodeController.text = widget.initialAddress!.postalCode ?? '';
      _countryController.text = widget.initialAddress!.country ?? '';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMapPicker(),
                  _buildSearchPicker(),
                  if (widget.allowManualEntry) _buildManualEntry(),
                ],
              ),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Text(
            'Select Location',
            style: TextStyle(
              fontSize: AppSizes.fontSizeXLarge,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.surface,
      child: TabBar(
        controller: _tabController,
        tabs: [
          const Tab(icon: Icon(Icons.map), text: 'Map'),
          const Tab(icon: Icon(Icons.search), text: 'Search'),
          if (widget.allowManualEntry)
            const Tab(icon: Icon(Icons.edit), text: 'Manual'),
        ],
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
      ),
    );
  }

  Widget _buildMapPicker() {
    return Column(
      children: [
        Expanded(
          child: kIsWeb
              ? _buildWebMapFallback()
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target:
                        _selectedLocation ??
                        const LatLng(37.7749, -122.4194), // Default to SF
                    zoom: 15,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                  onTap: (LatLng location) {
                    setState(() {
                      _selectedLocation = location;
                    });
                    _reverseGeocode(location);
                  },
                  markers: _selectedLocation != null
                      ? {
                          Marker(
                            markerId: const MarkerId('selected'),
                            position: _selectedLocation!,
                            infoWindow: const InfoWindow(
                              title: 'Selected Location',
                            ),
                          ),
                        }
                      : {},
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                ),
        ),
        if (_selectedAddress != null) _buildSelectedAddressInfo(),
      ],
    );
  }

  Widget _buildWebMapFallback() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: AppSizes.spacing16),
                  const Text(
                    'Interactive Map (Web Mode)',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeXLarge,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacing8),
                  const Text(
                    'Enter coordinates below to set location',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeMedium,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSizes.spacing16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(AppSizes.radiusLarge),
                bottomRight: Radius.circular(AppSizes.radiusLarge),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppInputField(
                        label: 'Latitude',
                        hintText:
                            _selectedLocation?.latitude.toString() ?? '37.7749',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (value) {
                          final lat = double.tryParse(value);
                          if (lat != null) {
                            final lng =
                                _selectedLocation?.longitude ?? -122.4194;
                            setState(() {
                              _selectedLocation = LatLng(lat, lng);
                            });
                            _updateAddressFromCoordinates();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacing16),
                    Expanded(
                      child: AppInputField(
                        label: 'Longitude',
                        hintText:
                            _selectedLocation?.longitude.toString() ??
                            '-122.4194',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (value) {
                          final lng = double.tryParse(value);
                          if (lng != null) {
                            final lat = _selectedLocation?.latitude ?? 37.7749;
                            setState(() {
                              _selectedLocation = LatLng(lat, lng);
                            });
                            _updateAddressFromCoordinates();
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.spacing12),
                AppButton(
                  text: 'Set Random Location (Demo)',
                  onPressed: () {
                    // Generate random coordinates near San Francisco for demo
                    final random = DateTime.now().millisecondsSinceEpoch % 1000;
                    final lat = 37.7749 + (random - 500) / 10000;
                    final lng = -122.4194 + (random - 500) / 10000;
                    setState(() {
                      _selectedLocation = LatLng(lat, lng);
                    });
                    _updateAddressFromCoordinates();
                  },
                  type: AppButtonType.secondary,
                  fullWidth: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateAddressFromCoordinates() {
    if (_selectedLocation != null) {
      setState(() {
        _selectedAddress = Address(
          street: 'Coordinate Location',
          city: 'Selected City',
          state: 'Selected State',
          postalCode: '12345',
          country: 'Selected Country',
          latitude: _selectedLocation!.latitude,
          longitude: _selectedLocation!.longitude,
        );
      });
    }
  }

  Widget _buildSearchPicker() {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.spacing24),
      child: Column(
        children: [
          AppInputField(
            label: 'Search Address',
            hintText: 'Enter address to search...',
            suffixIcon: const Icon(Icons.search),
            onChanged: (value) {
              // Implement address search
              if (value.isNotEmpty) {
                _searchAddress(value);
              }
            },
          ),
          const SizedBox(height: AppSizes.spacing16),
          AppButton(
            text: 'Use Current Location',
            onPressed: _getCurrentLocation,
            isLoading: _isLoadingLocation,
            fullWidth: true,
          ),
          const SizedBox(height: AppSizes.spacing24),
          if (_selectedAddress != null) _buildSelectedAddressInfo(),
        ],
      ),
    );
  }

  Widget _buildManualEntry() {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.spacing24),
      child: SingleChildScrollView(
        child: Column(
          children: [
            AppInputField(
              label: 'Street Address',
              hintText: 'Enter street address',
              controller: _streetController,
              onChanged: _updateSelectedAddress,
            ),
            const SizedBox(height: AppSizes.spacing16),
            Row(
              children: [
                Expanded(
                  child: AppInputField(
                    label: 'City',
                    hintText: 'Enter city',
                    controller: _cityController,
                    onChanged: _updateSelectedAddress,
                  ),
                ),
                const SizedBox(width: AppSizes.spacing16),
                Expanded(
                  child: AppInputField(
                    label: 'State/Province',
                    hintText: 'Enter state',
                    controller: _stateController,
                    onChanged: _updateSelectedAddress,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacing16),
            Row(
              children: [
                Expanded(
                  child: AppInputField(
                    label: 'Postal Code',
                    hintText: 'Enter postal code',
                    controller: _postalCodeController,
                    onChanged: _updateSelectedAddress,
                  ),
                ),
                const SizedBox(width: AppSizes.spacing16),
                Expanded(
                  child: AppInputField(
                    label: 'Country',
                    hintText: 'Enter country',
                    controller: _countryController,
                    onChanged: _updateSelectedAddress,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacing24),
            if (_selectedAddress != null) _buildSelectedAddressInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedAddressInfo() {
    if (_selectedAddress == null) return const SizedBox();

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selected Address',
              style: TextStyle(
                fontSize: AppSizes.fontSizeLarge,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.spacing8),
            Text(
              _selectedAddress!.getFormattedAddress(),
              style: const TextStyle(
                fontSize: AppSizes.fontSizeMedium,
                color: AppColors.textSecondary,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
            ),
            if (_selectedLocation != null) ...[
              const SizedBox(height: AppSizes.spacing8),
              Text(
                'Coordinates: ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                style: const TextStyle(
                  fontSize: AppSizes.fontSizeSmall,
                  color: AppColors.textTertiary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              text: 'Cancel',
              onPressed: () => Navigator.of(context).pop(),
              type: AppButtonType.secondary,
            ),
          ),
          const SizedBox(width: AppSizes.spacing16),
          Expanded(
            child: AppButton(
              text: 'Select Location',
              onPressed: _selectedAddress != null ? _confirmSelection : null,
            ),
          ),
        ],
      ),
    );
  }

  void _updateSelectedAddress(String value) {
    setState(() {
      _selectedAddress = Address(
        street: _streetController.text,
        city: _cityController.text,
        state: _stateController.text,
        postalCode: _postalCodeController.text,
        country: _countryController.text,
        latitude: _selectedLocation?.latitude,
        longitude: _selectedLocation?.longitude,
      );
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied, we cannot request permissions.';
      }

      Position position = await Geolocator.getCurrentPosition();
      LatLng location = LatLng(position.latitude, position.longitude);

      setState(() {
        _selectedLocation = location;
      });

      await _reverseGeocode(location);

      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLng(location));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
      }
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _reverseGeocode(LatLng location) async {
    // In a real implementation, you would use a geocoding service
    // For now, we'll create a mock address
    setState(() {
      _selectedAddress = Address(
        street:
            '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
        city: 'Unknown City',
        state: 'Unknown State',
        postalCode: '00000',
        country: 'Unknown Country',
        latitude: location.latitude,
        longitude: location.longitude,
      );
    });
  }

  Future<void> _searchAddress(String query) async {
    // In a real implementation, you would use a geocoding service
    // For now, we'll create a mock search result
    setState(() {
      _selectedAddress = Address(
        street: query,
        city: 'Search Result City',
        state: 'Search Result State',
        postalCode: '12345',
        country: 'Search Result Country',
        latitude: 37.7749,
        longitude: -122.4194,
      );
      _selectedLocation = const LatLng(37.7749, -122.4194);
    });
  }

  void _confirmSelection() {
    if (_selectedAddress != null) {
      widget.onLocationSelected(_selectedAddress!);
      Navigator.of(context).pop();
    }
  }
}
