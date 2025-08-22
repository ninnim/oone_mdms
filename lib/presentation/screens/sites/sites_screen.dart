import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../widgets/common/app_lottie_state_widget.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/common/app_confirm_dialog.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/blunest_data_table.dart';
import '../../widgets/common/results_pagination.dart';
import '../../widgets/common/kanban_view.dart';
import '../../widgets/common/app_input_field.dart';
import '../../widgets/sites/site_filters_and_actions_v2.dart';
import '../../widgets/sites/site_summary_card.dart';
import '../../widgets/sites/site_form_dialog.dart';
import '../../widgets/sites/site_table_columns.dart';
import '../../widgets/sites/subsite_table_columns.dart';
import '../../widgets/sites/site_kanban_adapter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/models/site.dart';
import '../../../core/services/site_service.dart';
import '../../../core/utils/responsive_helper.dart';

class SitesScreen extends StatefulWidget {
  final Function(List<String>)? onBreadcrumbUpdate;

  const SitesScreen({super.key, this.onBreadcrumbUpdate});

  @override
  State<SitesScreen> createState() => _SitesScreenState();
}

class _SitesScreenState extends State<SitesScreen> with ResponsiveMixin {
  late SiteService _siteService;

  // State management
  List<Site> _sites = [];
  List<Site> _filteredSites = []; // This will now hold current page data
  Set<Site> _selectedSites = {};

  bool _isLoading = false;
  String? _errorMessage;

  // API response data
  int _totalItems = 0; // Total count from API
  int _totalPages = 0; // Total pages from API

  // Search debounce
  Timer? _searchDebounceTimer;
  final Duration _searchDebounceDelay = const Duration(milliseconds: 800);
  final TextEditingController _searchController = TextEditingController();

  // Filtering & Search
  String _searchQuery = '';

  // View Mode
  SiteViewMode _currentViewMode = SiteViewMode.table;

  // Sidebar state
  bool _isSidebarOpen = false;
  Site? _selectedSiteForDetails;
  List<Site> _subSites = [];
  bool _isLoadingSubSites = false;

  // Sub-sites table sorting
  String? _subSitesSortColumn;
  bool _subSitesSortAscending = true;

  // Responsive state
  bool _summaryCardCollapsed = false;
  bool _isKanbanView = false;

  // State persistence for desktop/mobile transitions
  SiteViewMode?
  _previousViewModeBeforeMobile; // Track previous view mode before mobile switch
  bool?
  _previousSummaryStateBeforeMobile; // Track previous summary state before mobile switch

  // Table Configuration
  final List<String> _availableColumns = [
    'Site Name',
    'Description',
    'Sub Sites',
    'Status',
    'Actions',
  ];
  List<String> _hiddenColumns = [];

  // Sorting
  String _sortBy = 'name';
  bool _sortAscending = true;

  // Pagination
  int _currentPage = 1;
  int _itemsPerPage = 10;
  // Remove client-side pagination calculations - use API data
  int get _offset => (_currentPage - 1) * _itemsPerPage;
  List<Site> get _paginatedSites =>
      _filteredSites; // API already returns paginated data

  @override
  void initState() {
    super.initState();
    _siteService = Provider.of<SiteService>(context, listen: false);
    _loadSites();
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
        _previousViewModeBeforeMobile = _currentViewMode;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isKanbanView = true;
            _currentViewMode = SiteViewMode.kanban;
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
      '📱 SitesScreen: Responsive state updated (mobile: $isMobile, kanban: $_isKanbanView, view: $_currentViewMode) - UI ONLY, no API calls',
    );
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // Event Handlers
  void _onSearchChanged(String query) {
    // Cancel any existing timer
    _searchDebounceTimer?.cancel();

    // Update search query immediately for UI responsiveness
    setState(() {
      _searchQuery = query;
    });

    // Start new timer for API call
    _searchDebounceTimer = Timer(_searchDebounceDelay, () {
      // Reset to first page when search changes
      setState(() {
        _currentPage = 1;
      });
      _loadSites();
    });
  }

