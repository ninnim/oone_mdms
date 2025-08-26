import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../themes/app_theme.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/device.dart';
import '../../../core/services/device_service.dart';
import '../common/status_chip.dart';
import '../common/app_lottie_state_widget.dart';
import '../common/responsive_map_pagination.dart';

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
    _deviceService =
        widget.deviceService ??
        Provider.of<DeviceService>(context, listen: false);
    _loadDevicesForMap();
  }

  Future<void> _loadDevicesForMap() async {
    setState(() {
      _isLoadingDevices = true;
      _errorMessage = '';
    });

    try {
      // Load devices for this specific group using the proper API with filter
      final response = await _deviceService.getDevicesForGroupMap(
        deviceGroupId: widget.deviceGroupId,
        search: '',
        offset: 0,
        limit: 1000,
      );

      if (response.success) {
        setState(() {
          _allDevicesForMap = response.data ?? [];
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
    try {
      final response = await _deviceService.getDevicesForGroupMap(
        deviceGroupId: widget.deviceGroupId,
        search: _searchQuery,
        offset: (_currentPage - 1) * _itemsPerPage,
        limit: _itemsPerPage,
      );

      if (response.success) {
        setState(() {
          _mapDevices = response.data ?? [];
          _totalItems = response.paging?.item.total ?? 0;
          _totalPages = (_totalItems / _itemsPerPage).ceil();
          if (_totalPages == 0) _totalPages = 1;
        });
      }
    } catch (e) {
      print('Error loading device list page: $e');
    }
  }

  void _buildMarkers() {
    // Use all devices from the API that already have location data
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
              border: Border.all(
                color: Theme.of(context).colorScheme.onPrimary,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: context.shadowColor.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.location_on,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 20,
            ),
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
          titleColor: context.primaryColor,
          messageColor: context.secondaryColor,
        ),
      );
    }

    if (_allDevicesForMap.isEmpty) {
      return Center(
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
              'No devices with location found',
              style: TextStyle(fontSize: 18, color: context.textSecondaryColor),
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
          Container(width: 1, color: Theme.of(context).colorScheme.outline),
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
                    urlTemplate: Theme.of(context).brightness == Brightness.dark
                        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                        : 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                    additionalOptions:
                        Theme.of(context).brightness == Brightness.dark
                        ? {
                            'attribution':
                                '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>',
                          }
                        : {},
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
    final color = isLarge ? AppColors.error : AppColors.primary;

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
          style: TextStyle(
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
        color: context.surfaceColor,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: context.textSecondaryColor.withOpacity(0.05),
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
              color: context.primaryColor,
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
                  color: context.textSecondaryColor,
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
        color: context.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: context.textSecondaryColor.withOpacity(0.1),
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
            decoration: BoxDecoration(
              color: context.surfaceColor,
              border: Border(bottom: BorderSide(color: context.borderColor)),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: context.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Device Locations ($_totalItems)',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeSmall,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimaryColor,
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
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: context.primaryColor),
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
                      titleColor: context.primaryColor,
                      messageColor: context.secondaryColor,
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
                          color: context.textSecondaryColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage,
                          style: TextStyle(color: context.textSecondaryColor),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadDevicesForMap,
                          child: Text('Retry'),
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
                          color: context.textSecondaryColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No devices found',
                          style: TextStyle(color: context.textSecondaryColor),
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
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: context.textSecondaryColor.withOpacity(0.1),
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                backgroundColor: context.primaryColor,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: Text('View Details'),
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
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(device.status.isNotEmpty ? device.status : 'None'),
        trailing: Icon(Icons.location_on, color: context.primaryColor),
        onTap: () => _onDeviceListItemTapped(device),
      ),
    );
  }

  Widget _buildPaginationControls() {
    if (_totalPages <= 1) return const SizedBox.shrink();

    return ResponsiveMapPagination(
      currentPage: _currentPage,
      totalPages: _totalPages,
      totalItems: _totalItems,
      startItem: (_currentPage - 1) * _itemsPerPage + 1,
      endItem: (_currentPage * _itemsPerPage > _totalItems)
          ? _totalItems
          : _currentPage * _itemsPerPage,
      onPageChanged: (page) {
        setState(() {
          _currentPage = page;
        });
        _loadDeviceListPage();
      },
      itemLabel: 'devices',
      isLoading: _isLoadingDevices,
    );
  }
}
