import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/schedule.dart';
import '../../../core/services/schedule_service.dart';
import '../../../core/services/service_locator.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_confirm_dialog.dart';
import '../../widgets/common/app_lottie_state_widget.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/common/blunest_data_table.dart';
import '../../widgets/common/results_pagination.dart';
import '../../widgets/schedules/schedule_form_dialog.dart';
import '../../widgets/schedules/schedule_table_columns.dart';
import '../../widgets/schedules/schedule_filters_and_actions_v2.dart';
import '../../widgets/schedules/schedule_summary_card.dart';
import '../../widgets/schedules/schedule_kanban_view.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final ScheduleService _scheduleService;
  bool _isLoading = false;
  List<Schedule> _schedules = [];
  List<Schedule> _filteredSchedules = [];
  Set<Schedule> _selectedSchedules = {};
  List<String> _hiddenColumns = [];
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  int _itemsPerPage = 25;
  String _errorMessage = '';
  Timer? _debounceTimer;

  // View mode
  ScheduleViewMode _currentViewMode = ScheduleViewMode.table;

  // Filters
  String? _selectedStatus;
  String? _selectedTargetType;

  // Sorting
  String? _sortBy;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    final serviceLocator = ServiceLocator();
    final apiService = serviceLocator.apiService;
    _scheduleService = ScheduleService(apiService);
    _loadSchedules();
  }

  void _onSearchChanged(String value) {
    // Cancel the previous timer
    _debounceTimer?.cancel();

    // Set a new timer
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      // Reset to first page when searching
      _currentPage = 1;
      _searchController.text = value;
      _loadSchedules();
    });
  }

  Future<void> _loadSchedules() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final search = _searchController.text.isEmpty
          ? '%%'
          : '%${_searchController.text}%';
      final offset = (_currentPage - 1) * _itemsPerPage;

      final response = await _scheduleService.getSchedules(
        search: search,
        offset: offset,
        limit: _itemsPerPage,
      );

      if (response.success) {
        setState(() {
          _schedules = response.data ?? [];
          // Apply client-side filters for now (until API supports them)
          _filteredSchedules = _applyFilters(_schedules);

          // Use total count from API response for server-side pagination
          _totalItems = response.paging?.item.total ?? _schedules.length;
          _totalPages = _totalItems > 0
              ? ((_totalItems - 1) ~/ _itemsPerPage) + 1
              : 1;

          // Ensure current page is valid
          if (_currentPage > _totalPages) {
            _currentPage = _totalPages;
          }
          if (_currentPage < 1) {
            _currentPage = 1;
          }

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
        _errorMessage = 'Failed to load schedules: $e';
        _isLoading = false;
      });
    }
  }

  List<Schedule> _applyFilters(List<Schedule> schedules) {
    var filtered = schedules;

    if (_selectedStatus != null) {
      filtered = filtered
          .where((schedule) => schedule.displayStatus == _selectedStatus)
          .toList();
    }

    if (_selectedTargetType != null) {
      filtered = filtered
          .where(
            (schedule) => schedule.displayTargetType == _selectedTargetType,
          )
          .toList();
    }

    return filtered;
  }

  List<Schedule> _getPaginatedSchedules() {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;

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

  void _updatePaginationTotals() {
    _totalItems = _filteredSchedules.length;
    _totalPages = _totalItems > 0
        ? ((_totalItems - 1) ~/ _itemsPerPage) + 1
        : 1;

    // Ensure current page is valid
    if (_currentPage > _totalPages) {
      _currentPage = _totalPages;
    }
    if (_currentPage < 1) {
      _currentPage = 1;
    }
  }

  Widget _buildErrorMessage() {
    if (_errorMessage.isEmpty) return const SizedBox.shrink();

    // Show full-screen error state if no schedules and there's an error
    if (_schedules.isEmpty) {
      return AppLottieStateWidget.error(
        title: 'Failed to Load Schedules',
        message: _errorMessage,
        buttonText: 'Try Again',
        onButtonPressed: _loadSchedules,
      );
    }

    // Show compact error banner if schedules exist but there was an error
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
            onPressed: _loadSchedules,
            icon: const Icon(Icons.refresh, color: AppColors.error),
            tooltip: 'Retry',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildMainContent(context);
  }

  Widget _buildMainContent(BuildContext context) {
    // Show full-screen error state if no schedules and there's an error
    if (_errorMessage.isNotEmpty && _schedules.isEmpty) {
      return _buildErrorMessage();
    }

    return Column(
      children: [
        SizedBox(height: AppSizes.spacing12),
        // Summary card with padding
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
          child: ScheduleSummaryCard(schedules: _filteredSchedules),
        ),

        const SizedBox(height: AppSizes.spacing8),

        // Filters and actions with padding
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
          child: ScheduleFiltersAndActionsV2(
            onSearchChanged: _onSearchChanged,
            onStatusFilterChanged: _onStatusFilterChanged,
            onTargetTypeFilterChanged: _onTargetTypeFilterChanged,
            onViewModeChanged: _onViewModeChanged,
            onAddSchedule: _showCreateDialog,
            onRefresh: _loadSchedules,
            onExport: _exportSchedules,
            onImport: _importSchedules,
            currentViewMode: _currentViewMode,
            selectedStatus: _selectedStatus,
            selectedTargetType: _selectedTargetType,
          ),
        ),

        const SizedBox(height: AppSizes.spacing8),

        // Error message with padding (compact banner for existing schedules)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
          child: _buildErrorMessage(),
        ),

        // Content based on view mode
        Expanded(child: _buildContent()),
        // Always show pagination area, even if empty (no padding)
        _buildPagination(),
      ],
    );
  }

  Widget _buildScheduleTable() {
    // Get the schedules for current page based on whether filters are applied
    final hasFilters = _selectedStatus != null || _selectedTargetType != null;
    final displaySchedules = hasFilters
        ? _getPaginatedSchedules()
        : _filteredSchedules;

    return BluNestDataTable<Schedule>(
      columns: ScheduleTableColumns.getBluNestColumns(
        onView: (schedule) => _showViewDialog(schedule),
        onEdit: (schedule) => _showEditDialog(schedule),
        onDelete: (schedule) => _showDeleteDialog(schedule),
        currentPage: _currentPage,
        itemsPerPage: _itemsPerPage,
        schedules: displaySchedules,
      ),
      data: displaySchedules,
      onRowTap: (schedule) => _showViewDialog(schedule),
      onEdit: (schedule) => _showEditDialog(schedule),
      onDelete: (schedule) => _showDeleteDialog(schedule),
      onView: (schedule) => _showViewDialog(schedule),
      enableMultiSelect: true,
      selectedItems: _selectedSchedules,
      onSelectionChanged: (selectedItems) {
        setState(() {
          _selectedSchedules = selectedItems;
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
      onSelectAllItems: _fetchAllSchedules,
    );
  }

  Widget _buildPagination() {
    // Use filtered schedules count when filters are applied, otherwise use API total
    final hasFilters = _selectedStatus != null || _selectedTargetType != null;
    final displayTotalItems = hasFilters
        ? _filteredSchedules.length
        : _totalItems;
    final displayTotalPages = displayTotalItems > 0
        ? ((displayTotalItems - 1) ~/ _itemsPerPage) + 1
        : 1;

    // Calculate display range based on filtered or unfiltered data
    final startItem = hasFilters
        ? ((_currentPage - 1) * _itemsPerPage + 1)
        : ((_currentPage - 1) * _itemsPerPage + 1);
    final endItem = hasFilters
        ? ((_currentPage * _itemsPerPage) > displayTotalItems
              ? displayTotalItems
              : _currentPage * _itemsPerPage)
        : ((_currentPage * _itemsPerPage) > _totalItems
              ? _totalItems
              : _currentPage * _itemsPerPage);

    return ResultsPagination(
      currentPage: _currentPage,
      totalPages: displayTotalPages,
      totalItems: displayTotalItems,
      itemsPerPage: _itemsPerPage,
      itemsPerPageOptions: const [5, 10, 20, 25, 50],
      startItem: startItem,
      endItem: endItem,
      onPageChanged: (page) {
        setState(() {
          _currentPage = page;
        });
        if (hasFilters) {
          // For filtered data, just update the page (client-side pagination)
          setState(() {});
        } else {
          // For unfiltered data, reload from server
          _loadSchedules();
        }
      },
      onItemsPerPageChanged: (newItemsPerPage) {
        setState(() {
          _itemsPerPage = newItemsPerPage;
          _currentPage = 1;
          _totalPages = _totalItems > 0
              ? ((_totalItems + _itemsPerPage - 1) ~/ _itemsPerPage)
              : 1;
        });
        _loadSchedules();
      },
      showItemsPerPageSelector: true,
    );
  }

  // CRUD Operations
  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => ScheduleFormDialog(
        onSuccess: () {
          _loadSchedules();
          AppToast.showSuccess(
            context,
            message: 'Schedule created successfully',
          );
        },
      ),
    );
  }

  void _showEditDialog(Schedule schedule) {
    showDialog(
      context: context,
      builder: (context) => ScheduleFormDialog(
        schedule: schedule,
        onSuccess: () {
          _loadSchedules();
          AppToast.showSuccess(
            context,
            message: 'Schedule updated successfully',
          );
        },
      ),
    );
  }

  void _showViewDialog(Schedule schedule) {
    showDialog(
      context: context,
      builder: (context) => ScheduleFormDialog(
        schedule: schedule,
        mode: 'view',
        onSuccess: () {
          _loadSchedules();
          AppToast.showSuccess(
            context,
            message: 'Schedule updated successfully',
          );
        },
      ),
    );
  }

  Future<void> _showDeleteDialog(Schedule schedule) async {
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

        await _loadSchedules();
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

  Future<List<Schedule>> _fetchAllSchedules() async {
    try {
      // Fetch all schedules without pagination
      final search = _searchController.text.isEmpty
          ? '%%'
          : '%${_searchController.text}%';

      final response = await _scheduleService.getSchedules(
        search: search,
        offset: 0,
        limit: 10000, // Large limit to get all items
      );

      if (response.success && response.data != null) {
        // Apply same filters as current view
        return _applyFilters(response.data!);
      } else {
        throw Exception(response.message ?? 'Failed to fetch all schedules');
      }
    } catch (e) {
      throw Exception('Error fetching all schedules: $e');
    }
  }

  void _updateFilteredPagination() {
    // For client-side filtering, calculate pagination based on filtered results
    final filteredTotal = _filteredSchedules.length;
    _totalPages = filteredTotal > 0
        ? ((filteredTotal - 1) ~/ _itemsPerPage) + 1
        : 1;

    // Ensure current page is valid for filtered results
    if (_currentPage > _totalPages) {
      _currentPage = _totalPages;
    }
    if (_currentPage < 1) {
      _currentPage = 1;
    }
  }

  void _onStatusFilterChanged(String? status) {
    setState(() {
      _selectedStatus = status;
      _filteredSchedules = _applyFilters(_schedules);
      // Update pagination for filtered results (client-side)
      _updateFilteredPagination();
    });
  }

  void _onTargetTypeFilterChanged(String? targetType) {
    setState(() {
      _selectedTargetType = targetType;
      _filteredSchedules = _applyFilters(_schedules);
      _updatePaginationTotals();
    });
  }

  void _onViewModeChanged(ScheduleViewMode mode) {
    setState(() {
      _currentViewMode = mode;
    });
  }

  void _exportSchedules() {
    // TODO: Implement export functionality
    AppToast.showInfo(
      context,
      title: 'Export',
      message: 'Export functionality coming soon',
    );
  }

  void _importSchedules() {
    // TODO: Implement import functionality
    AppToast.showInfo(
      context,
      title: 'Import',
      message: 'Import functionality coming soon',
    );
  }

  void _handleSort(String columnKey, bool ascending) {
    setState(() {
      _sortBy = columnKey;
      _sortAscending = ascending;
      _sortSchedules();
    });
  }

  void _sortSchedules() {
    if (_sortBy == null) return;

    _filteredSchedules.sort((a, b) {
      dynamic aValue;
      dynamic bValue;

      switch (_sortBy) {
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
      return _sortAscending ? comparison : -comparison;
    });
  }

  Widget _buildContent() {
    // Show loading state
    if (_isLoading && _schedules.isEmpty) {
      return AppLottieStateWidget.loading(
        title: 'Loading Schedules',
        titleColor: AppColors.primary,
        messageColor: AppColors.secondary,
        message: 'Please wait while we fetch your schedules...',
        lottieSize: 100,
      );
    }

    // Show no data state if no schedules after loading
    if (!_isLoading && _schedules.isEmpty && _errorMessage.isEmpty) {
      return AppLottieStateWidget.noData(
        title: 'No Schedules Found',
        message: '',
        buttonText: 'Add Schedule',
        titleColor: AppColors.primary,
        messageColor: AppColors.secondary,
        onButtonPressed: _showCreateDialog,
      );
    }

    // Show filtered empty state if filtered schedules are empty but original schedules exist
    if (!_isLoading && _filteredSchedules.isEmpty && _schedules.isNotEmpty) {
      return AppLottieStateWidget.noData(
        title: 'No Matching Schedules',
        message:
            'No schedules match your current filters. Try adjusting your search criteria.',
        buttonText: 'Clear Filters',
        onButtonPressed: _clearAllFilters,
      );
    }

    // Build content based on view mode
    return switch (_currentViewMode) {
      ScheduleViewMode.table => _buildTableView(),
      ScheduleViewMode.kanban => _buildKanbanView(),
    };
  }

  Widget _buildTableView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
      child: _buildScheduleTable(),
    );
  }

  Widget _buildKanbanView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
      child: ScheduleKanbanView(
        schedules: _getPaginatedSchedules(),
        onScheduleSelected: _showViewDialog,
        onScheduleView: _showViewDialog,
        onScheduleEdit: _showEditDialog,
        onScheduleDelete: _showDeleteDialog,
        isLoading: _isLoading,
        enablePagination: false,
        itemsPerPage: _itemsPerPage,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _clearAllFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedTargetType = null;
      _searchController.clear();
    });
    _onSearchChanged('');
  }
}
