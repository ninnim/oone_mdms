import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mdms_clone/presentation/widgets/device_groups/device_group_filters_and_actions_v2.dart';
import 'dart:async';
import '../../../core/models/device_group.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/services/device_group_service.dart';
import '../../../core/services/service_locator.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/blunest_data_table.dart';
import '../../widgets/common/results_pagination.dart';
import '../../widgets/common/app_lottie_state_widget.dart';
import '../../widgets/common/status_chip.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/common/app_confirm_dialog.dart';
import '../../widgets/device_groups/device_group_summary_card.dart';
import 'create_edit_device_group_dialog.dart';
import 'device_group_manage_devices_dialog.dart';

class DeviceGroupsScreen extends StatefulWidget {
  const DeviceGroupsScreen({super.key});

  @override
  State<DeviceGroupsScreen> createState() => _DeviceGroupsScreenState();
}

class _DeviceGroupsScreenState extends State<DeviceGroupsScreen> {
  late final DeviceGroupService _deviceGroupService;

  // Data
  List<DeviceGroup> _deviceGroups = [];
  List<DeviceGroup> _filteredDeviceGroups = [];
  bool _isLoading = true;
  String? _errorMessage;

  // State
  DeviceGroupViewMode _currentViewMode = DeviceGroupViewMode.table;
  String _searchQuery = '';
  Set<DeviceGroup> _selectedDeviceGroups = {};

  // Sorting and column visibility
  String _sortBy = 'name';
  bool _sortAscending = true;
  List<String> _hiddenColumns = [];

  // Pagination
  int _currentPage = 1;
  int _itemsPerPage = 25;
  int _totalItems = 0;
  int _totalPages = 1;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _deviceGroupService = DeviceGroupService(ServiceLocator().apiService);
    _loadDeviceGroups();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDeviceGroups() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final offset = (_currentPage - 1) * _itemsPerPage;
      final search = _searchQuery.isEmpty
          ? ApiConstants.defaultSearch
          : '%$_searchQuery%';

      final response = await _deviceGroupService.getDeviceGroups(
        search: search,
        offset: offset,
        limit: _itemsPerPage,
      );

