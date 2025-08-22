import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/schedule.dart';
import '../../../core/services/schedule_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_confirm_dialog.dart';
import '../../widgets/common/app_input_field.dart';
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

class _ScheduleScreenState extends State<ScheduleScreen> with ResponsiveMixin {
  final TextEditingController _searchController = TextEditingController();
  ScheduleService? _scheduleService;
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
  bool _isInitialized = false; // Track if data has been loaded initially

  // View mode
  ScheduleViewMode _currentViewMode = ScheduleViewMode.table;

  // Filters
  String? _selectedStatus;
  String? _selectedTargetType;

  // Sorting
  String? _sortBy;
  bool _sortAscending = true;

  // Responsive UI state
  bool _summaryCardCollapsed = false;
  bool _isKanbanView = false;
  ScheduleViewMode?
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
    if (_scheduleService == null) {
      final serviceLocator = ServiceLocator();
      final apiService = serviceLocator.apiService;
      _scheduleService = ScheduleService(apiService);
    }

    // Only load data on first initialization, not on every dependency change (like screen resize)
    if (!_isInitialized) {
      _isInitialized = true;
      _loadSchedules();
      print('🚀 ScheduleScreen: Initial data load triggered');
    } else {
      print(
        '📱 ScheduleScreen: Dependencies changed (likely screen resize) - NO API call',
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
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
            _currentViewMode = ScheduleViewMode.kanban;
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
      '📱 ScheduleScreen: Responsive state updated (mobile: $isMobile, kanban: $_isKanbanView, view: $_currentViewMode) - UI ONLY, no API calls',
    );
  }

