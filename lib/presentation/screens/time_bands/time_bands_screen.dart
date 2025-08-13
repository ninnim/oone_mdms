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
import '../../widgets/time_bands/time_band_form_dialog.dart';
import '../../widgets/time_bands/time_band_table_columns.dart';
import '../../widgets/time_bands/time_band_smart_chips.dart';
import '../../widgets/time_bands/time_band_filters_and_actions_v2.dart';

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
      builder: (context) => TimeBandFormDialog(
        onSaved: () {
          Navigator.of(context).pop();
          _loadTimeBands();
        },
      ),
    );
  }

  Future<void> _editTimeBand(TimeBand timeBand) async {
    showDialog(
      context: context,
      builder: (context) => TimeBandFormDialog(
        timeBand: timeBand,
        onSaved: () {
          Navigator.of(context).pop();
          _loadTimeBands();
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
      builder: (context) => TimeBandFormDialog(
        timeBand: timeBand,
        isViewMode: true, // This makes it read-only initially
        onSaved: () {
          // Handle save when edit button is pressed
          Navigator.of(context).pop();
          _loadTimeBands();
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
            itemsPerPageOptions: const [5, 10, 20, 25, 50],
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final groupedTimeBands = _groupTimeBandsByStatus();

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: groupedTimeBands.entries.map((entry) {
            return _buildStatusColumn(entry.key, entry.value);
          }).toList(),
        ),
      ),
    );
  }

  Map<String, List<TimeBand>> _groupTimeBandsByStatus() {
    final Map<String, List<TimeBand>> grouped = {'Active': [], 'Inactive': []};

    for (final timeBand in _timeBands) {
      if (timeBand.active) {
        grouped['Active']!.add(timeBand);
      } else {
        grouped['Inactive']!.add(timeBand);
      }
    }

    return grouped;
  }

  Widget _buildStatusColumn(String status, List<TimeBand> timeBands) {
    Color statusColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'active':
        statusColor = AppColors.success;
        statusIcon = Icons.access_time;
        break;
      case 'inactive':
        statusColor = AppColors.textSecondary;
        statusIcon = Icons.pause_circle;
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusIcon = Icons.help_outline;
    }

    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: AppSizes.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column header
          Container(
            padding: const EdgeInsets.all(AppSizes.spacing16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSizes.radiusMedium),
                topRight: Radius.circular(AppSizes.radiusMedium),
              ),
              border: Border(
                bottom: BorderSide(color: statusColor.withOpacity(0.2)),
              ),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: AppSizes.spacing8),
                Text(
                  status,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                    fontSize: AppSizes.fontSizeMedium,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacing8,
                    vertical: AppSizes.spacing4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  ),
                  child: Text(
                    '${timeBands.length}',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeSmall,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Time Band cards
          Expanded(
            child: timeBands.isEmpty
                ? _buildEmptyState(status)
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSizes.spacing8),
                    itemCount: timeBands.length,
                    itemBuilder: (context, index) {
                      return _buildTimeBandKanbanCard(timeBands[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String status) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.access_time_outlined,
            size: 48,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: AppSizes.spacing12),
          Text(
            'No ${status.toLowerCase()} time bands',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppSizes.fontSizeSmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBandKanbanCard(TimeBand timeBand) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spacing8),
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _viewTimeBandDetails(timeBand),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name, status, and actions
            Row(
              children: [
                Expanded(
                  child: Text(
                    timeBand.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontSize: AppSizes.fontSizeMedium,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSizes.spacing8),
                _buildTimeBandStatusChip(timeBand.active),
                const SizedBox(width: AppSizes.spacing4),
                _buildActionsDropdown(timeBand),
              ],
            ),
            const SizedBox(height: AppSizes.spacing12),

            // Time range and description
            _buildDetailRow(Icons.schedule, 'Time', timeBand.timeRangeDisplay),

            if (timeBand.description.isNotEmpty) ...[
              const SizedBox(height: AppSizes.spacing8),
              _buildDetailRow(
                Icons.description,
                'Description',
                timeBand.description,
              ),
            ],

            const SizedBox(height: AppSizes.spacing8),
            _buildDetailRow(
              Icons.layers,
              'Attributes',
              '${timeBand.timeBandAttributes.length}',
            ),

            // Days of Week chips
            if (timeBand.daysOfWeek.isNotEmpty) ...[
              const SizedBox(height: AppSizes.spacing12),
              const Text(
                'Days:',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeSmall,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSizes.spacing4),
              TimeBandSmartChips.buildDayOfWeekChips(timeBand.daysOfWeek),
            ],

            // Months chips
            if (timeBand.monthsOfYear.isNotEmpty) ...[
              const SizedBox(height: AppSizes.spacing8),
              const Text(
                'Months:',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeSmall,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSizes.spacing4),
              TimeBandSmartChips.buildMonthOfYearChips(timeBand.monthsOfYear),
            ],

            // Seasons and Special Days (if any)
            if (timeBand.seasonIds.isNotEmpty ||
                timeBand.specialDayIds.isNotEmpty) ...[
              const SizedBox(height: AppSizes.spacing8),
              if (timeBand.seasonIds.isNotEmpty) ...[
                const Text(
                  'Seasons:',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeSmall,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSizes.spacing4),
                TimeBandSmartChips.buildSeasonChips(
                  timeBand.seasonIds,
                  _availableSeasons,
                ),
              ],
              if (timeBand.specialDayIds.isNotEmpty) ...[
                if (timeBand.seasonIds.isNotEmpty)
                  const SizedBox(height: AppSizes.spacing8),
                const Text(
                  'Special Days:',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeSmall,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSizes.spacing4),
                TimeBandSmartChips.buildSpecialDayChips(
                  timeBand.specialDayIds,
                  _availableSpecialDays,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeBandStatusChip(bool isActive) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    String text;

    if (isActive) {
      backgroundColor = AppColors.success.withOpacity(0.1);
      borderColor = AppColors.success.withOpacity(0.3);
      textColor = AppColors.success;
      text = 'Active';
    } else {
      backgroundColor = AppColors.textSecondary.withOpacity(0.1);
      borderColor = AppColors.textSecondary.withOpacity(0.3);
      textColor = AppColors.textSecondary;
      text = 'Inactive';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacing8,
        vertical: AppSizes.spacing4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: AppSizes.fontSizeSmall,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: AppSizes.iconSmall, color: AppColors.textSecondary),
        const SizedBox(width: AppSizes.spacing8),
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: AppSizes.fontSizeSmall,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: AppSizes.spacing4),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionsDropdown(TimeBand timeBand) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert,
        color: AppColors.textSecondary,
        size: 16,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'view',
          child: Row(
            children: [
              Icon(Icons.visibility, size: 16, color: AppColors.primary),
              SizedBox(width: AppSizes.spacing8),
              Text('View Details'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 16, color: AppColors.warning),
              SizedBox(width: AppSizes.spacing8),
              Text('Edit'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 16, color: AppColors.error),
              SizedBox(width: AppSizes.spacing8),
              Text('Delete', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'view':
            _viewTimeBandDetails(timeBand);
            break;
          case 'edit':
            _editTimeBand(timeBand);
            break;
          case 'delete':
            _deleteTimeBand(timeBand);
            break;
        }
      },
    );
  }
}
