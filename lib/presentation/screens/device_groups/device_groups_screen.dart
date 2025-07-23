import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
import '../../widgets/common/kanban_view.dart';
import '../../widgets/common/status_chip.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/common/app_confirm_dialog.dart';
import '../../widgets/device_groups/device_group_filters_and_actions.dart';
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

  // Available columns for table view
  final List<String> _availableColumns = [
    'Group Name',
    'Description',
    'Device Count',
    'Status',
    'Actions',
  ];

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
      final response = await _deviceGroupService.getDeviceGroups(
        search: ApiConstants
            .defaultSearch, // Always use default search, filter locally
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
    setState(() {
      _searchQuery = query;
      _filteredDeviceGroups = _applyFilters(_deviceGroups);
      _sortDeviceGroups();
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
      message: 'Are you sure you want to delete "${deviceGroup.name}"?',
      confirmType: AppButtonType.danger,
    );

    if (confirmed == true) {
      try {
        final response = await _deviceGroupService.deleteDeviceGroup(
          deviceGroup.id!,
        );

        if (response.success) {
          AppToast.show(
            context,
            title: 'Success',
            message: 'Device group deleted successfully',
            type: ToastType.success,
          );
          _loadDeviceGroups();
        } else {
          AppToast.show(
            context,
            title: 'Error',
            message: response.message ?? 'Unknown error occurred',
            type: ToastType.error,
          );
        }
      } catch (e) {
        AppToast.show(
          context,
          title: 'Error',
          message: 'Failed to delete device group',
          type: ToastType.error,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildContent()),
          if (_filteredDeviceGroups.isNotEmpty) _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return DeviceGroupFiltersAndActions(
      onSearchChanged: _onSearchChanged,
      onStatusFilterChanged: _onStatusFilterChanged,
      onViewModeChanged: _onViewModeChanged,
      onAddDeviceGroup: _createDeviceGroup,
      onRefresh: _loadDeviceGroups,
      currentViewMode: _currentViewMode,
      selectedStatus: null, // We can add status filtering later
      availableColumns: _availableColumns,
      hiddenColumns: _hiddenColumns,
      onColumnVisibilityChanged: (hiddenColumns) {
        setState(() {
          _hiddenColumns = hiddenColumns;
        });
      },
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: AppLottieStateWidget.loading(
          title: 'Loading Device Groups...',
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

    if (_filteredDeviceGroups.isEmpty) {
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

    return Column(
      children: [
        // Summary card
        Padding(
          padding: const EdgeInsets.all(AppSizes.spacing16),
          child: DeviceGroupSummaryCard(deviceGroups: _filteredDeviceGroups),
        ),

        // Main content based on view mode
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.spacing16),
            child: _buildViewContent(),
          ),
        ),
      ],
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
    return KanbanView<DeviceGroup>(
      columns: [
        KanbanColumn(id: 'Active', title: 'Active', color: AppColors.success),
        KanbanColumn(id: 'Inactive', title: 'Inactive', color: AppColors.error),
      ],
      items: _filteredDeviceGroups,
      onItemTapped: _viewDeviceGroup,
      cardBuilder: (group) => _buildKanbanCard(group),
      getItemColumn: (group) => group.active == true ? 'Active' : 'Inactive',
    );
  }

  Widget _buildKanbanCard(DeviceGroup group) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spacing8),
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(color: AppColors.border.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.name ?? 'Unnamed Group',
            style: const TextStyle(
              fontSize: AppSizes.fontSizeMedium,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (group.description?.isNotEmpty == true) ...[
            const SizedBox(height: AppSizes.spacing8),
            Text(
              group.description!,
              style: const TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppSizes.spacing12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacing8,
                  vertical: AppSizes.spacing4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
                child: Text(
                  '${group.devices?.length ?? 0} devices',
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeSmall,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                ),
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
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(
                          Icons.visibility,
                          size: 16,
                          color: AppColors.primary,
                        ),
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
                        Text(
                          'Delete',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border.withOpacity(0.1), width: 1),
        ),
      ),
      child: ResultsPagination(
        currentPage: _currentPage,
        totalPages: _totalPages,
        totalItems: _totalItems,
        itemsPerPage: _itemsPerPage,
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
        itemLabel: 'device groups',
      ),
    );
  }
}
