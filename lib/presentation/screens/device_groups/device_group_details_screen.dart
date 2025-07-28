import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../core/constants/app_colors.dart';
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
import '../../widgets/common/blunest_data_table.dart';
import '../../widgets/common/status_chip.dart';
import '../../widgets/common/app_lottie_state_widget.dart';
import '../../widgets/common/results_pagination.dart';
import '../../widgets/devices/device_filters_and_actions_v2.dart';
import '../../widgets/devices/device_summary_card.dart';
import '../../widgets/devices/device_table_columns.dart';
import '../../widgets/devices/device_kanban_view.dart';
import '../../widgets/devices/group_device_map_view.dart';
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
  String? _error;
  int _currentTabIndex = 0;

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
  DeviceViewMode _deviceViewMode = DeviceViewMode.table;
  Set<Device> _selectedDevicesForActions = {};
  Timer? _debounceTimer;

  // Schedule tab sorting and columns
  String _scheduleSortBy = 'name';
  bool _scheduleSortAscending = true;
  Set<String> _hiddenScheduleColumns = {};

  final TextEditingController _deviceSearchController = TextEditingController();

  @override
  void dispose() {
    _deviceSearchController.dispose();
    _debounceTimer?.cancel();
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

    _loadData();
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentTabIndex = index;
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
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
        _allDevices = devices;
        _selectedDevices = List.from(groupDevices);
        _schedules = schedules;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load data: $e';
        _isLoading = false;
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

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    try {
      // Update devices to belong to this group
      final updateFutures = <Future>[];

      // Remove devices that are no longer selected
      final currentGroupDevices = _allDevices
          .where((device) => device.deviceGroupId == widget.deviceGroup.id)
          .toList();

      for (final device in currentGroupDevices) {
        if (!_selectedDevices.any((d) => d.id == device.id)) {
          updateFutures.add(
            _deviceService.updateDevice(
              device.copyWith(deviceGroupId: 0), // 0 means no group
            ),
          );
        }
      }

      // Add newly selected devices to this group
      for (final device in _selectedDevices) {
        if (device.deviceGroupId != widget.deviceGroup.id) {
          updateFutures.add(
            _deviceService.updateDevice(
              device.copyWith(deviceGroupId: widget.deviceGroup.id),
            ),
          );
        }
      }

      await Future.wait(updateFutures);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device group updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        // Navigate back to device groups list
        context.go('/device-groups');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update device group: $e'),
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
                  AppButton(
                    text: 'Save Change',
                    onPressed: _isLoading ? null : _saveChanges,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Tab content with AppPillTabs
        Expanded(
          child: _isLoading
              ? const Center(
                  child: AppLottieStateWidget.loading(
                    title: 'Loading Device Group Details...',
                    message: 'Please wait while we fetch the data.',
                  ),
                )
              : _error != null
              ? AppLottieStateWidget.error(
                  title: 'Error Loading Device Group',
                  message: _error!,
                  buttonText: 'Retry',
                  onButtonPressed: _loadData,
                )
              : AppPillTabs(
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
            onRefresh: _loadData,
            onExport: _exportGroupDevices,
            onImport: null, // No import for group devices
            currentViewMode: _deviceViewMode,
            selectedStatus: _deviceStatusFilter,
            selectedLinkStatus:
                null, // Group devices don't have link status filter
          ),

          const SizedBox(height: AppSizes.spacing8),

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

    // Show loading state
    if (_isLoading && filteredDevices.isEmpty) {
      return AppLottieStateWidget.loading(
        title: 'Loading Devices',
        titleColor: AppColors.primary,
        messageColor: AppColors.secondary,
        message: 'Please wait while we fetch devices in this group...',
        lottieSize: 100,
      );
    }

    // Show no data state if no devices after loading
    if (!_isLoading && filteredDevices.isEmpty) {
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

    switch (_deviceViewMode) {
      case DeviceViewMode.table:
        return _buildDeviceTableView();
      case DeviceViewMode.kanban:
        return _buildDeviceKanbanView();
      case DeviceViewMode.map:
        return _buildDeviceMapView();
    }
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
          Expanded(
            child: DeviceKanbanView(
              devices: paginatedDevices,
              onDeviceSelected: _viewDevice,
              isLoading: false,
              enablePagination: false, // Use external pagination
              itemsPerPage: _deviceItemsPerPage,
            ),
          ),
          _buildDevicePagination(),
        ],
      ),
    );
  }

  Widget _buildDeviceMapView() {
    return Column(
      children: [
        // Map implementation toggle - UPDATED TO MATCH DEVICES SCREEN
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
          child: GroupDeviceMapView(
            deviceGroupId: widget.deviceGroup.id ?? 0,
            onDeviceSelected: _viewDevice,
            isLoading: _isLoading,
            groupName: widget.deviceGroup.name ?? 'Unknown Group',
            deviceService: _deviceService,
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

    return ResultsPagination(
      currentPage: _deviceCurrentPage,
      totalPages: totalPages,
      totalItems: filteredDevices.length,
      itemsPerPage: _deviceItemsPerPage,
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
      itemLabel: 'devices',
      showItemsPerPageSelector: true,
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

  void _onDeviceViewModeChanged(DeviceViewMode mode) {
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
          _loadData(); // Refresh the data after editing
        },
      ),
    );
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

        await _loadData();

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
    final sortedSchedules = filteredSchedules;

    if (sortedSchedules.isEmpty) {
      return const AppLottieStateWidget.noData(
        title: 'No Schedules Found',
        message: 'This device group has no scheduled tasks configured.',
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Schedules Header
          Row(
            children: [
              const Text(
                'Scheduled Tasks',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${sortedSchedules.length} schedule(s)',
                style: const TextStyle(
                  fontSize: AppSizes.fontSizeSmall,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing16),

          // Schedules Table - Use Flexible instead of Expanded
          Flexible(
            child: BluNestDataTable<Schedule>(
              columns: _buildScheduleTableColumns(),
              data: sortedSchedules,
              enableMultiSelect: false,
              selectedItems: const {},
              onSelectionChanged: (selectedItems) {},
              hiddenColumns: _hiddenScheduleColumns.toList(),
              onColumnVisibilityChanged: (hiddenColumns) {
                setState(() {
                  _hiddenScheduleColumns = hiddenColumns.toSet();
                });
              },
              sortBy: _scheduleSortBy,
              sortAscending: _scheduleSortAscending,
              onSort: (column, ascending) {
                setState(() {
                  _scheduleSortBy = column;
                  _scheduleSortAscending = ascending;
                });
              },
              isLoading: false,
            ),
          ),
        ],
      ),
    );
  }

  List<BluNestTableColumn<Schedule>> _buildScheduleTableColumns() {
    return [
      // Schedule Name
      BluNestTableColumn<Schedule>(
        key: 'name',
        title: 'Name',
        flex: 2,
        sortable: true,
        builder: (schedule) => Text(
          schedule.name ?? 'N/A',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      // Schedule Code
      BluNestTableColumn<Schedule>(
        key: 'code',
        title: 'Code',
        flex: 1,
        sortable: true,
        builder: (schedule) => Text(
          schedule.code ?? 'N/A',
          style: const TextStyle(
            fontFamily: 'monospace',
            color: AppColors.textPrimary,
          ),
        ),
      ),
      // Target Type
      BluNestTableColumn<Schedule>(
        key: 'targetType',
        title: 'Target Type',
        flex: 1,
        sortable: true,
        builder: (schedule) => StatusChip(
          text: schedule.targetType ?? 'Unknown',
          type: schedule.targetType == 'Group'
              ? StatusChipType.info
              : StatusChipType.warning,
        ),
      ),
      // Cron Expression
      BluNestTableColumn<Schedule>(
        key: 'cronExpression',
        title: 'Cron Expression',
        flex: 2,
        sortable: false,
        builder: (schedule) => Text(
          schedule.cronExpression ?? 'N/A',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: AppSizes.fontSizeSmall,
            color: AppColors.textSecondary,
          ),
        ),
      ),
      // Job Status
      BluNestTableColumn<Schedule>(
        key: 'jobStatus',
        title: 'Status',
        flex: 1,
        sortable: true,
        builder: (schedule) => StatusChip(
          text: schedule.jobStatus ?? 'Unknown',
          type: _getStatusChipType(schedule.jobStatus),
        ),
      ),
      // Next Billing Date
      BluNestTableColumn<Schedule>(
        key: 'nextBillingDate',
        title: 'Next Run',
        flex: 2,
        sortable: true,
        builder: (schedule) => Text(
          schedule.billingDevice?.nextBillingDate != null
              ? _formatDateTime(schedule.billingDevice!.nextBillingDate!)
              : 'N/A',
          style: const TextStyle(
            fontSize: AppSizes.fontSizeSmall,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      // Active Status
      BluNestTableColumn<Schedule>(
        key: 'active',
        title: 'Active',
        flex: 1,
        sortable: true,
        builder: (schedule) => StatusChip(
          text: schedule.active == true ? 'Active' : 'Inactive',
          type: schedule.active == true
              ? StatusChipType.success
              : StatusChipType.error,
        ),
      ),
    ];
  }

  StatusChipType _getStatusChipType(String? status) {
    switch (status?.toLowerCase()) {
      case 'running':
        return StatusChipType.success;
      case 'failed':
        return StatusChipType.error;
      case 'pending':
        return StatusChipType.warning;
      default:
        return StatusChipType.info;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showCreateDeviceDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateEditDeviceDialog(
        device: null,
        presetDeviceGroupId: widget.deviceGroup.id,
        onSaved: () {
          _loadData(); // Refresh the data after creating a device
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
}
