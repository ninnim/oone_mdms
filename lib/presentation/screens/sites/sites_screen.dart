import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/app_lottie_state_widget.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/common/app_confirm_dialog.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/blunest_data_table.dart';
import '../../widgets/common/results_pagination.dart';
import '../../widgets/sites/site_filters_and_actions_v2.dart';
import '../../widgets/sites/site_summary_card.dart';
import '../../widgets/sites/site_form_dialog.dart';
import '../../widgets/sites/site_kanban_view.dart';
import '../../widgets/sites/site_table_columns.dart';
import '../../widgets/sites/subsite_table_columns.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/models/site.dart';
import '../../../core/services/site_service.dart';

class SitesScreen extends StatefulWidget {
  final Function(List<String>)? onBreadcrumbUpdate;

  const SitesScreen({super.key, this.onBreadcrumbUpdate});

  @override
  State<SitesScreen> createState() => _SitesScreenState();
}

class _SitesScreenState extends State<SitesScreen> {
  late SiteService _siteService;

  // State management
  List<Site> _sites = [];
  List<Site> _filteredSites = [];
  Set<Site> _selectedSites = {};

  bool _isLoading = false;
  String? _errorMessage;

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
  int get _totalPages => (_filteredSites.length / _itemsPerPage).ceil();
  int get _offset => (_currentPage - 1) * _itemsPerPage;
  List<Site> get _paginatedSites {
    final start = _offset;
    final end = (start + _itemsPerPage).clamp(0, _filteredSites.length);
    return _filteredSites.sublist(start, end);
  }

  @override
  void initState() {
    super.initState();
    _siteService = Provider.of<SiteService>(context, listen: false);
    _loadSites();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Event Handlers
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 1;
    });
    _applyFilters();
  }

  void _onViewModeChanged(SiteViewMode mode) {
    setState(() {
      _currentViewMode = mode;
    });
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
    });
    _applyFilters();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _onItemsPerPageChanged(int itemsPerPage) {
    setState(() {
      _itemsPerPage = itemsPerPage;
      _currentPage = 1;
    });
  }

  // CRUD Operations
  void _createSite() {
    // Only show main sites as potential parents
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
      final response = await _siteService.getSites(
        search: _searchQuery.isNotEmpty ? _searchQuery : '',
        limit: 1000, // Load all sites for client-side filtering
        offset: 0,
      );

      if (response.success && response.data != null) {
        setState(() {
          _sites = response.data!;
          _isLoading = false;
        });
        _applyFilters();
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Failed to load sites';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading sites: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<Site> filtered = List.from(_sites);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((site) {
        return site.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            site.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      dynamic aValue, bValue;

      switch (_sortBy) {
        case 'name':
          aValue = a.name;
          bValue = b.name;
          break;
        case 'description':
          aValue = a.description;
          bValue = b.description;
          break;
        case 'subSites':
          aValue = a.subSites?.length ?? 0;
          bValue = b.subSites?.length ?? 0;
          break;
        case 'status':
          aValue = a.active ? 'Active' : 'Inactive';
          bValue = b.active ? 'Active' : 'Inactive';
          break;
        default:
          aValue = a.name;
          bValue = b.name;
      }

      if (aValue == null && bValue == null) return 0;
      if (aValue == null) return 1;
      if (bValue == null) return -1;

      final comparison = aValue.toString().compareTo(bValue.toString());
      return _sortAscending ? comparison : -comparison;
    });

    setState(() {
      _filteredSites = filtered;
      // Reset to page 1 if current page exceeds available pages
      if (_currentPage > _totalPages && _totalPages > 0) {
        _currentPage = 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Main content
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacing16,
                  ),
                  child: _buildHeader(),
                ),
                Expanded(child: _buildContent()),
                if (_filteredSites.isNotEmpty) _buildPagination(),
              ],
            ),
          ),
          // Sticky sidebar
          if (_selectedSiteForDetails != null)
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

  Widget _buildHeader() {
    return Column(
      children: [
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
        const SizedBox(height: AppSizes.spacing16),
        SiteSummaryCard(sites: _filteredSites),
      ],
    );
  }

  Widget _buildContent() {
    // Show full-screen loading only if no data exists yet
    if (_isLoading && _sites.isEmpty) {
      return const Center(
        child: AppLottieStateWidget.loading(
          title: 'Loading Sites',
          lottieSize: 100,
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

    return Padding(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      child: _buildViewContent(),
    );
  }

  Widget _buildViewContent() {
    switch (_currentViewMode) {
      case SiteViewMode.table:
        return _buildTableView();
      case SiteViewMode.kanban:
        return _buildKanbanView();
    }
  }

  Widget _buildTableView() {
    return BluNestDataTable<Site>(
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
    );
  }

  Widget _buildKanbanView() {
    return SiteKanbanView(
      sites: _paginatedSites,
      onEdit: _editSite,
      onDelete: _deleteSite,
      onView: _viewSite,
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
    final endItem = (_offset + _itemsPerPage).clamp(0, _filteredSites.length);

    return Padding(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      child: ResultsPagination(
        currentPage: _currentPage,
        totalPages: _totalPages,
        itemsPerPage: _itemsPerPage,
        totalItems: _filteredSites.length,
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
          // decoration: BoxDecoration(
          //   color: Theme.of(context).colorScheme.surface,
          //   border: Border(
          //     bottom: BorderSide(
          //       color: Theme.of(context).dividerColor,
          //       width: 1,
          //     ),
          //   ),
          // ),
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
