import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/device.dart';
import '../../../core/services/device_service.dart';
import '../../../core/services/api_service.dart';
import '../common/status_chip.dart';
import '../common/results_pagination.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';

enum CustomMapType { normal, satellite, hybrid, terrain }

class AdvancedDeviceMapView extends StatefulWidget {
  final List<Device>
  devices; // Keep for compatibility, but will be overridden by API calls
  final Function(Device) onDeviceSelected;
  final bool isLoading;
  final DeviceService? deviceService; // Optional for dependency injection

  const AdvancedDeviceMapView({
    super.key,
    required this.devices,
    required this.onDeviceSelected,
    this.isLoading = false,
    this.deviceService,
  });

  @override
  State<AdvancedDeviceMapView> createState() => _AdvancedDeviceMapViewState();
}

class _AdvancedDeviceMapViewState extends State<AdvancedDeviceMapView> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Circle> _clusters = {};
  LatLng _center = const LatLng(
    11.556400,
    104.928200,
  ); // Default center (Cambodia)
  double _zoom = 10.0;
  CustomMapType _selectedMapType = CustomMapType.normal;
  Device? _selectedDevice;
  bool _showDeviceList = true;

  // API and pagination state
  late DeviceService _deviceService;
  List<Device> _mapDevices = [];
  List<Device> _allDevicesForMap = []; // Store all devices for map display
  bool _isLoadingDevices = false;
  String _errorMessage = '';

  // Device list pagination
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  int _itemsPerPage = 10; // Smaller page size for sidebar
  String _searchQuery = '';

  // Clustering parameters
  static const double _clusterDistance = 100.0; // pixels
  final List<DeviceCluster> _deviceClusters = [];

  @override
  void initState() {
    super.initState();
    // Initialize device service - use injected one or create new
    _deviceService = widget.deviceService ?? DeviceService(ApiService());
    _loadDevicesForMap();
  }

  @override
  void didUpdateWidget(AdvancedDeviceMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If devices are passed as props and API is not available, use them
    if (oldWidget.devices != widget.devices && _allDevicesForMap.isEmpty) {
      _setupMapData(widget.devices);
    }
  }

  // Load all devices with location data for map display
  Future<void> _loadDevicesForMap() async {
    setState(() {
      _isLoadingDevices = true;
      _errorMessage = '';
    });

    try {
      // Load all devices for map clustering (high limit to get all devices)
      final response = await _deviceService.getDevicesForMap(
        search: '',
        offset: 0,
        limit: 1000, // Get all devices for map clustering
      );

      if (response.success) {
        _allDevicesForMap = response.data ?? [];
        _setupMapData(_allDevicesForMap);

        // Load first page for device list sidebar
        await _loadDeviceListPage();
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Unknown error occurred';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load devices: $e';
      });
    } finally {
      setState(() {
        _isLoadingDevices = false;
      });
    }
  }

  // Load devices for the sidebar list with pagination
  Future<void> _loadDeviceListPage() async {
    try {
      final response = await _deviceService.getDevicesForMap(
        search: _searchQuery,
        offset: (_currentPage - 1) * _itemsPerPage,
        limit: _itemsPerPage,
      );

      if (response.success) {
        setState(() {
          _mapDevices = response.data ?? [];
          _totalItems = response.paging?.item?.total ?? 0;
          _totalPages = (_totalItems / _itemsPerPage).ceil();
        });
      }
    } catch (e) {
      print('Error loading device list page: $e');
    }
  }

  void _setupMapData(List<Device> devices) {
    if (devices.isEmpty) return;

    // Filter devices with valid addresses
    final devicesWithLocation = devices.where((device) {
      return device.address != null &&
          device.address!.latitude != 0.0 &&
          device.address!.longitude != 0.0;
    }).toList();

    if (devicesWithLocation.isEmpty) return;

    // Calculate center based on devices
    double sumLat = 0;
    double sumLng = 0;
    for (final device in devicesWithLocation) {
      sumLat += device.address!.latitude ?? 0.0;
      sumLng += device.address!.longitude ?? 0.0;
    }

    setState(() {
      _center = LatLng(
        sumLat / devicesWithLocation.length,
        sumLng / devicesWithLocation.length,
      );
    });

    _createClusters(devicesWithLocation);
  }

  void _createClusters(List<Device> devices) {
    _deviceClusters.clear();

    for (final device in devices) {
      if (device.address == null) continue;

      final deviceLatLng = LatLng(
        device.address!.latitude ?? 0.0,
        device.address!.longitude ?? 0.0,
      );
      bool addedToCluster = false;

      // Check if device can be added to existing cluster
      for (final cluster in _deviceClusters) {
        final distance = _calculateDistance(deviceLatLng, cluster.center);
        if (distance < 0.01) {
          // ~1km clustering radius
          cluster.devices.add(device);
          // Update cluster center
          cluster.center = _calculateClusterCenter(cluster.devices);
          addedToCluster = true;
          break;
        }
      }

      // Create new cluster if not added to existing
      if (!addedToCluster) {
        _deviceClusters.add(
          DeviceCluster(center: deviceLatLng, devices: [device]),
        );
      }
    }

    _createMarkers();
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double p = 0.017453292519943295; // Math.PI / 180
    final double a =
        0.5 -
        math.cos((point2.latitude - point1.latitude) * p) / 2 +
        math.cos(point1.latitude * p) *
            math.cos(point2.latitude * p) *
            (1 - math.cos((point2.longitude - point1.longitude) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
  }

  LatLng _calculateClusterCenter(List<Device> devices) {
    double sumLat = 0;
    double sumLng = 0;
    for (final device in devices) {
      sumLat += device.address!.latitude ?? 0.0;
      sumLng += device.address!.longitude ?? 0.0;
    }
    return LatLng(sumLat / devices.length, sumLng / devices.length);
  }

  void _createMarkers() async {
    final markers = <Marker>{};

    for (int i = 0; i < _deviceClusters.length; i++) {
      final cluster = _deviceClusters[i];

      if (cluster.devices.length == 1) {
        // Single device marker
        final device = cluster.devices.first;
        final markerIcon = await _createDeviceMarkerIcon(device);

        markers.add(
          Marker(
            markerId: MarkerId('device_${device.id}'),
            position: cluster.center,
            icon: markerIcon,
            onTap: () => _onDeviceMarkerTapped(device),
            infoWindow: InfoWindow(
              title: device.serialNumber,
              snippet: device.status.isNotEmpty ? device.status : 'Unknown',
            ),
          ),
        );
      } else {
        // Cluster marker
        final clusterIcon = await _createClusterMarkerIcon(
          cluster.devices.length,
        );

        markers.add(
          Marker(
            markerId: MarkerId('cluster_$i'),
            position: cluster.center,
            icon: clusterIcon,
            onTap: () => _onClusterMarkerTapped(cluster),
            infoWindow: InfoWindow(
              title: '${cluster.devices.length} Devices',
              snippet: 'Tap to see devices',
            ),
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
    });
  }

  Future<BitmapDescriptor> _createDeviceMarkerIcon(Device device) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = const Size(48, 48);

    // Determine color based on device status
    Color markerColor;
    switch (device.status.toLowerCase()) {
      case 'commissioned':
        markerColor = AppColors.success;
        break;
      case 'decommissioned':
        markerColor = AppColors.error;
        break;
      case 'renovation':
        markerColor = AppColors.warning;
        break;
      default:
        markerColor = AppColors.textSecondary;
    }

    // Draw marker background
    final paint = Paint()..color = markerColor;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 20, paint);

    // Draw white border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 20, borderPaint);

    // Draw device icon
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.memory.codePoint),
        style: TextStyle(
          fontSize: 16,
          fontFamily: Icons.memory.fontFamily,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(
        (size.width - iconPainter.width) / 2,
        (size.height - iconPainter.height) / 2,
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  Future<BitmapDescriptor> _createClusterMarkerIcon(int count) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = const Size(60, 60);

    // Draw cluster background
    final paint = Paint()..color = AppColors.primary;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 25, paint);

    // Draw white border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 25, borderPaint);

    // Draw count text
    final textPainter = TextPainter(
      text: TextSpan(
        text: count.toString(),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  void _onDeviceMarkerTapped(Device device) {
    setState(() {
      _selectedDevice = device;
    });

    // Center map on device
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(
          device.address!.latitude ?? 0.0,
          device.address!.longitude ?? 0.0,
        ),
      ),
    );
  }

  void _onClusterMarkerTapped(DeviceCluster cluster) {
    // Zoom in on cluster
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(cluster.center, _zoom + 2),
    );
  }

  void _onDeviceListItemTapped(Device device) {
    if (device.address != null) {
      setState(() {
        _selectedDevice = device;
      });

      // Center map on device and zoom
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(
            device.address!.latitude ?? 0.0,
            device.address!.longitude ?? 0.0,
          ),
          15.0,
        ),
      );
    }
  }

  MapType _getGoogleMapType() {
    switch (_selectedMapType) {
      case CustomMapType.satellite:
        return MapType.satellite;
      case CustomMapType.hybrid:
        return MapType.hybrid;
      case CustomMapType.terrain:
        return MapType.terrain;
      default:
        return MapType.normal;
    }
  }

  // Handle search in device list
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 1;
    });
    _loadDeviceListPage();
  }

  // Handle page change in device list
  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _loadDeviceListPage();
  }

  // Handle items per page change
  void _onItemsPerPageChanged(int itemsPerPage) {
    setState(() {
      _itemsPerPage = itemsPerPage;
      _currentPage = 1;
    });
    _loadDeviceListPage();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading if devices are being loaded for the first time
    if (_isLoadingDevices && _allDevicesForMap.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading devices with location data...'),
          ],
        ),
      );
    }

    // Show error state if there's an error and no devices loaded
    if (_errorMessage.isNotEmpty && _allDevicesForMap.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDevicesForMap,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Show empty state if no devices with location
    if (_allDevicesForMap.isEmpty) {
      return _buildEmptyState();
    }

    return Row(
      children: [
        // Device list sidebar
        if (_showDeviceList) ...[
          _buildDeviceListSidebar(),
          Container(width: 1, color: AppColors.border),
        ],

        // Map view
        Expanded(
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _center,
                  zoom: _zoom,
                ),
                markers: _markers,
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                  // Apply custom map style here if needed
                },
                onCameraMove: (CameraPosition position) {
                  _zoom = position.zoom;
                },
                mapType: _getGoogleMapType(),
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                compassEnabled: true,
              ),

              // Map controls
              _buildMapControls(),

              // Selected device info panel
              if (_selectedDevice != null) _buildDeviceInfoPanel(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceListSidebar() {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FA),
              border: Border(bottom: BorderSide(color: Color(0xFFE1E5E9))),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Device Locations ($_totalItems)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _showDeviceList = false;
                    });
                  },
                ),
              ],
            ),
          ),

          // Search field
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search devices...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ),

          // Device list
          Expanded(
            child: _isLoadingDevices
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadDevicesForMap,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _mapDevices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No devices with location found',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _mapDevices.length,
                    itemBuilder: (context, index) {
                      final device = _mapDevices[index];
                      final isSelected = _selectedDevice?.id == device.id;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.1)
                              : null,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _getDeviceStatusColor(
                                device.status,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.memory,
                              color: _getDeviceStatusColor(device.status),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            device.serialNumber.isNotEmpty
                                ? device.serialNumber
                                : 'Device ${device.id.substring(0, 8)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (device.name.isNotEmpty)
                                Text(
                                  device.name,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              const SizedBox(height: 4),
                              StatusChip(
                                text: device.status.isNotEmpty
                                    ? device.status
                                    : 'None',
                                type: _getStatusChipType(device.status),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.center_focus_strong,
                                  size: 18,
                                ),
                                tooltip: 'Center on map',
                                onPressed: () =>
                                    _onDeviceListItemTapped(device),
                              ),
                              IconButton(
                                icon: const Icon(Icons.open_in_new, size: 18),
                                tooltip: 'Device details',
                                onPressed: () =>
                                    widget.onDeviceSelected(device),
                              ),
                            ],
                          ),
                          onTap: () => _onDeviceListItemTapped(device),
                        ),
                      );
                    },
                  ),
          ),

          // Pagination
          if (_totalPages > 1)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FA),
                border: Border(top: BorderSide(color: Color(0xFFE1E5E9))),
              ),
              child: ResultsPagination(
                currentPage: _currentPage,
                totalPages: _totalPages,
                totalItems: _totalItems,
                itemsPerPage: _itemsPerPage,
                startItem: (_currentPage - 1) * _itemsPerPage + 1,
                endItem: (_currentPage * _itemsPerPage).clamp(1, _totalItems),
                onPageChanged: _onPageChanged,
                onItemsPerPageChanged: _onItemsPerPageChanged,
                showItemsPerPageSelector: false, // Keep sidebar compact
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      top: 16,
      right: 16,
      child: Column(
        children: [
          // Map type selector
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMapTypeButton('Map', CustomMapType.normal),
                _buildMapTypeButton('Satellite', CustomMapType.satellite),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Toggle device list button
          if (!_showDeviceList)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.list),
                onPressed: () {
                  setState(() {
                    _showDeviceList = true;
                  });
                },
                tooltip: 'Show device list',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapTypeButton(String label, CustomMapType mapType) {
    final isSelected = _selectedMapType == mapType;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedMapType = mapType;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceInfoPanel() {
    return Positioned(
      bottom: 16,
      left: _showDeviceList ? 336 : 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getDeviceStatusColor(
                  _selectedDevice!.status,
                ).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.memory,
                color: _getDeviceStatusColor(_selectedDevice!.status),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedDevice!.serialNumber,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_selectedDevice!.name.isNotEmpty)
                    Text(
                      _selectedDevice!.name,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  const SizedBox(height: 4),
                  StatusChip(
                    text: _selectedDevice!.status.isNotEmpty
                        ? _selectedDevice!.status
                        : 'None',
                    type: _getStatusChipType(_selectedDevice!.status),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => widget.onDeviceSelected(_selectedDevice!),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: const Text('View Details'),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _selectedDevice = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          const Text(
            'No device locations found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Devices need valid address information to appear on the map',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getDeviceStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'commissioned':
        return AppColors.success;
      case 'decommissioned':
        return AppColors.error;
      case 'renovation':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  StatusChipType _getStatusChipType(String status) {
    switch (status.toLowerCase()) {
      case 'commissioned':
        return StatusChipType.success;
      case 'decommissioned':
        return StatusChipType.danger;
      case 'renovation':
        return StatusChipType.warning;
      default:
        return StatusChipType.secondary;
    }
  }
}

class DeviceCluster {
  LatLng center;
  List<Device> devices;

  DeviceCluster({required this.center, required this.devices});
}
