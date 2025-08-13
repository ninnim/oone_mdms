import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/device.dart';
import '../../../core/models/device_group.dart';
import '../../../core/models/schedule.dart';
import '../../../core/services/device_service.dart';
import '../../../core/services/schedule_service.dart';
import '../../../core/services/service_locator.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_tabs.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/common/app_confirm_dialog.dart';
import '../../widgets/common/blunest_data_table.dart';
import '../../widgets/common/app_lottie_state_widget.dart';
import '../../widgets/common/results_pagination.dart';
import '../../widgets/devices/device_filters_and_actions_v2.dart';
import '../../widgets/devices/device_summary_card.dart';
import '../../widgets/devices/device_table_columns.dart';
import '../../widgets/devices/group_device_map_view.dart';
import '../../widgets/schedules/schedule_form_dialog.dart';
import '../../widgets/schedules/schedule_filters_and_actions_v2.dart';
import '../../widgets/schedules/schedule_summary_card.dart';
import '../../widgets/schedules/schedule_kanban_view.dart';
import '../../widgets/schedules/schedule_table_columns.dart';
import '../devices/create_edit_device_screen.dart';

class DeviceGroupDetailsScreen extends StatefulWidget {
  final DeviceGroup deviceGroup;

  const DeviceGroupDetailsScreen({super.key, required this.deviceGroup});

  @override
  State<DeviceGroupDetailsScreen> createState() =>
      _DeviceGroupDetailsScreenState();
}

class _DeviceGroupDetailsScreenState extends State<DeviceGroupDetailsScreen> {
  late DeviceService _deviceService;
  late ScheduleService _scheduleService;

  // State
  List<Device> _allDevices = [];
  List<Device> _selectedDevices = [];
  List<Schedule> _schedules = [];
  bool _isLoading = false;
  int _currentTabIndex = 0;

  // Tab-specific loading states
  bool _isOverviewLoading = false;
  bool _isDevicesLoading = false;
  bool _isSchedulesLoading = false;
  String? _overviewError;
  String? _devicesError;
  String? _schedulesError;

  // Device tab filtering, searching, and pagination
  String _deviceSearchQuery = '';
  String? _deviceStatusFilter;
  String? _deviceTypeFilter;
  String? _deviceManufacturerFilter;
  String _deviceSortBy = 'serialNumber';
  bool _deviceSortAscending = true;
  Set<String> _hiddenDeviceColumns = {};
  int _deviceCurrentPage = 1;
  int _deviceItemsPerPage = 10;
  DeviceDisplayMode _deviceViewMode = DeviceDisplayMode.table;
  Set<Device> _selectedDevicesForActions = {};
  Timer? _debounceTimer;

  // Schedule tab state
  ScheduleViewMode _scheduleViewMode = ScheduleViewMode.table;
  String _scheduleSearchQuery = '';
  String? _scheduleStatusFilter;
  String? _scheduleTargetTypeFilter;
  List<Schedule> _filteredSchedules = [];
  int _scheduleCurrentPage = 1;
  int _scheduleItemsPerPage = 25;
  Set<Schedule> _selectedSchedules = {};
  Timer? _scheduleDebounceTimer;

  // Schedule tab sorting and columns
  String _scheduleSortBy = 'name';
  bool _scheduleSortAscending = true;
  Set<String> _hiddenScheduleColumns = {};

  final TextEditingController _deviceSearchController = TextEditingController();
  final TextEditingController _scheduleSearchController =
      TextEditingController();

