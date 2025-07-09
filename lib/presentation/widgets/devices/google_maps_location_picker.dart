import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/address.dart';
import '../../../core/services/google_api_service.dart';

class GoogleMapsLocationPicker extends StatefulWidget {
  final Address? initialAddress;
  final Function(Address address)? onLocationSelected;

  const GoogleMapsLocationPicker({
    super.key,
    this.initialAddress,
    this.onLocationSelected,
  });

  @override
  State<GoogleMapsLocationPicker> createState() =>
      _GoogleMapsLocationPickerState();
}

class _GoogleMapsLocationPickerState extends State<GoogleMapsLocationPicker> {
  final TextEditingController _searchController = TextEditingController();
  final GoogleApiService _googleApiService = GoogleApiService();

  double _currentLat = 11.556400;
  double _currentLng = 104.928200;
  String _currentAddress = '';
  bool _isLoading = false;
  List<Address> _searchResults = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null) {
      _currentLat = widget.initialAddress!.latitude ?? 11.556400;
      _currentLng = widget.initialAddress!.longitude ?? 104.928200;
      _currentAddress = widget.initialAddress!.longText;
      _searchController.text = _currentAddress;
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _searchResults.clear();
    });

    try {
      final results = await _googleApiService.searchPlaces(query);
      // Convert PlaceSearchResult to Address
      final addresses = results
          .map(
            (result) => Address(
              id: result.placeId,
              longText: result.description,
              shortText: result.mainText,
              latitude: null, // Will be filled when place details are fetched
              longitude: null,
            ),
          )
          .toList();

      setState(() {
        _searchResults = addresses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Fallback to demo locations if API fails
      _showDemoLocations(query);
    }
  }

  void _showDemoLocations(String query) {
    Map<String, Address> demoLocations = {
      'phnom penh': Address(
        id: '1',
        longText: 'Phnom Penh, Cambodia',
        shortText: 'Phnom Penh',
        latitude: 11.556400,
        longitude: 104.928200,
      ),
      'siem reap': Address(
        id: '2',
        longText: 'Siem Reap, Cambodia',
        shortText: 'Siem Reap',
        latitude: 13.367540,
        longitude: 103.845596,
      ),
      'battambang': Address(
        id: '3',
        longText: 'Battambang, Cambodia',
        shortText: 'Battambang',
        latitude: 13.095300,
        longitude: 103.202200,
      ),
      'kampong cham': Address(
        id: '4',
        longText: 'Kampong Cham, Cambodia',
        shortText: 'Kampong Cham',
        latitude: 11.993900,
        longitude: 105.463600,
      ),
      'london': Address(
        id: '5',
        longText: 'London, United Kingdom',
        shortText: 'London',
        latitude: 51.5074,
        longitude: -0.1278,
      ),
      'paris': Address(
        id: '6',
        longText: 'Paris, France',
        shortText: 'Paris',
        latitude: 48.8566,
        longitude: 2.3522,
      ),
    };

    String searchKey = query.toLowerCase();
    List<Address> matches = [];

    for (String key in demoLocations.keys) {
      if (key.contains(searchKey) || searchKey.contains(key)) {
        matches.add(demoLocations[key]!);
      }
    }

    setState(() {
      _searchResults = matches;
    });
  }

  void _selectLocation(Address address) {
    setState(() {
      _currentLat = address.latitude!;
      _currentLng = address.longitude!;
      _currentAddress = address.longText;
      _searchController.text = address.longText;
      _searchResults.clear();
    });

    if (widget.onLocationSelected != null) {
      widget.onLocationSelected!(address);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search TextField
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search for a location...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchResults.clear();
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onChanged: (value) {
            if (value.length > 2) {
              _searchPlaces(value);
            } else {
              setState(() {
                _searchResults.clear();
              });
            }
          },
        ),

        // Search Results
        if (_searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final result = _searchResults[index];
                return ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(result.shortText),
                  subtitle: Text(result.longText),
                  onTap: () => _selectLocation(result),
                );
              },
            ),
          ),

        const SizedBox(height: 16),

        // Map Display
        Container(
          height: 300,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                // Map Background (using OpenStreetMap tiles)
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.grey[100],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563eb),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _currentAddress.isNotEmpty
                              ? _currentAddress
                              : 'No location selected',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Lat: ${_currentLat.toStringAsFixed(6)}, Lng: ${_currentLng.toStringAsFixed(6)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Tap to select location overlay
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      // For demo purposes, just show the coordinates
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Selected: ${_currentLat.toStringAsFixed(6)}, ${_currentLng.toStringAsFixed(6)}',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Coordinates display
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              const Icon(Icons.my_location, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Current Location: ${_currentLat.toStringAsFixed(6)}, ${_currentLng.toStringAsFixed(6)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
