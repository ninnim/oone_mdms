import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../core/models/device_group.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/device_group_service.dart';
import '../../../core/services/service_locator.dart';
import '../../widgets/common/app_card.dart';
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
  final TextEditingController _searchController = TextEditingController();
  late final DeviceGroupService _deviceGroupService;
  bool _isLoading = false;
  List<DeviceGroup> _deviceGroups = [];
  List<DeviceGroup> _filteredDeviceGroups = [];
  Set<DeviceGroup> _selectedDeviceGroups = {};
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  int _itemsPerPage = 25;
  String _errorMessage = '';
  Timer? _debounceTimer;

  // View mode
  DeviceGroupViewMode _currentViewMode = DeviceGroupViewMode.table;

  // Filters
  String? _selectedStatus;

  // Sorting
  String? _sortBy;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    
    // Initialize services using ServiceLocator
    final serviceLocator = ServiceLocator();
    final apiService = serviceLocator.apiService;
    _deviceGroupService = DeviceGroupService(apiService);

    _loadDeviceGroups();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDeviceGroups() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final searchQuery = _searchController.text.trim();
      final response = await _deviceGroupService.getDeviceGroups(
        search: searchQuery.isNotEmpty ? searchQuery : '%%',
        limit: _itemsPerPage,
        offset: (_currentPage - 1) * _itemsPerPage,
        includeDevices: true,
      );

      if (response.success && response.data != null) {
        setState(() {
          _deviceGroups = response.data!;
          _totalItems = response.paging?.item.total ?? _deviceGroups.length;
          _totalPages = (_totalItems / _itemsPerPage).ceil().clamp(1, double.infinity).toInt();
          _applyFilters();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Failed to load device groups';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading device groups: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    _filteredDeviceGroups = _deviceGroups.where((group) {
      // Status filter
      if (_selectedStatus != null) {
        final isActive = group.active == true;
        if (_selectedStatus == 'active' && !isActive) return false;
        if (_selectedStatus == 'inactive' && isActive) return false;
      }
      return true;
    }).toList();

    // Apply sorting
    if (_sortBy != null) {
      _filteredDeviceGroups.sort((a, b) {
        int comparison = 0;
        switch (_sortBy) {
          case 'name':
            comparison = (a.name ?? '').compareTo(b.name ?? '');
            break;
          case 'description':
            comparison = (a.description ?? '').compareTo(b.description ?? '');
            break;
          case 'deviceCount':
            comparison = (a.devices?.length ?? 0).compareTo(b.devices?.length ?? 0);
            break;
          case 'status':
            comparison = (a.active == true ? 'Active' : 'Inactive')
                .compareTo(b.active == true ? 'Active' : 'Inactive');
            break;
        }
        return _sortAscending ? comparison : -comparison;
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _currentPage = 1;
        _loadDeviceGroups();
      }
    });
  }

  void _onSortChanged(String column, bool ascending) {
    setState(() {
      _sortBy = column;
      _sortAscending = ascending;
      _applyFilters();
    });
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _loadDeviceGroups();
  }

  void _onItemsPerPageChanged(int itemsPerPage) {
    setState(() {
      _itemsPerPage = itemsPerPage;
      _currentPage = 1;
    });
    _loadDeviceGroups();
  }

  List<DeviceGroup> get _paginatedDeviceGroups {
    if (_currentViewMode == DeviceGroupViewMode.kanban) {
      return _filteredDeviceGroups;
    }
    return _filteredDeviceGroups;
  }

  void _viewDeviceGroup(DeviceGroup deviceGroup) {
    context.go('/device-groups/details/${deviceGroup.id}', extra: deviceGroup);
  }

  void _createDeviceGroup() {
    showDialog(
      context: context,
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
      builder: (context) => CreateEditDeviceGroupDialog(
        deviceGroup: deviceGroup,
        onSaved: () {
          _loadDeviceGroups();
        },
      ),
    );
  }

  Future<void> _deleteDeviceGroup(DeviceGroup deviceGroup) async {
    final confirmed = await _showDeleteConfirmation(deviceGroup);
    if (!confirmed) return;

    try {
      final response = await _deviceGroupService.deleteDeviceGroup(deviceGroup.id!);
      
      if (response.success) {
        if (mounted) {
          AppToast.showSuccess(
            context,
            title: 'Success',
            message: 'Device group deleted successfully',
          );
          _loadDeviceGroups(); 
        }
      } else {
        if (mounted) {
          AppToast.showError(
            context,
            error: response.message ?? 'Failed to delete device group',
            title: 'Error',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(
          context,
          error: 'Error deleting device group: $e',
          title: 'Error',
        );
      }
    }
  }

  Future<bool> _showDeleteConfirmation(DeviceGroup deviceGroup) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AppConfirmDialog(
        title: 'Delete Device Group',
        message: 'Are you sure you want to delete "${deviceGroup.name}"?\n\nThis action cannot be undone.',
        confirmText: 'Delete',
        cancelText: 'Cancel',
        isDestructive: true,
      ),
    ) ?? false;
  }

  Future<void> _deleteSelectedDeviceGroups() async {
    if (_selectedDeviceGroups.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AppConfirmDialog(
        title: 'Delete Device Groups',
        message: 'Are you sure you want to delete ${_selectedDeviceGroups.length} device group(s)?\n\nThis action cannot be undone.',
        confirmText: 'Delete All',
        cancelText: 'Cancel',
        isDestructive: true,
      ),
    ) ?? false;

    if (!confirmed) return;

    try {
      for (final deviceGroup in _selectedDeviceGroups) {
        await _deviceGroupService.deleteDeviceGroup(deviceGroup.id!);
      }
      
      if (mounted) {
        AppToast.showSuccess(
          context,
          title: 'Success',
          message: '${_selectedDeviceGroups.length} device group(s) deleted successfully',
        );
        setState(() => _selectedDeviceGroups.clear());
        _loadDeviceGroups();
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(
          context,
          error: 'Error deleting device groups: $e',
          title: 'Error',
        );
      }
    }
  }

  Widget _buildErrorMessage() {
    if (_errorMessage.isEmpty) return const SizedBox.shrink();

    // Show full-screen error state if no device groups and there's an error
    if (_deviceGroups.isEmpty) {
      return AppLottieStateWidget.error(
        title: 'Failed to Load Device Groups',
        message: _errorMessage,
        buttonText: 'Try Again',
        onButtonPressed: _loadDeviceGroups,
      );
    }

    // Show compact error banner if device groups exist but there was an error
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSizes.spacing16),
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppColors.error,
            size: AppSizes.iconMedium,
          ),
          const SizedBox(width: AppSizes.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Error Loading Device Groups',
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeMedium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _errorMessage,
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeSmall,
                    color: AppColors.error.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _loadDeviceGroups,
            child: const Text(
              'Retry',
              style: TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                fontWeight: FontWeight.w500,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header and Actions
          _buildHeader(),
          
          // Error message (if any)
          _buildErrorMessage(),

          // Content
          Expanded(
            child: _isLoading && _deviceGroups.isEmpty
                ? const AppLottieStateWidget.loading(message: 'Loading device groups...')
                : _deviceGroups.isEmpty && !_isLoading
                    ? AppLottieStateWidget.empty(
                        title: 'No Device Groups',
                        message: 'Create your first device group to get started.',
                        buttonText: 'Create Device Group',
                        onButtonPressed: _createDeviceGroup,
                      )
                    : Column(
                        children: [
                          // Filters and Search
                          _buildFiltersAndSearch(),

                          // Selected items toolbar (if any)
                          if (_selectedDeviceGroups.isNotEmpty) _buildSelectedItemsToolbar(),

                          // Content based on view mode
                          Expanded(
                            child: _currentViewMode == DeviceGroupViewMode.table
                                ? _buildDeviceGroupTable()
                                : _buildKanbanView(),
                          ),

                          // Pagination
                          if (_totalPages > 1) _buildPagination(),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          // Title
          Text(
            'Device Groups',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          
          // View mode toggle
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildViewModeButton(
                  icon: Icons.table_rows,
                  mode: DeviceGroupViewMode.table,
                  tooltip: 'Table View',
                ),
                _buildViewModeButton(
                  icon: Icons.view_kanban,
                  mode: DeviceGroupViewMode.kanban,
                  tooltip: 'Kanban View',
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.spacing16),
          
          // Create button
          AppButton(
            text: 'Create Device Group',
            type: AppButtonType.primary,
            onPressed: _createDeviceGroup,
            prefixIcon: Icons.add,
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeButton({
    required IconData icon,
    required DeviceGroupViewMode mode,
    required String tooltip,
  }) {
    final isSelected = _currentViewMode == mode;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => setState(() => _currentViewMode = mode),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.spacing8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          ),
          child: Icon(
            icon,
            size: AppSizes.iconSmall,
            color: isSelected ? AppColors.surface : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersAndSearch() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          // Search
          Expanded(
            flex: 2,
            child: AppInputField(
              controller: _searchController,
              hintText: 'Search device groups...',
              prefixIcon: Icons.search,
              onChanged: _onSearchChanged,
            ),
          ),
          const SizedBox(width: AppSizes.spacing16),

          // Status filter
          Expanded(
            child: DropdownButtonFormField<String?>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSizes.spacing12,
                  vertical: AppSizes.spacing8,
                ),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('All Statuses')),
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                  _currentPage = 1;
                });
                _loadDeviceGroups();
              },
            ),
          ),
          const SizedBox(width: AppSizes.spacing16),

          // Clear filters button
          AppButton(
            text: 'Clear',
            type: AppButtonType.secondary,
            onPressed: () {
              setState(() {
                _searchController.clear();
                _selectedStatus = null;
                _currentPage = 1;
              });
              _loadDeviceGroups();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedItemsToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacing16,
        vertical: AppSizes.spacing12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primaryLight,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: AppColors.primary,
            size: AppSizes.iconMedium,
          ),
          const SizedBox(width: AppSizes.spacing8),
          Text(
            '${_selectedDeviceGroups.length} device group(s) selected',
            style: const TextStyle(
              fontSize: AppSizes.fontSizeMedium,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 16),
          TextButton.icon(
            onPressed: () => setState(() => _selectedDeviceGroups.clear()),
            icon: const Icon(Icons.clear, size: AppSizes.iconMedium),
            label: const Text('Clear'),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _deleteSelectedDeviceGroups,
            icon: const Icon(Icons.delete, size: AppSizes.iconMedium),
            label: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceGroupTable() {
    return BluNestDataTable<DeviceGroup>(
      columns: _buildTableColumns(),
      data: _paginatedDeviceGroups,
      onRowTap: _viewDeviceGroup,
      enableMultiSelect: true,
      selectedItems: _selectedDeviceGroups,
      onSelectionChanged: (selectedItems) {
        setState(() => _selectedDeviceGroups = selectedItems);
      },
      sortBy: _sortBy,
      sortAscending: _sortAscending,
      onSort: _onSortChanged,
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
          final index = _paginatedDeviceGroups.indexOf(group);
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
      BluNestTableColumn<DeviceGroup>(
        key: 'name',
        title: 'Name',
        sortable: true,
        flex: 2,
        builder: (group) => Text(
          group.name ?? 'Unnamed Group',
          style: const TextStyle(
            fontSize: AppSizes.fontSizeMedium,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      BluNestTableColumn<DeviceGroup>(
        key: 'description',
        title: 'Description',
        sortable: true,
        flex: 3,
        builder: (group) => Text(
          group.description ?? 'No description',
          style: const TextStyle(
            fontSize: AppSizes.fontSizeSmall,
            color: AppColors.textSecondary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      BluNestTableColumn<DeviceGroup>(
        key: 'deviceCount',
        title: 'Devices',
        sortable: true,
        flex: 1,
        builder: (group) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${group.devices?.length ?? 0}',
            style: const TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
      BluNestTableColumn<DeviceGroup>(
        key: 'status',
        title: 'Status',
        sortable: true,
        flex: 1,
        builder: (group) => StatusChip(
          text: group.active == true ? 'Active' : 'Inactive',
          type: group.active == true ? StatusChipType.success : StatusChipType.error,
        ),
      ),
      BluNestTableColumn<DeviceGroup>(
        key: 'actions',
        title: 'Actions',
        flex: 2,
        builder: (group) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _viewDeviceGroup(group),
              icon: const Icon(Icons.visibility, size: AppSizes.iconSmall),
              tooltip: 'View Details',
            ),
            IconButton(
              onPressed: () => _editDeviceGroup(group),
              icon: const Icon(Icons.edit, size: AppSizes.iconSmall),
              tooltip: 'Edit',
            ),
            IconButton(
              onPressed: () => _deleteDeviceGroup(group),
              icon: const Icon(
                Icons.delete,
                size: AppSizes.iconSmall,
                color: AppColors.error,
              ),
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildKanbanView() {
    final columns = [
      KanbanColumn<DeviceGroup>(
        id: 'active',
        title: 'Active Groups',
        color: AppColors.success,
        icon: Icons.check_circle,
      ),
      KanbanColumn<DeviceGroup>(
        id: 'inactive',
        title: 'Inactive Groups',
        color: AppColors.error,
        icon: Icons.cancel,
      ),
    ];

    return KanbanView<DeviceGroup>(
      columns: columns,
      items: _filteredDeviceGroups,
      cardBuilder: _buildDeviceGroupCard,
      getItemColumn: (group) => group.active == true ? 'active' : 'inactive',
      onItemTapped: _viewDeviceGroup,
    );
  }

  Widget _buildDeviceGroupCard(DeviceGroup group) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  group.name ?? 'Unnamed Group',
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeMedium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              StatusChip(
                text: group.active == true ? 'Active' : 'Inactive',
                type: group.active == true ? StatusChipType.success : StatusChipType.error,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing8),

          // Description
          if (group.description?.isNotEmpty == true) ...[
            Text(
              group.description!,
              style: const TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSizes.spacing12),
          ],

          // Device count
          Row(
            children: [
              Icon(
                Icons.devices,
                size: AppSizes.iconSmall,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSizes.spacing4),
              Text(
                '${group.devices?.length ?? 0} device${(group.devices?.length ?? 0) != 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: AppSizes.fontSizeSmall,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing12),

          // Actions
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _viewDeviceGroup(group),
                  icon: const Icon(Icons.visibility, size: AppSizes.iconSmall),
                  label: const Text('View'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing8),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.spacing8),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _editDeviceGroup(group),
                  icon: const Icon(Icons.edit, size: AppSizes.iconSmall),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing8),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.spacing8),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _deleteDeviceGroup(group),
                  icon: const Icon(Icons.delete, size: AppSizes.iconSmall, color: AppColors.error),
                  label: const Text('Delete', style: TextStyle(color: AppColors.error)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing8),
                  ),
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
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: ResultsPagination(
        currentPage: _currentPage,
        totalPages: _totalPages,
        totalItems: _totalItems,
        itemsPerPage: _itemsPerPage,
        onPageChanged: _onPageChanged,
        onItemsPerPageChanged: _onItemsPerPageChanged,
      ),
    );
  }
}
