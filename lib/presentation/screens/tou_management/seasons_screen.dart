import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mdms_clone/presentation/widgets/common/app_input_field.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/blunest_data_table.dart';
import '../../widgets/common/results_pagination.dart';
import '../../widgets/common/app_lottie_state_widget.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/common/app_confirm_dialog.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/seasons/season_filters_and_actions_v2.dart';
import '../../widgets/seasons/season_form_dialog.dart';
import '../../widgets/seasons/season_table_columns.dart';
import '../../widgets/seasons/season_summary_card.dart';
import '../../widgets/seasons/seasons_kanban_view.dart';
import '../../themes/app_theme.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/models/season.dart';
import '../../../core/services/season_service.dart';
import '../../../core/utils/responsive_helper.dart';

class SeasonsScreen extends StatefulWidget {
  const SeasonsScreen({super.key});

  @override
  State<SeasonsScreen> createState() => _SeasonsScreenState();
}

class _SeasonsScreenState extends State<SeasonsScreen> with ResponsiveMixin {
  SeasonService? _seasonService;

  // Data state
  bool _isLoading = false;
  List<Season> _seasons = [];
  Set<Season> _selectedSeasons = {};
  String _errorMessage = '';
  bool _isInitialized = false; // Track if data has been loaded initially

  // Pagination - SERVER-SIDE
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  int _itemsPerPage = 25;

  // View and filter state - REAL-TIME API
  SeasonViewMode _currentView = SeasonViewMode.table;
  String _searchQuery = '';
  String? _selectedStatus;
  bool _showActiveOnly = false;
  List<String> _hiddenColumns = ['id'];

  // Responsive UI state
  bool _summaryCardCollapsed = false;
  bool _isKanbanView = false;
  SeasonViewMode?
  _previousViewModeBeforeMobile; // Track previous view mode before mobile switch
  bool?
  _previousSummaryStateBeforeMobile; // Track previous summary state before mobile switch
  final TextEditingController _searchController = TextEditingController();

  // Search delay timer
  Timer? _searchTimer;

  // Sorting state
  String? _sortBy;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _seasonService ??= Provider.of<SeasonService>(context, listen: false);

