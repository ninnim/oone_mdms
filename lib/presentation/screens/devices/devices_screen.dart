import 'package:flutter/material.dart';
import 'dart:async';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/blunest_data_table.dart';
import '../../widgets/common/results_pagination.dart';
import '../../widgets/devices/device_table_columns.dart';
import '../../widgets/devices/device_kanban_view.dart';
import '../../widgets/devices/flutter_map_device_view.dart';
import '../../widgets/devices/device_filters_and_actions.dart';
import 'create_edit_device_screen.dart';
import 'device_360_details_screen.dart';
import 'device_billing_readings_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/device.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/device_service.dart';

class DevicesScreen extends StatefulWidget {
  final Function(Device)? onDeviceSelected;
  final Function(List<String>)? onBreadcrumbUpdate;
  final Function(int)? onBreadcrumbNavigate;
  final Function(Function(int)?)? onSetBreadcrumbHandler;
  final Function(String?, String, {String? billingId})? onDeepLinkUpdate;
  final VoidCallback? onDeepLinkClear;

  const DevicesScreen({
    super.key,
    this.onDeviceSelected,
    this.onBreadcrumbUpdate,
    this.onBreadcrumbNavigate,
    this.onSetBreadcrumbHandler,
    this.onDeepLinkUpdate,
    this.onDeepLinkClear,
  });

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final DeviceService _deviceService;
  bool _isLoading = false;
  List<Device> _devices = [];
  List<Device> _filteredDevices = [];
  Set<Device> _selectedDevices = {};
  List<String> _hiddenColumns = [];
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  int _itemsPerPage = 25;
  String _errorMessage = '';
  Timer? _debounceTimer;

  // Navigation state
  String _currentView =
      'devices_list'; // 'devices_list', 'device_details', 'billing_readings'
  Device? _selectedDevice;
  Map<String, dynamic>? _selectedBillingRecord;

  // View mode
  DeviceViewMode _currentViewMode = DeviceViewMode.table;

  // Filters
  String? _selectedStatus;
  String? _selectedType;
  String? _selectedLinkStatus;

  // Sorting
  String? _sortBy;
  bool _sortAscending = true;

  // Available columns for table view
  final List<String> _availableColumns = [
    'Serial Number',
    'Model',
    'Type',
    'Status',
    'Link Status',
    'Address',
    'Actions',
  ];

  @override
  void initState() {
    super.initState();
    _deviceService = DeviceService(ApiService());

    // Set up breadcrumb navigation handler
    widget.onSetBreadcrumbHandler?.call(_handleBreadcrumbNavigation);

    _loadDevices();
  }

