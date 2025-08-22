import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/time_band.dart';
import '../../../core/models/season.dart';
import '../../../core/models/special_day.dart';
import '../../../core/services/time_band_service.dart';
import '../../../core/services/season_service.dart';
import '../../../core/services/special_day_service.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_confirm_dialog.dart';
import '../../widgets/common/app_input_field.dart';
import '../../widgets/common/app_lottie_state_widget.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/common/blunest_data_table.dart';
import '../../widgets/common/results_pagination.dart';
import '../../widgets/time_bands/time_band_form_dialog_enhanced.dart';
import '../../widgets/time_bands/time_band_table_columns.dart';
import '../../widgets/time_bands/time_band_filters_and_actions_v2.dart';
import '../../widgets/time_bands/time_band_kanban_view.dart';

class TimeBandsScreen extends StatefulWidget {
  const TimeBandsScreen({super.key});

  @override
  State<TimeBandsScreen> createState() => _TimeBandsScreenState();
}

class _TimeBandsScreenState extends State<TimeBandsScreen>
    with ResponsiveMixin {
  TimeBandService? _timeBandService;
  SeasonService? _seasonService;
  SpecialDayService? _specialDayService;

  // Data state
  bool _isLoading = false;
  List<TimeBand> _timeBands = [];
  Set<TimeBand> _selectedTimeBands = {};
  String _errorMessage = '';

  // Available data for display
  List<Season> _availableSeasons = [];
  List<SpecialDay> _availableSpecialDays = [];

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  int _itemsPerPage = 25;

  // View and filter state
  TimeBandViewMode _currentView = TimeBandViewMode.table;
  String _searchQuery = '';
  List<String> _hiddenColumns = ['id', 'attributes', 'status'];

  // Responsive UI state
  bool _summaryCardCollapsed = false;
  bool _isKanbanView = false;
  TimeBandViewMode?
  _previousViewModeBeforeMobile; // Track previous view mode before mobile switch
  bool?
  _previousSummaryStateBeforeMobile; // Track previous summary state before mobile switch
  bool _isInitialized = false; // Track if data has been loaded initially
  final TextEditingController _searchController = TextEditingController();

  // Search delay timer
  Timer? _searchTimer;

  // Sorting state
  String? _sortBy;
  bool _sortAscending = true;

  void _toggleSummaryCard() {
    print(
      '🔽 TimeBandsScreen: Manual summary card toggle - current: $_summaryCardCollapsed',
    );
    setState(() {
      _summaryCardCollapsed = !_summaryCardCollapsed;
      // Reset the mobile tracking to prevent responsive logic from overriding manual changes
      _previousSummaryStateBeforeMobile = null;
    });
    print(
      '🔽 TimeBandsScreen: Summary card manually toggled to: $_summaryCardCollapsed',
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
      '📱 TimeBandsScreen: Responsive check (mobile: $isMobile, kanban: $_isKanbanView, view: $_currentView, prevMode: $_previousViewModeBeforeMobile)',
    );

    // Auto-collapse summary card on mobile, keep visible but allow toggle
    if (isMobile && !_summaryCardCollapsed) {
      // Save previous summary state before collapsing for mobile
      if (_previousSummaryStateBeforeMobile == null) {
        _previousSummaryStateBeforeMobile = _summaryCardCollapsed;
        print(
          '📱 TimeBandsScreen: Saving summary state for mobile: $_summaryCardCollapsed',
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _summaryCardCollapsed = true; // Default to collapsed on mobile
            });
            print('📱 TimeBandsScreen: Auto-collapsed summary card for mobile');
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
            print('📱 TimeBandsScreen: Auto-expanded summary card for desktop');
          }
        });
      }
    }

    // Auto-switch to kanban view on mobile - ALWAYS force kanban on mobile
    if (isMobile &&
        (!_isKanbanView || _currentView != TimeBandViewMode.kanban)) {
      // Save previous view mode before switching to mobile kanban
      if (_previousViewModeBeforeMobile == null &&
          _currentView != TimeBandViewMode.kanban) {
        _previousViewModeBeforeMobile = _currentView;
        print(
          '📱 TimeBandsScreen: Saved previous view mode: $_previousViewModeBeforeMobile',
        );
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isKanbanView = true;
            _currentView = TimeBandViewMode.kanban;
          });
          print('📱 TimeBandsScreen: AUTO-SWITCHED to kanban for mobile');
        }
      });
    }

    // Auto-switch back to previous view mode on desktop
    if (!isMobile && _isKanbanView && _previousViewModeBeforeMobile != null) {
      final restoreViewMode = _previousViewModeBeforeMobile!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isKanbanView = (restoreViewMode == TimeBandViewMode.kanban);
            _currentView = restoreViewMode;
            _previousViewModeBeforeMobile = null; // Reset tracking
          });
          print(
            '📱 TimeBandsScreen: AUTO-SWITCHED back to $restoreViewMode for desktop',
          );
        }
      });
    }

    print(
      '📱 TimeBandsScreen: Responsive state updated (mobile: $isMobile, kanban: $_isKanbanView, view: $_currentView) - UI ONLY, no API calls',
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timeBandService ??= Provider.of<TimeBandService>(context, listen: false);
    _seasonService ??= Provider.of<SeasonService>(context, listen: false);
    _specialDayService ??= Provider.of<SpecialDayService>(
      context,
      listen: false,
    );

    // Only load data on first initialization, not on every dependency change (like screen resize)
    if (!_isInitialized) {
      _isInitialized = true;
      _loadInitialData();
      print('🚀 TimeBandsScreen: Initial data load triggered');
    } else {
      print(
        '📱 TimeBandsScreen: Dependencies changed (likely screen resize) - NO API call',
      );
    }
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([_loadSeasons(), _loadSpecialDays(), _loadTimeBands()]);
  }

  Future<void> _loadSeasons() async {
    try {
      final response = await _seasonService!.getSeasons(limit: 100);
      if (response.success && response.data != null) {
        setState(() {
          _availableSeasons = response.data!;
        });
      }
    } catch (e) {
      print('Warning: Failed to load seasons: $e');
    }
  }

  Future<void> _loadSpecialDays() async {
    try {
      final response = await _specialDayService!.getSpecialDays(limit: 100);
      if (response.success && response.data != null) {
        setState(() {
          _availableSpecialDays = response.data!;
        });
      }
    } catch (e) {
      print('Warning: Failed to load special days: $e');
    }
  }

  Future<void> _loadTimeBands() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print(
        '🔄 TimeBandsScreen: Loading time bands (page: $_currentPage, search: "$_searchQuery", formatted: "${_searchQuery.isNotEmpty ? '%$_searchQuery%' : '%%'}")',
      );

      final response = await _timeBandService!.getTimeBands(
        search: _searchQuery.isNotEmpty ? '%$_searchQuery%' : '%%',
        offset: (_currentPage - 1) * _itemsPerPage,
        limit: _itemsPerPage,
      );

      if (mounted) {
        if (response.success && response.data != null) {
          setState(() {
            _timeBands = response.data!;
            _totalItems = response.paging?.item.total ?? 0;
            _totalPages = (_totalItems / _itemsPerPage).ceil();
            _isLoading = false;
          });

          print(
            '✅ TimeBandsScreen: Loaded ${_timeBands.length} time bands (total: $_totalItems)',
          );
        } else {
          setState(() {
            _errorMessage = response.message ?? 'Failed to load time bands';
            _isLoading = false;
          });
          print('❌ TimeBandsScreen: Load failed: $_errorMessage');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading time bands: $e';
          _isLoading = false;
        });
        print('❌ TimeBandsScreen: Exception loading time bands: $e');
      }
    }
  }

  void _applySorting() {
    if (_sortBy != null) {
      _timeBands.sort((a, b) {
        dynamic aValue, bValue;

        switch (_sortBy) {
          case 'name':
            aValue = a.name.toLowerCase();
            bValue = b.name.toLowerCase();
            break;
          case 'timeRange':
            aValue = a.startTime;
            bValue = b.startTime;
            break;
          case 'status':
            aValue = a.active ? 1 : 0;
            bValue = b.active ? 1 : 0;
            break;
          default:
            return 0;
        }

        int comparison = aValue.compareTo(bValue);
        return _sortAscending ? comparison : -comparison;
      });
    }
  }

  // Search Event Handler - with delay to avoid excessive API calls
  void _handleSearch(String query) {
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
          '🔍 TimeBandsScreen: Search triggered for: "$query" (formatted: "%$query%")',
        );
        _loadTimeBands(); // Trigger API call after delay
      }
    });
  }

  void _handleViewModeChanged(TimeBandViewMode? viewMode) {
    if (viewMode != null) {
      final isMobile = MediaQuery.of(context).size.width < 768;

      print(
        '🔄 TimeBandsScreen: View mode change requested to $viewMode (mobile: $isMobile, current: $_currentView)',
      );

      // On mobile, always force kanban mode regardless of user choice
      if (isMobile) {
        if (viewMode != TimeBandViewMode.kanban) {
          print(
            '📱 TimeBandsScreen: Ignoring user choice on mobile - forcing kanban (user tried: $viewMode)',
          );
          // Don't change anything, mobile should stay in kanban
          return;
        }
        // If user explicitly chooses kanban on mobile, that's fine
        setState(() {
          _currentView = TimeBandViewMode.kanban;
          _isKanbanView = true;
          _selectedTimeBands.clear();
        });
        return;
      }

      // On desktop, allow free choice but remember it for responsive behavior
      setState(() {
        _currentView = viewMode;
        _isKanbanView = (viewMode == TimeBandViewMode.kanban);
        _selectedTimeBands.clear(); // Clear selection when changing view

        // Reset mobile tracking when user makes a manual choice on desktop
        // This ensures their choice becomes the new "previous" mode
        _previousViewModeBeforeMobile = null;
      });

      print(
        '� TimeBandsScreen: View mode changed to $viewMode (kanban: $_isKanbanView)',
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
    });
    _applySorting();
    setState(() {}); // Trigger rebuild to show sorted data
  }

  void _handlePageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _loadTimeBands();
  }

  void _handlePageSizeChanged(int pageSize) {
    setState(() {
      _itemsPerPage = pageSize;
      _currentPage = 1; // Reset to first page when changing page size
    });
    _loadTimeBands();
  }

  void _handleFiltersChanged(Map<String, dynamic> filters) {
    setState(() {
      _currentPage = 1; // Reset to first page when filtering
    });
    _loadTimeBands();
  }

  Future<void> _createTimeBand() async {
    showDialog(
      context: context,
      builder: (context) => TimeBandFormDialogEnhanced(
        onSaved: () {
          _loadTimeBands(); // Refresh data
        },
      ),
    );
  }

  Future<void> _editTimeBand(TimeBand timeBand) async {
    showDialog(
      context: context,
      builder: (context) => TimeBandFormDialogEnhanced(
        timeBand: timeBand,
        onSaved: () {
          _loadTimeBands(); // Refresh data
        },
      ),
    );
  }

  Future<void> _deleteTimeBand(TimeBand timeBand) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Delete Time Band',
      message: 'Are you sure you want to delete "${timeBand.name}"?',
      confirmText: 'Delete',
      icon: Icons.delete_outline,
      confirmType: AppButtonType.danger,
    );

    if (confirmed == true) {
      await _performDeleteTimeBand(timeBand.id);
    }
  }

  Future<void> _deleteSelectedTimeBands() async {
    if (_selectedTimeBands.isEmpty) return;

    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Delete Time Bands',
      message:
          'Are you sure you want to delete ${_selectedTimeBands.length} time band(s)?',
      confirmText: 'Delete All',
      confirmType: AppButtonType.danger,
      icon: Icons.delete_outline,
    );

    if (confirmed == true) {
      final ids = _selectedTimeBands.map((tb) => tb.id).toList();
      await _performDeleteTimeBands(ids);
    }
  }

  Future<void> _performDeleteTimeBand(int id) async {
    setState(() => _isLoading = true);

    try {
      final response = await _timeBandService!.deleteTimeBand(id);

      if (mounted) {
        if (response.success) {
          AppToast.showSuccess(
            context,
            message: 'Time band deleted successfully',
          );
          await _loadTimeBands();
        } else {
          setState(() => _isLoading = false);
          AppToast.showError(
            context,
            error: response.message ?? 'Failed to delete time band',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.showError(context, error: 'Error deleting time band: $e');
      }
    }
  }

  Future<void> _performDeleteTimeBands(List<int> ids) async {
    setState(() => _isLoading = true);

    try {
      final response = await _timeBandService!.deleteTimeBands(ids);

      if (mounted) {
        if (response.success) {
          setState(() {
            _selectedTimeBands.clear();
          });
          AppToast.showSuccess(
            context,
            message: 'Time bands deleted successfully',
          );
          await _loadTimeBands();
        } else {
          setState(() => _isLoading = false);
          AppToast.showError(
            context,
            error: response.message ?? 'Failed to delete time bands',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.showError(context, error: 'Error deleting time bands: $e');
      }
    }
  }

  void _viewTimeBandDetails(TimeBand timeBand) {
    showDialog(
      context: context,
      builder: (context) => TimeBandFormDialogEnhanced(
        timeBand: timeBand,
        isViewMode: true, // This makes it read-only initially
        onSaved: () {
          // Handle save when edit button is pressed
          _loadTimeBands(); // Refresh data
        },
      ),
    );
  }

  Future<List<TimeBand>> _fetchAllTimeBands() async {
    try {
      // Fetch all time bands without pagination
      final response = await _timeBandService!.getTimeBands(
        search: _searchQuery.isNotEmpty ? '%$_searchQuery%' : '%%',
        offset: 0,
        limit: 10000, // Large limit to get all items
      );

      if (response.success && response.data != null) {
        return response.data!;
      } else {
        throw Exception(response.message ?? 'Failed to fetch all time bands');
      }
    } catch (e) {
      throw Exception('Error fetching all time bands: $e');
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
                        Icons.access_time,
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
                        onPressed: _toggleSummaryCard,
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
          TimeBandFiltersAndActionsV2(
            onSearchChanged: _handleSearch,
            onViewModeChanged: _handleViewModeChanged,
            onAddTimeBand: _createTimeBand,
            onRefresh: _loadTimeBands,
            currentViewMode: _currentView,
            onFiltersChanged: _handleFiltersChanged,
            onExport: () {
              AppToast.showInfo(
                context,
                message: 'Export functionality coming soon',
              );
            },
          ),
          const SizedBox(height: AppSizes.spacing24),
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
        hintText: 'Search time bands...',
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
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSizes.spacing8),
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
        onSelected: (value) {
          switch (value) {
            case 'add':
              _createTimeBand();
              break;
            case 'refresh':
              _loadTimeBands();
              break;
            case 'kanban':
              _handleViewModeChanged(TimeBandViewMode.kanban);
              break;
            case 'table':
              _handleViewModeChanged(TimeBandViewMode.table);
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
                Text('Add Time Band'),
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
                  color: _currentView == TimeBandViewMode.kanban
                      ? AppColors.primary
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  'Kanban View',
                  style: TextStyle(
                    color: _currentView == TimeBandViewMode.kanban
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
                  color: _currentView == TimeBandViewMode.table
                      ? AppColors.primary
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  'Table View',
                  style: TextStyle(
                    color: _currentView == TimeBandViewMode.table
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
      onPageChanged: _handlePageChanged,
      onItemsPerPageChanged: _handlePageSizeChanged,
      showItemsPerPageSelector: true,
      itemsPerPageOptions: const [5, 10, 20, 50, 100],
    );
  }

  Widget _buildSummaryCard({bool isCompact = false}) {
    final activeTimeBands = _timeBands.where((tb) => tb.active).length;
    final inactiveTimeBands = _timeBands.where((tb) => !tb.active).length;
    final totalAttributes = _timeBands.fold<int>(
      0,
      (sum, tb) => sum + tb.timeBandAttributes.length,
    );

    if (isCompact) {
      return _buildCompactSummaryCard(
        activeTimeBands: activeTimeBands,
        inactiveTimeBands: inactiveTimeBands,
        totalAttributes: totalAttributes,
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: AppColors.border),
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
              'Total Time Bands',
              _totalItems.toString(),
              Icons.access_time,
              AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSizes.spacing12),
          Expanded(
            child: _buildStatCard(
              'Active',
              activeTimeBands.toString(),
              Icons.check_circle_outline,
              AppColors.success,
            ),
          ),
          const SizedBox(width: AppSizes.spacing12),
          Expanded(
            child: _buildStatCard(
              'Inactive',
              inactiveTimeBands.toString(),
              Icons.pause_circle_outline,
              AppColors.error,
            ),
          ),
          const SizedBox(width: AppSizes.spacing12),
          Expanded(
            child: _buildStatCard(
              'Total Attributes',
              totalAttributes.toString(),
              Icons.settings,
              AppColors.info,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSummaryCard({
    required int activeTimeBands,
    required int inactiveTimeBands,
    required int totalAttributes,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: AppColors.border),
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
              Icons.access_time,
              AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSizes.spacing8),
          Expanded(
            child: _buildCompactStatCard(
              'Active',
              activeTimeBands.toString(),
              Icons.check_circle_outline,
              AppColors.success,
            ),
          ),
          const SizedBox(width: AppSizes.spacing8),
          Expanded(
            child: _buildCompactStatCard(
              'Inactive',
              inactiveTimeBands.toString(),
              Icons.pause_circle_outline,
              AppColors.error,
            ),
          ),
          const SizedBox(width: AppSizes.spacing8),
          Expanded(
            child: _buildCompactStatCard(
              'Attributes',
              totalAttributes.toString(),
              Icons.settings,
              AppColors.info,
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
            style: const TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              color: AppColors.textSecondary,
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
              color: AppColors.textSecondary,
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
    // Show full-screen loading only if no data exists yet
    if (_isLoading && _timeBands.isEmpty) {
      return const Center(
        child: AppLottieStateWidget.loading(
          title: 'Loading Time Bands',
          lottieSize: 80,
          message: 'Please wait while we fetch your time bands.',
        ),
      );
    }

    if (_errorMessage.isNotEmpty && _timeBands.isEmpty) {
      return AppLottieStateWidget.error(
        title: 'Error Loading Time Bands',
        message: _errorMessage,
        buttonText: 'Try Again',
        onButtonPressed: _loadTimeBands,
      );
    }

    if (_timeBands.isEmpty && !_isLoading) {
      return AppLottieStateWidget.noData(
        title: _searchQuery.isNotEmpty ? 'No Results Found' : 'No Time Bands',
        message: _searchQuery.isNotEmpty
            ? 'No time bands match your search criteria.'
            : 'Start by creating your first time band.',
        buttonText: 'Create Time Band',
        onButtonPressed: _createTimeBand,
      );
    }

    return _buildViewContent();
  }

  Widget _buildViewContent() {
    return (_currentView == TimeBandViewMode.table && !_isKanbanView)
        ? _buildTableView()
        : _buildKanbanView();
  }

  Widget _buildTableView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
      child: BluNestDataTable<TimeBand>(
        columns: _buildTableColumns(),
        data: _timeBands,
        onRowTap: _viewTimeBandDetails,
        enableMultiSelect: true,
        selectedItems: _selectedTimeBands,
        onSelectionChanged: (selectedItems) {
          setState(() {
            _selectedTimeBands = selectedItems;
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
        onSort: (String sortBy, bool ascending) => _handleSort(sortBy),
        isLoading: _isLoading,
        totalItemsCount: _totalItems,
        onSelectAllItems: _fetchAllTimeBands,
        emptyState: AppLottieStateWidget.noData(
          title: 'No Time Bands',
          message: 'No time bands found for the current filter criteria.',
          lottieSize: 120,
        ),
      ),
    );
  }

  Widget _buildKanbanView() {
    if (_isLoading && _timeBands.isEmpty) {
      return const Center(
        child: AppLottieStateWidget.loading(
          title: 'Loading Time Bands',
          lottieSize: 80,
          message: 'Please wait while we fetch your time bands.',
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
      child: TimeBandKanbanView(
        timeBands: _timeBands,
        onItemTap: _viewTimeBandDetails,
        onItemEdit: _editTimeBand,
        onItemDelete: _deleteTimeBand,
        isLoading: _isLoading,
        searchQuery: _searchQuery,
      ),
    );
  }

  List<BluNestTableColumn<TimeBand>> _buildTableColumns() {
    return TimeBandTableColumns.buildAllColumns(
      sortBy: _sortBy,
      sortAscending: _sortAscending,
      onEdit: _editTimeBand,
      onDelete: _deleteTimeBand,
      onView: _viewTimeBandDetails,
      availableSeasons: _availableSeasons,
      availableSpecialDays: _availableSpecialDays,
      currentPage: _currentPage,
      itemsPerPage: _itemsPerPage,
      data: _timeBands,
    );
  }
}