  void _onViewModeChanged(SiteViewMode mode) {
    setState(() {
      _currentViewMode = mode;
      // Update kanban view state based on the new mode
      _isKanbanView = (mode == SiteViewMode.kanban);

      // If user manually changes view mode, reset mobile tracking
      if (MediaQuery.of(context).size.width >= 768) {
        _previousViewModeBeforeMobile = null;
      }
    });
    print(
      '🔄 SitesScreen: View mode changed to $mode (kanban: $_isKanbanView)',
    );
  }

  void _onStatusFilterChanged(String? status) {
    // TODO: Implement status filtering
    // This would filter sites by status when we add status to the model
    setState(() {
      _currentPage = 1;
    });
    _loadSites();
  }

  void _handleSort(String column, bool ascending) {
    setState(() {
      _sortBy = column;
      _sortAscending = ascending;
      _currentPage = 1; // Reset to first page when sorting changes
    });
    _loadSites(); // Trigger API call for sorting
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _loadSites(); // Trigger API call for new page
  }

  void _onItemsPerPageChanged(int itemsPerPage) {
    setState(() {
      _itemsPerPage = itemsPerPage;
      _currentPage = 1; // Reset to first page
    });
    _loadSites(); // Trigger API call with new page size
  }

  // CRUD Operations
  void _createSite() {
    // Get main sites from current loaded data or make API call if needed
    final mainSites = _sites.where((site) => site.isMainSite).toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SiteFormDialog(
        availableParentSites: mainSites,
        onSuccess: () {
          // Refresh sites list after successful operation
          _loadSites();
        },
        onSave: (Site newSite) async {
          try {
            final response = await _siteService.createSite(newSite);
            if (response.success) {
              // Success handling moved to dialog
            }
          } catch (e) {
            AppToast.show(
              context,
              title: 'Error',
              message: 'Failed to create site',
              type: ToastType.error,
            );
          }
        },
      ),
    );
  }

  void _editSite(Site site) {
    // Only show main sites as potential parents (excluding the site being edited to prevent circular reference)
    final mainSites = _sites
        .where((s) => s.isMainSite && s.id != site.id)
        .toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SiteFormDialog(
        site: site,
        availableParentSites: mainSites,
        onSuccess: () {
          // Refresh sites list after successful operation
          _loadSites();
          // If we're viewing this site's details, refresh the sidebar data too
          if (_selectedSiteForDetails?.id == site.id) {
            _refreshSiteById(site.id!);
          }
        },
        onSave: (Site updatedSite) async {
          try {
            final response = await _siteService.updateSite(updatedSite);
            if (response.success) {
              // Success handling moved to dialog
            }
          } catch (e) {
            AppToast.show(
              context,
              title: 'Error',
              message: 'Failed to update site',
              type: ToastType.error,
            );
          }
        },
      ),
    );
  }

  void _viewSite(Site site) {
    setState(() {
      _selectedSiteForDetails = site;
      _isSidebarOpen = true;
    });
    _loadSubSites(site.id!.toString());
  }

  Future<void> _loadSubSites(String siteId) async {
    print('🔄 Loading sub-sites for site ID: $siteId');
    setState(() {
      _isLoadingSubSites = true;
    });

    try {
      final response = await _siteService.getSiteById(
        int.parse(siteId),
        includeSubSite: true,
        search: '%%',
      );

      if (response.success && response.data != null) {
        final subSites = response.data!.subSites ?? [];
        print(
          '✅ Loaded ${subSites.length} sub-sites for site: ${response.data!.name}',
        );
        setState(() {
          _subSites = subSites;
          _isLoadingSubSites = false;
        });
      } else {
        print('❌ Failed to load sub-sites: ${response.message}');
        setState(() {
          _subSites = [];
          _isLoadingSubSites = false;
        });
      }
    } catch (e) {
      print('❌ Error loading sub-sites: $e');
      setState(() {
        _subSites = [];
        _isLoadingSubSites = false;
      });
    }
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });

    // If we're opening the sidebar and have a selected site, refresh its data
    if (_isSidebarOpen && _selectedSiteForDetails != null) {
      _refreshSiteById(_selectedSiteForDetails!.id!);
    }
  }

  void _closeSidebarCompletely() {
    setState(() {
      _isSidebarOpen = false;
      _selectedSiteForDetails = null;
      _subSites = [];
    });
  }

  Future<void> _refreshSiteById(int siteId) async {
    try {
      print('🔄 Refreshing site data for ID: $siteId');

      // Refresh the selected site data
      final siteResponse = await _siteService.getSiteById(siteId);
      if (siteResponse.success && siteResponse.data != null) {
        print('✅ Site data refreshed: ${siteResponse.data!.name}');
        setState(() {
          _selectedSiteForDetails = siteResponse.data;
        });

        // Also refresh subsites if it's a main site
        if (siteResponse.data!.isMainSite) {
          print(
            '🔄 Refreshing sub-sites for main site: ${siteResponse.data!.name}',
          );
          await _loadSubSites(siteId.toString());
        }
      } else {
        print('❌ Failed to refresh site data: ${siteResponse.message}');
      }

      // Refresh the main sites list to ensure consistency
      print('🔄 Refreshing main sites list');
      await _loadSites();
    } catch (e) {
      // Handle error silently or show toast if needed
      print('❌ Error refreshing site data: $e');
    }
  }

  Future<void> _deleteSite(Site site) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Delete Site',
      message:
          'Are you sure you want to delete "${site.name}"? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      confirmType: AppButtonType.danger,
      icon: Icons.delete_outline,
    );

    if (confirmed == true) {
      try {
        final response = await _siteService.deleteSite(site.id!);

        if (response.success) {
          AppToast.showSuccess(
            context,
            title: 'Site Deleted',
            message: 'Site "${site.name}" has been successfully deleted.',
          );
          _loadSites();
        } else {
          AppToast.showError(
            context,
            error: response.message ?? 'Failed to delete site',
            title: 'Delete Failed',
            errorContext: 'site_delete',
          );
        }
      } catch (e) {
        AppToast.showError(
          context,
          error: 'Network error: Please check your connection',
          title: 'Connection Error',
          errorContext: 'site_delete_network',
        );
      }
    }
  }

  // Data Operations
  Future<void> _loadSites() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Format search query with wildcards for API
      String formattedSearch = '';
      if (_searchQuery.isNotEmpty) {
        formattedSearch = '%${_searchQuery.trim()}%';
      }

      print(
        '🔄 Loading sites - Page: $_currentPage, Search: "$formattedSearch", Sort: $_sortBy ($_sortAscending)',
      );

      final response = await _siteService.getSites(
        search: formattedSearch,
        limit: _itemsPerPage,
        offset: _offset,
        // TODO: Add sorting parameters if your API supports them
        // sortBy: _sortBy,
        // sortOrder: _sortAscending ? 'asc' : 'desc',
      );

      if (response.success && response.data != null) {
        // Calculate total pages from API response
        final totalCount = response.paging?.item.total ?? response.data!.length;
        final calculatedTotalPages = (totalCount / _itemsPerPage).ceil();

        setState(() {
          _sites = response.data!; // Keep for reference
          _filteredSites = response.data!; // Current page data
          _totalItems = totalCount;
          _totalPages = calculatedTotalPages;
          _isLoading = false;
        });

        print(
          '✅ Sites loaded - ${response.data!.length} items, Total: $totalCount, Pages: $calculatedTotalPages',
        );
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Failed to load sites';
          _isLoading = false;
          _totalItems = 0;
          _totalPages = 0;
        });
        print('❌ Failed to load sites: ${response.message}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading sites: $e';
        _isLoading = false;
        _totalItems = 0;
        _totalPages = 0;
      });
      print('❌ Exception loading sites: $e');
    }
  }

  // Method to fetch all sites for selection
  Future<List<Site>> _fetchAllSites() async {
    try {
      print('🔄 Fetching all sites for selection');

      // Format current search query with wildcards
      String formattedSearch = '';
      if (_searchQuery.isNotEmpty) {
        formattedSearch = '%${_searchQuery.trim()}%';
      }

      // Fetch all sites matching current search criteria
      final response = await _siteService.getSites(
        search: formattedSearch,
        limit: 1000, // Large limit to get all matching sites
        offset: 0,
      );

      if (response.success && response.data != null) {
        print('✅ Fetched ${response.data!.length} sites for selection');
        return response.data!;
      } else {
        print('❌ Failed to fetch all sites: ${response.message}');
        throw Exception(response.message ?? 'Failed to fetch sites');
      }
    } catch (e) {
      print('❌ Exception fetching all sites: $e');
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Main content
          Expanded(
            child: SafeArea(
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
          ),
          // Sticky sidebar for desktop only
          if (!isMobile && _selectedSiteForDetails != null)
            Container(
              width: _isSidebarOpen ? 500 : 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSizes.spacing8),
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(color: AppColors.border),
              ),
              child: _isSidebarOpen
                  ? _buildSidebarContent()
                  : _buildCollapsedSidebar(),
            ),
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
      child: SiteSummaryCard(
        sites: _filteredSites,
        isCompact: isMobile || isTablet,
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
          SiteFiltersAndActionsV2(
            onSearchChanged: _onSearchChanged,
            onStatusFilterChanged: _onStatusFilterChanged,
            onViewModeChanged: _onViewModeChanged,
            onAddSite: _createSite,
            onRefresh: _loadSites,
            onExport: () {}, // TODO: Implement export functionality
            onImport: () {}, // TODO: Implement import functionality
            currentViewMode: _currentViewMode,
            selectedStatus: null, // We can add status filtering later
          ),
          const SizedBox(height: AppSizes.spacing24),
        ],
      ),
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
                        Icons.location_city,
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
                                fontSize: headerFontSize,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
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
                          size: AppSizes.iconSmall,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(
                          minHeight: isMobile ? 28 : 32,
                          minWidth: isMobile ? 28 : 32,
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
                    child: SiteSummaryCard(
                      sites: _filteredSites,
                      isCompact: isMobile || isTablet,
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
        hintText: 'Search sites...',
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
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSizes.spacing8),
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
        onSelected: (value) {
          switch (value) {
            case 'add':
              _createSite();
              break;
            case 'refresh':
              _loadSites();
              break;
            case 'kanban':
              _onViewModeChanged(SiteViewMode.kanban);
              break;
            case 'table':
              _onViewModeChanged(SiteViewMode.table);
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
                Text('Add Site'),
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
                  color: _currentViewMode == SiteViewMode.kanban
                      ? AppColors.primary
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  'Kanban View',
                  style: TextStyle(
                    color: _currentViewMode == SiteViewMode.kanban
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
                  color: _currentViewMode == SiteViewMode.table
                      ? AppColors.primary
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  'Table View',
                  style: TextStyle(
                    color: _currentViewMode == SiteViewMode.table
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
    if (_isLoading && _filteredSites.isEmpty) {
      return const Center(
        child: AppLottieStateWidget.loading(
          title: 'Loading Sites',
          lottieSize: 80,
          message: 'Please wait while we fetch your sites.',
        ),
      );
    }

    if (_errorMessage != null) {
      return AppLottieStateWidget.error(
        title: 'Error Loading Sites',
        message: _errorMessage!,
        buttonText: 'Try Again',
        onButtonPressed: _loadSites,
      );
    }

    if (_filteredSites.isEmpty && !_isLoading) {
      return AppLottieStateWidget.noData(
        title: _searchQuery.isNotEmpty ? 'No Results Found' : 'No Sites',
        message: _searchQuery.isNotEmpty
            ? 'No sites match your search criteria.'
            : 'Start by creating your first site.',
        buttonText: 'Create Site',
        onButtonPressed: _createSite,
      );
    }

    return _buildViewContent();
  }

  Widget _buildViewContent() {
    return (_currentViewMode == SiteViewMode.table && !_isKanbanView)
        ? _buildTableView()
        : _buildKanbanView();
  }

  Widget _buildTableView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
      child: BluNestDataTable<Site>(
        columns: _buildTableColumns(),
        data: _paginatedSites,
        onRowTap: _viewSite,
        onView: _viewSite,
        onEdit: _editSite,
        onDelete: _deleteSite,
        enableMultiSelect: true,
        selectedItems: _selectedSites,
        onSelectionChanged: (selectedItems) {
          setState(() {
            _selectedSites = selectedItems;
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
        // Enhanced selection parameters
        totalItemsCount: _totalItems, // Use API total count
        onSelectAllItems: _fetchAllSites,
        emptyState: AppLottieStateWidget.noData(
          title: 'No Sites',
          message: 'No sites found for the current filter criteria.',
          lottieSize: 120,
        ),
      ),
    );
  }

  Widget _buildKanbanView() {
    if (_isLoading && _filteredSites.isEmpty) {
      return const Center(
        child: AppLottieStateWidget.loading(
          title: 'Loading Sites',
          lottieSize: 80,
          message: 'Please wait while we fetch your sites.',
        ),
      );
    }

    final kanbanItems = _paginatedSites
        .map((site) => SiteKanbanItem(site))
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
      child: KanbanView<SiteKanbanItem>(
        items: kanbanItems,
        columns: SiteKanbanConfig.columns,
        actions: SiteKanbanConfig.getActions(
          onView: _viewSite,
          onEdit: _editSite,
          onDelete: _deleteSite,
        ),
        onItemTap: (item) => _viewSite(item.site),
        isLoading: _isLoading,
        padding: const EdgeInsets.all(AppSizes.spacing16),
      ),
    );
  }

  List<BluNestTableColumn<Site>> _buildTableColumns() {
    return SiteTableColumns.buildBluNestColumns(
      visibleColumns: _availableColumns
          .where((column) => !_hiddenColumns.contains(column))
          .toList(),
      sortBy: _sortBy,
      sortAscending: _sortAscending,
      onSort: _handleSort,
      onView: _viewSite,
      onEdit: _editSite,
      onDelete: _deleteSite,
      currentPage: _currentPage,
      itemsPerPage: _itemsPerPage,
      sites: _paginatedSites,
    );
  }

  Widget _buildPagination() {
    final startItem = _offset + 1;
    final endItem = (_offset + _itemsPerPage).clamp(0, _totalItems);

    return Container(
      constraints: const BoxConstraints(
        maxHeight: 80, // Limit pagination height
      ),
      child: ResultsPagination(
        currentPage: _currentPage,
        totalPages: _totalPages, // Use API total pages
        itemsPerPage: _itemsPerPage,
        totalItems: _totalItems, // Use API total items
        startItem: startItem,
        endItem: endItem,
        onPageChanged: _onPageChanged,
        onItemsPerPageChanged: _onItemsPerPageChanged,
      ),
    );
  }

  Widget _buildSidebarContent() {
    return Column(
      children: [
        // Sidebar header
        Container(
          padding: const EdgeInsets.all(AppSizes.spacing16),

          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _toggleSidebar,
                      icon: Icon(
                        _isSidebarOpen
                            ? Icons.keyboard_arrow_right
                            : Icons.keyboard_arrow_left,
                        size: AppSizes.iconSmall,
                      ),
                      tooltip: _isSidebarOpen
                          ? 'Collapse sidebar'
                          : 'Expand sidebar',

                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.all(6),
                        minimumSize: const Size(30, 30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sub Sites',
                          style: TextStyle(fontSize: AppSizes.fontSizeLarge),
                        ),
                        Text(
                          'Parent: ${_selectedSiteForDetails?.name ?? ''}',
                          style: TextStyle(
                            fontSize: AppSizes.fontSizeSmall,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppButton(
                    text: 'Add Sub-site',
                    type: AppButtonType.primary,
                    size: AppButtonSize.small,
                    onPressed: () => _createSubSite(_selectedSiteForDetails!),
                    icon: const Icon(Icons.add, size: AppSizes.iconSmall),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Sub-sites table
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.spacing16),
            child: _buildSubSitesTable(),
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsedSidebar() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Collapsed header with expand button
          IconButton(
            onPressed: _toggleSidebar,
            icon: const Icon(Icons.keyboard_arrow_left, size: 20),
            tooltip: 'Expand sidebar',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.all(6),
              minimumSize: const Size(28, 28),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(color: AppColors.border),
              ),
            ),
          ),

          const SizedBox(height: AppSizes.spacing16),
          // Vertical text showing site name (without Expanded)
          if (_selectedSiteForDetails != null)
            SizedBox(
              height: 200, // Fixed height instead of Expanded
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(
                  _selectedSiteForDetails!.name,
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeLarge,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          const SizedBox(height: AppSizes.spacing8),

          // Close button
          IconButton(
            onPressed: _closeSidebarCompletely,
            icon: const Icon(Icons.close, size: AppSizes.iconSmall),
            tooltip: 'Close sidebar',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textTertiary,
              padding: const EdgeInsets.all(4),
              minimumSize: const Size(30, 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(color: AppColors.borderLight),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubSitesTable() {
    print(
      '🔄 Building subsites table - Loading: $_isLoadingSubSites, Count: ${_subSites.length}',
    );

    // Sort the sub-sites based on current sorting
    List<Site> sortedSubSites = List.from(_subSites);
    if (_subSitesSortColumn != null) {
      sortedSubSites.sort((a, b) {
        dynamic aValue, bValue;
        switch (_subSitesSortColumn) {
          case 'name':
            aValue = a.name;
            bValue = b.name;
            break;
          case 'description':
            aValue = a.description;
            bValue = b.description;
            break;
          default:
            return 0;
        }

        int result = aValue.toString().compareTo(bValue.toString());
        return _subSitesSortAscending ? result : -result;
      });
    }

    // Get table columns from SubSiteTableColumns
    final columns = SubSiteTableColumns.getBluNestColumns(
      context: context,
      onEdit: _editSubSite,
      onDelete: _deleteSubSite,
      subSites: sortedSubSites,
      sortColumn: _subSitesSortColumn,
      sortAscending: _subSitesSortAscending,
    );

    print('🔄 Building subsite table with ${sortedSubSites.length} items');

    return BluNestDataTable<Site>(
      key: ValueKey(
        'subsite_table_${_selectedSiteForDetails?.id}_${_subSites.length}',
      ),
      columns: columns,
      data: sortedSubSites,
      isLoading: _isLoadingSubSites,
      sortBy: _subSitesSortColumn,
      sortAscending: _subSitesSortAscending,
      onSort: (column, ascending) {
        print('🔄 Subsite table sort changed: $column, ascending: $ascending');
        setState(() {
          _subSitesSortColumn = column;
          _subSitesSortAscending = ascending;
        });
      },
      emptyState: AppLottieStateWidget.noData(
        title: 'No Sub Sites',
        message: 'This main site has no sub-sites yet.',
        lottieSize: 120,
      ),
    );
  }

  void _createSubSite(Site parentSite) async {
    final availableParentSites = [
      parentSite,
    ]; // Only allow current site as parent

    showDialog(
      context: context,
      builder: (context) => SiteFormDialog(
        availableParentSites: availableParentSites,
        preferredParentId: parentSite.id!, // Auto-select the current main site
        onSuccess: () {
          // Refresh parent site data to get updated subsite information
          print('🔄 Triggering refresh for parent site ID: ${parentSite.id}');
          _refreshSiteById(parentSite.id!);
        },
        onSave: (newSite) async {
          try {
            print(
              '🔄 Creating sub-site: ${newSite.name} under parent: ${parentSite.name}',
            );
            final response = await _siteService.createSite(newSite);
            if (response.success) {
              print('✅ Sub-site created successfully: ${newSite.name}');
              // Success handling moved to dialog
            }
            // else {
            //   AppToast.show(
            //     context,
            //     title: 'Error',
            //     message: response.message ?? 'Failed to create sub-site',
            //     type: ToastType.error,
            //   );
            // }
          } catch (e) {
            AppToast.show(
              context,
              title: 'Error',
              message: 'Failed to create sub-site',
              type: ToastType.error,
            );
          }
        },
      ),
    );
  }

  void _editSubSite(Site subSite) async {
    // Get all main sites as potential parents
    final allMainSites = _sites.where((s) => s.isMainSite).toList();

    // Build available parent sites list
    final availableParentSites = <Site>[...allMainSites];

    // If we're viewing a specific main site's details, prioritize it
    // Otherwise, ensure the current parent is included
    if (_selectedSiteForDetails != null &&
        _selectedSiteForDetails!.isMainSite) {
      // We're in a main site's detail view - prioritize the current main site
      final currentMainSite = _selectedSiteForDetails!;

      // Ensure current main site is in the list
      if (!availableParentSites.any((s) => s.id == currentMainSite.id)) {
        availableParentSites.add(currentMainSite);
      }

      // Also ensure the subsite's actual current parent is available (if different)
      if (subSite.parentId != 0 && subSite.parentId != currentMainSite.id) {
        final actualCurrentParent = _sites.firstWhere(
          (s) => s.id == subSite.parentId,
          orElse: () => Site(
            id: subSite.parentId,
            name: 'Current Parent (${subSite.parentId})',
            description: '',
            parentId: 0,
            active: true,
          ),
        );

        if (!availableParentSites.any((s) => s.id == actualCurrentParent.id)) {
          availableParentSites.add(actualCurrentParent);
        }
      }
    } else {
      // Not in a specific main site view - just ensure current parent is available
      if (subSite.parentId != 0) {
        final currentParent = _sites.firstWhere(
          (s) => s.id == subSite.parentId,
          orElse: () => Site(
            id: subSite.parentId,
            name: 'Current Parent (${subSite.parentId})',
            description: '',
            parentId: 0,
            active: true,
          ),
        );

        if (!availableParentSites.any((s) => s.id == currentParent.id)) {
          availableParentSites.add(currentParent);
        }
      }
    }
    // Determine the preferred parent ID
    int? preferredParentId;
    if (_selectedSiteForDetails != null &&
        _selectedSiteForDetails!.isMainSite) {
      // We're editing from within a main site's details - prefer the current main site
      preferredParentId = _selectedSiteForDetails!.id!;
    }

    showDialog(
      context: context,
      builder: (context) => SiteFormDialog(
        site: subSite,
        availableParentSites: availableParentSites,
        preferredParentId: preferredParentId,
        onSuccess: () {
          // Refresh parent site data to get updated subsite information
          if (_selectedSiteForDetails != null) {
            print(
              '🔄 Triggering refresh for selected site ID: ${_selectedSiteForDetails!.id}',
            );
            _refreshSiteById(_selectedSiteForDetails!.id!);
          }
        },
        onSave: (updatedSite) async {
          try {
            print('🔄 Updating sub-site: ${updatedSite.name}');
            final response = await _siteService.updateSite(updatedSite);
            if (response.success) {
              print('✅ Sub-site updated successfully: ${updatedSite.name}');
              // Success handling moved to dialog
            } else {
              AppToast.show(
                context,
                title: 'Error',
                message: response.message ?? 'Failed to update sub-site',
                type: ToastType.error,
              );
            }
          } catch (e) {
            AppToast.show(
              context,
              title: 'Error',
              message: 'Failed to update sub-site',
              type: ToastType.error,
            );
          }
        },
      ),
    );
  }

  void _deleteSubSite(Site subSite) async {
    // Safety check - ensure subSite has valid ID
    if (subSite.id == null) {
      print('❌ Cannot delete subsite: ID is null');
      AppToast.show(
        context,
        title: 'Error',
        message: 'Cannot delete subsite: Invalid subsite data',
        type: ToastType.error,
      );
      return;
    }

    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Delete Sub-site',
      message:
          'Are you sure you want to delete "${subSite.name}"? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      confirmType: AppButtonType.danger,
    );

    if (confirmed == true) {
      try {
        print('🔄 Deleting sub-site: ${subSite.name} (ID: ${subSite.id})');

        // Show loading state if needed
        if (mounted) {
          setState(() {
            _isLoadingSubSites = true;
          });
        }

        final response = await _siteService.deleteSite(subSite.id!);

        if (mounted) {
          setState(() {
            _isLoadingSubSites = false;
          });
        }

        if (response.success) {
          print('✅ Sub-site deleted successfully: ${subSite.name}');

          if (mounted) {
            AppToast.show(
              context,
              title: 'Success',
              message: 'Sub-site deleted successfully',
              type: ToastType.success,
            );
          }

          // Refresh the data only if we have a valid selected site
          if (_selectedSiteForDetails?.id != null) {
            print(
              '🔄 Triggering refresh for selected site ID: ${_selectedSiteForDetails!.id}',
            );
            await _refreshSiteById(_selectedSiteForDetails!.id!);
          }
        } else {
          print('❌ Failed to delete sub-site: ${response.message}');
          if (mounted) {
            AppToast.show(
              context,
              title: 'Error',
              message: response.message ?? 'Failed to delete sub-site',
              type: ToastType.error,
            );
          }
        }
      } catch (e) {
        print('❌ Exception while deleting sub-site: $e');

        if (mounted) {
          setState(() {
            _isLoadingSubSites = false;
          });

          AppToast.show(
            context,
            title: 'Error',
            message: 'Failed to delete sub-site: ${e.toString()}',
            type: ToastType.error,
          );
        }
      }
    } else {
      print('🚫 Sub-site deletion cancelled by user');
    }
  }
}
