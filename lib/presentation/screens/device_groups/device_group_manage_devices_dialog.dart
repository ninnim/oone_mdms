import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/models/device_group.dart';
import '../../../core/models/device.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/device_group_service.dart';
import '../../../core/services/device_service.dart';
import '../../../core/services/service_locator.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/common/blunest_data_table.dart';
import '../../widgets/common/app_lottie_state_widget.dart';
import '../../widgets/common/app_tabs.dart';
import '../../widgets/common/results_pagination.dart';
import '../../widgets/common/app_input_field.dart';

class DeviceGroupManageDevicesDialog extends StatefulWidget {
  final DeviceGroup deviceGroup;
  final VoidCallback? onDevicesChanged;

  const DeviceGroupManageDevicesDialog({
    super.key,
    required this.deviceGroup,
    this.onDevicesChanged,
  });

  @override
  State<DeviceGroupManageDevicesDialog> createState() =>
      _DeviceGroupManageDevicesDialogState();
}

class _DeviceGroupManageDevicesDialogState
    extends State<DeviceGroupManageDevicesDialog> {
  late final DeviceGroupService _deviceGroupService;
  late final DeviceService _deviceService;
  final TextEditingController _searchController = TextEditingController();

  List<Device> _availableDevices = [];
  List<Device> _currentDevices = [];
  Set<Device> _selectedAvailableDevices = {};
  Set<Device> _selectedCurrentDevices = {};

  bool _isLoadingAvailable = false;
  bool _isLoadingCurrent = false;
  bool _isProcessing = false;
  bool _isSearching = false;
  String? _errorMessage;
  int _currentTabIndex = 0;

  // Pagination for available devices
  int _availableCurrentPage = 1;
  int _availableItemsPerPage = 10;
  int _totalAvailableDevices = 0;
  String _availableSearchQuery = '%%'; // Default search to get all devices
  Timer? _availableSearchDebounce;

  // Pagination for current devices
  int _currentDevicesPage = 1;
  int _currentDevicesItemsPerPage = 10;
  int _totalCurrentDevices = 0;
  String _currentSearchQuery = '%%'; // Default search to get all devices
  Timer? _currentSearchDebounce;

  // Sorting for available devices table
  String? _availableSortBy;
  bool _availableSortAscending = true;

  // Sorting for current devices table
  String? _currentSortBy;
  bool _currentSortAscending = true;

  // Column visibility for both tables
  List<String> _availableHiddenColumns = [];
  List<String> _currentHiddenColumns = [];

  @override
  void initState() {
    super.initState();

    // Initialize services
    final serviceLocator = ServiceLocator();
    final apiService = serviceLocator.apiService;
    _deviceGroupService = DeviceGroupService(apiService);
    _deviceService = DeviceService(apiService);

    // Load data
    _loadAvailableDevices();
    _loadCurrentDevices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _availableSearchDebounce?.cancel();
    _currentSearchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadAvailableDevices() async {
    setState(() => _isLoadingAvailable = true);

    try {
      // Calculate offset from page number
      final offset = (_availableCurrentPage - 1) * _availableItemsPerPage;

      final response = await _deviceGroupService.getAvailableDevices(
        search: _availableSearchQuery,
        offset: offset,
        limit: _availableItemsPerPage,
      );

      if (response.success && response.data != null) {
        setState(() {
          _availableDevices = response.data!;
          // Use the total count from API paging if available
          _totalAvailableDevices = response.paging?.item.total ?? 0;
          _errorMessage = null;
        });

        // Apply sorting after loading data
        _sortAvailableDevices();
      } else {
        setState(() {
          _errorMessage =
              response.message ?? 'Failed to load available devices';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load available devices: $e';
      });
    } finally {
      setState(() => _isLoadingAvailable = false);
    }
  }

  Future<void> _loadCurrentDevices() async {
    setState(() => _isLoadingCurrent = true);

    try {
      // Calculate offset from page number
      final offset = (_currentDevicesPage - 1) * _currentDevicesItemsPerPage;

      final response = await _deviceGroupService.getDevicesInGroup(
        groupId: widget.deviceGroup.id!,
        search: _currentSearchQuery,
        offset: offset,
        limit: _currentDevicesItemsPerPage,
      );

      if (response.success && response.data != null) {
        setState(() {
          _currentDevices = response.data!;
          // Use the total count from API paging if available
          _totalCurrentDevices = response.paging?.item.total ?? 0;
          _errorMessage = null;
        });

        // Apply sorting after loading data
        _sortCurrentDevices();
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Failed to load current devices';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load current devices: $e';
      });
    } finally {
      setState(() => _isLoadingCurrent = false);
    }
  }

  void _onAvailableSearchChanged(String value) {
    // Cancel any existing timer
    _availableSearchDebounce?.cancel();

    // Show searching indicator only if there's actual input change
    final formattedQuery = value.trim().isEmpty ? '%%' : '%${value.trim()}%';
    if (_availableSearchQuery != formattedQuery) {
      setState(() {
        _isSearching = true;
      });
    }

    // Set up a new timer with 800ms delay (increased for better UX)
    _availableSearchDebounce = Timer(const Duration(milliseconds: 800), () {
      // Only search if the query actually changed
      if (_availableSearchQuery != formattedQuery) {
        setState(() {
          _availableSearchQuery = formattedQuery;
          _availableCurrentPage = 1; // Reset to first page when searching
          _isSearching = false;
        });
        _loadAvailableDevices();
      } else {
        setState(() {
          _isSearching = false;
        });
      }
    });
  }

  void _onCurrentSearchChanged(String value) {
    // Cancel any existing timer
    _currentSearchDebounce?.cancel();

    // Show searching indicator only if there's actual input change
    final formattedQuery = value.trim().isEmpty ? '%%' : '%${value.trim()}%';
    if (_currentSearchQuery != formattedQuery) {
      setState(() {
        _isSearching = true;
      });
    }

    // Set up a new timer with 800ms delay (increased for better UX)
    _currentSearchDebounce = Timer(const Duration(milliseconds: 800), () {
      // Only search if the query actually changed
      if (_currentSearchQuery != formattedQuery) {
        setState(() {
          _currentSearchQuery = formattedQuery;
          _currentDevicesPage = 1; // Reset to first page when searching
          _isSearching = false;
        });
        _loadCurrentDevices();
      } else {
        setState(() {
          _isSearching = false;
        });
      }
    });
  }

  // Sorting methods for available devices
  void _onAvailableSort(String columnKey, bool ascending) {
    setState(() {
      _availableSortBy = columnKey;
      _availableSortAscending = ascending;
    });

    // Apply local sorting to current data
    _sortAvailableDevices();
  }

  void _onAvailableColumnVisibilityChanged(List<String> hiddenColumns) {
    setState(() {
      _availableHiddenColumns = hiddenColumns;
    });
  }

  void _sortAvailableDevices() {
    if (_availableSortBy == null) return;

    _availableDevices.sort((a, b) {
      dynamic valueA;
      dynamic valueB;

      switch (_availableSortBy) {
        case 'SerialNumber':
          valueA = a.serialNumber.toLowerCase();
          valueB = b.serialNumber.toLowerCase();
          break;
        case 'Name':
          valueA = a.name.toLowerCase();
          valueB = b.name.toLowerCase();
          break;
        case 'Type':
          valueA = a.deviceType.toLowerCase();
          valueB = b.deviceType.toLowerCase();
          break;
        case 'Model':
          valueA = a.model.toLowerCase();
          valueB = b.model.toLowerCase();
          break;
        case 'Status':
          valueA = a.status.toLowerCase();
          valueB = b.status.toLowerCase();
          break;
        default:
          return 0;
      }

      final comparison = valueA.compareTo(valueB);
      return _availableSortAscending ? comparison : -comparison;
    });
  }

  // Sorting methods for current devices
  void _onCurrentSort(String columnKey, bool ascending) {
    setState(() {
      _currentSortBy = columnKey;
      _currentSortAscending = ascending;
    });

    // Apply local sorting to current data
    _sortCurrentDevices();
  }

  void _onCurrentColumnVisibilityChanged(List<String> hiddenColumns) {
    setState(() {
      _currentHiddenColumns = hiddenColumns;
    });
  }

  void _sortCurrentDevices() {
    if (_currentSortBy == null) return;

    _currentDevices.sort((a, b) {
      dynamic valueA;
      dynamic valueB;

      switch (_currentSortBy) {
        case 'SerialNumber':
          valueA = a.serialNumber.toLowerCase();
          valueB = b.serialNumber.toLowerCase();
          break;
        case 'Name':
          valueA = a.name.toLowerCase();
          valueB = b.name.toLowerCase();
          break;
        case 'Type':
          valueA = a.deviceType.toLowerCase();
          valueB = b.deviceType.toLowerCase();
          break;
        case 'Model':
          valueA = a.model.toLowerCase();
          valueB = b.model.toLowerCase();
          break;
        case 'Status':
          valueA = a.status.toLowerCase();
          valueB = b.status.toLowerCase();
          break;
        default:
          return 0;
      }

      final comparison = valueA.compareTo(valueB);
      return _currentSortAscending ? comparison : -comparison;
    });
  }

  Future<List<Device>> _fetchAllAvailableDevices() async {
    try {
      // Return all available devices (since they're already loaded)
      return _availableDevices;
    } catch (e) {
      throw Exception('Error fetching all available devices: $e');
    }
  }

  Future<List<Device>> _fetchAllCurrentDevices() async {
    try {
      // Return all current devices (since they're already loaded)
      return _currentDevices;
    } catch (e) {
      throw Exception('Error fetching all current devices: $e');
    }
  }

  Future<void> _addDevicesToGroup() async {
    if (_selectedAvailableDevices.isEmpty) {
      AppToast.show(
        context,
        title: 'Warning',
        message: 'Please select devices to add',
        type: ToastType.warning,
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Update each selected device to set the group ID
      for (final device in _selectedAvailableDevices) {
        final updatedDevice = device.copyWith(
          deviceGroupId: widget.deviceGroup.id,
        );
        await _deviceService.updateDevice(updatedDevice);
      }

      AppToast.show(
        context,
        title: 'Success',
        message: '${_selectedAvailableDevices.length} device(s) added to group',
        type: ToastType.success,
      );

      // Clear selection and refresh data
      setState(() => _selectedAvailableDevices.clear());
      await Future.wait([_loadAvailableDevices(), _loadCurrentDevices()]);

      widget.onDevicesChanged?.call();
    } catch (e) {
      AppToast.show(
        context,
        title: 'Error',
        message: 'Failed to add devices: $e',
        type: ToastType.error,
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _removeDevicesFromGroup() async {
    if (_selectedCurrentDevices.isEmpty) {
      AppToast.show(
        context,
        title: 'Warning',
        message: 'Please select devices to remove',
        type: ToastType.warning,
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Update each selected device to remove from group (set deviceGroupId to 0)
      for (final device in _selectedCurrentDevices) {
        final updatedDevice = device.copyWith(deviceGroupId: 0);
        await _deviceService.updateDevice(updatedDevice);
      }

      AppToast.show(
        context,
        title: 'Success',
        message:
            '${_selectedCurrentDevices.length} device(s) removed from group',
        type: ToastType.success,
      );

      // Clear selection and refresh data
      setState(() => _selectedCurrentDevices.clear());
      await Future.wait([_loadAvailableDevices(), _loadCurrentDevices()]);

      widget.onDevicesChanged?.call();
    } catch (e) {
      AppToast.show(
        context,
        title: 'Error',
        message: 'Failed to remove devices: $e',
        type: ToastType.error,
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.spacing8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  ),
                  child: const Icon(
                    Icons.devices,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSizes.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manage Devices in ${widget.deviceGroup.name}',
                        style: const TextStyle(
                          fontSize: AppSizes.fontSizeLarge,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacing4),
                      const Text(
                        'Add or remove devices from this group',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeSmall,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacing16),

            // Search field - styled exactly like device screen
            AppInputField(
              controller: _searchController,
              hintText: 'Search devices...',
              prefixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.search, size: AppSizes.iconSmall),
              onChanged: (value) {
                // Search based on current tab
                if (_currentTabIndex == 0) {
                  _onAvailableSearchChanged(value);
                } else {
                  _onCurrentSearchChanged(value);
                }
              },
            ),
            const SizedBox(height: AppSizes.spacing16),

            // Content with AppPillTabs
            Expanded(
              child: AppPillTabs(
                initialIndex: _currentTabIndex,
                onTabChanged: (index) {
                  setState(() {
                    _currentTabIndex = index;
                  });
                },
                tabs: [
                  AppTab(
                    label: 'Available Devices ($_totalAvailableDevices)',
                    icon: Icon(
                      Icons.add_circle_outline,
                      size: AppSizes.iconSmall,
                    ),
                    content: _buildAvailableDevicesTab(),
                  ),
                  AppTab(
                    label: 'Current Devices ($_totalCurrentDevices)',
                    icon: Icon(Icons.devices, size: AppSizes.iconSmall),
                    content: _buildCurrentDevicesTab(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.spacing16),

            // Action buttons
            Row(
              children: [
                if (_currentTabIndex == 0) ...[
                  Text(
                    '${_selectedAvailableDevices.length} device(s) selected',
                    style: const TextStyle(
                      fontSize: AppSizes.fontSizeSmall,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  AppButton(
                    onPressed:
                        _selectedAvailableDevices.isEmpty || _isProcessing
                        ? null
                        : _addDevicesToGroup,
                    type: AppButtonType.primary,
                    size: AppButtonSize.medium,
                    isLoading: _isProcessing,
                    text: 'Add to Group',
                    icon: const Icon(Icons.add),
                  ),
                ] else ...[
                  Text(
                    '${_selectedCurrentDevices.length} device(s) selected',
                    style: const TextStyle(
                      fontSize: AppSizes.fontSizeSmall,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  AppButton(
                    onPressed: _selectedCurrentDevices.isEmpty || _isProcessing
                        ? null
                        : _removeDevicesFromGroup,
                    type: AppButtonType.danger,
                    size: AppButtonSize.medium,
                    isLoading: _isProcessing,
                    text: 'Remove from Group',
                    icon: const Icon(Icons.remove),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableDevicesTab() {
    if (_isLoadingAvailable) {
      return AppLottieStateWidget.loading(
        title: 'Loading Available Devices',
        message: 'Please wait...',
        lottieSize: 60,
      );
    }

    if (_errorMessage != null) {
      return AppLottieStateWidget.error(
        title: 'Error Loading Devices',
        message: _errorMessage!,
        lottieSize: 60,
        onButtonPressed: _loadAvailableDevices,
      );
    }

    if (_availableDevices.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.devices_other, size: 48, color: AppColors.textSecondary),
            SizedBox(height: AppSizes.spacing16),
            Text(
              'No Available Devices',
              style: TextStyle(
                fontSize: AppSizes.fontSizeMedium,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppSizes.spacing8),
            Text(
              'All devices are already assigned to groups.',
              style: TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // Safe pagination calculation to avoid clamp errors
    final totalPages = _totalAvailableDevices > 0
        ? (_totalAvailableDevices / _availableItemsPerPage).ceil()
        : 1;
    final startIndex = _totalAvailableDevices > 0
        ? (_availableCurrentPage - 1) * _availableItemsPerPage + 1
        : 0;
    final endIndex = _totalAvailableDevices > 0
        ? (_availableCurrentPage * _availableItemsPerPage).clamp(
            1,
            _totalAvailableDevices,
          )
        : 0;

    return Column(
      children: [
        Expanded(
          child: BluNestDataTable<Device>(
            columns: _buildDeviceTableColumns(),
            data: _availableDevices,
            enableMultiSelect: true,
            selectedItems: _selectedAvailableDevices,
            onSelectionChanged: (selected) {
              setState(() => _selectedAvailableDevices = selected);
            },
            sortBy: _availableSortBy,
            sortAscending: _availableSortAscending,
            onSort: _onAvailableSort,
            hiddenColumns: _availableHiddenColumns,
            onColumnVisibilityChanged: _onAvailableColumnVisibilityChanged,
            totalItemsCount: _availableDevices.length,
            onSelectAllItems: _fetchAllAvailableDevices,
          ),
        ),

        // Pagination - show if we have devices, matching device_groups_screen behavior
        if (_totalAvailableDevices > 0)
          Container(
            padding: const EdgeInsets.all(AppSizes.spacing16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(
                  color: AppColors.border.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: ResultsPagination(
              currentPage: _availableCurrentPage,
              totalPages: totalPages,
              totalItems: _totalAvailableDevices,
              itemsPerPage: _availableItemsPerPage,
              itemsPerPageOptions: const [5, 10, 20, 25, 50],
              startItem: startIndex,
              endItem: endIndex,
              itemLabel: 'devices',
              onPageChanged: (page) {
                setState(() {
                  _availableCurrentPage = page;
                });
                _loadAvailableDevices();
              },
              onItemsPerPageChanged: (itemsPerPage) {
                setState(() {
                  _availableItemsPerPage = itemsPerPage;
                  _availableCurrentPage = 1;
                });
                _loadAvailableDevices();
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCurrentDevicesTab() {
    if (_isLoadingCurrent) {
      return AppLottieStateWidget.loading(
        title: 'Loading Current Devices',
        message: 'Please wait...',
        lottieSize: 60,
      );
    }

    if (_errorMessage != null) {
      return AppLottieStateWidget.error(
        title: 'Error Loading Devices',
        message: _errorMessage!,
        lottieSize: 60,
        onButtonPressed: _loadCurrentDevices,
      );
    }

    if (_currentDevices.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.devices_other, size: 48, color: AppColors.textSecondary),
            SizedBox(height: AppSizes.spacing16),
            Text(
              'No Devices in Group',
              style: TextStyle(
                fontSize: AppSizes.fontSizeMedium,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppSizes.spacing8),
            Text(
              'Add devices from the "Available Devices" tab.',
              style: TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // Safe pagination calculation to avoid clamp errors
    final totalPages = _totalCurrentDevices > 0
        ? (_totalCurrentDevices / _currentDevicesItemsPerPage).ceil()
        : 1;
    final startIndex = _totalCurrentDevices > 0
        ? (_currentDevicesPage - 1) * _currentDevicesItemsPerPage + 1
        : 0;
    final endIndex = _totalCurrentDevices > 0
        ? (_currentDevicesPage * _currentDevicesItemsPerPage).clamp(
            1,
            _totalCurrentDevices,
          )
        : 0;

    return Column(
      children: [
        Expanded(
          child: BluNestDataTable<Device>(
            columns: _buildDeviceTableColumns(),
            data: _currentDevices,
            enableMultiSelect: true,
            selectedItems: _selectedCurrentDevices,
            onSelectionChanged: (selected) {
              setState(() => _selectedCurrentDevices = selected);
            },
            sortBy: _currentSortBy,
            sortAscending: _currentSortAscending,
            onSort: _onCurrentSort,
            hiddenColumns: _currentHiddenColumns,
            onColumnVisibilityChanged: _onCurrentColumnVisibilityChanged,
            totalItemsCount: _currentDevices.length,
            onSelectAllItems: _fetchAllCurrentDevices,
          ),
        ),

        // Pagination - show if we have devices, matching device_groups_screen behavior
        if (_totalCurrentDevices > 0)
          Container(
            padding: const EdgeInsets.all(AppSizes.spacing16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(
                  color: AppColors.border.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: ResultsPagination(
              currentPage: _currentDevicesPage,
              totalPages: totalPages,
              totalItems: _totalCurrentDevices,
              itemsPerPage: _currentDevicesItemsPerPage,
              itemsPerPageOptions: const [5, 10, 20, 25, 50],
              startItem: startIndex,
              endItem: endIndex,
              itemLabel: 'devices',
              onPageChanged: (page) {
                setState(() {
                  _currentDevicesPage = page;
                });
                _loadCurrentDevices();
              },
              onItemsPerPageChanged: (itemsPerPage) {
                setState(() {
                  _currentDevicesItemsPerPage = itemsPerPage;
                  _currentDevicesPage = 1;
                });
                _loadCurrentDevices();
              },
            ),
          ),
      ],
    );
  }

  List<BluNestTableColumn<Device>> _buildDeviceTableColumns() {
    return [
      BluNestTableColumn<Device>(
        key: 'SerialNumber',
        title: 'Serial Number',
        flex: 2,
        sortable: true,
        builder: (device) => Text(
          device.serialNumber,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
      BluNestTableColumn<Device>(
        key: 'Name',
        title: 'Name',
        flex: 2,
        sortable: true,
        builder: (device) =>
            Text(device.name.isEmpty ? 'Unnamed' : device.name),
      ),
      BluNestTableColumn<Device>(
        key: 'Type',
        title: 'Type',
        flex: 1,
        sortable: true,
        builder: (device) =>
            Text(device.deviceType.isEmpty ? 'Unknown' : device.deviceType),
      ),
      BluNestTableColumn<Device>(
        key: 'Model',
        title: 'Model',
        flex: 1,
        sortable: true,
        builder: (device) =>
            Text(device.model.isEmpty ? 'Unknown' : device.model),
      ),
      BluNestTableColumn<Device>(
        key: 'Status',
        title: 'Status',
        flex: 1,
        sortable: true,
        builder: (device) => Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacing8,
            vertical: AppSizes.spacing4,
          ),
          decoration: BoxDecoration(
            color: _getStatusColor(device.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          ),
          child: Text(
            device.status.isEmpty ? 'Unknown' : device.status,
            style: TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              fontWeight: FontWeight.w500,
              color: _getStatusColor(device.status),
            ),
          ),
        ),
      ),
    ];
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'commissioned':
        return AppColors.success;
      case 'none':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }
}
