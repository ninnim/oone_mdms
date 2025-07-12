import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/device.dart';
import '../../../core/services/device_service.dart';
import '../common/status_chip.dart';
import '../common/results_pagination.dart';
import 'dart:math' as math;

class FlutterMapDeviceView extends StatefulWidget {
  final List<Device> devices;
  final Function(Device) onDeviceSelected;
  final bool isLoading;
  final DeviceService? deviceService;

  const FlutterMapDeviceView({
    super.key,
    required this.devices,
    required this.onDeviceSelected,
    this.isLoading = false,
    this.deviceService,
  });

  @override
  State<FlutterMapDeviceView> createState() => _FlutterMapDeviceViewState();
}

class _FlutterMapDeviceViewState extends State<FlutterMapDeviceView> {
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
    _deviceService =
        widget.deviceService ??
        Provider.of<DeviceService>(context, listen: false);
    _loadDevicesForMap();
  }

  @override
  void didUpdateWidget(FlutterMapDeviceView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.devices != widget.devices && _allDevicesForMap.isEmpty) {
      _setupMapData(widget.devices);
    }
  }

  Future<void> _loadDevicesForMap() async {
    setState(() {
      _isLoadingDevices = true;
      _errorMessage = '';
    });

    try {
      final response = await _deviceService.getDevicesForMap(
        search: '',
        offset: 0,
        limit: 1000,
      );

      if (response.success) {
        _allDevicesForMap = response.data ?? [];
        _setupMapData(_allDevicesForMap);
        await _loadDeviceListPage();
      } else {
        _errorMessage = response.message ?? 'Failed to load devices';
      }
    } catch (e) {
      print('Error loading devices for map: $e');
      _errorMessage = 'Error loading devices';
    } finally {
      setState(() {
        _isLoadingDevices = false;
      });
    }
  }

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
          _totalItems = response.paging?.item.total ?? 0;
          _totalPages = (_totalItems / _itemsPerPage).ceil();
        });
      }
    } catch (e) {
      print('Error loading device list page: $e');
    }
  }

  void _setupMapData(List<Device> devices) {
    final markers = <Marker>[];

    for (final device in devices) {
      if (device.address?.latitude != null &&
          device.address?.longitude != null) {
        markers.add(
          Marker(
            point: LatLng(
              device.address!.latitude!,
              device.address!.longitude!,
            ),
            child: GestureDetector(
              onTap: () => _onDeviceMarkerTapped(device),
              child: Icon(
                Icons.location_on,
                color: _getDeviceStatusColor(device.status),
                size: 30,
              ),
            ),
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
    });
  }

  void _onDeviceMarkerTapped(Device device) {
    setState(() {
      _selectedDevice = device;
    });

    _mapController.move(
      LatLng(device.address!.latitude!, device.address!.longitude!),
      16.0,
    );
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _loadDeviceListPage();
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
      setState(() {
        _selectedDevice = device;
      });

      _mapController.move(
        LatLng(device.address!.latitude!, device.address!.longitude!),
        16.0,
      );
    }
  }

  Color _getDeviceStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'commissioned':
        return AppColors.success;
      case 'decommissioned':
        return AppColors.error;
      case 'none':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingDevices && _allDevicesForMap.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading device locations...'),
          ],
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
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _mapDevices.length,
                    itemBuilder: (context, index) {
                      final device = _mapDevices[index];
                      final isSelected = _selectedDevice?.id == device.id;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.08)
                              : null,
                          border: isSelected
                              ? Border.all(
                                  color: AppColors.primary.withOpacity(0.3),
                                  width: 1,
                                )
                              : null,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          leading: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: _getDeviceStatusColor(device.status),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${index + (_currentPage - 1) * _itemsPerPage + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            device.serialNumber.isNotEmpty
                                ? device.serialNumber
                                : 'Device-${device.id.substring(0, 6)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.black87,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.my_location,
                                  size: 16,
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.grey[500],
                                ),
                                tooltip: 'Center on map',
                                onPressed: () =>
                                    _onDeviceListItemTapped(device),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: Colors.grey[500],
                                ),
                                tooltip: 'Device details',
                                onPressed: () =>
                                    widget.onDeviceSelected(device),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                              ),
                            ],
                          ),
                          onTap: () => _onDeviceListItemTapped(device),
                        ),
                      );
                    },
                  ),
          ),

          // Reusable pagination
          if (_totalPages > 1)
            ResultsPagination(
              currentPage: _currentPage,
              totalPages: _totalPages,
              totalItems: _totalItems,
              itemsPerPage: _itemsPerPage,
              startItem: (_currentPage - 1) * _itemsPerPage + 1,
              endItem: math.min(_currentPage * _itemsPerPage, _totalItems),
              onPageChanged: _onPageChanged,
              showItemsPerPageSelector: false,
              itemLabel: 'devices',
            ),
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
                        : 'Device ${_selectedDevice!.id.substring(0, 6)}',
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
                  : 'Unknown',
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

  StatusChipType _getStatusChipType(String status) {
    switch (status.toLowerCase()) {
      case 'commissioned':
        return StatusChipType.success;
      case 'decommissioned':
        return StatusChipType.error;
      case 'none':
        return StatusChipType.warning;
      default:
        return StatusChipType.secondary;
    }
  }
}