  @override
  void dispose() {
    _deviceSearchController.dispose();
    _scheduleSearchController.dispose();
    _debounceTimer?.cancel();
    _scheduleDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // Initialize services using ServiceLocator
    final serviceLocator = ServiceLocator();
    final apiService = serviceLocator.apiService;
    _deviceService = DeviceService(apiService);
    _scheduleService = ScheduleService(apiService);

    // Load data for initial tab
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Load data based on the initial tab (Overview by default)
    switch (_currentTabIndex) {
      case 0: // Overview tab
        _loadOverviewData();
        break;
      case 1: // Devices tab
        _loadDevicesData();
        break;
      case 2: // Schedules tab
        _loadSchedulesData();
        break;
      default:
        // Default to overview
        _loadOverviewData();
        break;
    }
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentTabIndex = index;
    });

    // Trigger API based on selected tab
    switch (index) {
      case 0: // Overview tab
        _loadOverviewData();
        break;
      case 1: // Devices tab
        _loadDevicesData();
        break;
      case 2: // Schedules tab
        _loadSchedulesData();
        break;
    }
  }

  Future<void> _loadData() async {
    // Load all data - useful for complete refresh
    await Future.wait([
      _loadOverviewData(),
      _loadDevicesData(),
      _loadSchedulesData(),
    ]);
  }

  // Individual tab loading methods
  Future<void> _loadOverviewData() async {
    setState(() {
      _isOverviewLoading = true;
      _overviewError = null;
    });

    try {
      // For overview, load basic device count data
      final devicesResponse = await _deviceService.getDevices();

      if (!devicesResponse.success) {
        throw Exception(devicesResponse.message);
      }

      final devices = devicesResponse.data ?? [];
      final groupDevices = devices
          .where((device) => device.deviceGroupId == widget.deviceGroup.id)
          .toList();

      setState(() {
        _allDevices = devices;
        _selectedDevices = List.from(groupDevices);
        _isOverviewLoading = false;
      });
    } catch (e) {
      setState(() {
        _overviewError = 'Failed to load overview data: $e';
        _isOverviewLoading = false;
      });
    }
  }

  Future<void> _loadDevicesData() async {
    setState(() {
      _isDevicesLoading = true;
      _devicesError = null;
    });

    try {
      // Load all available devices
      final devicesResponse = await _deviceService.getDevices();

      if (!devicesResponse.success) {
        throw Exception(devicesResponse.message);
      }

      final devices = devicesResponse.data ?? [];

      // Get devices currently in this group
      final groupDevices = devices
          .where((device) => device.deviceGroupId == widget.deviceGroup.id)
          .toList();

      setState(() {
        _allDevices = devices;
        _selectedDevices = List.from(groupDevices);
        _isDevicesLoading = false;
      });
    } catch (e) {
      setState(() {
        _devicesError = 'Failed to load devices: $e';
        _isDevicesLoading = false;
      });
    }
  }

  Future<void> _loadSchedulesData() async {
    setState(() {
      _isSchedulesLoading = true;
      _schedulesError = null;
    });

    try {
      // Load schedules for this device group
      List<Schedule> schedules = [];
      if (widget.deviceGroup.id != null) {
        final schedulesResponse = await _scheduleService
            .getSchedulesByDeviceGroupId(widget.deviceGroup.id!);

        if (schedulesResponse.success) {
          schedules = schedulesResponse.data ?? [];
        }
      }

      setState(() {
        _schedules = schedules;
        _filteredSchedules = List.from(schedules);
        _isSchedulesLoading = false;
      });
    } catch (e) {
      setState(() {
        _schedulesError = 'Failed to load schedules: $e';
        _isSchedulesLoading = false;
      });
    }
  }

  // Helper methods for device filtering and pagination
  List<Device> get filteredGroupDevices {
    var groupDevices = _allDevices
        .where((device) => device.deviceGroupId == widget.deviceGroup.id)
        .toList();

    // Apply search filter
    if (_deviceSearchQuery.isNotEmpty) {
      final query = _deviceSearchQuery.toLowerCase();
      groupDevices = groupDevices.where((device) {
        return device.serialNumber.toLowerCase().contains(query) ||
            device.name.toLowerCase().contains(query) ||
            device.deviceType.toLowerCase().contains(query);
      }).toList();
    }

    // Apply status filter
    if (_deviceStatusFilter != null && _deviceStatusFilter!.isNotEmpty) {
      groupDevices = groupDevices
          .where(
            (device) =>
                device.status.toLowerCase() ==
                _deviceStatusFilter!.toLowerCase(),
          )
          .toList();
    }

    // Apply device type filter
    if (_deviceTypeFilter != null && _deviceTypeFilter!.isNotEmpty) {
      groupDevices = groupDevices
          .where(
            (device) =>
                device.deviceType.toLowerCase() ==
                _deviceTypeFilter!.toLowerCase(),
          )
          .toList();
    }

    // Apply manufacturer filter
    if (_deviceManufacturerFilter != null &&
        _deviceManufacturerFilter!.isNotEmpty) {
      groupDevices = groupDevices
          .where(
            (device) =>
                device.manufacturer.toLowerCase() ==
                _deviceManufacturerFilter!.toLowerCase(),
          )
          .toList();
    }

    // Apply sorting
    groupDevices.sort((a, b) {
      dynamic aValue, bValue;
      switch (_deviceSortBy) {
        case 'serialNumber':
          aValue = a.serialNumber;
          bValue = b.serialNumber;
          break;
        case 'name':
          aValue = a.name;
          bValue = b.name;
          break;
        case 'deviceType':
          aValue = a.deviceType;
          bValue = b.deviceType;
          break;
        case 'status':
          aValue = a.status;
          bValue = b.status;
          break;
        default:
          aValue = a.serialNumber;
          bValue = b.serialNumber;
      }

      final comparison = aValue.toString().compareTo(bValue.toString());
      return _deviceSortAscending ? comparison : -comparison;
    });

    return groupDevices;
  }

  List<Device> get paginatedGroupDevices {
    final filtered = filteredGroupDevices;
    final startIndex = (_deviceCurrentPage - 1) * _deviceItemsPerPage;
    final endIndex = startIndex + _deviceItemsPerPage;

    if (startIndex >= filtered.length) {
      return [];
    }

    return filtered.sublist(
      startIndex,
      endIndex > filtered.length ? filtered.length : endIndex,
    );
  }

  int get totalDevicePages {
    return (filteredGroupDevices.length / _deviceItemsPerPage).ceil();
  }

  List<Schedule> get filteredSchedules {
    var schedules = List<Schedule>.from(_schedules);

    // Apply sorting
    schedules.sort((a, b) {
      dynamic aValue, bValue;
      switch (_scheduleSortBy) {
        case 'name':
          aValue = a.name ?? '';
          bValue = b.name ?? '';
          break;
        case 'code':
          aValue = a.code ?? '';
          bValue = b.code ?? '';
          break;
        case 'jobStatus':
          aValue = a.jobStatus ?? '';
          bValue = b.jobStatus ?? '';
          break;
        default:
          aValue = a.name ?? '';
          bValue = b.name ?? '';
      }

      final comparison = aValue.toString().compareTo(bValue.toString());
      return _scheduleSortAscending ? comparison : -comparison;
    });

    return schedules;
  }

  // Future<void> _saveChanges() async {
  //   setState(() => _isLoading = true);

  //   try {
  //     // Update devices to belong to this group
  //     final updateFutures = <Future>[];

  //     // Remove devices that are no longer selected
  //     final currentGroupDevices = _allDevices
  //         .where((device) => device.deviceGroupId == widget.deviceGroup.id)
  //         .toList();

  //     for (final device in currentGroupDevices) {
  //       if (!_selectedDevices.any((d) => d.id == device.id)) {
  //         updateFutures.add(
  //           _deviceService.updateDevice(
  //             device.copyWith(deviceGroupId: 0), // 0 means no group
  //           ),
  //         );
  //       }
  //     }

  //     // Add newly selected devices to this group
  //     for (final device in _selectedDevices) {
  //       if (device.deviceGroupId != widget.deviceGroup.id) {
  //         updateFutures.add(
  //           _deviceService.updateDevice(
  //             device.copyWith(deviceGroupId: widget.deviceGroup.id),
  //           ),
  //         );
  //       }
  //     }

  //     await Future.wait(updateFutures);

  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('Device group updated successfully'),
  //           backgroundColor: AppColors.success,
  //         ),
  //       );
  //       // Navigate back to device groups list
  //       context.go('/device-groups');
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Failed to update device group: $e'),
  //           backgroundColor: AppColors.error,
  //         ),
  //       );
  //     }
  //   } finally {
  //     if (mounted) {
  //       setState(() => _isLoading = false);
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with breadcrumbs
        Container(
          padding: const EdgeInsets.all(AppSizes.spacing16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Back button
                  IconButton(
                    onPressed: () => context.go('/device-groups'),
                    icon: const Icon(Icons.arrow_back),
                    color: AppColors.textSecondary,
                    tooltip: 'Back to Device Groups',
                  ),
                  const SizedBox(width: AppSizes.spacing8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.deviceGroup.name ?? 'Device Groups!',
                          style: const TextStyle(
                            fontSize: AppSizes.fontSizeLarge,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (widget.deviceGroup.description?.isNotEmpty ==
                            true) ...[
                          const SizedBox(height: AppSizes.spacing4),
                          Text(
                            widget.deviceGroup.description!,
                            style: const TextStyle(
                              fontSize: AppSizes.fontSizeMedium,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // AppButton(text: 'Save Change', onPressed: _saveChanges),
                ],
              ),
            ],
          ),
        ),

        // Tab content with AppPillTabs
        Expanded(
          child: AppPillTabs(
            initialIndex: _currentTabIndex,
            onTabChanged: _onTabChanged,
            tabs: [
              AppTab(
                label: 'Overview',
                icon: Icon(Icons.info, size: AppSizes.iconSmall),
                content: _buildOverviewTab(),
              ),
              AppTab(
                label: 'Devices',
                icon: Icon(Icons.devices, size: AppSizes.iconSmall),
                content: _buildDevicesTab(),
              ),
              AppTab(
                label: 'Schedules',
                icon: Icon(Icons.schedule, size: AppSizes.iconSmall),
                content: _buildSchedulesTab(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab() {
    // Show loading state for overview tab
    if (_isOverviewLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSizes.spacing24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: AppSizes.spacing16),
              Text('Loading overview data...'),
            ],
          ),
        ),
      );
    }

    // Show error state for overview tab
    if (_overviewError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.spacing24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSizes.spacing16),
              Text(
                _overviewError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: AppSizes.spacing16),
              AppButton(text: 'Retry', onPressed: _loadOverviewData),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Information Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Basic Information',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeLarge,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.spacing16),
                _buildInfoRow('Name', widget.deviceGroup.name ?? 'None'),
                _buildInfoRow(
                  'Description',
                  widget.deviceGroup.description ?? 'No description',
                ),
                _buildInfoRow(
                  'Status',
                  widget.deviceGroup.active == true ? 'Active' : 'Inactive',
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.spacing16),

          // Statistics Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Statistics',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeLarge,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.spacing16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Devices',
                        _selectedDevices.length.toString(),
                        Icons.devices,
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacing16),
                    Expanded(
                      child: _buildStatCard(
                        'Active Devices',
                        _selectedDevices
                            .where((d) => d.status == 'Commissioned')
                            .length
                            .toString(),
                        Icons.check_circle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevicesTab() {
    // Show loading state for devices tab
    if (_isDevicesLoading) {
      return AppLottieStateWidget.loading(
        title: 'Loading Devices',
        titleColor: AppColors.primary,
        messageColor: AppColors.secondary,
        message: 'Please wait while we fetch devices in this group...',
        lottieSize: 100,
      );
    }

    // Show error state for devices tab
    if (_devicesError != null) {
      return AppLottieStateWidget.error(
        title: 'Failed to Load Devices',
        message: _devicesError!,
        buttonText: 'Retry',
        onButtonPressed: _loadDevicesData,
      );
    }

    final filteredDevices = filteredGroupDevices;

    return Padding(
      padding: const EdgeInsets.all(AppSizes.spacing12),
      child: Column(
        children: [
          // Filters and actions (same style as devices screen)
          DeviceFiltersAndActionsV2(
            onSearchChanged: _onDeviceSearchChanged,
            onStatusFilterChanged: _onDeviceStatusFilterChanged,
            onLinkStatusFilterChanged: _onDeviceLinkStatusFilterChanged,
            onViewModeChanged: _onDeviceViewModeChanged,
            onAddDevice: _showCreateDeviceDialog,
            onRefresh: _loadDevicesData, // Use specific device loading method
            onExport: _exportGroupDevices,
            onImport: null, // No import for group devices
            currentViewMode: _deviceViewMode,
            selectedStatus: _deviceStatusFilter,
            selectedLinkStatus:
                null, // Group devices don't have link status filter
          ),

          SizedBox(height: AppSizes.spacing12),

          // Summary card (same style as devices screen)
          DeviceSummaryCard(devices: filteredDevices),

          const SizedBox(height: AppSizes.spacing8),

          // Content based on view mode
          Expanded(child: _buildDeviceContent()),
        ],
      ),
    );
  }

  Widget _buildDeviceContent() {
    final filteredDevices = filteredGroupDevices;

    // Show no data state if no devices (loading is handled at tab level)
    if (filteredDevices.isEmpty) {
      return AppLottieStateWidget.noData(
        title: 'No Devices Found',
        message: _deviceSearchQuery.isNotEmpty || _deviceStatusFilter != null
            ? 'No devices match the current filters.'
            : 'This device group has no devices assigned.',
        buttonText: 'Add Device',
        titleColor: AppColors.primary,
        messageColor: AppColors.secondary,
        onButtonPressed: _showCreateDeviceDialog,
      );
    }

    return switch (_deviceViewMode) {
      DeviceDisplayMode.table => _buildDeviceTableView(),
      DeviceDisplayMode.kanban => _buildDeviceKanbanView(),
      DeviceDisplayMode.map => _buildDeviceMapView(),
    };
  }

  Widget _buildDeviceTableView() {
    final paginatedDevices = paginatedGroupDevices;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          if (_selectedDevicesForActions.isNotEmpty) _buildMultiSelectToolbar(),
          Expanded(
            child: BluNestDataTable<Device>(
              columns: DeviceTableColumns.getColumns(
                onView: (device) => _viewDevice(device),
                onEdit: (device) => _editDevice(device),
                onDelete: (device) => _removeDeviceFromGroup(device),
                currentPage: _deviceCurrentPage,
                itemsPerPage: _deviceItemsPerPage,
                devices: paginatedDevices,
              ),
              data: paginatedDevices,
              onRowTap: (device) => _viewDevice(device),
              enableMultiSelect: true,
              selectedItems: _selectedDevicesForActions,
              onSelectionChanged: (selectedItems) {
                setState(() {
                  _selectedDevicesForActions = selectedItems;
                });
              },
              hiddenColumns: _hiddenDeviceColumns.toList(),
              onColumnVisibilityChanged: (hiddenColumns) {
                setState(() {
                  _hiddenDeviceColumns = hiddenColumns.toSet();
                });
              },
              sortBy: _deviceSortBy,
              sortAscending: _deviceSortAscending,
              onSort: (column, ascending) {
                setState(() {
                  _deviceSortBy = column;
                  _deviceSortAscending = ascending;
                });
              },
              isLoading: false,
              totalItemsCount: filteredGroupDevices.length,
              onSelectAllItems: _fetchAllGroupDevices,
            ),
          ),
          _buildDevicePagination(),
        ],
      ),
    );
  }

  Widget _buildDeviceKanbanView() {
    final paginatedDevices = paginatedGroupDevices;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          if (_selectedDevicesForActions.isNotEmpty) _buildMultiSelectToolbar(),
          Expanded(child: _buildEnhancedDeviceKanbanView(paginatedDevices)),
          _buildDevicePagination(),
        ],
      ),
    );
  }

  Widget _buildEnhancedDeviceKanbanView(List<Device> devices) {
    if (devices.isEmpty && !_isLoading) {
      return const Center(
        child: Text(
          'No devices in this group',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: AppSizes.fontSizeMedium,
          ),
        ),
      );
    }

    final groupedDevices = _groupDevicesByStatus(devices);

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: groupedDevices.entries.map((entry) {
            return _buildDeviceStatusColumn(entry.key, entry.value);
          }).toList(),
        ),
      ),
    );
  }

  Map<String, List<Device>> _groupDevicesByStatus(List<Device> devices) {
    final Map<String, List<Device>> grouped = {
      'Commissioned': [],
      'Decommissioned': [],
      'Unknown': [],
    };

    for (final device in devices) {
      if (device.status.toLowerCase() == 'commissioned') {
        grouped['Commissioned']!.add(device);
      } else if (device.status.toLowerCase() == 'decommissioned') {
        grouped['Decommissioned']!.add(device);
      } else {
        grouped['Unknown']!.add(device);
      }
    }

    return grouped;
  }

  Widget _buildDeviceStatusColumn(String status, List<Device> devices) {
    Color statusColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'commissioned':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'decommissioned':
        statusColor = AppColors.error;
        statusIcon = Icons.cancel_outlined;
        break;
      case 'unknown':
      default:
        statusColor = AppColors.textSecondary;
        statusIcon = Icons.help_outline;
    }

    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: AppSizes.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column header
          Container(
            padding: const EdgeInsets.all(AppSizes.spacing16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSizes.radiusMedium),
                topRight: Radius.circular(AppSizes.radiusMedium),
              ),
              border: Border(
                bottom: BorderSide(color: statusColor.withOpacity(0.2)),
              ),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: AppSizes.spacing8),
                Text(
                  status,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                    fontSize: AppSizes.fontSizeMedium,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacing8,
                    vertical: AppSizes.spacing4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  ),
                  child: Text(
                    '${devices.length}',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeSmall,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Device cards
          Expanded(
            child: devices.isEmpty
                ? _buildDeviceEmptyState(status)
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSizes.spacing8),
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      return _buildDeviceKanbanCard(devices[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceEmptyState(String status) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.device_hub_outlined,
            size: 48,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: AppSizes.spacing12),
          Text(
            'No ${status.toLowerCase()} devices',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppSizes.fontSizeSmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceKanbanCard(Device device) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spacing8),
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _viewDevice(device),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name, status, and actions
            Row(
              children: [
                Expanded(
                  child: Text(
                    device.name.isNotEmpty ? device.name : device.serialNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontSize: AppSizes.fontSizeMedium,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSizes.spacing8),
                _buildDeviceStatusChip(device.status, device.active),
                const SizedBox(width: AppSizes.spacing4),
                _buildDeviceActionsDropdown(device),
              ],
            ),
            const SizedBox(height: AppSizes.spacing12),

            // Device details
            _buildDetailRow(Icons.tag, 'Serial', device.serialNumber),
            const SizedBox(height: AppSizes.spacing8),
            _buildDetailRow(Icons.memory, 'Type', device.deviceType),
            const SizedBox(height: AppSizes.spacing8),
            _buildDetailRow(Icons.settings, 'Model', device.model),
            const SizedBox(height: AppSizes.spacing8),
            _buildDetailRow(
              Icons.business,
              'Manufacturer',
              device.manufacturer,
            ),

            // Link status indicator
            if (device.linkStatus.isNotEmpty) ...[
              const SizedBox(height: AppSizes.spacing12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacing8,
                  vertical: AppSizes.spacing4,
                ),
                decoration: BoxDecoration(
                  color: _getDeviceLinkStatusColor(
                    device.linkStatus,
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  border: Border.all(
                    color: _getDeviceLinkStatusColor(
                      device.linkStatus,
                    ).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      device.linkStatus.toLowerCase() == 'connected'
                          ? Icons.link
                          : Icons.link_off,
                      size: 14,
                      color: _getDeviceLinkStatusColor(device.linkStatus),
                    ),
                    const SizedBox(width: AppSizes.spacing4),
                    Text(
                      'Link: ${device.linkStatus}',
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeExtraSmall,
                        color: _getDeviceLinkStatusColor(device.linkStatus),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceStatusChip(String status, bool isActive) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;

    if (status.toLowerCase().contains('active') || isActive) {
      // Active - Green
      backgroundColor = const Color(0xFF059669).withOpacity(0.1);
      borderColor = const Color(0xFF059669).withOpacity(0.3);
      textColor = const Color(0xFF059669);
    } else {
      // Inactive - Red
      backgroundColor = const Color(0xFFDC2626).withOpacity(0.1);
      borderColor = const Color(0xFFDC2626).withOpacity(0.3);
      textColor = const Color(0xFFDC2626);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacing8,
        vertical: AppSizes.spacing4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          color: textColor,
          fontSize: AppSizes.fontSizeSmall,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: AppSizes.iconSmall, color: AppColors.textSecondary),
        const SizedBox(width: AppSizes.spacing8),
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: AppSizes.fontSizeSmall,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: AppSizes.spacing4),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : 'Not specified',
            style: const TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceActionsDropdown(Device device) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert,
        color: AppColors.textSecondary,
        size: 16,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'view',
          child: Row(
            children: [
              Icon(Icons.visibility, size: 16, color: AppColors.primary),
              SizedBox(width: AppSizes.spacing8),
              Text('View Details'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 16, color: AppColors.warning),
              SizedBox(width: AppSizes.spacing8),
              Text('Edit'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'remove',
          child: Row(
            children: [
              Icon(Icons.remove_circle, size: 16, color: AppColors.error),
              SizedBox(width: AppSizes.spacing8),
              Text(
                'Remove from Group',
                style: TextStyle(color: AppColors.error),
              ),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'view':
            _viewDevice(device);
            break;
          case 'edit':
            _editDevice(device);
            break;
          case 'remove':
            _removeDeviceFromGroup(device);
            break;
        }
      },
    );
  }

  Color _getDeviceLinkStatusColor(String linkStatus) {
    switch (linkStatus.toLowerCase()) {
      case 'connected':
      case 'online':
      case 'multidrive':
        return AppColors.success;
      case 'disconnected':
      case 'offline':
        return AppColors.error;
      case 'pending':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildDeviceMapView() {
    return Column(
      children: [
        // Map implementation toggle
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
        ),

        // Map view
        Expanded(
          child: GroupDeviceMapView(
            deviceGroupId: widget.deviceGroup.id ?? 0,
            onDeviceSelected: _viewDevice,
            isLoading: _isLoading,
            deviceService: _deviceService,
            groupName: '',
          ),
        ),
      ],
    );
  }

  Widget _buildDevicePagination() {
    final filteredDevices = filteredGroupDevices;
    final totalPages = totalDevicePages;

    if (totalPages <= 1) return const SizedBox.shrink();

    final startItem = (_deviceCurrentPage - 1) * _deviceItemsPerPage + 1;
    final endItem =
        (_deviceCurrentPage * _deviceItemsPerPage) > filteredDevices.length
        ? filteredDevices.length
        : _deviceCurrentPage * _deviceItemsPerPage;

    return Padding(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      child: ResultsPagination(
        currentPage: _deviceCurrentPage,
        totalPages: totalPages,
        totalItems: filteredDevices.length,
        itemsPerPage: _deviceItemsPerPage,
        itemsPerPageOptions: const [5, 10, 20, 25, 50],
        startItem: startItem,
        endItem: endItem,
        onPageChanged: (page) {
          setState(() {
            _deviceCurrentPage = page;
          });
        },
        onItemsPerPageChanged: (newItemsPerPage) {
          setState(() {
            _deviceItemsPerPage = newItemsPerPage;
            _deviceCurrentPage = 1;
          });
        },
        showItemsPerPageSelector: true,
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
            '${_selectedDevicesForActions.length} device${_selectedDevicesForActions.length == 1 ? '' : 's'} selected',
            style: const TextStyle(
              fontSize: AppSizes.fontSizeMedium,
              fontWeight: FontWeight.w600,
              color: AppColors.surface,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () {
              _bulkRemoveDevicesFromGroup();
            },
            icon: const Icon(
              Icons.remove_circle_outline,
              color: AppColors.surface,
              size: AppSizes.iconSmall,
            ),
            label: const Text(
              'Remove from Group',
              style: TextStyle(color: AppColors.surface),
            ),
          ),
        ],
      ),
    );
  }

  // Filter and action handlers
  void _onDeviceSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _deviceSearchQuery = value;
        _deviceCurrentPage = 1;
      });
    });
  }

  void _onDeviceStatusFilterChanged(String? status) {
    setState(() {
      _deviceStatusFilter = status;
      _deviceCurrentPage = 1;
    });
  }

  void _onDeviceLinkStatusFilterChanged(String? linkStatus) {
    // Device groups don't use link status filter
    // This method is required by the interface but can be empty
  }

  void _onDeviceViewModeChanged(DeviceDisplayMode mode) {
    setState(() {
      _deviceViewMode = mode;
    });
  }

  void _exportGroupDevices() {
    // TODO: Implement export functionality for group devices
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionality coming soon'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _editDevice(Device device) {
    showDialog(
      context: context,
      builder: (context) => CreateEditDeviceDialog(
        device: device,
        presetDeviceGroupId: widget.deviceGroup.id,
        onSaved: () {
          _loadDevicesData(); // Refresh the devices after editing
        },
      ),
    );
  }

  Future<List<Device>> _fetchAllGroupDevices() async {
    try {
      // Return all devices in the current group (filteredGroupDevices)
      // This represents all devices that would be selected across all pages
      return filteredGroupDevices;
    } catch (e) {
      throw Exception('Error fetching all group devices: $e');
    }
  }

  Future<void> _bulkRemoveDevicesFromGroup() async {
    final deviceCount = _selectedDevicesForActions.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Devices from Group'),
        content: Text(
          'Are you sure you want to remove $deviceCount selected device${deviceCount == 1 ? '' : 's'} from this group?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);

        // Update devices to remove from group (set deviceGroupId to 0)
        final updateFutures = _selectedDevicesForActions.map((device) {
          return _deviceService.updateDevice(device.copyWith(deviceGroupId: 0));
        }).toList();

        await Future.wait(updateFutures);

        // Clear selection and reload data
        setState(() {
          _selectedDevicesForActions.clear();
        });

        await _loadDevicesData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$deviceCount device${deviceCount == 1 ? '' : 's'} removed from group successfully',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove devices: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spacing12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: AppSizes.fontSizeMedium,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.spacing16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: AppSizes.fontSizeMedium,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: AppSizes.iconLarge, color: AppColors.primary),
          const SizedBox(height: AppSizes.spacing8),
          Text(
            value,
            style: const TextStyle(
              fontSize: AppSizes.fontSizeHeading,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSizes.spacing4),
          Text(
            title,
            style: const TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulesTab() {
    // Show loading state for schedules tab
    if (_isSchedulesLoading) {
      return AppLottieStateWidget.loading(
        title: 'Loading Schedules',
        titleColor: AppColors.primary,
        messageColor: AppColors.secondary,
        message: 'Please wait while we fetch schedules for this group...',
        lottieSize: 100,
      );
    }

    // Show error state for schedules tab
    if (_schedulesError != null) {
      return AppLottieStateWidget.error(
        title: 'Failed to Load Schedules',
        message: _schedulesError!,
        buttonText: 'Retry',
        onButtonPressed: _loadSchedulesData,
      );
    }

    return Column(
      children: [
        // Summary card with padding (same style as schedule screen)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
          child: ScheduleSummaryCard(schedules: _filteredSchedules),
        ),

        const SizedBox(height: AppSizes.spacing8),

        // Filters and actions with padding (same style as schedule screen)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
          child: ScheduleFiltersAndActionsV2(
            onSearchChanged: _onScheduleSearchChanged,
            onStatusFilterChanged: _onScheduleStatusFilterChanged,
            onTargetTypeFilterChanged: _onScheduleTargetTypeFilterChanged,
            onViewModeChanged: _onScheduleViewModeChanged,
            onAddSchedule: _showCreateScheduleDialog,
            onRefresh:
                _loadSchedulesData, // Use specific schedule loading method
            onExport: _exportSchedules,
            onImport: _importSchedules,
            currentViewMode: _scheduleViewMode,
            selectedStatus: _scheduleStatusFilter,
            selectedTargetType: _scheduleTargetTypeFilter,
          ),
        ),

        const SizedBox(height: AppSizes.spacing8),

        // Content based on view mode
        Expanded(child: _buildScheduleContent()),
      ],
    );
  }

  Widget _buildScheduleContent() {
    // Show no data state if no schedules (loading is handled at tab level)
    if (_schedules.isEmpty) {
      return AppLottieStateWidget.noData(
        title: 'No Schedules Found',
        message: 'This device group has no scheduled tasks configured.',
        buttonText: 'Create Schedule',
        titleColor: AppColors.primary,
        messageColor: AppColors.secondary,
        onButtonPressed: _showCreateScheduleDialog,
      );
    }

    // Show filtered empty state if filtered schedules are empty but original schedules exist
    if (_filteredSchedules.isEmpty && _schedules.isNotEmpty) {
      return AppLottieStateWidget.noData(
        title: 'No Matching Schedules',
        message:
            'No schedules match your current filters. Try adjusting your search criteria.',
        buttonText: 'Clear Filters',
        onButtonPressed: _clearScheduleFilters,
      );
    }

    // Build content based on view mode
    return switch (_scheduleViewMode) {
      ScheduleViewMode.table => _buildScheduleTableView(),
      ScheduleViewMode.kanban => _buildScheduleKanbanView(),
    };
  }

  Widget _buildScheduleTableView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
      child: _buildScheduleTable(),
    );
  }

  Widget _buildScheduleKanbanView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
      child: ScheduleKanbanView(
        schedules: _getPaginatedSchedules(),
        onScheduleSelected: _showViewScheduleDialog,
        onScheduleView: _showViewScheduleDialog,
        onScheduleEdit: _showEditScheduleDialog,
        onScheduleDelete: _showDeleteScheduleDialog,
        isLoading: _isLoading,
        enablePagination: false,
        itemsPerPage: _scheduleItemsPerPage,
      ),
    );
  }

  Widget _buildScheduleTable() {
    final displaySchedules = _getPaginatedSchedules();

    return BluNestDataTable<Schedule>(
      columns: ScheduleTableColumns.getBluNestColumns(
        onView: (schedule) => _showViewScheduleDialog(schedule),
        onEdit: (schedule) => _showEditScheduleDialog(schedule),
        onDelete: (schedule) => _showDeleteScheduleDialog(schedule),
        currentPage: _scheduleCurrentPage,
        itemsPerPage: _scheduleItemsPerPage,
        schedules: displaySchedules,
      ),
      data: displaySchedules,
      onRowTap: (schedule) => _showViewScheduleDialog(schedule),
      onEdit: (schedule) => _showEditScheduleDialog(schedule),
      onDelete: (schedule) => _showDeleteScheduleDialog(schedule),
      onView: (schedule) => _showViewScheduleDialog(schedule),
      enableMultiSelect: true,
      selectedItems: _selectedSchedules,
      onSelectionChanged: (selectedItems) {
        setState(() {
          _selectedSchedules = selectedItems;
        });
      },
      hiddenColumns: _hiddenScheduleColumns.toList(),
      onColumnVisibilityChanged: (hiddenColumns) {
        setState(() {
          _hiddenScheduleColumns = hiddenColumns.toSet();
        });
      },
      sortBy: _scheduleSortBy,
      sortAscending: _scheduleSortAscending,
      onSort: _handleScheduleSort,
      isLoading: _isLoading,
      totalItemsCount: _filteredSchedules.length,
      onSelectAllItems: _fetchAllGroupSchedules,
    );
  }

  void _showCreateDeviceDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateEditDeviceDialog(
        device: null,
        presetDeviceGroupId: widget.deviceGroup.id,
        onSaved: () {
          _loadDevicesData(); // Refresh the devices after creating a device
        },
      ),
    );
  }

  void _viewDevice(Device device) {
    // Navigate to device details page with back route to device group details
    final backRoute = '/device-groups/details/${widget.deviceGroup.id}';
    context.go(
      '/devices/details/${device.id}?back=${Uri.encodeComponent(backRoute)}',
      extra: device,
    );
  }

  Future<void> _removeDeviceFromGroup(Device device) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Device'),
        content: Text(
          'Are you sure you want to remove "${device.serialNumber}" from this group?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        setState(() => _isLoading = true);

        // Update device to remove from group (set deviceGroupId to 0)
        final updatedDevice = device.copyWith(deviceGroupId: 0);
        await _deviceService.updateDevice(updatedDevice);

        // Reload data
        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Device removed from group successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove device: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  // Schedule Management Methods
  List<Schedule> _applyScheduleFilters(List<Schedule> schedules) {
    var filtered = schedules;

    if (_scheduleSearchQuery.isNotEmpty) {
      final query = _scheduleSearchQuery.toLowerCase();
      filtered = filtered.where((schedule) {
        return (schedule.name?.toLowerCase().contains(query) ?? false) ||
            (schedule.code?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    if (_scheduleStatusFilter != null) {
      filtered = filtered
          .where((schedule) => schedule.displayStatus == _scheduleStatusFilter)
          .toList();
    }

    if (_scheduleTargetTypeFilter != null) {
      filtered = filtered
          .where(
            (schedule) =>
                schedule.displayTargetType == _scheduleTargetTypeFilter,
          )
          .toList();
    }

    return filtered;
  }

  List<Schedule> _getPaginatedSchedules() {
    final startIndex = (_scheduleCurrentPage - 1) * _scheduleItemsPerPage;
    final endIndex = startIndex + _scheduleItemsPerPage;

    if (startIndex >= _filteredSchedules.length) {
      return [];
    }

    return _filteredSchedules.sublist(
      startIndex,
      endIndex > _filteredSchedules.length
          ? _filteredSchedules.length
          : endIndex,
    );
  }

  void _onScheduleSearchChanged(String value) {
    _scheduleDebounceTimer?.cancel();
    _scheduleDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _scheduleSearchQuery = value;
        _scheduleCurrentPage = 1;
        _filteredSchedules = _applyScheduleFilters(_schedules);
      });
    });
  }

  void _onScheduleStatusFilterChanged(String? status) {
    setState(() {
      _scheduleStatusFilter = status;
      _scheduleCurrentPage = 1;
      _filteredSchedules = _applyScheduleFilters(_schedules);
    });
  }

  void _onScheduleTargetTypeFilterChanged(String? targetType) {
    setState(() {
      _scheduleTargetTypeFilter = targetType;
      _scheduleCurrentPage = 1;
      _filteredSchedules = _applyScheduleFilters(_schedules);
    });
  }

  void _onScheduleViewModeChanged(ScheduleViewMode mode) {
    setState(() {
      _scheduleViewMode = mode;
    });
  }

  void _clearScheduleFilters() {
    setState(() {
      _scheduleStatusFilter = null;
      _scheduleTargetTypeFilter = null;
      _scheduleSearchQuery = '';
      _scheduleSearchController.clear();
      _filteredSchedules = List.from(_schedules);
    });
  }

  void _handleScheduleSort(String columnKey, bool ascending) {
    setState(() {
      _scheduleSortBy = columnKey;
      _scheduleSortAscending = ascending;
      _sortSchedules();
    });
  }

  void _sortSchedules() {
    if (_scheduleSortBy.isEmpty) return;

    _filteredSchedules.sort((a, b) {
      dynamic aValue;
      dynamic bValue;

      switch (_scheduleSortBy) {
        case 'code':
          aValue = a.displayCode.toLowerCase();
          bValue = b.displayCode.toLowerCase();
          break;
        case 'name':
          aValue = a.displayName.toLowerCase();
          bValue = b.displayName.toLowerCase();
          break;
        case 'targetType':
          aValue = a.displayTargetType.toLowerCase();
          bValue = b.displayTargetType.toLowerCase();
          break;
        case 'status':
          aValue = a.displayStatus.toLowerCase();
          bValue = b.displayStatus.toLowerCase();
          break;
        case 'interval':
          aValue = a.displayInterval.toLowerCase();
          bValue = b.displayInterval.toLowerCase();
          break;
        default:
          return 0;
      }

      int comparison = aValue.toString().compareTo(bValue.toString());
      return _scheduleSortAscending ? comparison : -comparison;
    });
  }

  Future<List<Schedule>> _fetchAllGroupSchedules() async {
    try {
      // Return all schedules for the current group (filtered schedules)
      return _filteredSchedules;
    } catch (e) {
      throw Exception('Error fetching all group schedules: $e');
    }
  }

  void _showCreateScheduleDialog() {
    showDialog(
      context: context,
      builder: (context) => ScheduleFormDialog(
        preselectedDeviceGroupId: widget.deviceGroup.id,
        preselectedTargetType: 'DeviceGroup',
        onSuccess: () {
          _loadSchedulesData();
          AppToast.showSuccess(
            context,
            message: 'Schedule created successfully',
          );
        },
      ),
    );
  }

  void _showEditScheduleDialog(Schedule schedule) {
    showDialog(
      context: context,
      builder: (context) => ScheduleFormDialog(
        schedule: schedule,
        onSuccess: () {
          _loadSchedulesData();
          AppToast.showSuccess(
            context,
            message: 'Schedule updated successfully',
          );
        },
      ),
    );
  }

  void _showViewScheduleDialog(Schedule schedule) {
    showDialog(
      context: context,
      builder: (context) => ScheduleFormDialog(
        schedule: schedule,
        mode: 'view',
        onSuccess: () {
          _loadSchedulesData();
          AppToast.showSuccess(
            context,
            message: 'Schedule updated successfully',
          );
        },
      ),
    );
  }

  Future<void> _showDeleteScheduleDialog(Schedule schedule) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Delete Schedule',
      message:
          'Are you sure you want to delete schedule "${schedule.displayName}"? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      confirmType: AppButtonType.danger,
      icon: Icons.delete_outline,
    );

    if (confirmed == true && mounted) {
      await _deleteSchedule(schedule);
    }
  }

  Future<void> _deleteSchedule(Schedule schedule) async {
    try {
      // Direct API call without another confirmation dialog
      await _scheduleService.deleteSchedule(
        schedule.billingDevice!.id!.toLowerCase(),
      );

      if (mounted) {
        AppToast.showSuccess(
          context,
          title: 'Schedule Deleted',
          message:
              'Schedule "${schedule.displayName}" has been successfully deleted.',
        );

        await _loadSchedulesData();
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(
          context,
          error: e,
          title: 'Delete Failed',
          errorContext: 'schedule_delete',
        );
      }
    }
  }

  void _exportSchedules() {
    AppToast.showInfo(
      context,
      title: 'Export',
      message: 'Export functionality coming soon',
    );
  }

  void _importSchedules() {
    AppToast.showInfo(
      context,
      title: 'Import',
      message: 'Import functionality coming soon',
    );
  }
}
