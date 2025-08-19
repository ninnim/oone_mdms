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
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_confirm_dialog.dart';
import '../../widgets/common/app_lottie_state_widget.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/common/blunest_data_table.dart';
import '../../widgets/common/results_pagination.dart';
import '../../widgets/time_bands/time_band_form_dialog_enhanced.dart';
import '../../widgets/time_bands/time_band_table_columns.dart';
import '../../widgets/time_bands/time_band_smart_chips.dart';
import '../../widgets/time_bands/time_band_filters_and_actions_v2.dart';
import '../../widgets/time_bands/time_band_kanban_view.dart';

class TimeBandsScreen extends StatefulWidget {
  const TimeBandsScreen({super.key});

  @override
  State<TimeBandsScreen> createState() => _TimeBandsScreenState();
}

class _TimeBandsScreenState extends State<TimeBandsScreen> {
  late final TimeBandService _timeBandService;
  late final SeasonService _seasonService;
  late final SpecialDayService _specialDayService;

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
    _timeBandService = Provider.of<TimeBandService>(context, listen: false);
    _seasonService = Provider.of<SeasonService>(context, listen: false);
    _specialDayService = Provider.of<SpecialDayService>(context, listen: false);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([_loadSeasons(), _loadSpecialDays(), _loadTimeBands()]);
  }

  Future<void> _loadSeasons() async {
    try {
      final response = await _seasonService.getSeasons(limit: 100);
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
      final response = await _specialDayService.getSpecialDays(limit: 100);
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
        '🔄 TimeBandsScreen: Loading time bands (page: $_currentPage, search: "$_searchQuery")',
      );

      final response = await _timeBandService.getTimeBands(
        search: _searchQuery.isNotEmpty ? _searchQuery : '%%',
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
          AppToast.showError(context, error: _errorMessage);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading time bands: $e';
          _isLoading = false;
        });
        AppToast.showError(context, error: _errorMessage);
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

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 1; // Reset to first page when searching
    });
    _loadTimeBands();
  }

  void _handleViewModeChanged(TimeBandViewMode? viewMode) {
    if (viewMode != null) {
      setState(() {
        _currentView = viewMode;
        _selectedTimeBands.clear(); // Clear selection when changing view
      });
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
      final response = await _timeBandService.deleteTimeBand(id);

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
      final response = await _timeBandService.deleteTimeBands(ids);

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
      final response = await _timeBandService.getTimeBands(
        search: _searchQuery.isNotEmpty ? _searchQuery : '%%',
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header with summary card and filters
          _buildHeader(),

          // Content
          Expanded(child: _buildContent()),

          // Pagination - Always visible for consistency (no padding)
          ResultsPagination(
            currentPage: _currentPage,
            totalPages: _totalPages,
            totalItems: _totalItems,
            itemsPerPage: _itemsPerPage,
            //  itemsPerPageOptions: const [5, 10, 20, 25, 50],
            startItem: ((_currentPage - 1) * _itemsPerPage) + 1,
            endItem: (_currentPage * _itemsPerPage).clamp(0, _totalItems),
            onPageChanged: _handlePageChanged,
            onItemsPerPageChanged: _handlePageSizeChanged,
            showItemsPerPageSelector: true,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
      color: Colors.white,
      child: Column(
        children: [
          SizedBox(height: AppSizes.spacing12),
          // Summary Card
          _buildSummaryCard(),
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
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final activeTimeBands = _timeBands.where((tb) => tb.active).length;
    final inactiveTimeBands = _timeBands.where((tb) => !tb.active).length;
    final totalAttributes = _timeBands.fold<int>(
      0,
      (sum, tb) => sum + tb.timeBandAttributes.length,
    );

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

  Widget _buildContent() {
    if (_isLoading) {
      return const AppLottieStateWidget.loading(lottieSize: 80);
    }

    if (_errorMessage.isNotEmpty) {
      return AppLottieStateWidget.error(
        message: _errorMessage,
        onButtonPressed: _loadTimeBands,
      );
    }

    if (_timeBands.isEmpty) {
      return AppLottieStateWidget.noData(
        message: _searchQuery.isNotEmpty
            ? 'No time bands found matching your search criteria.'
            : 'No time bands available.',
        buttonText: _searchQuery.isEmpty ? 'Create Time Band' : 'Refresh',
        onButtonPressed: _searchQuery.isEmpty
            ? _createTimeBand
            : _loadTimeBands,
      );
    }

    switch (_currentView) {
      case TimeBandViewMode.table:
        return _buildTableView();
      case TimeBandViewMode.kanban:
        return _buildKanbanView();
    }
  }

  Widget _buildTableView() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: BluNestDataTable<TimeBand>(
        data: _timeBands,
        columns: _buildTableColumns(),
        selectedItems: _selectedTimeBands,
        onSelectionChanged: (selectedItems) {
          setState(() {
            _selectedTimeBands = selectedItems;
          });
        },
        onRowTap: _viewTimeBandDetails, // Add row click functionality
        onSort: (String sortBy, bool ascending) => _handleSort(sortBy),
        sortBy: _sortBy,
        sortAscending: _sortAscending,
        enableMultiSelect: true,
        // Add column visibility functionality
        hiddenColumns: _hiddenColumns,
        onColumnVisibilityChanged: (hiddenColumns) {
          setState(() {
            _hiddenColumns = hiddenColumns;
          });
        },
        totalItemsCount: _totalItems,
        onSelectAllItems: _fetchAllTimeBands,
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

  Widget _buildKanbanView() {
    return TimeBandKanbanView(
      timeBands: _timeBands,
      onItemTap: _viewTimeBandDetails,
      onItemEdit: _editTimeBand,
      onItemDelete: _deleteTimeBand,
      isLoading: _isLoading,
      searchQuery: _searchQuery,
    );
  }
}