    // Only load data on first initialization, not on every dependency change (like screen resize)
    if (!_isInitialized) {
      _isInitialized = true;
      _loadSeasons();
      print('🚀 SeasonsScreen: Initial data load triggered');
    } else {
      print(
        '📱 SeasonsScreen: Dependencies changed (likely screen resize) - NO API call',
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
      // Save previous summary state before collapsing for mobile
      if (_previousSummaryStateBeforeMobile == null) {
        _previousSummaryStateBeforeMobile = _summaryCardCollapsed;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _summaryCardCollapsed = true; // Default to collapsed on mobile
          });
        }
      });
    }

    // Auto-expand summary card on desktop - restore previous state
    if (!isMobile && !isTablet) {
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
          }
        });
      }
    }

    // Auto-switch to kanban view on mobile
    if (isMobile && !_isKanbanView) {
      // Save previous view mode before switching to mobile kanban
      if (_previousViewModeBeforeMobile == null) {
        _previousViewModeBeforeMobile = _currentView;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isKanbanView = true;
            _currentView = SeasonViewMode.kanban;
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
            _currentView = _previousViewModeBeforeMobile!;
            _previousViewModeBeforeMobile = null; // Reset tracking
          });
        }
      });
    }

    print(
      '📱 SeasonsScreen: Responsive state updated (mobile: $isMobile, kanban: $_isKanbanView, view: $_currentView) - UI ONLY, no API calls',
    );
  }

  Future<void> _loadSeasons() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _seasonService!.getSeasons(
        search: _searchQuery.isNotEmpty ? '%$_searchQuery%' : '%%',
        offset: (_currentPage - 1) * _itemsPerPage,
        limit: _itemsPerPage,
      );

      if (response.success && response.data != null) {
        setState(() {
          _seasons = response.data!;
          // Get total from pagination info, fallback to data length if not available
          _totalItems = response.paging?.item.total ?? response.data!.length;
          _totalPages = _totalItems > 0
              ? ((_totalItems - 1) ~/ _itemsPerPage) + 1
              : 1;
          _isLoading = false;
        });

        // Apply any existing sorting
        _applySorting();
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Failed to load seasons';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading seasons: $e';
        _isLoading = false;
      });
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
          '🔍 SeasonsScreen: Search triggered for: "$query" (formatted: "%$query%")',
        );
        _loadSeasons(); // Trigger API call after delay
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
      _loadSeasons(); // Trigger API call immediately
    }
  }

  void _onViewModeChanged(SeasonViewMode mode) {
    setState(() {
      _currentView = mode;
      // Update kanban view state based on the new mode
      _isKanbanView = (mode == SeasonViewMode.kanban);

      // If user manually changes view mode, reset mobile tracking
      if (MediaQuery.of(context).size.width >= 768) {
        _previousViewModeBeforeMobile = null;
      }
    });
    print(
      '🔄 SeasonsScreen: View mode changed to $mode (kanban: $_isKanbanView)',
    );
  }

  void _onItemsPerPageChanged(int itemsPerPage) {
    setState(() {
      _itemsPerPage = itemsPerPage;
      _currentPage = 1;
    });
    _loadSeasons();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _loadSeasons();
  }

  void _onSort(String columnKey, bool ascending) {
    setState(() {
      _sortBy = columnKey;
      _sortAscending = ascending;
    });
    print(
      '🔄 SeasonsScreen: Sort changed to $columnKey (ascending: $ascending)',
    );
    _loadSeasons(); // Reload data with new sort
  }

  void _applySorting() {
    if (_sortBy == null || _seasons.isEmpty) return;

    setState(() {
      _seasons.sort((a, b) {
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

  void _createSeason() {
    showDialog(
      context: context,
      builder: (context) => SeasonFormDialog(
        onSave: _handleCreateSeason,
        onSuccess: _loadSeasons,
      ),
    );
  }

  void _editSeason(Season season) {
    showDialog(
      context: context,
      builder: (context) => SeasonFormDialog(
        season: season,
        onSave: _handleUpdateSeason,
        onSuccess: _loadSeasons,
      ),
    );
  }

  void _viewSeasonDetails(Season season) {
    showDialog(
      context: context,
      builder: (context) => SeasonFormDialog(
        season: season,
        isReadOnly: true,
        onSave: _handleUpdateSeason,
        onSuccess: _loadSeasons,
      ),
    );
  }

  Future<void> _handleCreateSeason(Season season) async {
    try {
      print('🔄 SeasonsScreen: Creating season: ${season.name}');
      final response = await _seasonService!.createSeason(season);

      if (!response.success) {
        throw Exception(response.message ?? 'Failed to create season');
      }

      print('✅ SeasonsScreen: Season created successfully');
    } catch (e) {
      print('❌ SeasonsScreen: Error creating season: $e');
      rethrow;
    }
  }

  Future<void> _handleUpdateSeason(Season season) async {
    try {
      print('🔄 SeasonsScreen: Updating season: ${season.name}');
      final response = await _seasonService!.updateSeason(season);

      if (!response.success) {
        throw Exception(response.message ?? 'Failed to update season');
      }

      print('✅ SeasonsScreen: Season updated successfully');
    } catch (e) {
      print('❌ SeasonsScreen: Error updating season: $e');
      rethrow;
    }
  }

  Future<void> _handleDeleteSeason(Season season) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Delete Season',
      message:
          'Are you sure you want to delete "${season.name}"? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      confirmType: AppButtonType.danger,
      icon: Icons.delete_outline,
    );

    if (confirmed == true) {
      try {
        print('🔄 SeasonsScreen: Deleting season: ${season.name}');
        final response = await _seasonService!.deleteSeason(season.id);

        if (!response.success) {
          throw Exception(response.message ?? 'Failed to delete season');
        }

        // Remove from local state
        setState(() {
          _seasons.removeWhere((s) => s.id == season.id);
          _selectedSeasons.removeWhere((s) => s.id == season.id);
          _totalItems--;
        });

        // Show success message
        if (mounted) {
          AppToast.showSuccess(
            context,
            title: 'Season Deleted',
            message: 'Season "${season.name}" has been successfully deleted.',
          );
        }

        print('✅ SeasonsScreen: Season deleted successfully');
      } catch (e) {
        print('❌ SeasonsScreen: Error deleting season: $e');
        if (mounted) {
          AppToast.showError(
            context,
            error: 'Failed to delete season. Please try again.',
            title: 'Delete Failed',
            errorContext: 'season_delete',
          );
        }
      }
    }
  }

  Future<List<Season>> _fetchAllSeasons() async {
    try {
      // Fetch all seasons without pagination
      final response = await _seasonService!.getSeasons(
        search: _searchQuery.isNotEmpty ? '%$_searchQuery%' : '%%',
        offset: 0,
        limit: 10000, // Large limit to get all items
      );

      if (response.success && response.data != null) {
        // Apply same filters as current view
        List<Season> filtered = List.from(response.data!);

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          filtered = filtered.where((season) {
            return season.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                season.description.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );
          }).toList();
        }

        return filtered;
      } else {
        throw Exception(response.message ?? 'Failed to fetch all seasons');
      }
    } catch (e) {
      throw Exception('Error fetching all seasons: $e');
    }
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
            // Summary Card FIRST (like special days screen)
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
      child: Column(
        children: [
          const SizedBox(height: AppSizes.spacing8),
          // Filters and Actions
          SeasonFiltersAndActionsV2(
            currentViewMode: _currentView,
            onViewModeChanged: _onViewModeChanged,
            onSearchChanged: _onSearchChanged,
            onStatusFilterChanged: _onStatusFilterChanged,
            onAddSeason: _createSeason,
            onRefresh: _loadSeasons,
            selectedStatus: _selectedStatus,
          ),
          const SizedBox(height: AppSizes.spacing8),
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
      child: SeasonSummaryCard(seasons: _seasons),
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
            color: context.surfaceColor, // AppColors.surface,
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
                        Icons.calendar_today,
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
                                color: context
                                    .textPrimaryColor, //AppColors.textPrimary,
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
                    child: SeasonSummaryCard(seasons: _seasons),
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
        hintText: 'Search seasons...',
        controller: _searchController,
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
        color: context.primaryColor,
        borderRadius: BorderRadius.circular(AppSizes.spacing8),
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
        onSelected: (value) {
          switch (value) {
            case 'add':
              _createSeason();
              break;
            case 'refresh':
              _loadSeasons();
              break;
            case 'kanban':
              _onViewModeChanged(SeasonViewMode.kanban);
              break;
            case 'table':
              _onViewModeChanged(SeasonViewMode.table);
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
                Text('Add Season'),
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
                  color: _currentView == SeasonViewMode.kanban
                      ? context.primaryColor
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  'Kanban View',
                  style: TextStyle(
                    color: _currentView == SeasonViewMode.kanban
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
                  color: _currentView == SeasonViewMode.table
                      ? context.primaryColor
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  'Table View',
                  style: TextStyle(
                    color: _currentView == SeasonViewMode.table
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

  Widget _buildContent() {
    // Show full-screen loading only if no data exists yet
    if (_isLoading && _seasons.isEmpty) {
      return const Center(
        child: AppLottieStateWidget.loading(
          title: 'Loading Seasons',
          lottieSize: 80,
          message: 'Please wait while we fetch your seasons.',
        ),
      );
    }

    if (_errorMessage.isNotEmpty && _seasons.isEmpty) {
      return AppLottieStateWidget.error(
        title: 'Error Loading Seasons',
        message: _errorMessage,
        buttonText: 'Try Again',
        onButtonPressed: _loadSeasons,
      );
    }

    if (_seasons.isEmpty && !_isLoading) {
      return AppLottieStateWidget.noData(
        title: _searchQuery.isNotEmpty ? 'No Results Found' : 'No Seasons',
        message: _searchQuery.isNotEmpty
            ? 'No seasons match your search criteria.'
            : 'Start by creating your first season.',
        buttonText: 'Create Season',
        onButtonPressed: _createSeason,
      );
    }

    return _buildViewContent();
  }

  Widget _buildViewContent() {
    return (_currentView == SeasonViewMode.table && !_isKanbanView)
        ? _buildTableView()
        : _buildKanbanView();
  }

  Widget _buildTableView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
      child: BluNestDataTable<Season>(
        columns: SeasonTableColumns.buildAllColumns(
          context: context,
          onEdit: _editSeason,
          onDelete: _handleDeleteSeason,
          onView: _viewSeasonDetails,
          currentPage: _currentPage,
          itemsPerPage: _itemsPerPage,
          data: _seasons,
        ),
        data: _seasons,
        onRowTap: _viewSeasonDetails,
        enableMultiSelect: true,
        selectedItems: _selectedSeasons,
        onSelectionChanged: (selectedItems) {
          setState(() {
            _selectedSeasons = selectedItems;
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
        onSort: _onSort,
        isLoading: _isLoading,
        totalItemsCount: _totalItems,
        onSelectAllItems: _fetchAllSeasons,
        emptyState: AppLottieStateWidget.noData(
          title: 'No Seasons',
          message: 'No seasons found for the current filter criteria.',
          lottieSize: 120,
        ),
      ),
    );
  }

  Widget _buildKanbanView() {
    if (_isLoading && _seasons.isEmpty) {
      return const Center(
        child: AppLottieStateWidget.loading(
          title: 'Loading Seasons',
          lottieSize: 80,
          message: 'Please wait while we fetch your seasons.',
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
      child: SeasonsKanbanView(
        seasons: _seasons,
        onItemTap: _viewSeasonDetails,
        onItemEdit: _editSeason,
        onItemDelete: _handleDeleteSeason,
        isLoading: _isLoading,
        searchQuery: _searchQuery,
      ),
    );
  }
}