  void _onSearchChanged(String value) {
    // Cancel the previous timer
    _debounceTimer?.cancel();

    // Set a new timer
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      // Reset to first page when searching
      _currentPage = 1;
      _searchController.text = value;
      _loadDevices();
    });
  }

  Future<void> _loadDevices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final search = _searchController.text.isEmpty
          ? '%%'
          : '%${_searchController.text}%';
      final offset = (_currentPage - 1) * _itemsPerPage;

      final response = await _deviceService.getDevices(
        search: search,
        offset: offset,
        limit: _itemsPerPage,
      );

      if (response.success) {
        setState(() {
          _devices = response.data!;
          _filteredDevices = _applyFilters(_devices);
          _totalItems = response.paging?.item.total ?? 0;
          // Fix pagination calculation
          _totalPages = _totalItems > 0
              ? ((_totalItems + _itemsPerPage - 1) ~/ _itemsPerPage)
              : 1;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Unknown error occurred';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load devices: $e';
        _isLoading = false;
      });
    }
  }

  List<Device> _applyFilters(List<Device> devices) {
    var filtered = devices;

    if (_selectedStatus != null) {
      filtered = filtered
          .where((device) => device.status == _selectedStatus)
          .toList();
    }

    if (_selectedType != null) {
      filtered = filtered
          .where((device) => device.deviceType == _selectedType)
          .toList();
    }

    if (_selectedLinkStatus != null) {
      filtered = filtered
          .where((device) => device.linkStatus == _selectedLinkStatus)
          .toList();
    }

    return filtered;
  }

  Widget _buildErrorMessage() {
    if (_errorMessage.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spacing16),
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: AppSizes.iconMedium,
          ),
          const SizedBox(width: AppSizes.spacing12),
          Expanded(
            child: Text(
              _errorMessage,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: AppSizes.fontSizeMedium,
              ),
            ),
          ),
          IconButton(
            onPressed: _loadDevices,
            icon: const Icon(Icons.refresh, color: AppColors.error),
            tooltip: 'Retry',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show different screens based on current view
    switch (_currentView) {
      case 'device_details':
        // Update breadcrumbs for device details
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onBreadcrumbUpdate?.call([
            'Devices',
            _selectedDevice!.serialNumber,
          ]);
        });
        return Device360DetailsScreen(
          device: _selectedDevice!,
          onBack: _navigateBackToDevices,
          onNavigateToBillingReadings: _navigateToBillingReadings,
        );
      case 'billing_readings':
        // Update breadcrumbs for billing readings
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onBreadcrumbUpdate?.call([
            'Devices',
            _selectedDevice!.serialNumber,
            'Billing Readings',
          ]);
        });
        return DeviceBillingReadingsScreen(
          device: _selectedDevice!,
          billingRecord: _selectedBillingRecord!,
          onBack: _navigateBackToDeviceDetails,
        );
      default:
        // Clear breadcrumbs for devices list
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onBreadcrumbUpdate?.call([]);
        });
        return _buildMainContent(context);
    }
  }

  Widget _buildMainContent(BuildContext context) {
    // Main devices view - optimized for maximum table space
    return Padding(
      padding: const EdgeInsets.all(
        AppSizes.spacing12,
      ), // Reduced from spacing16
      child: Column(
        children: [
          // Filters and actions
          DeviceFiltersAndActions(
            onSearchChanged: _onSearchChanged,
            onStatusFilterChanged: _onStatusFilterChanged,
            onTypeFilterChanged: _onTypeFilterChanged,
            onLinkStatusFilterChanged: _onLinkStatusFilterChanged,
            onViewModeChanged: _onViewModeChanged,
            onColumnVisibilityChanged: _onColumnVisibilityChanged,
            onAddDevice: _showAddDeviceModal,
            onRefresh: _loadDevices,
            onExport: _exportDevices,
            onImport: _importDevices,
            currentViewMode: _currentViewMode,
            availableColumns: _availableColumns,
            hiddenColumns: _hiddenColumns,
            selectedStatus: _selectedStatus,
            selectedType: _selectedType,
            selectedLinkStatus: _selectedLinkStatus,
          ),

          const SizedBox(height: AppSizes.spacing8), // Reduced from spacing12
          // Error message
          _buildErrorMessage(),

          // Content based on view mode
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  // Widget _buildTableHeader() {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(
  //       horizontal: AppSizes.spacing16,
  //       vertical: AppSizes.spacing12,
  //     ),
  //     decoration: const BoxDecoration(
  //       color: AppColors.surfaceVariant,
  //       border: Border(bottom: BorderSide(color: AppColors.border)),
  //     ),
  //     child: Row(
  //       children: [
  //         const Text(
  //           'Devices',
  //           style: TextStyle(
  //             fontSize: AppSizes.fontSizeMedium,
  //             fontWeight: FontWeight.w600,
  //             color: AppColors.textPrimary,
  //           ),
  //         ),
  //         const SizedBox(width: AppSizes.spacing8),
  //         Container(
  //           padding: const EdgeInsets.symmetric(
  //             horizontal: AppSizes.spacing8,
  //             vertical: AppSizes.spacing4,
  //           ),
  //           decoration: BoxDecoration(
  //             color: AppColors.primary.withOpacity(0.1),
  //             borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
  //           ),
  //           child: Text(
  //             '${_filteredDevices.length}',
  //             style: const TextStyle(
  //               fontSize: AppSizes.fontSizeSmall,
  //               fontWeight: FontWeight.w600,
  //               color: AppColors.primary,
  //             ),
  //           ),
  //         ),
  //         const SizedBox(width: AppSizes.spacing8),
  //         if (_isLoading)
  //           const SizedBox(
  //             width: 16,
  //             height: 16,
  //             child: CircularProgressIndicator(
  //               strokeWidth: 2,
  //               valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
  //             ),
  //           ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildDeviceTable() {
    return BluNestDataTable<Device>(
      columns: DeviceTableColumns.getColumns(
        onView: (device) => _viewDeviceDetails(device),
        onEdit: (device) => _editDevice(device),
        onDelete: (device) => _deleteDevice(device),
        currentPage: _currentPage,
        itemsPerPage: _itemsPerPage,
        devices: _filteredDevices,
      ),
      data: _filteredDevices,
      onRowTap: (device) => _viewDeviceDetails(device),
      onEdit: (device) => _editDevice(device),
      onDelete: (device) => _deleteDevice(device),
      onView: (device) => _viewDeviceDetails(device),
      enableMultiSelect: true,
      selectedItems: _selectedDevices,
      onSelectionChanged: (selectedItems) {
        setState(() {
          _selectedDevices = selectedItems;
        });
      },
      hiddenColumns: _hiddenColumns,
      onColumnVisibilityChanged: (hiddenColumns) {
        setState(() {
          _hiddenColumns = hiddenColumns;
        });
      },
      sortBy: _sortBy,
      sortAscending: _sortAscending,
      onSort: _handleSort,
      isLoading: _isLoading,
    );
  }

  Widget _buildPagination() {
    final startItem = (_currentPage - 1) * _itemsPerPage + 1;
    final endItem = (_currentPage * _itemsPerPage) > _totalItems
        ? _totalItems
        : _currentPage * _itemsPerPage;

    return ResultsPagination(
      currentPage: _currentPage,
      totalPages: _totalPages,
      totalItems: _totalItems,
      itemsPerPage: _itemsPerPage,
      startItem: startItem,
      endItem: endItem,
      onPageChanged: (page) {
        setState(() {
          _currentPage = page;
        });
        _loadDevices();
      },
      onItemsPerPageChanged: (newItemsPerPage) {
        setState(() {
          _itemsPerPage = newItemsPerPage;
          _currentPage = 1;
          _totalPages = _totalItems > 0
              ? ((_totalItems + _itemsPerPage - 1) ~/ _itemsPerPage)
              : 1;
        });
        _loadDevices();
      },
      itemLabel: 'devices',
      showItemsPerPageSelector: true,
    );
  }

  void _showAddDeviceModal() {
    showDialog(
      context: context,
      builder: (context) => CreateEditDeviceDialog(
        onSaved: () {
          // Refresh devices list after saving
          _loadDevices();
        },
      ),
    );
  }

  void _viewDeviceDetails(Device device) {
    // When using router system, always use the router navigation
    if (widget.onDeepLinkUpdate != null) {
      widget.onDeepLinkUpdate!(device.id, 'details');
    } else if (widget.onDeviceSelected != null) {
      widget.onDeviceSelected!(device);
    } else {
      // Fallback to internal navigation only if no callbacks are provided
      setState(() {
        _currentView = 'device_details';
        _selectedDevice = device;
      });
    }
  }

  void _navigateToBillingReadings(
    Device device,
    Map<String, dynamic> billingRecord,
  ) {
    final billingId =
        billingRecord['Id']?.toString() ??
        billingRecord['id']?.toString() ??
        'unknown';

    // When using router system, always use the router navigation
    if (widget.onDeepLinkUpdate != null) {
      widget.onDeepLinkUpdate!(device.id, 'billing', billingId: billingId);
    } else {
      // Fallback to internal navigation
      setState(() {
        _currentView = 'billing_readings';
        _selectedDevice = device;
        _selectedBillingRecord = billingRecord;
      });
    }
  }

  void _navigateBackToDevices() {
    setState(() {
      _currentView = 'devices_list';
      _selectedDevice = null;
      _selectedBillingRecord = null;
    });

    // Clear deep link context when back to list
    widget.onDeepLinkClear?.call();
  }

  void _navigateBackToDeviceDetails() {
    setState(() {
      _currentView = 'device_details';
      _selectedBillingRecord = null;
    });

    // Update deep link context back to device details
    if (_selectedDevice != null) {
      widget.onDeepLinkUpdate?.call(_selectedDevice!.id, 'details');
    }
  }

  void _editDevice(Device device) {
    showDialog(
      context: context,
      builder: (context) => CreateEditDeviceDialog(
        device: device,
        onSaved: () {
          // Refresh devices list after editing
          _loadDevices();
        },
      ),
    );
  }

  void _deleteDevice(Device device) {
    // TODO: Show delete confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Device'),
        content: Text(
          'Are you sure you want to delete ${device.serialNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          AppButton(
            text: 'Delete',
            type: AppButtonType.danger,
            size: AppButtonSize.small,
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement delete functionality
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMultiSelectToolbar() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: const BoxDecoration(
        color: AppColors.info,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.surface,
            size: AppSizes.iconSmall,
          ),
          const SizedBox(width: AppSizes.spacing8),
          Text(
            '${_selectedDevices.length} device${_selectedDevices.length == 1 ? '' : 's'} selected',
            style: const TextStyle(
              fontSize: AppSizes.fontSizeMedium,
              fontWeight: FontWeight.w600,
              color: AppColors.surface,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () {
              // Bulk edit functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Bulk edit ${_selectedDevices.length} devices'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            icon: const Icon(
              Icons.edit,
              color: AppColors.surface,
              size: AppSizes.iconSmall,
            ),
            label: const Text(
              'Edit',
              style: TextStyle(color: AppColors.surface),
            ),
          ),
          const SizedBox(width: AppSizes.spacing8),
          TextButton.icon(
            onPressed: () {
              // Bulk delete functionality
              _showBulkDeleteConfirmation();
            },
            icon: const Icon(
              Icons.delete,
              color: AppColors.surface,
              size: AppSizes.iconSmall,
            ),
            label: const Text(
              'Delete',
              style: TextStyle(color: AppColors.surface),
            ),
          ),
          const SizedBox(width: AppSizes.spacing8),
          TextButton.icon(
            onPressed: () {
              // Export selected devices
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Export ${_selectedDevices.length} devices'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            icon: const Icon(
              Icons.file_download,
              color: AppColors.surface,
              size: AppSizes.iconSmall,
            ),
            label: const Text(
              'Export',
              style: TextStyle(color: AppColors.surface),
            ),
          ),
        ],
      ),
    );
  }

  void _showBulkDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Devices'),
        content: Text(
          'Are you sure you want to delete ${_selectedDevices.length} selected device${_selectedDevices.length == 1 ? '' : 's'}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Perform bulk delete
              setState(() {
                for (var device in _selectedDevices) {
                  _devices.remove(device);
                }
                _selectedDevices.clear();
                _totalItems = _devices.length;
                _totalPages = (_totalItems / _itemsPerPage).ceil();
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Selected devices deleted successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _onStatusFilterChanged(String? status) {
    setState(() {
      _selectedStatus = status;
      _filteredDevices = _applyFilters(_devices);
    });
  }

  void _onTypeFilterChanged(String? type) {
    setState(() {
      _selectedType = type;
      _filteredDevices = _applyFilters(_devices);
    });
  }

  void _onLinkStatusFilterChanged(String? linkStatus) {
    setState(() {
      _selectedLinkStatus = linkStatus;
      _filteredDevices = _applyFilters(_devices);
    });
  }

  void _onViewModeChanged(DeviceViewMode mode) {
    setState(() {
      _currentViewMode = mode;
    });
  }

  void _onColumnVisibilityChanged(List<String> hiddenColumns) {
    setState(() {
      _hiddenColumns = hiddenColumns;
    });
  }

  void _exportDevices() {
    // TODO: Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionality coming soon'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _importDevices() {
    // TODO: Implement import functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Import functionality coming soon'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _handleSort(String columnKey, bool ascending) {
    setState(() {
      _sortBy = columnKey;
      _sortAscending = ascending;
      _sortDevices();
    });
  }

  void _sortDevices() {
    if (_sortBy == null) return;

    _filteredDevices.sort((a, b) {
      dynamic aValue;
      dynamic bValue;

      switch (_sortBy) {
        case 'serialNumber':
          aValue = a.serialNumber.toLowerCase();
          bValue = b.serialNumber.toLowerCase();
          break;
        case 'name':
          aValue = a.name.toLowerCase();
          bValue = b.name.toLowerCase();
          break;
        case 'deviceType':
          aValue = a.deviceType.toLowerCase();
          bValue = b.deviceType.toLowerCase();
          break;
        case 'model':
          aValue = a.model.toLowerCase();
          bValue = b.model.toLowerCase();
          break;
        case 'status':
          aValue = a.status.toLowerCase();
          bValue = b.status.toLowerCase();
          break;
        case 'linkStatus':
          aValue = a.linkStatus.toLowerCase();
          bValue = b.linkStatus.toLowerCase();
          break;
        case 'address':
          aValue = '${a.address?.street ?? ''} ${a.address?.city ?? ''}'
              .toLowerCase();
          bValue = '${b.address?.street ?? ''} ${b.address?.city ?? ''}'
              .toLowerCase();
          break;
        case 'manufacturer':
          aValue = a.manufacturer.toLowerCase();
          bValue = b.manufacturer.toLowerCase();
          break;
        default:
          return 0;
      }

      int comparison = aValue.toString().compareTo(bValue.toString());
      return _sortAscending ? comparison : -comparison;
    });
  }

  Widget _buildContent() {
    switch (_currentViewMode) {
      case DeviceViewMode.table:
        return _buildTableView();
      case DeviceViewMode.kanban:
        return _buildKanbanView();
      case DeviceViewMode.map:
        return _buildMapView();
    }
  }

  Widget _buildTableView() {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          //  _buildTableHeader(),
          if (_selectedDevices.isNotEmpty) _buildMultiSelectToolbar(),
          Expanded(child: _buildDeviceTable()),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildKanbanView() {
    return DeviceKanbanView(
      devices: _filteredDevices,
      onDeviceSelected: _viewDeviceDetails,
      isLoading: _isLoading,
      itemsPerPage: _itemsPerPage, // Use the screen's items per page setting
    );
  }

  Widget _buildMapView() {
    return Column(
      children: [
        // Map implementation toggle
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Text(
                'Device Map View - OpenStreetMap with clustering',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),

        // Map view
        Expanded(
          child: FlutterMapDeviceView(
            devices: _filteredDevices,
            onDeviceSelected: _viewDeviceDetails,
            isLoading: _isLoading,
            deviceService: _deviceService,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Handle breadcrumb navigation from MainLayout
  void _handleBreadcrumbNavigation(int index) {
    switch (index) {
      case 0: // "Devices" clicked
        _navigateBackToDevices();
        break;
      case 1: // Device serial number clicked (when in billing readings)
        if (_currentView == 'billing_readings') {
          _navigateBackToDeviceDetails();
        }
        break;
      // No action needed for the last breadcrumb (current page)
    }
  }
}