  void _onSearchChanged(String value) {
    // Cancel any existing timer
    _searchTimer?.cancel();

    // Update search query immediately for UI responsiveness
    _searchController.text = value;

    // Set a delay before triggering the API call
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _currentPage = 1; // Reset to first page when search changes
        });
        print('🔍 ScheduleScreen: Search triggered for: "$value"');
        _loadSchedules(); // Trigger API call after delay
      }
    });
  }

  Future<void> _loadSchedules() async {
    if (_scheduleService == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Pass search value directly without % wrapping
      final search = _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim();
      final offset = (_currentPage - 1) * _itemsPerPage;

      final response = await _scheduleService!.getSchedules(
        search: search,
        offset: offset,
        limit: _itemsPerPage,
      );

      if (response.success) {
        setState(() {
          _schedules = response.data ?? [];
          // For API-driven search, use the data directly without additional filtering
          _filteredSchedules = _schedules;

          // Use total count from API response for server-side pagination
          _totalItems = response.paging?.item.total ?? _schedules.length;
          _totalPages = _totalItems > 0
              ? ((_totalItems - 1) ~/ _itemsPerPage) + 1
              : 1;

          // Ensure current page is valid
          if (_currentPage > _totalPages && _totalPages > 0) {
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

        if (mounted) {
          AppToast.showError(
            context,
            error: Exception(response.message ?? 'Failed to load schedules'),
            title: 'Load Failed',
            errorContext: 'schedule_load',
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load schedules: $e';
        _isLoading = false;
      });

      if (mounted) {
        AppToast.showError(
          context,
          error: e,
          title: 'Load Failed',
          errorContext: 'schedule_load',
        );
      }
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
                // Summary Card FIRST (like seasons screen)
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
          ScheduleFiltersAndActionsV2(
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
      child: ScheduleSummaryCard(schedules: _filteredSchedules),
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
                        Icons.schedule,
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
                    child: ScheduleSummaryCard(schedules: _filteredSchedules),
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
        hintText: 'Search schedules...',
        //  controller: _searchController,
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
              _showCreateDialog();
              break;
            case 'refresh':
              _loadSchedules();
              break;
            case 'kanban':
              _onViewModeChanged(ScheduleViewMode.kanban);
              break;
            case 'table':
              _onViewModeChanged(ScheduleViewMode.table);
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
                Text('Add Schedule'),
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
                  color: _currentViewMode == ScheduleViewMode.kanban
                      ? AppColors.primary
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  'Kanban View',
                  style: TextStyle(
                    color: _currentViewMode == ScheduleViewMode.kanban
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
                  color: _currentViewMode == ScheduleViewMode.table
                      ? AppColors.primary
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  'Table View',
                  style: TextStyle(
                    color: _currentViewMode == ScheduleViewMode.table
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

  Widget _buildScheduleTable() {
    // Check if we have client-side filters applied
    final hasClientFilters =
        _selectedStatus != null || _selectedTargetType != null;
    final displaySchedules = hasClientFilters
        ? _getPaginatedSchedules() // Use client-side pagination for filtered data
        : _filteredSchedules; // Use API data directly

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
      totalItemsCount: hasClientFilters
          ? _filteredSchedules.length
          : _totalItems,
      onSelectAllItems: _fetchAllSchedules,
      emptyState: AppLottieStateWidget.noData(
        title: 'No Schedules',
        message: 'No schedules found for the current filter criteria.',
        lottieSize: 120,
      ),
    );
  }

  Widget _buildPagination() {
    // Check if we have client-side filters applied
    final hasClientFilters =
        _selectedStatus != null || _selectedTargetType != null;

    // Use appropriate total items and pages based on filter state
    final displayTotalItems = hasClientFilters
        ? _filteredSchedules.length
        : _totalItems;
    final displayTotalPages = hasClientFilters
        ? (displayTotalItems > 0
              ? ((_filteredSchedules.length - 1) ~/ _itemsPerPage) + 1
              : 1)
        : _totalPages;

    // Calculate display range
    final startItem = (_currentPage - 1) * _itemsPerPage + 1;
    final endItem = (_currentPage * _itemsPerPage) > displayTotalItems
        ? displayTotalItems
        : _currentPage * _itemsPerPage;

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
        if (hasClientFilters) {
          // For client-side filtered data, just update the page
          setState(() {});
        } else {
          // For API data, reload from server
          _loadSchedules();
        }
      },
      onItemsPerPageChanged: (newItemsPerPage) {
        setState(() {
          _itemsPerPage = newItemsPerPage;
          _currentPage = 1;
        });
        if (hasClientFilters) {
          // Recalculate pagination for filtered data
          _applyClientSideFilters();
        } else {
          // Reload from API with new page size
          _loadSchedules();
        }
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
    if (_scheduleService == null) return;

    try {
      // Direct API call without another confirmation dialog
      await _scheduleService!.deleteSchedule(
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
    if (_scheduleService == null) return [];

    try {
      // Fetch all schedules without pagination for the current search
      final search = _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim();

      final response = await _scheduleService!.getSchedules(
        search: search,
        offset: 0,
        limit: 10000, // Large limit to get all items
      );

      if (response.success && response.data != null) {
        // Apply same client-side filters as current view
        return _applyFilters(response.data!);
      } else {
        throw Exception(response.message ?? 'Failed to fetch all schedules');
      }
    } catch (e) {
      throw Exception('Error fetching all schedules: $e');
    }
  }

  void _onStatusFilterChanged(String? status) {
    setState(() {
      _selectedStatus = status;
      _currentPage = 1; // Reset to first page when filters change
    });
    // Note: For now, this is client-side until API supports status filtering
    // When API supports it, add status parameter to _loadSchedules()
    _applyClientSideFilters();
  }

  void _onTargetTypeFilterChanged(String? targetType) {
    setState(() {
      _selectedTargetType = targetType;
      _currentPage = 1; // Reset to first page when filters change
    });
    // Note: For now, this is client-side until API supports target type filtering
    // When API supports it, add targetType parameter to _loadSchedules()
    _applyClientSideFilters();
  }

  void _applyClientSideFilters() {
    setState(() {
      _filteredSchedules = _applyFilters(_schedules);

      // Update pagination for filtered results
      _totalItems = _filteredSchedules.length;
      _totalPages = _totalItems > 0
          ? ((_totalItems - 1) ~/ _itemsPerPage) + 1
          : 1;

      // Ensure current page is valid for filtered results
      if (_currentPage > _totalPages && _totalPages > 0) {
        _currentPage = _totalPages;
      }
      if (_currentPage < 1) {
        _currentPage = 1;
      }
    });
  }

  void _onViewModeChanged(ScheduleViewMode mode) {
    setState(() {
      _currentViewMode = mode;
      // Update kanban view state based on the new mode
      _isKanbanView = (mode == ScheduleViewMode.kanban);

      // If user manually changes view mode, reset mobile tracking
      if (MediaQuery.of(context).size.width >= 768) {
        _previousViewModeBeforeMobile = null;
      }
    });
    print(
      '🔄 ScheduleScreen: View mode changed to $mode (kanban: $_isKanbanView)',
    );
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
      return const Center(
        child: AppLottieStateWidget.loading(
          title: 'Loading Schedules',
          titleColor: AppColors.primary,
          messageColor: AppColors.textSecondary,
          message: 'Please wait while we fetch your schedules...',
          lottieSize: 80,
        ),
      );
    }

    // Show error state if no schedules and there's an error
    if (_errorMessage.isNotEmpty && _schedules.isEmpty) {
      return AppLottieStateWidget.error(
        title: 'Error Loading Schedules',
        message: _errorMessage,
        buttonText: 'Try Again',
        onButtonPressed: _loadSchedules,
      );
    }

    // Show no data state if no schedules after loading
    if (!_isLoading && _schedules.isEmpty && _errorMessage.isEmpty) {
      return AppLottieStateWidget.noData(
        title: 'No Schedules Found',
        message: 'Start by creating your first schedule.',
        buttonText: 'Add Schedule',
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

    return _buildViewContent();
  }

  Widget _buildViewContent() {
    return (_currentViewMode == ScheduleViewMode.table && !_isKanbanView)
        ? _buildTableView()
        : _buildKanbanView();
  }

  Widget _buildTableView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
      child: _buildScheduleTable(),
    );
  }

  Widget _buildKanbanView() {
    // Check if we have client-side filters applied
    final hasClientFilters =
        _selectedStatus != null || _selectedTargetType != null;
    final displaySchedules = hasClientFilters
        ? _getPaginatedSchedules() // Use client-side pagination for filtered data
        : _filteredSchedules; // Use API data directly

    if (_isLoading && _schedules.isEmpty) {
      return const Center(
        child: AppLottieStateWidget.loading(
          title: 'Loading Schedules',
          lottieSize: 80,
          message: 'Please wait while we fetch your schedules.',
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
      child: ScheduleKanbanView(
        schedules: displaySchedules,
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

  void _clearAllFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedTargetType = null;
      _searchController.clear();
      _currentPage = 1;
    });
    // Reload from API without search or filters
    _loadSchedules();
  }
}
