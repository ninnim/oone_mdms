import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/time_of_use.dart';
import '../../../core/services/time_of_use_service.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_confirm_dialog.dart';
import '../../widgets/common/app_input_field.dart';
import '../../widgets/common/app_lottie_state_widget.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/common/blunest_data_table.dart';
import '../../widgets/common/results_pagination.dart';
import '../../widgets/time_of_use/time_of_use_form_dialog.dart';
import '../../widgets/time_of_use/time_of_use_table_columns.dart';
import '../../widgets/time_of_use/time_of_use_filters_and_actions_v2.dart';
import '../../widgets/time_of_use/time_of_use_kanban_view.dart';
import '../../themes/app_theme.dart';

class TimeOfUseScreen extends StatefulWidget {
  const TimeOfUseScreen({super.key});

  @override
  State<TimeOfUseScreen> createState() => _TimeOfUseScreenState();
}

class _TimeOfUseScreenState extends State<TimeOfUseScreen>
    with ResponsiveMixin {
  TimeOfUseService? _timeOfUseService;

  // Data state
  bool _isLoading = false;
  List<TimeOfUse> _timeOfUseList = [];
  Set<TimeOfUse> _selectedTimeOfUse = {};
  String _errorMessage = '';
  bool _isInitialized = false; // Track if data has been loaded initially

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  int _itemsPerPage = 25;

  // View and filter state
  TimeOfUseViewMode _currentView = TimeOfUseViewMode.table;
  String _searchQuery = '';
  List<String> _hiddenColumns = [];

  // Responsive UI state
  bool _summaryCardCollapsed = false;
  bool _isKanbanView = false;
  TimeOfUseViewMode?
  _previousViewModeBeforeMobile; // Track previous view mode before mobile switch
  bool?
  _previousSummaryStateBeforeMobile; // Track previous summary state before mobile switch
  final TextEditingController _searchController = TextEditingController();

  // Search delay timer
  Timer? _searchTimer;

  // Sorting state
  String? _sortBy;
  bool _sortAscending = true;

  void _toggleSummaryCard() {
    print(
      '🔽 TimeOfUseScreen: Manual summary card toggle - current: $_summaryCardCollapsed',
    );
    setState(() {
      _summaryCardCollapsed = !_summaryCardCollapsed;
      // Reset the mobile tracking to prevent responsive logic from overriding manual changes
      _previousSummaryStateBeforeMobile = null;
    });
    print(
      '🔽 TimeOfUseScreen: Summary card manually toggled to: $_summaryCardCollapsed',
    );
  }

  @override
  void handleResponsiveStateChange() {
    if (!mounted) return;

    final mediaQuery = MediaQuery.of(context);
    final isMobile = mediaQuery.size.width < 768;
    final isTablet =
        mediaQuery.size.width >= 768 && mediaQuery.size.width < 1024;

    print(
      '📱 TimeOfUseScreen: Responsive check (mobile: $isMobile, kanban: $_isKanbanView, view: $_currentView, prevMode: $_previousViewModeBeforeMobile)',
    );

    // Auto-collapse summary card on mobile, keep visible but allow toggle
    if (isMobile && !_summaryCardCollapsed) {
      // Save previous summary state before collapsing for mobile
      if (_previousSummaryStateBeforeMobile == null) {
        _previousSummaryStateBeforeMobile = _summaryCardCollapsed;
        print(
          '📱 TimeOfUseScreen: Saving summary state for mobile: $_summaryCardCollapsed',
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _summaryCardCollapsed = true; // Default to collapsed on mobile
            });
            print('📱 TimeOfUseScreen: Auto-collapsed summary card for mobile');
          }
        });
      }
    }

    // Auto-expand summary card on desktop - restore previous state
    if (!isMobile && !isTablet && _previousSummaryStateBeforeMobile != null) {
      final shouldExpand =
          _previousSummaryStateBeforeMobile == false ||
          (_previousSummaryStateBeforeMobile == null && _summaryCardCollapsed);
      if (shouldExpand) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _summaryCardCollapsed =
                  _previousSummaryStateBeforeMobile ?? false;
              _previousSummaryStateBeforeMobile = null; // Reset tracking
            });
            print('📱 TimeOfUseScreen: Auto-expanded summary card for desktop');
          }
        });
      }
    }

    // Auto-switch to kanban view on mobile - ALWAYS force kanban on mobile
    if (isMobile &&
        (!_isKanbanView || _currentView != TimeOfUseViewMode.kanban)) {
      // Save previous view mode before switching to mobile kanban
      if (_previousViewModeBeforeMobile == null &&
          _currentView != TimeOfUseViewMode.kanban) {
        _previousViewModeBeforeMobile = _currentView;
        print(
          '📱 TimeOfUseScreen: Saved previous view mode: $_previousViewModeBeforeMobile',
        );
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isKanbanView = true;
            _currentView = TimeOfUseViewMode.kanban;
          });
          print('📱 TimeOfUseScreen: AUTO-SWITCHED to kanban for mobile');
        }
      });
    }

    // Auto-switch back to previous view mode on desktop
    if (!isMobile && _isKanbanView && _previousViewModeBeforeMobile != null) {
      final restoreViewMode = _previousViewModeBeforeMobile!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isKanbanView = (restoreViewMode == TimeOfUseViewMode.kanban);
            _currentView = restoreViewMode;
            _previousViewModeBeforeMobile = null; // Reset tracking
          });
          print(
            '📱 TimeOfUseScreen: AUTO-SWITCHED back to $restoreViewMode for desktop',
          );
        }
      });
    }

    print(
      '📱 TimeOfUseScreen: Responsive state updated (mobile: $isMobile, kanban: $_isKanbanView, view: $_currentView) - UI ONLY, no API calls',
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timeOfUseService ??= Provider.of<TimeOfUseService>(context, listen: false);

    // Only load data on first initialization, not on every dependency change (like screen resize)
    if (!_isInitialized) {
      _isInitialized = true;
      _loadTimeOfUse();
      print('🚀 TimeOfUseScreen: Initial data load triggered');
    } else {
      print(
        '📱 TimeOfUseScreen: Dependencies changed (likely screen resize) - NO API call',
      );
    }
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTimeOfUse() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print(
        '🔄 TimeOfUseScreen: Loading time of use (page: $_currentPage, search: "$_searchQuery", formatted: "${_searchQuery.isNotEmpty ? '%$_searchQuery%' : '%%'}")',
      );

      final response = await _timeOfUseService!.getTimeOfUse(
        search: _searchQuery.isEmpty ? '' : _searchQuery,
        offset: (_currentPage - 1) * _itemsPerPage,
        limit: _itemsPerPage,
      );

      if (response.success && response.data != null) {
        if (mounted) {
          setState(() {
            _timeOfUseList = response.data!;
            _totalItems = response.paging?.item.total ?? 0;
            _totalPages = (_totalItems / _itemsPerPage).ceil();
            _isLoading = false;
          });
          print(
            '✅ TimeOfUseScreen: Loaded ${_timeOfUseList.length} time of use items (total: $_totalItems)',
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = response.message ?? 'Failed to load time of use';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading time of use: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  // Method to fetch all items for selection
  Future<List<TimeOfUse>> _fetchAllTimeOfUseItems() async {
    try {
      final response = await _timeOfUseService!.getTimeOfUse(
        search: _searchQuery.isEmpty ? '' : _searchQuery,
        offset: 0,
        limit: 10000, // Large limit to get all items
      );

      if (response.success && response.data != null) {
        print(
          '✅ TimeOfUseScreen: Fetched ${response.data!.length} items for selection',
        );
        return response.data!;
      } else {
        throw Exception(response.message ?? 'Failed to fetch all items');
      }
    } catch (e) {
      throw Exception('Error fetching all time of use items: $e');
    }
  }

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
          '🔍 TimeOfUseScreen: Search triggered for: "$query" (formatted: "%$query%")',
        );
        _loadTimeOfUse(); // Trigger API call after delay
      }
    });
  }

  void _handleSearch(String query) {
    _onSearchChanged(query);
  }

  void _handleViewModeChanged(TimeOfUseViewMode? viewMode) {
    if (viewMode != null) {
      final isMobile = MediaQuery.of(context).size.width < 768;

      print(
        '🔄 TimeOfUseScreen: View mode change requested to $viewMode (mobile: $isMobile, current: $_currentView)',
      );

      // On mobile, always force kanban mode regardless of user choice
      if (isMobile) {
        if (viewMode != TimeOfUseViewMode.kanban) {
          print(
            '📱 TimeOfUseScreen: Ignoring user choice on mobile - forcing kanban (user tried: $viewMode)',
          );
          // Don't change anything, mobile should stay in kanban
          return;
        }
        // If user explicitly chooses kanban on mobile, that's fine
        setState(() {
          _currentView = TimeOfUseViewMode.kanban;
          _isKanbanView = true;
          _selectedTimeOfUse.clear();
        });
        return;
      }

      // On desktop, allow free choice but remember it for responsive behavior
      setState(() {
        _currentView = viewMode;
        _isKanbanView = (viewMode == TimeOfUseViewMode.kanban);
        _selectedTimeOfUse.clear(); // Clear selection when changing view

        // Reset mobile tracking when user makes a manual choice on desktop
        // This ensures their choice becomes the new "previous" mode
        _previousViewModeBeforeMobile = null;
      });

      print(
        '🔄 TimeOfUseScreen: View mode changed to $viewMode (kanban: $_isKanbanView)',
      );
    }
  }

  void _handleSort(String sortBy) {
    setState(() {
      if (_sortBy == sortBy) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = sortBy;
        _sortAscending = true;
      }
      _currentPage = 1;
    });
    _loadTimeOfUse();
  }

  void _handleFiltersChanged(Map<String, dynamic> filters) {
    setState(() {
      _currentPage = 1;
    });
    _loadTimeOfUse();
  }

  Widget _buildPagination() {
    final startItem = _totalItems > 0
        ? ((_currentPage - 1) * _itemsPerPage) + 1
        : 0;
    final endItem = (_currentPage * _itemsPerPage).clamp(0, _totalItems);

    return ResultsPagination(
      currentPage: _currentPage,
      totalPages: _totalPages,
      totalItems: _totalItems,
      itemsPerPage: _itemsPerPage,
      // itemsPerPageOptions: const [5, 10, 20, 25, 50],
      startItem: startItem,
      endItem: endItem,
      onPageChanged: (page) {
        setState(() {
          _currentPage = page;
        });
        _loadTimeOfUse();
      },
      onItemsPerPageChanged: (newItemsPerPage) {
        setState(() {
          _itemsPerPage = newItemsPerPage;
          _currentPage = 1;
          _totalPages = _totalItems > 0
              ? ((_totalItems + _itemsPerPage - 1) ~/ _itemsPerPage)
              : 1;
        });
        _loadTimeOfUse();
      },
      showItemsPerPageSelector: true,
    );
  }

  Future<void> _createTimeOfUse() async {
    final result = await showDialog<bool>(
      barrierDismissible: false,
      context: context,
      builder: (context) => TimeOfUseFormDialog(
        onSaved: () {
          // Trigger immediate refresh via callback
          _loadTimeOfUse();
        },
      ),
    );

    if (result == true) {
      await _loadTimeOfUse();
    }
  }

  Future<void> _editTimeOfUse(TimeOfUse timeOfUse) async {
    final result = await showDialog<bool>(
      barrierDismissible: false,
      context: context,
      builder: (context) => TimeOfUseFormDialog(
        timeOfUse: timeOfUse,
        isReadOnly: false,
        onSaved: () {
          // Trigger immediate refresh via callback
          _loadTimeOfUse();
        },
      ),
    );

    if (result == true) {
      await _loadTimeOfUse();
    }
  }

  Future<void> _viewTimeOfUseDetails(TimeOfUse timeOfUse) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => TimeOfUseFormDialog(
        timeOfUse: timeOfUse,
        isReadOnly: true,
        onSaved: () {
          // Trigger immediate refresh via callback even when opened in view mode
          _loadTimeOfUse();
        },
      ),
    );

    if (result == true) {
      await _loadTimeOfUse();
    }
  }

  Future<void> _deleteTimeOfUse(TimeOfUse timeOfUse) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Delete Time of Use',
      message:
          'Are you sure you want to delete "${timeOfUse.name}"?\nThis action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      confirmType: AppButtonType.danger,
      icon: Icons.delete_outline,
    );

    if (confirmed == true) {
      await _performDeleteTimeOfUse(timeOfUse.id ?? 0);
    }
  }

  Future<void> _performDeleteTimeOfUse(int id) async {
    setState(() => _isLoading = true);

    try {
      final response = await _timeOfUseService?.deleteTimeOfUse(id);

      if (mounted) {
        if (response!.success) {
          AppToast.showSuccess(
            context,
            message: 'Time of use deleted successfully',
          );
          await _loadTimeOfUse();
        } else {
          setState(() => _isLoading = false);
          AppToast.showError(
            context,
            error: response.message ?? 'Failed to delete time of use',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.showError(context, error: 'Error deleting time of use: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isMobile = screenWidth < 768;

        return Scaffold(
          backgroundColor: context.backgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                // Summary Card FIRST (like time bands screen)
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

  Widget _buildDesktopSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacing16,
        vertical: AppSizes.spacing8,
      ),
      child: _buildSummaryCard(isCompact: isMobile || isTablet),
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
                        Icons.schedule_outlined,
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
                        onPressed: _toggleSummaryCard,
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
                    child: _buildSummaryCard(isCompact: isMobile || isTablet),
                  ),
                ),
            ],
          ),
        ),
      ),
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
          TimeOfUseFiltersAndActionsV2(
            onSearchChanged: _handleSearch,
            onViewModeChanged: _handleViewModeChanged,
            onAddTimeOfUse: _createTimeOfUse,
            onRefresh: _loadTimeOfUse,
            currentViewMode: _currentView,
            onFiltersChanged: _handleFiltersChanged,
            onExport: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export feature coming soon')),
              );
            },
          ),
          const SizedBox(height: AppSizes.spacing8),
        ],
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
      child: AppInputField.search(
        hintText: 'Search time of use...',
        controller: _searchController,
        onChanged: _handleSearch,
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
        color: context.primaryColor,
        borderRadius: BorderRadius.circular(AppSizes.spacing8),
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
        onSelected: (value) {
          switch (value) {
            case 'add':
              _createTimeOfUse();
              break;
            case 'refresh':
              _loadTimeOfUse();
              break;
            case 'kanban':
              _handleViewModeChanged(TimeOfUseViewMode.kanban);
              break;
            case 'table':
              _handleViewModeChanged(TimeOfUseViewMode.table);
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
                Text('Add Time of Use'),
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
                  color: _currentView == TimeOfUseViewMode.kanban
                      ? context.primaryColor
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  'Kanban View',
                  style: TextStyle(
                    color: _currentView == TimeOfUseViewMode.kanban
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
                  color: _currentView == TimeOfUseViewMode.table
                      ? context.primaryColor
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  'Table View',
                  style: TextStyle(
                    color: _currentView == TimeOfUseViewMode.table
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

  Widget _buildSummaryCard({bool isCompact = false}) {
    final activeTimeOfUse = _timeOfUseList.where((tou) => tou.active).length;
    final inactiveTimeOfUse = _timeOfUseList.where((tou) => !tou.active).length;
    final totalChannels = _timeOfUseList.fold<int>(
      0,
      (sum, tou) => sum + tou.timeOfUseDetails.length,
    );

    if (isCompact) {
      return _buildCompactSummaryCard(
        activeTimeOfUse: activeTimeOfUse,
        inactiveTimeOfUse: inactiveTimeOfUse,
        totalChannels: totalChannels,
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Time of Use',
              _totalItems.toString(),
              Icons.schedule_outlined,
              context.primaryColor,
            ),
          ),
          const SizedBox(width: AppSizes.spacing12),
          Expanded(
            child: _buildStatCard(
              'Active',
              activeTimeOfUse.toString(),
              Icons.check_circle_outline,
              context.successColor,
            ),
          ),
          const SizedBox(width: AppSizes.spacing12),
          Expanded(
            child: _buildStatCard(
              'Inactive',
              inactiveTimeOfUse.toString(),
              Icons.pause_circle_outline,
              context.errorColor,
            ),
          ),
          const SizedBox(width: AppSizes.spacing12),
          Expanded(
            child: _buildStatCard(
              'Total Channels',
              totalChannels.toString(),
              Icons.account_tree_outlined,
              context.infoColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSummaryCard({
    required int activeTimeOfUse,
    required int inactiveTimeOfUse,
    required int totalChannels,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildCompactStatCard(
              'Total',
              _totalItems.toString(),
              Icons.schedule_outlined,
              context.primaryColor,
            ),
          ),
          const SizedBox(width: AppSizes.spacing8),
          Expanded(
            child: _buildCompactStatCard(
              'Active',
              activeTimeOfUse.toString(),
              Icons.check_circle_outline,
              context.successColor,
            ),
          ),
          const SizedBox(width: AppSizes.spacing8),
          Expanded(
            child: _buildCompactStatCard(
              'Inactive',
              inactiveTimeOfUse.toString(),
              Icons.pause_circle_outline,
              context.errorColor,
            ),
          ),
          const SizedBox(width: AppSizes.spacing8),
          Expanded(
            child: _buildCompactStatCard(
              'Channels',
              totalChannels.toString(),
              Icons.account_tree_outlined,
              context.infoColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing8),
          Text(
            title,
            style: TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              color: context.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: AppSizes.spacing4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: AppSizes.fontSizeExtraSmall,
              color: context.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // Show full-screen loading only when no data exists yet
    if (_isLoading && _timeOfUseList.isEmpty) {
      return const AppLottieStateWidget.loading(
        // title: 'Loading Time of Use',
        // message:
        //     'Please wait while we fetch your time of use configurations...',
        lottieSize: 80,
      );
    }

    if (_errorMessage.isNotEmpty && _timeOfUseList.isEmpty) {
      return AppLottieStateWidget.error(
        title: 'Error Loading Time of Use',
        message: _errorMessage,
        buttonText: 'Try Again',
        onButtonPressed: _loadTimeOfUse,
      );
    }

    if (_timeOfUseList.isEmpty && !_isLoading) {
      return AppLottieStateWidget.noData(
        title: _searchQuery.isNotEmpty ? 'No Results Found' : 'No Time of Use',
        message: _searchQuery.isNotEmpty
            ? 'No time of use configurations match your search criteria.'
            : 'Start by creating your first time of use configuration.',
        buttonText: _searchQuery.isNotEmpty
            ? 'Clear Search'
            : 'Create Time of Use',
        onButtonPressed: _searchQuery.isNotEmpty
            ? () {
                setState(() => _searchQuery = '');
                _loadTimeOfUse();
              }
            : _createTimeOfUse,
      );
    }

    switch (_currentView) {
      case TimeOfUseViewMode.table:
        return _buildTableView();
      case TimeOfUseViewMode.kanban:
        return _buildKanbanView();
    }
  }

  Widget _buildTableView() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        boxShadow: [AppSizes.shadowSmall],
      ),
      child: BluNestDataTable<TimeOfUse>(
        data: _timeOfUseList,
        columns: TimeOfUseTableColumns.buildAllBluNestColumns(
          context: context,
          sortBy: _sortBy,
          sortAscending: _sortAscending,
          onEdit: _editTimeOfUse,
          onDelete: _deleteTimeOfUse,
          onView: _viewTimeOfUseDetails,
          currentPage: _currentPage,
          itemsPerPage: _itemsPerPage,
          data: _timeOfUseList,
        ),
        selectedItems: _selectedTimeOfUse,
        onSelectionChanged: (selectedItems) {
          setState(() {
            _selectedTimeOfUse = selectedItems;
          });
        },
        onRowTap: _viewTimeOfUseDetails,
        onSort: (String sortBy, bool ascending) => _handleSort(sortBy),
        sortBy: _sortBy,
        sortAscending: _sortAscending,
        enableMultiSelect: true,
        isLoading: _isLoading,
        hiddenColumns: _hiddenColumns,
        onColumnVisibilityChanged: (hiddenColumns) {
          setState(() {
            _hiddenColumns = hiddenColumns;
          });
        },
        // Enhanced selection parameters
        totalItemsCount: _totalItems,
        onSelectAllItems: _fetchAllTimeOfUseItems,
        emptyState: AppLottieStateWidget.noData(
          title: 'No Time of Use Found',
          message: _searchQuery.isNotEmpty
              ? 'No time of use configurations match your search criteria.'
              : 'Start by creating your first time of use configuration.',
          buttonText: _searchQuery.isNotEmpty
              ? 'Clear Search'
              : 'Create Time of Use',
          onButtonPressed: _searchQuery.isNotEmpty
              ? () {
                  setState(() => _searchQuery = '');
                  _loadTimeOfUse();
                }
              : _createTimeOfUse,
          lottieSize: 120,
        ),
      ),
    );
  }

  Widget _buildKanbanView() {
    return TimeOfUseKanbanView(
      timeOfUseList: _timeOfUseList,
      onItemTap: _viewTimeOfUseDetails,
      onItemEdit: _editTimeOfUse,
      onItemDelete: _deleteTimeOfUse,
      isLoading: _isLoading,
      searchQuery: _searchQuery,
    );
  }
}
