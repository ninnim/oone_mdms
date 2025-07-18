import 'package:flutter/material.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_input_field.dart';
import '../../widgets/common/blunest_data_table.dart';
import '../../widgets/common/results_pagination.dart';
import '../../widgets/common/app_lottie_state_widget.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/device_group.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/services/device_service.dart';

class DeviceGroupsScreen extends StatefulWidget {
  const DeviceGroupsScreen({super.key});

  @override
  State<DeviceGroupsScreen> createState() => _DeviceGroupsScreenState();
}

class _DeviceGroupsScreenState extends State<DeviceGroupsScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final DeviceService _deviceService;
  bool _isLoading = false;
  List<DeviceGroup> _deviceGroups = [];
  Set<DeviceGroup> _selectedGroups = {};
  List<String> _hiddenColumns = [];
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  int _itemsPerPage = 25;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    // Use ServiceLocator to get properly configured API service
    final serviceLocator = ServiceLocator();
    final apiService = serviceLocator.apiService;
    _deviceService = DeviceService(apiService);
    _loadDeviceGroups();
  }

  Future<void> _loadDeviceGroups() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _deviceService.getDeviceGroups(
        offset: (_currentPage - 1) * _itemsPerPage,
        limit: _itemsPerPage,
      );

      if (response.success) {
        setState(() {
          _deviceGroups = response.data!;
          _totalItems = response.paging?.item.total ?? 0;
          _totalPages = ((_totalItems / _itemsPerPage).ceil())
              .clamp(1, double.infinity)
              .toInt();
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
        _errorMessage = 'Failed to load device groups: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state
    if (_isLoading && _deviceGroups.isEmpty) {
      return const AppLottieStateWidget.loading(
        title: 'Loading Device Groups',
        message: 'Please wait while we fetch your device groups...',
      );
    }

    // Show error state if error and no data
    if (_errorMessage.isNotEmpty && _deviceGroups.isEmpty) {
      return AppLottieStateWidget.error(
        title: 'Failed to Load Device Groups',
        message: _errorMessage,
        buttonText: 'Try Again',
        onButtonPressed: _loadDeviceGroups,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppSizes.spacing24),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: AppSizes.spacing24),
          _buildErrorMessage(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // Show no data state if no device groups after loading
    if (!_isLoading && _deviceGroups.isEmpty && _errorMessage.isEmpty) {
      return AppLottieStateWidget.noData(
        title: 'No Device Groups Found',
        message:
            'No device groups have been created yet. Click "Add Device Group" to create your first group.',
        buttonText: 'Add Device Group',
        onButtonPressed: _createDeviceGroup,
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildTableHeader(),
          if (_selectedGroups.isNotEmpty) _buildMultiSelectToolbar(),
          Expanded(child: _buildDeviceGroupTable()),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: AppInputField(
            controller: _searchController,
            hintText: 'Search device groups',
            prefixIcon: const Icon(Icons.search, size: AppSizes.iconMedium),
            onChanged: (value) {
              _loadDeviceGroups();
            },
          ),
        ),
        const SizedBox(width: AppSizes.spacing16),
        AppButton(
          text: 'Add Device Group',
          type: AppButtonType.primary,
          icon: const Icon(
            Icons.add,
            size: AppSizes.iconSmall,
            color: AppColors.textInverse,
          ),
          onPressed: () {
            _createDeviceGroup();
          },
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Device Groups',
              style: TextStyle(
                fontSize: AppSizes.fontSizeLarge,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          AppInputField(
            hintText: 'Filter...',
            prefixIcon: const Icon(Icons.filter_list, size: AppSizes.iconSmall),
            onChanged: (value) {
              // Implement filter
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceGroupTable() {
    return BluNestDataTable<DeviceGroup>(
      columns: [
        BluNestTableColumn<DeviceGroup>(
          key: 'id',
          title: 'ID',
          builder: (group) => SizedBox(
            width: 60,
            child: Text(
              group.id.toString(),
              style: const TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        BluNestTableColumn<DeviceGroup>(
          key: 'name',
          title: 'Group Name',
          builder: (group) => Expanded(
            flex: 2,
            child: Text(
              group.name ?? 'None',
              style: const TextStyle(
                fontSize: AppSizes.fontSizeMedium,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        BluNestTableColumn<DeviceGroup>(
          key: 'deviceCount',
          title: 'Device Count',
          builder: (group) => SizedBox(
            width: 120,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacing8,
                vertical: AppSizes.spacing4,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
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
        ),
        BluNestTableColumn<DeviceGroup>(
          key: 'description',
          title: 'Description',
          builder: (group) => SizedBox(
            width: 120,
            child: Text(
              group.description ?? 'N/A',
              style: const TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        BluNestTableColumn<DeviceGroup>(
          key: 'actions',
          title: 'Actions',
          builder: (group) => SizedBox(
            width: 120,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _viewGroupDetails(group),
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
        ),
      ],
      data: _deviceGroups,
      isLoading: _isLoading,
      enableMultiSelect: true,
      selectedItems: _selectedGroups,
      onSelectionChanged: (selectedItems) {
        setState(() {
          _selectedGroups = selectedItems;
        });
      },
      hiddenColumns: _hiddenColumns,
      onColumnVisibilityChanged: (hiddenColumns) {
        setState(() {
          _hiddenColumns = hiddenColumns;
        });
      },
      onRowTap: _viewGroupDetails,
      onEdit: _editDeviceGroup,
      onDelete: _deleteDeviceGroup,
      onView: _viewGroupDetails,
    );
  }

  Widget _buildMultiSelectToolbar() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        border: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Text(
            '${_selectedGroups.length} groups selected',
            style: const TextStyle(
              fontSize: AppSizes.fontSizeMedium,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
          const Spacer(),
          AppButton(
            text: 'Delete Selected',
            type: AppButtonType.outline,
            size: AppButtonSize.small,
            onPressed: () => _showBulkDeleteConfirmation(),
          ),
        ],
      ),
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
      onPageChanged: _goToPage,
      onItemsPerPageChanged: (newItemsPerPage) {
        setState(() {
          _itemsPerPage = newItemsPerPage;
          _currentPage = 1;
          _totalPages = (_totalItems / _itemsPerPage).ceil();
        });
        _loadDeviceGroups();
      },
      itemLabel: 'device groups',
      showItemsPerPageSelector: true,
    );
  }

  Widget _buildErrorMessage() {
    if (_errorMessage.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spacing16),
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
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
            onPressed: _loadDeviceGroups,
            icon: const Icon(Icons.refresh, color: AppColors.error),
            tooltip: 'Retry',
          ),
        ],
      ),
    );
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= _totalPages && page != _currentPage) {
      setState(() {
        _currentPage = page;
      });
      _loadDeviceGroups();
    }
  }

  void _createDeviceGroup() {
    // TODO: Implement create device group modal
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create device group - Coming soon')),
    );
  }

  void _viewGroupDetails(DeviceGroup group) {
    // TODO: Navigate to device group details
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('View details for ${group.name}')));
  }

  void _editDeviceGroup(DeviceGroup group) {
    // TODO: Implement edit device group modal
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Edit ${group.name} - Coming soon')));
  }

  void _deleteDeviceGroup(DeviceGroup group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Device Group'),
        content: Text('Are you sure you want to delete "${group.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement actual delete API call
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${group.name} deleted successfully')),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
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
        title: const Text('Delete Selected Groups'),
        content: Text(
          'Are you sure you want to delete ${_selectedGroups.length} selected device groups?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement bulk delete API call
              setState(() {
                _selectedGroups.clear();
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Selected groups deleted successfully'),
                ),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
