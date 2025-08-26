import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mdms_clone/presentation/widgets/common/app_input_field.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/app_lottie_state_widget.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_confirm_dialog.dart';
import '../../widgets/common/blunest_data_table.dart';
import '../../widgets/common/results_pagination.dart';
import '../../widgets/common/kanban_view.dart';
import '../../widgets/special_days/special_day_filters_and_actions_v2.dart';
import '../../widgets/special_days/special_day_form_dialog.dart';
import '../../widgets/special_days/special_day_table_columns.dart';
import '../../widgets/special_days/special_day_summary_card.dart';
import '../../widgets/special_days/special_day_kanban_adapter.dart';
import '../../themes/app_theme.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/models/special_day.dart';
import '../../../core/services/special_day_service.dart';
import '../../../core/utils/responsive_helper.dart';

class SpecialDaysScreen extends StatefulWidget {
  final Function(List<String>)? onBreadcrumbUpdate;

  const SpecialDaysScreen({super.key, this.onBreadcrumbUpdate});

  @override
  State<SpecialDaysScreen> createState() => _SpecialDaysScreenState();
}

class _SpecialDaysScreenState extends State<SpecialDaysScreen>
    with ResponsiveMixin {
  late SpecialDayService _specialDayService;

  // State management - SERVER-SIDE PAGINATION
  List<SpecialDay> _specialDays = [];
  Set<SpecialDay> _selectedSpecialDays = {};

  bool _isLoading = false;
  String _errorMessage = '';
  bool _isInitialized = false; // Track if data has been loaded initially

  // Pagination - SERVER-SIDE
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  int _itemsPerPage = 25;

  // Filtering & Search - REAL-TIME API
  String _searchQuery = '';
  String? _selectedStatus;
  bool _showActiveOnly = false;

  // View Mode
  SpecialDayViewMode _currentViewMode = SpecialDayViewMode.table;

  bool _summaryCardCollapsed = false;
  bool _isKanbanView = false;
  final TextEditingController _searchController = TextEditingController();

  // Search delay timer
  Timer? _searchTimer;

  // Sorting - SERVER-SIDE
  String? _sortBy;
  bool _sortAscending = true;

  // Table Configuration
  final List<String> _availableColumns = [
    'No.',
    'Name',
    'Description',
    'Special Day Details',
    'Status',
    'Actions',
  ];
  List<String> _hiddenColumns = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _specialDayService = Provider.of<SpecialDayService>(context, listen: false);

    // Only load data on first initialization, not on every dependency change (like screen resize)
    if (!_isInitialized) {
      _isInitialized = true;
      _loadSpecialDays();
      print('🚀 SpecialDaysScreen: Initial data load triggered');
    } else {
      print(
        '📱 SpecialDaysScreen: Dependencies changed (likely screen resize) - NO API call',
      );
    }
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
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
    if (isMobile && !_summaryCardCollapsed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _summaryCardCollapsed = true; // Default to collapsed on mobile
          });
        }
      });
    }

    // Auto-expand summary card on desktop
    if (!isMobile && !isTablet && _summaryCardCollapsed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _summaryCardCollapsed = false; // Default to expanded on desktop
          });
        }
      });
    }

    // Auto-switch to kanban view on mobile
    if (isMobile && !_isKanbanView) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isKanbanView = true;
          });
        }
      });
    }

    // Auto-switch back to table view on desktop (optional)
    if (!isMobile && _isKanbanView) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isKanbanView = false;
          });
        }
      });
    }

    print(
      '📱 SpecialDaysScreen: Responsive state updated (mobile: $isMobile) - UI ONLY, no API calls',
    );
  }

  // Event Handlers - REAL-TIME API TRIGGERS
  // Search Event Handler - with delay to avoid excessive API calls
  void _onSearchChanged(String query) {
    // Cancel any existing timer
    _searchTimer?.cancel();

    // Update search query immediately for UI responsiveness
    setState(() {
      _searchQuery = query;
    });

    // Set a delay before triggering the API call
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _currentPage = 1; // Reset to first page when search changes
        });
        print(
          '🔍 SpecialDaysScreen: Search triggered for: "$query" (formatted: "%$query%")',
        );
        _loadSpecialDays(); // Trigger API call after delay
      }
    });
  }

  void _onStatusFilterChanged(String? status) {
    bool shouldReload = false;
    bool newShowActiveOnly = status?.toLowerCase() == 'active';

    if (_showActiveOnly != newShowActiveOnly) {
      setState(() {
        _showActiveOnly = newShowActiveOnly;
        _selectedStatus = status;
        _currentPage = 1; // Reset to first page
      });
      shouldReload = true;
    }

    if (shouldReload) {
      _loadSpecialDays(); // Trigger API call immediately
    }
  }

  void _onViewModeChanged(SpecialDayViewMode mode) {
    setState(() {
      _currentViewMode = mode;
    });
  }

  void _applySorting() {
    if (_sortBy == null || _specialDays.isEmpty) return;

    setState(() {
      _specialDays.sort((a, b) {
        int comparison = 0;

        switch (_sortBy) {
          case 'name':
            comparison = a.name.compareTo(b.name);
            break;
          case 'description':
            comparison = a.description.compareTo(b.description);
            break;
          case 'active':
            comparison = a.active.toString().compareTo(b.active.toString());
            break;
          default:
            comparison = 0;
        }

        return _sortAscending ? comparison : -comparison;
      });
    });
  }

  // Sorting Event Handler - triggers API call
  void _handleSort(String sortField, bool ascending) {
    setState(() {
      _sortBy = sortField;
      _sortAscending = ascending;
    });
    print(
      '🔄 SpecialDaysScreen: Sort changed to $sortField (ascending: $ascending)',
    );
    _loadSpecialDays(); // Reload data with new sort
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _loadSpecialDays(); // Trigger API call for new page
  }

  void _onItemsPerPageChanged(int itemsPerPage) {
    setState(() {
      _itemsPerPage = itemsPerPage;
      _currentPage = 1; // Reset to first page
    });
    _loadSpecialDays(); // Trigger API call with new page size
  }

  void _onSpecialDaySelected(SpecialDay specialDay) {
    // Show view dialog
    _viewSpecialDayDetails(specialDay);
  }

  void _viewSpecialDayDetails(SpecialDay specialDay) {
    showDialog(
      context: context,
      builder: (context) => SpecialDayFormDialog(
        specialDay: specialDay,
        mode: SpecialDayDialogMode.view,
        onSave: (updatedSpecialDay) {
          // Handle update logic here
          _handleUpdateSpecialDay(updatedSpecialDay);
        },
        onSuccess: () {
          _loadSpecialDays();
        },
      ),
    );
  }

  // Data loading and processing - REAL-TIME API CALLS
  Future<void> _loadSpecialDays() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print(
        '🔄 SpecialDaysScreen: Loading special days (page: $_currentPage, search: "$_searchQuery", formatted: "${_searchQuery.isNotEmpty ? '%$_searchQuery%' : '%%'}")',
      );

      final response = await _specialDayService.getSpecialDays(
        search: _searchQuery.isNotEmpty ? '%$_searchQuery%' : '%%',
        offset: (_currentPage - 1) * _itemsPerPage,
        limit: _itemsPerPage,
      );

      if (response.success && response.data != null) {
        setState(() {
          _specialDays = response.data!;
          // Get total from pagination info, fallback to data length if not available
          _totalItems = response.paging?.item.total ?? response.data!.length;
          _totalPages = _totalItems > 0
              ? ((_totalItems - 1) ~/ _itemsPerPage) + 1
              : 1;
          _isLoading = false;
        });

        // Apply any existing sorting
        _applySorting();

        print(
          '✅ SpecialDaysScreen: Loaded ${_specialDays.length} special days (total: $_totalItems)',
        );
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Failed to load special days';
          _isLoading = false;
        });
        print('❌ SpecialDaysScreen: Load failed: $_errorMessage');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading special days: $e';
        _isLoading = false;
      });
      print('❌ SpecialDaysScreen: Exception loading special days: $e');
    }
  }

  // CRUD Operations - with API triggers
  void _createSpecialDay() {
    showDialog(
      context: context,
      builder: (context) => SpecialDayFormDialog(
        onSave: _handleCreateSpecialDay,
        onSuccess: _loadSpecialDays,
      ),
    );
  }

  void _editSpecialDay(SpecialDay specialDay) {
    showDialog(
      context: context,
      builder: (context) => SpecialDayFormDialog(
        specialDay: specialDay,
        onSave: _handleUpdateSpecialDay,
        onSuccess: _loadSpecialDays,
      ),
    );
  }

  Future<void> _handleCreateSpecialDay(SpecialDay specialDay) async {
    try {
      print('🔄 SpecialDaysScreen: Creating special day: ${specialDay.name}');
      final response = await _specialDayService.createSpecialDay(specialDay);

      if (!response.success) {
        throw Exception(response.message ?? 'Failed to create special day');
      }

      print('✅ SpecialDaysScreen: Special day created successfully');
    } catch (e) {
      print('❌ SpecialDaysScreen: Error creating special day: $e');
      rethrow;
    }
  }

  Future<void> _handleUpdateSpecialDay(SpecialDay specialDay) async {
    try {
      print('🔄 SpecialDaysScreen: Updating special day: ${specialDay.name}');
      final response = await _specialDayService.updateSpecialDay(specialDay);

      if (!response.success) {
        throw Exception(response.message ?? 'Failed to update special day');
      }

      print('✅ SpecialDaysScreen: Special day updated successfully');
    } catch (e) {
      print('❌ SpecialDaysScreen: Error updating special day: $e');
      rethrow;
    }
  }

  Future<void> _deleteSpecialDay(SpecialDay specialDay) async {
    print(
      '🗑️ Delete special day called for: ${specialDay.name} (ID: ${specialDay.id})',
    );

    final confirm = await AppConfirmDialog.show(
      context,
      title: 'Delete Special Day',
      message:
          'Are you sure you want to delete "${specialDay.name}"? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      confirmType: AppButtonType.danger,
      icon: Icons.delete_outline,
    );

    print('🗑️ Delete confirmation result: $confirm');

    if (confirm == true) {
      print(
        '🗑️ Starting delete operation for special day ID: ${specialDay.id}',
      );

      setState(() {
        _isLoading = true;
      });

      try {
        print('🗑️ Calling API delete service...');
        final response = await _specialDayService.deleteSpecialDay(
          specialDay.id,
        );

        print(
          '🗑️ Delete API response: success=${response.success}, message=${response.message}',
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          if (response.success) {
            print('🗑️ Delete successful, showing success toast');
            AppToast.showSuccess(
              context,
              title: 'Special Day Deleted',
              message:
                  'Special day "${specialDay.name}" has been successfully deleted.',
            );

            //  print('🗑️ Reloading special days list...');
            await _loadSpecialDays();

            // // Close sidebar if this special day was selected
            // if (_selectedSpecialDayForDetails?.id == specialDay.id) {
            //   print('🗑️ Closing sidebar as deleted item was selected');
            //   _onSidebarClosed();
            // }
          } else {
            // print('🗑️ Delete failed, showing error toast');
            AppToast.showError(
              context,
              error: response.message ?? 'Failed to delete special day',
              title: 'Delete Failed',
              errorContext: 'special_day_delete',
            );
          }
        }
      } catch (e) {
        //  print('🗑️ Delete operation threw exception: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          AppToast.showError(
            context,
            error: 'Network error: Please check your connection',
            title: 'Connection Error',
            errorContext: 'special_day_delete_network',
          );
        }
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadSpecialDays();
  }

  Future<List<SpecialDay>> _fetchAllSpecialDays() async {
    try {
      // Fetch all special days without pagination
      final response = await _specialDayService.getSpecialDays(
        search: _searchQuery.isNotEmpty ? '%$_searchQuery%' : '%%',
        offset: 0,
        limit: 10000, // Large limit to get all items
      );

      if (response.success && response.data != null) {
        // Apply same filters as current view
        List<SpecialDay> filtered = List.from(response.data!);

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          filtered = filtered.where((specialDay) {
            return specialDay.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                specialDay.description.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );
          }).toList();
        }

        return filtered;
      } else {
        throw Exception(response.message ?? 'Failed to fetch all special days');
      }
    } catch (e) {
      throw Exception('Error fetching all special days: $e');
    }
  }

  Widget _buildContent() {
    // Show full-screen loading only if no data exists yet
    if (_isLoading && _specialDays.isEmpty) {
      return const Center(
        child: AppLottieStateWidget.loading(
          title: 'Loading Special Days',
          lottieSize: 80,
          message: 'Please wait while we fetch your special days.',
        ),
      );
    }

    if (_errorMessage.isNotEmpty && _specialDays.isEmpty) {
      return AppLottieStateWidget.error(
        title: 'Error Loading Special Days',
        message: _errorMessage,
        buttonText: 'Try Again',
        onButtonPressed: _loadSpecialDays,
      );
    }

    if (_specialDays.isEmpty && !_isLoading) {
      return AppLottieStateWidget.noData(
        title: _searchQuery.isNotEmpty ? 'No Results Found' : 'No Special Days',
        message: _searchQuery.isNotEmpty
            ? 'No special days match your search criteria.'
            : 'Start by creating your first special day.',
        buttonText: 'Create Special Day',
        onButtonPressed: _createSpecialDay,
      );
    }

    return _buildViewContent();
  }

  Widget _buildViewContent() {
    return (_currentViewMode == SpecialDayViewMode.table && !_isKanbanView)
        ? Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacing16,
              vertical: AppSizes.spacing8,
            ),
            child: _buildTableView(),
          )
        : _buildKanbanView();
  }

  Widget _buildTableView() {
    return BluNestDataTable<SpecialDay>(
      columns: _buildTableColumns(),
      data: _specialDays,
      isLoading: _isLoading,
      onSort: _handleSort,
      sortBy: _sortBy,
      sortAscending: _sortAscending,
      selectedItems: _selectedSpecialDays,
      onSelectionChanged: (selection) {
        setState(() {
          _selectedSpecialDays = selection;
        });
      },
      onRowTap: _onSpecialDaySelected,
      enableMultiSelect: true,
      hiddenColumns: _hiddenColumns,
      onColumnVisibilityChanged: (hiddenColumns) {
        setState(() {
          _hiddenColumns = hiddenColumns;
        });
      },
      totalItemsCount: _totalItems,
      onSelectAllItems: _fetchAllSpecialDays,
      emptyState: AppLottieStateWidget.noData(
        title: 'No Special Days',
        message: 'No special days found for the current filter criteria.',
        lottieSize: 120,
      ),
    );
  }

  List<BluNestTableColumn<SpecialDay>> _buildTableColumns() {
    return SpecialDayTableColumns.buildBluNestColumns(
      context: context,
      visibleColumns: _availableColumns
          .where((col) => !_hiddenColumns.contains(col))
          .toList(),
      sortBy: _sortBy,
      sortAscending: _sortAscending,
      onSort: _handleSort,
      onEdit: _editSpecialDay,
      onDelete: _deleteSpecialDay,
      onView: _onSpecialDaySelected,
      currentPage: _currentPage,
      itemsPerPage: _itemsPerPage,
      specialDays: _specialDays,
    );
  }

  Widget _buildKanbanView() {
    if (_isLoading && _specialDays.isEmpty) {
      return const Center(
        child: AppLottieStateWidget.loading(
          title: 'Loading Special Days',
          lottieSize: 80,
          message: 'Please wait while we fetch your special days.',
        ),
      );
    }

    final kanbanItems = _specialDays
        .map((specialDay) => SpecialDayKanbanItem(specialDay, context))
        .toList();

    return KanbanView<SpecialDayKanbanItem>(
      items: kanbanItems,
      columns: SpecialDayKanbanConfig.columns,
      actions: SpecialDayKanbanConfig.getActions(
        context: context,
        onView: _onSpecialDaySelected,
        onEdit: _editSpecialDay,
        onDelete: _deleteSpecialDay,
        onManageDetails: _onSpecialDaySelected,
      ),
      onItemTap: (item) => _onSpecialDaySelected(item.specialDay),
      isLoading: _isLoading,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Summary Card FIRST (like devices/sites screens)
            if (isMobile)
              _buildCollapsibleSummaryCard()
            else
              _buildDesktopSummaryCard(),
            // Header/Filters AFTER summary card
            if (isMobile) _buildMobileHeader() else _buildDesktopHeader(),
            // Content
            Expanded(
              child: Container(width: double.infinity, child: _buildContent()),
            ),
            // Pagination - direct call like other screens
            Container(width: double.infinity, child: _buildPagination()),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
      child: SpecialDayFiltersAndActionsV2(
        onSearchChanged: _onSearchChanged,
        onStatusFilterChanged: _onStatusFilterChanged,
        onViewModeChanged: _onViewModeChanged,
        onAddSpecialDay: _createSpecialDay,
        onRefresh: _refreshData,
        currentViewMode: _currentViewMode,
        selectedStatus: _selectedStatus,
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
      child: SpecialDaySummaryCard(specialDays: _specialDays),
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
          height: AppSizes.cardMobile,
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.surfaceColor, //AppColors.surface,
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
                        Icons.event_note,
                        color: context.primaryColor,
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
                                color: context.textPrimaryColor,
                                fontSize: headerFontSize,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _summaryCardCollapsed = !_summaryCardCollapsed;
                          });
                        },
                        icon: Icon(
                          _summaryCardCollapsed
                              ? Icons.expand_more
                              : Icons.expand_less,
                          color: context.textSecondaryColor,
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
                    child: SpecialDaySummaryCard(
                      specialDays: _specialDays,
                      isCompact: isMobile,
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
        alignment:
            Alignment.centerLeft, // Fixed height to prevent constraint issues
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacing16,
          vertical: AppSizes.spacing8,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.spacing8),
          color: context.surfaceColor,
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
      child: Expanded(
        flex: 1,
        child: AppInputField.search(
          hintText: 'Search special days...',
          controller: _searchController,
          onChanged: _onSearchChanged,
          prefixIcon: const Icon(Icons.search, size: AppSizes.iconSmall),
          enabled: true,
        ),
      ),
    );
  }

  Widget _buildMobileMoreActionsButton() {
    return Container(
      height: 36,
      width: 36,
      decoration: BoxDecoration(
        color: context.primaryColor,
        borderRadius: BorderRadius.circular(AppSizes.spacing8),
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
        onSelected: (value) {
          switch (value) {
            case 'add':
              _createSpecialDay();
              break;
            case 'refresh':
              _refreshData();
              break;
            case 'kanban':
              _onViewModeChanged(SpecialDayViewMode.kanban);
              break;
            case 'table':
              _onViewModeChanged(SpecialDayViewMode.table);
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
                Text('Add Special Day'),
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
                  color: _currentViewMode == SpecialDayViewMode.kanban
                      ? context.primaryColor
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  'Kanban View',
                  style: TextStyle(
                    color: _currentViewMode == SpecialDayViewMode.kanban
                        ? context.primaryColor
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
                  color: _currentViewMode == SpecialDayViewMode.table
                      ? context.primaryColor
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  'Table View',
                  style: TextStyle(
                    color: _currentViewMode == SpecialDayViewMode.table
                        ? context.primaryColor
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

  Widget _buildPagination() {
    final startItem = ((_currentPage - 1) * _itemsPerPage) + 1;
    final endItem = ((_currentPage - 1) * _itemsPerPage + _itemsPerPage).clamp(
      0,
      _totalItems,
    );

    return ResultsPagination(
      currentPage: _currentPage,
      totalPages: _totalPages,
      itemsPerPage: _itemsPerPage,
      totalItems: _totalItems,
      startItem: startItem,
      endItem: endItem,
      onPageChanged: _onPageChanged,
      onItemsPerPageChanged: _onItemsPerPageChanged,
      showItemsPerPageSelector: true,
      itemsPerPageOptions: const [5, 10, 20, 50, 100],
    );
  }
}
