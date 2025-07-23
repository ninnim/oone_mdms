import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../core/models/device_group.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
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
import '../../widgets/common/app_input_field.dart';
import 'create_edit_device_group_dialog.dart';

enum DeviceGroupViewMode { table, kanban }

class DeviceGroupsScreen extends StatefulWidget {
  const DeviceGroupsScreen({super.key});

  @override
  State<DeviceGroupsScreen> createState() => _DeviceGroupsScreenState();
}

class _DeviceGroupsScreenState extends State<DeviceGroupsScreen> {
  late final DeviceGroupService _deviceGroupService;
  final TextEditingController _searchController = TextEditingController();

  // Data
  List<DeviceGroup> _deviceGroups = [];
  List<DeviceGroup> _filteredDeviceGroups = [];
  bool _isLoading = true;
  String? _errorMessage;

  // State
  DeviceGroupViewMode _currentViewMode = DeviceGroupViewMode.table;
  String _searchQuery = '';
  Set<DeviceGroup> _selectedDeviceGroups = {};

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
    _searchController.dispose();
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
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        offset: offset,
        limit: _itemsPerPage,
      );

      if (mounted) {
        if (response.success && response.data != null) {
          setState(() {
            _deviceGroups = response.data!;
            _filteredDeviceGroups = response.data!;
            _totalItems = response.paging?.total ?? response.data!.length;
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

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = _searchController.text;
        _currentPage = 1;
      });
      _loadDeviceGroups();
    });
  }

  void _toggleViewMode() {
    setState(() {
      _currentViewMode = _currentViewMode == DeviceGroupViewMode.table
          ? DeviceGroupViewMode.kanban
          : DeviceGroupViewMode.table;
    });
  }

  void _createDeviceGroup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CreateEditDeviceGroupDialog(
        onSaved: () {
          Navigator.of(context).pop();
          _loadDeviceGroups();
        },
        onCancel: () => Navigator.of(context).pop(),
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
          Navigator.of(context).pop();
          _loadDeviceGroups();
        },
        onCancel: () => Navigator.of(context).pop(),
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
      context: context,
      title: 'Delete Device Group',
      message: 'Are you sure you want to delete "${deviceGroup.name}"?',
      isDangerous: true,
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
            message: response.message,
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
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Search field
              Expanded(
                child: AppInputField(
                  controller: _searchController,
                  hintText: 'Search device groups...',
                  prefixIcon: const Icon(Icons.search),
                  onChanged: (value) => _onSearchChanged(),
                ),
              ),
              const SizedBox(width: AppSizes.spacing16),
              // View mode toggle
              AppButton(
                text: _currentViewMode == DeviceGroupViewMode.table
                    ? 'Kanban View'
                    : 'Table View',
                onPressed: _toggleViewMode,
                type: AppButtonType.secondary,
                size: AppButtonSize.medium,
                icon: Icon(
                  _currentViewMode == DeviceGroupViewMode.table
                      ? Icons.view_kanban
                      : Icons.table_chart,
                ),
              ),
              const SizedBox(width: AppSizes.spacing8),
              // Create button
              AppButton(
                text: 'Create Device Group',
                onPressed: _createDeviceGroup,
                type: AppButtonType.primary,
                size: AppButtonSize.medium,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
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
    );
  }

  List<BluNestTableColumn<DeviceGroup>> _buildTableColumns() {
    return [
      // Group Name
      BluNestTableColumn<DeviceGroup>(
        key: 'name',
        title: 'Group Name',
        flex: 2,
        sortable: true,
        builder: (group) => Text(
          group.name ?? 'Unnamed Group',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      // Description
      BluNestTableColumn<DeviceGroup>(
        key: 'description',
        title: 'Description',
        flex: 3,
        sortable: false,
        builder: (group) => Text(
          group.description?.isNotEmpty == true
              ? group.description!
              : 'No description',
          style: const TextStyle(color: AppColors.textSecondary),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      // Device Count
      BluNestTableColumn<DeviceGroup>(
        key: 'deviceCount',
        title: 'Device Count',
        flex: 1,
        sortable: true,
        builder: (group) => Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacing8,
            vertical: AppSizes.spacing4,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          ),
          child: Text(
            '${group.deviceCount ?? 0}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      // Status
      BluNestTableColumn<DeviceGroup>(
        key: 'status',
        title: 'Status',
        flex: 1,
        sortable: true,
        builder: (group) => StatusChip(
          text: group.active == true ? 'Active' : 'Inactive',
          type: group.active == true
              ? StatusChipType.success
              : StatusChipType.error,
        ),
      ),
      // Actions
      BluNestTableColumn<DeviceGroup>(
        key: 'actions',
        title: 'Actions',
        flex: 1,
        sortable: false,
        builder: (group) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility, size: 18),
              onPressed: () => _viewDeviceGroup(group),
              tooltip: 'View Details',
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: () => _editDeviceGroup(group),
              tooltip: 'Edit',
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete, size: 18),
              onPressed: () => _deleteDeviceGroup(group),
              tooltip: 'Delete',
            ),
          ],
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
            color: AppColors.shadow.withOpacity(0.1),
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
                  '${group.deviceCount ?? 0} devices',
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeSmall,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'view':
                      _viewDeviceGroup(group);
                      break;
                    case 'edit':
                      _editDeviceGroup(group);
                      break;
                    case 'delete':
                      _deleteDeviceGroup(group);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Text('View Details'),
                  ),
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
                child: const Icon(
                  Icons.more_vert,
                  color: AppColors.textSecondary,
                ),
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
