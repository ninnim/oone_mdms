import 'package:flutter/material.dart';
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
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/models/season.dart';
import '../../../core/services/season_service.dart';

class SeasonsScreen extends StatefulWidget {
  const SeasonsScreen({super.key});

  @override
  State<SeasonsScreen> createState() => _SeasonsScreenState();
}

class _SeasonsScreenState extends State<SeasonsScreen> {
  late final SeasonService _seasonService;

  // Data state
  bool _isLoading = false;
  List<Season> _seasons = [];
  Set<Season> _selectedSeasons = {};
  String _errorMessage = '';

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  int _itemsPerPage = 25;

  // View and filter state
  SeasonViewMode _currentView = SeasonViewMode.table;
  String _searchQuery = '';
  bool _showActiveOnly = false;
  List<String> _hiddenColumns = ['id'];

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
    _seasonService = Provider.of<SeasonService>(context, listen: false);
    _loadSeasons();
  }

  Future<void> _loadSeasons() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print(
        '🔄 SeasonsScreen: Loading seasons (page: $_currentPage, search: "$_searchQuery")',
      );

      final response = await _seasonService.getSeasons(
        search: _searchQuery.isNotEmpty ? _searchQuery : '%%',
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

        print(
          '✅ SeasonsScreen: Loaded ${_seasons.length} seasons (total: $_totalItems)',
        );
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Failed to load seasons';
          _isLoading = false;
        });
        print('❌ SeasonsScreen: Load failed: $_errorMessage');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading seasons: $e';
        _isLoading = false;
      });
      print('❌ SeasonsScreen: Exception loading seasons: $e');
    }
  }

  void _onSearch(String query) {
    if (_searchQuery != query) {
      setState(() {
        _searchQuery = query;
        _currentPage = 1;
      });
      _loadSeasons();
    }
  }

  void _onFilterChange({bool? showActiveOnly}) {
    bool shouldReload = false;

    if (showActiveOnly != null && _showActiveOnly != showActiveOnly) {
      setState(() {
        _showActiveOnly = showActiveOnly;
        _currentPage = 1;
      });
      shouldReload = true;
    }

    if (shouldReload) {
      _loadSeasons();
    }
  }

  void _onViewModeChanged(SeasonViewMode mode) {
    setState(() {
      _currentView = mode;
    });
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
    _applySorting();
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
      final response = await _seasonService.createSeason(season);

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
      final response = await _seasonService.updateSeason(season);

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
        final response = await _seasonService.deleteSeason(season.id);

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
      final response = await _seasonService.getSeasons(
        search: _searchQuery.isNotEmpty ? _searchQuery : '%%',
        offset: 0,
        limit: 10000, // Large limit to get all items
      );

      if (response.success && response.data != null) {
        return response.data!;
      } else {
        throw Exception(response.message ?? 'Failed to fetch all seasons');
      }
    } catch (e) {
      throw Exception('Error fetching all seasons: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Summary Card
          const SizedBox(height: AppSizes.spacing8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
            child: SeasonSummaryCard(seasons: _seasons),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
            child: _buildHeader(),
          ),

          Expanded(child: _buildContent()),
          // Always show pagination area, even if empty (no padding)
          ResultsPagination(
            currentPage: _currentPage,
            totalPages: _totalPages,
            totalItems: _totalItems,
            itemsPerPage: _itemsPerPage,

            /// itemsPerPageOptions: const [5, 10, 20, 25, 50],
            startItem: (_currentPage - 1) * _itemsPerPage + 1,
            endItem: (_currentPage * _itemsPerPage) > _totalItems
                ? _totalItems
                : _currentPage * _itemsPerPage,
            onPageChanged: _onPageChanged,
            onItemsPerPageChanged: _onItemsPerPageChanged,
            showItemsPerPageSelector: true,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Breadcrumb
        // const BreadcrumbNavigation(),
        const SizedBox(height: AppSizes.spacing8),

        // Filters and Actions
        SeasonFiltersAndActionsV2(
          currentViewMode: _currentView,
          onViewModeChanged: _onViewModeChanged,
          onSearchChanged: _onSearch,
          onStatusFilterChanged: (status) =>
              _onFilterChange(showActiveOnly: status == 'active'),
          onAddSeason: _createSeason,
          onRefresh: _loadSeasons,
          selectedStatus: _showActiveOnly ? 'active' : null,
        ),

        const SizedBox(height: AppSizes.spacing24),
      ],
    );
  }

  Widget _buildContent() {
    // Loading state
    if (_isLoading && _seasons.isEmpty) {
      return const AppLottieStateWidget.loading(
        // title: 'Loading Seasons',
        lottieSize: 80,
        //  message: 'Please wait while we fetch your season configurations...',
      );
    }

    // Error state
    if (_errorMessage.isNotEmpty && _seasons.isEmpty) {
      return AppLottieStateWidget.error(
        title: 'Failed to Load Seasons',
        message: _errorMessage,
        buttonText: 'Try Again',
        onButtonPressed: _loadSeasons,
      );
    }

    // No data state
    if (_seasons.isEmpty) {
      return AppLottieStateWidget.noData(
        title: 'No Seasons Found',
        message: _searchQuery.isNotEmpty
            ? 'No seasons match your search criteria. Try adjusting your filters.'
            : 'No seasons have been configured yet. Click "Create Season" to get started.',
        buttonText: 'Create Season',
        onButtonPressed: _createSeason,
      );
    }

    // Content based on view mode
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
      child: _currentView == SeasonViewMode.table
          ? _buildTableView()
          : _buildKanbanView(),
    );
  }

  Widget _buildTableView() {
    return BluNestDataTable<Season>(
      columns: SeasonTableColumns.buildAllColumns(
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
    );
  }

  Widget _buildKanbanView() {
    return SeasonsKanbanView(
      seasons: _seasons,
      onItemTap: _viewSeasonDetails,
      onItemEdit: _editSeason,
      onItemDelete: _handleDeleteSeason,
      isLoading: _isLoading,
      searchQuery: _searchQuery,
    );
  }
}
