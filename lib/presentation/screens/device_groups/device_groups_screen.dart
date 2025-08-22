import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mdms_clone/presentation/widgets/device_groups/device_group_filters_and_actions_v2.dart';
import '../../widgets/device_groups/device_group_kanban_view.dart';
import 'dart:async';
import '../../../core/models/device_group.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/services/device_group_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_input_field.dart';
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

class _DeviceGroupsScreenState extends State<DeviceGroupsScreen>
    with ResponsiveMixin {
  DeviceGroupService? _deviceGroupService;

  // Data
  List<DeviceGroup> _deviceGroups = [];
  List<DeviceGroup> _filteredDeviceGroups = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isInitialized = false; // Track if data has been loaded initially

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

  // Responsive UI state
  bool _summaryCardCollapsed = false;
  bool _isKanbanView = false;
  DeviceGroupViewMode?
  _previousViewModeBeforeMobile; // Track previous view mode before mobile switch
  bool?
  _previousSummaryStateBeforeMobile; // Track previous summary state before mobile switch

  // Search delay timer
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialize service only once
    if (_deviceGroupService == null) {
      _deviceGroupService = DeviceGroupService(ServiceLocator().apiService);
    }

    // Only load data on first initialization, not on every dependency change (like screen resize)
    if (!_isInitialized) {
      _isInitialized = true;
      _loadDeviceGroups();
      print('🚀 DeviceGroupsScreen: Initial data load triggered');
    } else {
      print(
        '📱 DeviceGroupsScreen: Dependencies changed (likely screen resize) - NO API call',
      );
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchTimer?.cancel();
    super.dispose();
  }

  @override
  void handleResponsiveStateChange() {
    if (!mounted) return;

    final mediaQuery = MediaQuery.of(context);
    final isMobile = mediaQuery.size.width < 768;
    final isTablet =
        mediaQuery.size.width >= 768 && mediaQuery.size.width < 1024;

    // Auto-collapse summary card on mobile, keep visible but allow toggle
    if (isMobile &&
        !_summaryCardCollapsed &&
        _previousSummaryStateBeforeMobile == null) {
      // Save previous summary state before collapsing for mobile
      _previousSummaryStateBeforeMobile = _summaryCardCollapsed;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _summaryCardCollapsed = true; // Default to collapsed on mobile
          });
          print('📱 Auto-collapsed summary card for mobile');
        }
      });
    }

    // Auto-expand summary card on desktop - restore previous state
    if (!isMobile && !isTablet && _previousSummaryStateBeforeMobile != null) {
      final shouldExpand = _previousSummaryStateBeforeMobile == false;
      if (shouldExpand) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _summaryCardCollapsed = _previousSummaryStateBeforeMobile!;
              _previousSummaryStateBeforeMobile = null; // Reset tracking
            });
            print('📱 Auto-expanded summary card for desktop');
          }
        });
      }
    }

    // Auto-switch to kanban view on mobile
    if (isMobile && !_isKanbanView) {
      // Save previous view mode before switching to mobile kanban
      if (_previousViewModeBeforeMobile == null) {
        _previousViewModeBeforeMobile = _currentViewMode;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isKanbanView = true;
            _currentViewMode = DeviceGroupViewMode.kanban;
          });
        }
      });
    }

    // Auto-switch back to previous view mode on desktop
    if (!isMobile && _isKanbanView && _previousViewModeBeforeMobile != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isKanbanView = false;
            _currentViewMode = _previousViewModeBeforeMobile!;
            _previousViewModeBeforeMobile = null; // Reset tracking
          });
        }
      });
    }

    print(
      '📱 DeviceGroupsScreen: Responsive state updated (mobile: $isMobile, kanban: $_isKanbanView, view: $_currentViewMode) - UI ONLY, no API calls',
    );
  }

  Future<void> _loadDeviceGroups() async {
    if (_deviceGroupService == null) return;

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

      final response = await _deviceGroupService!.getDeviceGroups(
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
    _searchTimer?.cancel();

    // Set a new timer to delay the search
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
        _currentPage = 1; // Reset to first page when searching
      });
      print('🔍 DeviceGroupsScreen: Search triggered for: "$query"');
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
      // Update kanban view state based on the new mode
      _isKanbanView = (viewMode == DeviceGroupViewMode.kanban);

      // If user manually changes view mode, reset mobile tracking
      if (MediaQuery.of(context).size.width >= 768) {
        _previousViewModeBeforeMobile = null;
      }
    });
    print(
      '🔄 DeviceGroupsScreen: View mode changed to $viewMode (kanban: $_isKanbanView)',
    );
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
        final response = await _deviceGroupService!.deleteDeviceGroup(
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
    if (_deviceGroupService == null) return [];

    try {
      // Fetch all device groups without pagination
      final response = await _deviceGroupService!.getDeviceGroups(
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isMobile = screenWidth < 768;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                // Summary Card FIRST (like schedule screen)
                if (isMobile)
                  _buildCollapsibleSummaryCard()
                else
                  _buildDesktopSummaryCard(),
                // Header/Filters AFTER summary card
                if (isMobile) _buildMobileHeader() else _buildDesktopHeader(),
                // Content
                Expanded(
                  child: Container(
                    width: double.infinity,
                    child: _buildContent(),
                  ),
                ),
                // Pagination - direct call like other screens
                Container(width: double.infinity, child: _buildPagination()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
      child: Column(
        children: [
          const SizedBox(height: AppSizes.spacing8),
          // Filters and Actions
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
          ),
          const SizedBox(height: AppSizes.spacing24),
        ],
      ),
    );
  }

  Widget _buildDesktopSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacing16,
        vertical: AppSizes.spacing8,
      ),
      child: DeviceGroupSummaryCard(deviceGroups: _filteredDeviceGroups),
    );
  }

  Widget _buildCollapsibleSummaryCard() {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final isTablet =
        MediaQuery.of(context).size.width >= 768 &&
        MediaQuery.of(context).size.width < 1024;

    // Responsive sizing
    final headerFontSize = isMobile ? 14.0 : (isTablet ? 15.0 : 16.0);
    final collapsedHeight = isMobile ? 60.0 : (isTablet ? 60.0 : 70.0);
    final expandedHeight = isMobile ? 180.0 : (isTablet ? 160.0 : 180.0);
    final headerHeight = isMobile ? 50.0 : (isTablet ? 45.0 : 50.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(
        left: AppSizes.spacing16,
        right: AppSizes.spacing16,
        top: AppSizes.spacing8,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: _summaryCardCollapsed ? collapsedHeight : expandedHeight,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            boxShadow: [AppSizes.shadowSmall],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with toggle button
              SizedBox(
                height: headerHeight,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile
                        ? AppSizes.paddingSmall
                        : AppSizes.paddingMedium,
                    vertical: AppSizes.paddingSmall,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.group_work,
                        color: AppColors.primary,
                        size: AppSizes.iconSmall,
                      ),
                      SizedBox(
                        width: isMobile ? AppSizes.spacing4 : AppSizes.spacing8,
                      ),
                      Expanded(
                        child: Text(
                          'Summary',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                fontSize: headerFontSize,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _summaryCardCollapsed = !_summaryCardCollapsed;
                            // Reset mobile tracking when user manually toggles
                            _previousSummaryStateBeforeMobile = null;
                          });
                          print(
                            '📱 Summary card toggled: collapsed=$_summaryCardCollapsed',
                          );
                        },
                        icon: Icon(
                          _summaryCardCollapsed
                              ? Icons.expand_more
                              : Icons.expand_less,
                          color: AppColors.textSecondary,
                          size: AppSizes.iconSmall,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(
                          minWidth: isMobile ? 28 : 32,
                          minHeight: isMobile ? 28 : 32,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Expanded summary content
              if (!_summaryCardCollapsed)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? AppSizes.paddingSmall : AppSizes.paddingMedium,
                      0,
                      isMobile ? AppSizes.paddingSmall : AppSizes.paddingMedium,
                      AppSizes.paddingSmall,
                    ),
                    child: DeviceGroupSummaryCard(
                      deviceGroups: _filteredDeviceGroups,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacing16,
        vertical: AppSizes.spacing8,
      ),
      child: Container(
        height: AppSizes.cardMobile,
        alignment: Alignment.centerLeft,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacing16,
          vertical: AppSizes.spacing8,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.spacing8),
          color: AppColors.surface,
          boxShadow: [AppSizes.shadowSmall],
        ),
        child: Row(
          children: [
            Expanded(child: _buildMobileSearchBar()),
            const SizedBox(width: AppSizes.spacing8),
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: _buildMobileMoreActionsButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing8),
      child: AppInputField.search(
        hintText: 'Search device groups...',
        onChanged: _onSearchChanged,
        prefixIcon: const Icon(Icons.search, size: AppSizes.iconSmall),
        enabled: true,
      ),
    );
  }

  Widget _buildMobileMoreActionsButton() {
    return Container(
      height: 36,
      width: 36,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSizes.spacing8),
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
        onSelected: (value) {
          switch (value) {
            case 'add':
              _createDeviceGroup();
              break;
            case 'refresh':
              _loadDeviceGroups();
              break;
            case 'kanban':
              _onViewModeChanged(DeviceGroupViewMode.kanban);
              break;
            case 'table':
              _onViewModeChanged(DeviceGroupViewMode.table);
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'add',
            child: Row(
              children: [
                Icon(Icons.add, size: 18),
                SizedBox(width: 8),
                Text('Add Device Group'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'refresh',
            child: Row(
              children: [
                Icon(Icons.refresh, size: 18),
                SizedBox(width: 8),
                Text('Refresh'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'kanban',
            child: Row(
              children: [
                Icon(
                  Icons.view_kanban,
                  size: 18,
                  color: _currentViewMode == DeviceGroupViewMode.kanban
                      ? AppColors.primary
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  'Kanban View',
                  style: TextStyle(
                    color: _currentViewMode == DeviceGroupViewMode.kanban
                        ? AppColors.primary
                        : null,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'table',
            child: Row(
              children: [
                Icon(
                  Icons.table_chart,
                  size: 18,
                  color: _currentViewMode == DeviceGroupViewMode.table
                      ? AppColors.primary
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  'Table View',
                  style: TextStyle(
                    color: _currentViewMode == DeviceGroupViewMode.table
                        ? AppColors.primary
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // Show full-screen loading only if no data exists yet
    if (_isLoading && _deviceGroups.isEmpty) {
      return const Center(
        child: AppLottieStateWidget.loading(
          title: 'Loading Device Groups',
          titleColor: AppColors.primary,
          messageColor: AppColors.textSecondary,
          message: 'Please wait while we fetch your device groups...',
          lottieSize: 80,
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

    return _buildViewContent();
  }

  Widget _buildViewContent() {
    return (_currentViewMode == DeviceGroupViewMode.table && !_isKanbanView)
        ? _buildTableView()
        : _buildKanbanView();
  }

  Widget _buildTableView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
      child: _buildDeviceGroupTable(),
    );
  }

  Widget _buildKanbanView() {
    if (_isLoading && _deviceGroups.isEmpty) {
      return const Center(
        child: AppLottieStateWidget.loading(
          title: 'Loading Device Groups',
          lottieSize: 80,
          message: 'Please wait while we fetch your device groups.',
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
      child: DeviceGroupKanbanView(
        deviceGroups: _filteredDeviceGroups,
        onDeviceGroupSelected: _viewDeviceGroup,
        onDeviceGroupEdit: _editDeviceGroup,
        onDeviceGroupDelete: _deleteDeviceGroup,
        onDeviceGroupView: _viewDeviceGroup,
        onManageDevices: _manageDevices,
        isLoading: _isLoading,
      ),
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

  Widget _buildDeviceGroupTable() {
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
      emptyState: AppLottieStateWidget.noData(
        title: 'No Device Groups',
        message: 'No device groups found for the current filter criteria.',
        lottieSize: 120,
      ),
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
