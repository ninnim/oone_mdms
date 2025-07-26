import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/device.dart';
import '../../../core/services/device_service.dart';
import '../common/status_chip.dart';
import '../common/app_lottie_state_widget.dart';

class GroupDeviceMapView extends StatefulWidget {
  final int deviceGroupId;
  final Function(Device) onDeviceSelected;
  final bool isLoading;
  final String groupName;
  final DeviceService? deviceService;

  const GroupDeviceMapView({
    super.key,
    required this.deviceGroupId,
    required this.onDeviceSelected,
    this.isLoading = false,
    required this.groupName,
    this.deviceService,
  });

  @override
  State<GroupDeviceMapView> createState() => _GroupDeviceMapViewState();
}

class _GroupDeviceMapViewState extends State<GroupDeviceMapView> {
  final MapController _mapController = MapController();
  List<Marker> _markers = [];
  double _currentZoom = 10.0;
  Device? _selectedDevice;
  bool _showDeviceList = true;

  // API and pagination state
  late DeviceService _deviceService;
  List<Device> _mapDevices = [];
  List<Device> _allDevicesForMap = [];
  bool _isLoadingDevices = false;
  String _errorMessage = '';

  // Device list pagination
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  final int _itemsPerPage = 8;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _deviceService = widget.deviceService ?? DeviceService.instance;
    _loadDevicesForMap();
  }

  Future<void> _loadDevicesForMap() async {
    setState(() {
      _isLoadingDevices = true;
      _errorMessage = '';
    });

    try {
      // Load devices for this specific group
      final response = await _deviceService.getDevices();

      if (response.success) {
        final allDevices = response.data ?? [];

        // Filter devices by group ID and has location
        final groupDevicesWithLocation = allDevices.where((device) {
          return device.deviceGroupId == widget.deviceGroupId &&
              device.address != null &&
              device.address!.latitude != null &&
              device.address!.longitude != null;
        }).toList();

        setState(() {
          _allDevicesForMap = groupDevicesWithLocation;
          _totalItems = _allDevicesForMap.length;
          _totalPages = (_totalItems / _itemsPerPage).ceil();
          if (_totalPages == 0) _totalPages = 1;
          _isLoadingDevices = false;
        });

        await _loadDeviceListPage();
        _buildMarkers();
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Failed to load devices';
          _isLoadingDevices = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading devices: $e';
        _isLoadingDevices = false;
      });
    }
  }

  Future<void> _loadDeviceListPage() async {
    if (_allDevicesForMap.isEmpty) {
      setState(() {
        _mapDevices = [];
      });
      return;
    }

    // Apply search filter
    var filteredDevices = _allDevicesForMap;
    if (_searchQuery.isNotEmpty) {
      filteredDevices = _allDevicesForMap.where((device) {
        return device.serialNumber.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            device.name.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply pagination
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;

    setState(() {
      _mapDevices = filteredDevices.sublist(
        startIndex,
        endIndex > filteredDevices.length ? filteredDevices.length : endIndex,
      );
    });
  }

  void _buildMarkers() {
    _markers = _allDevicesForMap.map((device) {
      return Marker(
        point: LatLng(device.address!.latitude!, device.address!.longitude!),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _onDeviceMarkerTapped(device),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getStatusColor(device.status),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.location_on, color: Colors.white, size: 20),
          ),
        ),
      );
    }).toList();
  }

  void _onDeviceMarkerTapped(Device device) {
    setState(() {
      _selectedDevice = device;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 1;
    });
    _loadDeviceListPage();
  }

  void _onDeviceListItemTapped(Device device) {
    if (device.address != null) {
      _mapController.move(
        LatLng(device.address!.latitude!, device.address!.longitude!),
        15.0,
      );
      setState(() {
        _selectedDevice = device;
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
      _loadDeviceListPage();
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
      });
      _loadDeviceListPage();
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'commissioned':
        return AppColors.success;
      case 'discommoded':
        return AppColors.error;
      case 'none':
      default:
        return AppColors.warning;
    }
  }

  StatusChipType _getStatusChipType(String status) {
    switch (status.toLowerCase()) {
      case 'commissioned':
        return StatusChipType.success;
      case 'discommoded':
        return StatusChipType.error;
      case 'none':
      default:
        return StatusChipType.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingDevices && _allDevicesForMap.isEmpty) {
      return Center(
        child: AppLottieStateWidget.loading(
          title: 'Loading Device Locations',
          message: 'Please wait while we fetch device locations.',
          lottieSize: 80,
          titleColor: AppColors.primary,
          messageColor: AppColors.secondary,
        ),
      );
    }

    if (_allDevicesForMap.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No devices with location found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        // Sidebar toggle
        _buildSidebarToggle(),

        // Device list sidebar
        if (_showDeviceList) ...[
          _buildDeviceListSidebar(),
          Container(width: 1, color: AppColors.border),
        ],

        // Map view
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(11.556400, 104.928200),
                  initialZoom: _currentZoom,
                  maxZoom: 18,
                  minZoom: 2,
                  onPositionChanged: (MapPosition pos, bool hasGesture) {
                    setState(() {
                      _currentZoom = pos.zoom ?? _currentZoom;
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                  ),
                  MarkerClusterLayerWidget(
                    options: MarkerClusterLayerOptions(
                      markers: _markers,
                      maxClusterRadius: 120,
                      size: const Size(40, 40),
                      builder: (context, markers) =>
                          _buildClusterMarker(markers.length),
                      zoomToBoundsOnClick: true,
                      spiderfyCluster: true,
                      showPolygon: false,
                    ),
                  ),
                ],
              ),

              // Selected device info panel
              if (_selectedDevice != null) _buildDeviceInfoPanel(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClusterMarker(int count) {
    final isLarge = count > 10;
    final color = isLarge ? Colors.red : const Color(0xFF2F3CFE);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarToggle() {
    return Container(
      width: 48,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(1, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          IconButton(
            icon: Icon(
              _showDeviceList ? Icons.chevron_left : Icons.chevron_right,
              color: AppColors.primary,
            ),
            onPressed: () {
              setState(() {
                _showDeviceList = !_showDeviceList;
              });
            },
            tooltip: _showDeviceList ? 'Hide device list' : 'Show device list',
          ),
          const SizedBox(height: 8),
          if (!_showDeviceList) ...[
            RotatedBox(
              quarterTurns: 3,
              child: Text(
                'Devices ($_totalItems)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ],
      ),
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
                      fontSize: AppSizes.fontSizeSmall,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
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
                ? Center(
                    child: AppLottieStateWidget.loading(
                      title: 'Loading Devices',
                      message: 'Please wait while we fetch devices.',
                      lottieSize: 50,
                      titleColor: AppColors.primary,
                      messageColor: AppColors.secondary,
                    ),
                  )
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
                          'No devices found',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _mapDevices.length,
                    itemBuilder: (context, index) {
                      final device = _mapDevices[index];
                      return _buildDeviceListItem(device);
                    },
                  ),
          ),

          // Pagination
          _buildPaginationControls(),
        ],
      ),
    );
  }

  Widget _buildDeviceInfoPanel() {
    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDevice!.serialNumber.isNotEmpty
                        ? _selectedDevice!.serialNumber
                        : 'Device ${_selectedDevice!.id?.substring(0, 6)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
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
            const SizedBox(height: 8),
            StatusChip(
              type: _getStatusChipType(_selectedDevice!.status),
              text: _selectedDevice!.status.isNotEmpty
                  ? _selectedDevice!.status
                  : 'None',
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => widget.onDeviceSelected(_selectedDevice!),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('View Details'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceListItem(Device device) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getStatusColor(device.status),
          ),
        ),
        title: Text(
          device.serialNumber.isNotEmpty
              ? device.serialNumber
              : 'Device ${device.id?.substring(0, 6)}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(device.status.isNotEmpty ? device.status : 'None'),
        trailing: const Icon(Icons.location_on, color: AppColors.primary),
        onTap: () => _onDeviceListItemTapped(device),
      ),
    );
  }

  Widget _buildPaginationControls() {
    if (_totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1 ? _previousPage : null,
          ),
          Text('$_currentPage / $_totalPages'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _totalPages ? _nextPage : null,
          ),
        ],
      ),
    );
  }
}