      if (mounted) {
        if (response.success && response.data != null) {
          setState(() {
            _deviceGroups = response.data!;
            _filteredDeviceGroups = _applyFilters(_deviceGroups);
            _sortDeviceGroups();
            _totalItems = response.paging?.item.total ?? _deviceGroups.length;
            _totalPages = (_totalItems / _itemsPerPage).ceil();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = response.message;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    // Cancel the previous timer
    _debounceTimer?.cancel();

    // Set a new timer to delay the search
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
        _currentPage = 1; // Reset to first page when searching
      });
      _loadDeviceGroups(); // Trigger API call
    });
  }

  List<DeviceGroup> _applyFilters(List<DeviceGroup> deviceGroups) {
    var filtered = deviceGroups;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((group) {
        return (group.name?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false) ||
            (group.description?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false);
      }).toList();
    }

    return filtered;
  }

  void _onViewModeChanged(DeviceGroupViewMode viewMode) {
    setState(() {
      _currentViewMode = viewMode;
    });
  }

  void _handleSort(String column, bool ascending) {
    setState(() {
      _sortBy = column;
      _sortAscending = ascending;
      _sortDeviceGroups();
    });
  }

  void _sortDeviceGroups() {
    if (_sortBy.isEmpty) return;

    _filteredDeviceGroups.sort((a, b) {
      dynamic aValue;
      dynamic bValue;

      switch (_sortBy) {
        case 'name':
          aValue = (a.name ?? '').toLowerCase();
          bValue = (b.name ?? '').toLowerCase();
          break;
        case 'description':
          aValue = (a.description ?? '').toLowerCase();
          bValue = (b.description ?? '').toLowerCase();
          break;
        case 'deviceCount':
          aValue = a.devices?.length ?? 0;
          bValue = b.devices?.length ?? 0;
          break;
        case 'active':
          aValue = a.active == true ? 1 : 0;
          bValue = b.active == true ? 1 : 0;
          break;
        default:
          return 0;
      }

      int comparison;
      if (aValue is int && bValue is int) {
        comparison = aValue.compareTo(bValue);
      } else {
        comparison = aValue.toString().compareTo(bValue.toString());
      }

      return _sortAscending ? comparison : -comparison;
    });
  }

  void _onStatusFilterChanged(String? status) {
    // TODO: Implement status filtering
    // This would filter device groups by status when we add status to the model
    setState(() {
      _currentPage = 1;
    });
    _loadDeviceGroups();
  }

  void _createDeviceGroup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CreateEditDeviceGroupDialog(
        onSaved: () {
          _loadDeviceGroups();
        },
      ),
    );
  }

  void _editDeviceGroup(DeviceGroup deviceGroup) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CreateEditDeviceGroupDialog(
        deviceGroup: deviceGroup,
        onSaved: () {
          _loadDeviceGroups();
        },
      ),
    );
  }

  void _viewDeviceGroup(DeviceGroup deviceGroup) {
    context.push(
      '/device-groups/details/${deviceGroup.id}',
      extra: deviceGroup,
    );
  }

  Future<void> _deleteDeviceGroup(DeviceGroup deviceGroup) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Delete Device Group',
      message:
          'Are you sure you want to delete "${deviceGroup.name}"? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      confirmType: AppButtonType.danger,
      icon: Icons.delete_outline,
    );

    if (confirmed == true) {
      try {
        final response = await _deviceGroupService.deleteDeviceGroup(
          deviceGroup.id!,
        );

        if (response.success) {
          AppToast.showSuccess(
            context,
            title: 'Device Group Deleted',
            message:
                'Device group "${deviceGroup.name}" has been successfully deleted.',
          );
          _loadDeviceGroups();
        } else {
          AppToast.showError(
            context,
            error: response.message ?? 'Failed to delete device group',
            title: 'Delete Failed',
            errorContext: 'device_group_delete',
          );
        }
      } catch (e) {
        AppToast.showError(
          context,
          error: 'Network error: Please check your connection',
          title: 'Connection Error',
          errorContext: 'device_group_delete_network',
        );
      }
    }
  }

  void _manageDevices(DeviceGroup deviceGroup) {
    // Import the dialog for managing devices
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeviceGroupManageDevicesDialog(
        deviceGroup: deviceGroup,
        onDevicesChanged: () {
          // Reload the device groups to reflect changes
          _loadDeviceGroups();
        },
      ),
    );
  }

  Future<List<DeviceGroup>> _fetchAllDeviceGroups() async {
    try {
      // Fetch all device groups without pagination
      final response = await _deviceGroupService.getDeviceGroups(
        search: _searchQuery.isEmpty
            ? ApiConstants.defaultSearch
            : '%$_searchQuery%',
        offset: 0,
        limit: 10000, // Large limit to get all items
      );

      if (response.success && response.data != null) {
        return response.data!;
      } else {
        throw Exception(
          response.message ?? 'Failed to fetch all device groups',
        );
      }
    } catch (e) {
      throw Exception('Error fetching all device groups: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing12),
            child: _buildHeader(),
          ),
          Expanded(child: _buildContent()),
          _buildPagination(), // Always show pagination for consistency
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        SizedBox(height: AppSizes.spacing12),
        DeviceGroupSummaryCard(deviceGroups: _filteredDeviceGroups),
        const SizedBox(height: AppSizes.spacing8),
        DeviceGroupFiltersAndActionsV2(
          onSearchChanged: _onSearchChanged,
          onStatusFilterChanged: _onStatusFilterChanged,
          onViewModeChanged: _onViewModeChanged,
          onAddDeviceGroup: _createDeviceGroup,
          onRefresh: _loadDeviceGroups,
          onExport: () {},
          onImport: () {},
          currentViewMode: _currentViewMode,
          selectedStatus: null, // We can add status filtering later
          // availableColumns: _availableColumns,
          // hiddenColumns: _hiddenColumns,
          // onColumnVisibilityChanged: (hiddenColumns) {
          //   setState(() {
          //     _hiddenColumns = hiddenColumns;
          //   });
          // },
        ),
      ],
    );
  }

  Widget _buildContent() {
    // Show full-screen loading only if no data exists yet
    if (_isLoading && _deviceGroups.isEmpty) {
      return const Center(
        child: AppLottieStateWidget.loading(
          title: 'Loading Device Groups',
          lottieSize: 80,
          message: 'Please wait while we fetch your device groups.',
        ),
      );
    }

    if (_errorMessage != null) {
      return AppLottieStateWidget.error(
        title: 'Error Loading Device Groups',
        message: _errorMessage!,
        buttonText: 'Try Again',
        onButtonPressed: _loadDeviceGroups,
      );
    }

    if (_filteredDeviceGroups.isEmpty && !_isLoading) {
      return AppLottieStateWidget.noData(
        title: _searchQuery.isNotEmpty
            ? 'No Results Found'
            : 'No Device Groups',
        message: _searchQuery.isNotEmpty
            ? 'No device groups match your search criteria.'
            : 'Start by creating your first device group.',
        buttonText: 'Create Device Group',
        onButtonPressed: _createDeviceGroup,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
      child: _buildViewContent(),
    );
  }

  Widget _buildViewContent() {
    switch (_currentViewMode) {
      case DeviceGroupViewMode.table:
        return _buildTableView();
      case DeviceGroupViewMode.kanban:
        return _buildKanbanView();
    }
  }

  Widget _buildTableView() {
    return BluNestDataTable<DeviceGroup>(
      columns: _buildTableColumns(),
      data: _filteredDeviceGroups,
      onRowTap: _viewDeviceGroup,
      enableMultiSelect: true,
      selectedItems: _selectedDeviceGroups,
      onSelectionChanged: (selectedItems) {
        setState(() {
          _selectedDeviceGroups = selectedItems;
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
      totalItemsCount: _totalItems,
      onSelectAllItems: _fetchAllDeviceGroups,
    );
  }

  List<BluNestTableColumn<DeviceGroup>> _buildTableColumns() {
    return [
      // No. (Row Number)
      BluNestTableColumn<DeviceGroup>(
        key: 'no',
        title: 'No.',
        flex: 1,
        sortable: false,
        builder: (group) {
          final index = _filteredDeviceGroups.indexOf(group);
          final rowNumber = ((_currentPage - 1) * _itemsPerPage) + index + 1;
          return Container(
            alignment: Alignment.centerLeft,
            child: Text(
              '$rowNumber',
              style: const TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          );
        },
      ),

      // Group Name
      BluNestTableColumn<DeviceGroup>(
        key: 'name',
        title: 'Group Name',
        flex: 2,
        sortable: true,
        builder: (group) => Container(
          alignment: Alignment.centerLeft,
          child: Text(
            group.name ?? 'None',
            style: const TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
      // Description
      BluNestTableColumn<DeviceGroup>(
        key: 'description',
        title: 'Description',
        flex: 3,
        sortable: false,
        builder: (group) => Container(
          alignment: Alignment.centerLeft,
          child: Text(
            group.description?.isNotEmpty == true
                ? group.description!
                : 'No description',
            style: const TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      // Device Count
      BluNestTableColumn<DeviceGroup>(
        key: 'deviceCount',
        title: 'Device Count',
        flex: 1,
        sortable: true,
        builder: (group) => Container(
          alignment: Alignment.centerLeft,
          child: StatusChip(
            text: '${group.devices?.length ?? 0}',
            type: StatusChipType.info,
            compact: true,
          ),
        ),
      ),
      // Status
      BluNestTableColumn<DeviceGroup>(
        key: 'status',
        title: 'Status',
        flex: 1,
        sortable: true,
        builder: (group) => Container(
          alignment: Alignment.centerLeft,
          child: StatusChip(
            text: group.active == true ? 'Active' : 'Inactive',
            type: group.active == true
                ? StatusChipType.success
                : StatusChipType.error,
            compact: true,
          ),
        ),
      ),
      // Actions
      BluNestTableColumn<DeviceGroup>(
        key: 'actions',
        title: 'Actions',
        flex: 1,
        sortable: false,
        builder: (group) => Container(
          alignment: Alignment.center,
          height: AppSizes.spacing40,
          child: PopupMenuButton<String>(
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
                value: 'manage_devices',
                child: Row(
                  children: [
                    Icon(Icons.device_hub, size: 16, color: AppColors.info),
                    SizedBox(width: AppSizes.spacing8),
                    Text('Manage Devices'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 16, color: AppColors.error),
                    SizedBox(width: AppSizes.spacing8),
                    Text('Delete', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'view':
                  _viewDeviceGroup(group);
                  break;
                case 'edit':
                  _editDeviceGroup(group);
                  break;
                case 'manage_devices':
                  _manageDevices(group);
                  break;
                case 'delete':
                  _deleteDeviceGroup(group);
                  break;
              }
            },
          ),
        ),
      ),
    ];
  }

  Widget _buildKanbanView() {
    if (_isLoading && _deviceGroups.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final groupedDeviceGroups = _groupDeviceGroupsByStatus();

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: groupedDeviceGroups.entries.map((entry) {
            return _buildDeviceGroupStatusColumn(entry.key, entry.value);
          }).toList(),
        ),
      ),
    );
  }

  Map<String, List<DeviceGroup>> _groupDeviceGroupsByStatus() {
    final Map<String, List<DeviceGroup>> grouped = {
      'Active': [],
      'Inactive': [],
    };

    for (final deviceGroup in _filteredDeviceGroups) {
      if (deviceGroup.active == true) {
        grouped['Active']!.add(deviceGroup);
      } else {
        grouped['Inactive']!.add(deviceGroup);
      }
    }

    return grouped;
  }

  Widget _buildDeviceGroupStatusColumn(
    String status,
    List<DeviceGroup> deviceGroups,
  ) {
    Color statusColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'active':
        statusColor = AppColors.success;
        statusIcon = Icons.group_outlined;
        break;
      case 'inactive':
        statusColor = AppColors.textSecondary;
        statusIcon = Icons.group_off_outlined;
        break;
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
                    '${deviceGroups.length}',
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

          // Device Group cards
          Expanded(
            child: deviceGroups.isEmpty
                ? _buildDeviceGroupEmptyState(status)
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSizes.spacing8),
                    itemCount: deviceGroups.length,
                    itemBuilder: (context, index) {
                      return _buildDeviceGroupKanbanCard(deviceGroups[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceGroupEmptyState(String status) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_outlined,
            size: 48,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: AppSizes.spacing12),
          Text(
            'No ${status.toLowerCase()} device groups',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppSizes.fontSizeSmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceGroupKanbanCard(DeviceGroup deviceGroup) {
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
        onTap: () => _viewDeviceGroup(deviceGroup),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name, status, and actions
            Row(
              children: [
                Expanded(
                  child: Text(
                    deviceGroup.name ?? 'Unnamed Group',
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
                _buildDeviceGroupStatusChip(deviceGroup.active ?? false),
                const SizedBox(width: AppSizes.spacing4),
                _buildDeviceGroupActionsDropdown(deviceGroup),
              ],
            ),
            const SizedBox(height: AppSizes.spacing12),

            // Device Group details
            _buildDetailRow(
              Icons.numbers,
              'ID',
              deviceGroup.id?.toString() ?? 'N/A',
            ),
            const SizedBox(height: AppSizes.spacing8),
            if (deviceGroup.description?.isNotEmpty == true) ...[
              _buildDetailRow(
                Icons.description,
                'Description',
                deviceGroup.description!,
              ),
              const SizedBox(height: AppSizes.spacing8),
            ],
            _buildDetailRow(
              Icons.devices,
              'Device Count',
              '${deviceGroup.devices?.length ?? 0} devices',
            ),

            // Active indicator footer
            if (deviceGroup.active == true) ...[
              const SizedBox(height: AppSizes.spacing12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacing8,
                  vertical: AppSizes.spacing4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  border: Border.all(
                    color: const Color(0xFF059669).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 14,
                      color: const Color(0xFF059669),
                    ),
                    const SizedBox(width: AppSizes.spacing4),
                    Text(
                      'Active Group',
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeExtraSmall,
                        color: const Color(0xFF059669),
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

  Widget _buildDeviceGroupStatusChip(bool isActive) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;

    if (isActive) {
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
            value,
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

  Widget _buildDeviceGroupActionsDropdown(DeviceGroup deviceGroup) {
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
          value: 'manage_devices',
          child: Row(
            children: [
              Icon(Icons.device_hub, size: 16, color: AppColors.info),
              SizedBox(width: AppSizes.spacing8),
              Text('Manage Devices'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 16, color: AppColors.error),
              SizedBox(width: AppSizes.spacing8),
              Text('Delete', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'view':
            _viewDeviceGroup(deviceGroup);
            break;
          case 'edit':
            _editDeviceGroup(deviceGroup);
            break;
          case 'manage_devices':
            _manageDevices(deviceGroup);
            break;
          case 'delete':
            _deleteDeviceGroup(deviceGroup);
            break;
        }
      },
    );
  }

  Widget _buildPagination() {
    return ResultsPagination(
      currentPage: _currentPage,
      totalPages: _totalPages,
      totalItems: _totalItems,
      itemsPerPage: _itemsPerPage,
      itemsPerPageOptions: const [5, 10, 20, 25, 50],
      startItem: (_currentPage - 1) * _itemsPerPage + 1,
      endItem: (_currentPage * _itemsPerPage > _totalItems)
          ? _totalItems
          : _currentPage * _itemsPerPage,
      onPageChanged: (page) {
        setState(() {
          _currentPage = page;
        });
        _loadDeviceGroups();
      },
      onItemsPerPageChanged: (itemsPerPage) {
        setState(() {
          _itemsPerPage = itemsPerPage;
          _currentPage = 1;
        });
        _loadDeviceGroups();
      },
      showItemsPerPageSelector: true,
    );
  }
}
