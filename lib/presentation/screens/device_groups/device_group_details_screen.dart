import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
import '../../widgets/common/breadcrumb_navigation.dart';
import '../../widgets/common/blunest_data_table.dart';
import '../../widgets/common/status_chip.dart';
import '../../widgets/common/app_lottie_state_widget.dart';
import '../../widgets/common/results_pagination.dart';
import '../../widgets/common/app_input_field.dart';
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

  // Schedule tab sorting and columns
  String _scheduleSortBy = 'name';
  bool _scheduleSortAscending = true;
  Set<String> _hiddenScheduleColumns = {};

  final TextEditingController _deviceSearchController = TextEditingController();

  @override
  void dispose() {
    _deviceSearchController.dispose();
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
              const BreadcrumbNavigation(),
              const SizedBox(height: AppSizes.spacing16),
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
                          widget.deviceGroup.name ?? 'Device Group',
                          style: const TextStyle(
                            fontSize: AppSizes.fontSizeHeading,
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
                    text: 'Save Changes',
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
                _buildInfoRow('Name', widget.deviceGroup.name ?? 'Unknown'),
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
    final paginatedDevices = paginatedGroupDevices;

    // Get unique values for filters
    final allGroupDevices = _allDevices
        .where((device) => device.deviceGroupId == widget.deviceGroup.id)
        .toList();
    final uniqueStatuses = allGroupDevices
        .map((d) => d.status)
        .toSet()
        .toList();
    final uniqueTypes = allGroupDevices
        .map((d) => d.deviceType)
        .toSet()
        .toList();
    final uniqueManufacturers = allGroupDevices
        .map((d) => d.manufacturer)
        .toSet()
        .toList();

    return Padding(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Create Device button
          Row(
            children: [
              Text(
                'Devices in Group (${filteredDevices.length})',
                style: const TextStyle(
                  fontSize: AppSizes.fontSizeLarge,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              AppButton(
                text: 'Add Device',
                onPressed: () => _showCreateDeviceDialog(),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing16),

          // Filters Row
          Row(
            children: [
              // Search Field
              Expanded(
                flex: 2,
                child: AppInputField(
                  controller: _deviceSearchController,
                  hintText: 'Search devices...',
                  prefixIcon: const Icon(Icons.search),
                  onChanged: (value) {
                    setState(() {
                      _deviceSearchQuery = value;
                      _deviceCurrentPage = 1; // Reset to first page
                    });
                  },
                ),
              ),
              const SizedBox(width: AppSizes.spacing8),

              // Status Filter
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _deviceStatusFilter,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Status'),
                    ),
                    ...uniqueStatuses.map(
                      (status) =>
                          DropdownMenuItem(value: status, child: Text(status)),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _deviceStatusFilter = value;
                      _deviceCurrentPage = 1;
                    });
                  },
                ),
              ),
              const SizedBox(width: AppSizes.spacing8),

              // Type Filter
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _deviceTypeFilter,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Types'),
                    ),
                    ...uniqueTypes.map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _deviceTypeFilter = value;
                      _deviceCurrentPage = 1;
                    });
                  },
                ),
              ),
              const SizedBox(width: AppSizes.spacing8),

              // Manufacturer Filter
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _deviceManufacturerFilter,
                  decoration: const InputDecoration(
                    labelText: 'Manufacturer',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Manufacturers'),
                    ),
                    ...uniqueManufacturers.map(
                      (manufacturer) => DropdownMenuItem(
                        value: manufacturer,
                        child: Text(manufacturer),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _deviceManufacturerFilter = value;
                      _deviceCurrentPage = 1;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing16),

          // Devices list
          if (filteredDevices.isEmpty)
            const Expanded(
              child: AppLottieStateWidget.noData(
                title: 'No Devices Found',
                message: 'No devices match the current filters.',
              ),
            )
          else
            Flexible(
              child: Column(
                children: [
                  Expanded(
                    child: BluNestDataTable<Device>(
                      columns: _buildDeviceTableColumns(),
                      data: paginatedDevices,
                      enableMultiSelect: false,
                      selectedItems: const {},
                      onSelectionChanged: (selectedItems) {},
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

                  // Pagination
                  if (totalDevicePages > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSizes.spacing16),
                      child: ResultsPagination(
                        currentPage: _deviceCurrentPage,
                        totalPages: totalDevicePages,
                        totalItems: filteredDevices.length,
                        itemsPerPage: _deviceItemsPerPage,
                        startItem:
                            (_deviceCurrentPage - 1) * _deviceItemsPerPage + 1,
                        endItem: (_deviceCurrentPage * _deviceItemsPerPage)
                            .clamp(1, filteredDevices.length),
                        onPageChanged: (page) {
                          setState(() {
                            _deviceCurrentPage = page;
                          });
                        },
                        onItemsPerPageChanged: (itemsPerPage) {
                          setState(() {
                            _deviceItemsPerPage = itemsPerPage;
                            _deviceCurrentPage = 1; // Reset to first page
                          });
                        },
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<BluNestTableColumn<Device>> _buildDeviceTableColumns() {
    return [
      BluNestTableColumn<Device>(
        key: 'serialNumber',
        title: 'Serial Number',
        flex: 2,
        sortable: true,
        builder: (device) => Text(
          device.serialNumber,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      BluNestTableColumn<Device>(
        key: 'name',
        title: 'Name',
        flex: 2,
        sortable: true,
        builder: (device) => Text(
          device.name.isNotEmpty ? device.name : '-',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      ),
      BluNestTableColumn<Device>(
        key: 'deviceType',
        title: 'Type',
        flex: 1,
        sortable: true,
        builder: (device) => Text(
          device.deviceType,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      ),
      BluNestTableColumn<Device>(
        key: 'status',
        title: 'Status',
        flex: 1,
        sortable: true,
        builder: (device) =>
            StatusChip(text: device.status, type: StatusChipType.success),
      ),
      BluNestTableColumn<Device>(
        key: 'actions',
        title: 'Actions',
        flex: 1,
        sortable: false,
        builder: (device) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility, size: AppSizes.iconSmall),
              onPressed: () => _viewDevice(device),
              tooltip: 'View Device',
            ),
            IconButton(
              icon: const Icon(
                Icons.remove_circle_outline,
                size: AppSizes.iconSmall,
                color: AppColors.error,
              ),
              onPressed: () => _removeDeviceFromGroup(device),
              tooltip: 'Remove from Group',
            ),
          ],
        ),
      ),
    ];
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
