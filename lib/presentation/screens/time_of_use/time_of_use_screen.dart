import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/time_of_use.dart';
import '../../../core/services/time_of_use_service.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_confirm_dialog.dart';
import '../../widgets/common/app_lottie_state_widget.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/common/blunest_data_table.dart';
import '../../widgets/common/results_pagination.dart';
import '../../widgets/time_of_use/time_of_use_form_dialog.dart';
import '../../widgets/time_of_use/time_of_use_table_columns.dart';
import '../../widgets/time_of_use/time_of_use_filters_and_actions_v2.dart';

class TimeOfUseScreen extends StatefulWidget {
  const TimeOfUseScreen({super.key});

  @override
  State<TimeOfUseScreen> createState() => _TimeOfUseScreenState();
}

class _TimeOfUseScreenState extends State<TimeOfUseScreen> {
  late final TimeOfUseService _timeOfUseService;

  // Data state
  bool _isLoading = false;
  List<TimeOfUse> _timeOfUseList = [];
  Set<TimeOfUse> _selectedTimeOfUse = {};
  String _errorMessage = '';

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  int _itemsPerPage = 25;

  // View and filter state
  TimeOfUseViewMode _currentView = TimeOfUseViewMode.table;
  String _searchQuery = '';
  List<String> _hiddenColumns = [];

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
    _timeOfUseService = Provider.of<TimeOfUseService>(context, listen: false);
    _loadTimeOfUse();
  }

  Future<void> _loadTimeOfUse() async {
    print('🔄 TOU Screen: _loadTimeOfUse called');
    if (!mounted) {
      print('❌ TOU Screen: Widget not mounted, skipping load');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('🌐 TOU Screen: Making API call to getTimeOfUse');
      final response = await _timeOfUseService.getTimeOfUse(
        search: _searchQuery.isEmpty ? '' : _searchQuery,
        offset: (_currentPage - 1) * _itemsPerPage,
        limit: _itemsPerPage,
      );

      print(
        '📥 TOU Screen: API response received - Success: ${response.success}, Data count: ${response.data?.length ?? 0}',
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
            '✅ TOU Screen: State updated with ${_timeOfUseList.length} items (total: $_totalItems)',
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = response.message ?? 'Failed to load time of use';
            _isLoading = false;
          });
          print('❌ TOU Screen: API call failed - ${_errorMessage}');
        }
      }
    } catch (e) {
      print('💥 TOU Screen: Exception during load - $e');
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
    print('🔄 TOU Screen: Fetching all items for selection');
    try {
      final response = await _timeOfUseService.getTimeOfUse(
        search: _searchQuery.isEmpty ? '' : _searchQuery,
        offset: 0,
        limit: _totalItems, // Fetch all items
      );

      if (response.success && response.data != null) {
        print(
          '✅ TOU Screen: Fetched ${response.data!.length} items for selection',
        );
        return response.data!;
      } else {
        throw Exception(response.message ?? 'Failed to fetch all items');
      }
    } catch (e) {
      print('❌ TOU Screen: Error fetching all items - $e');
      throw e;
    }
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 1;
    });
    _loadTimeOfUse();
  }

  void _handleViewModeChanged(TimeOfUseViewMode? mode) {
    if (mode != null) {
      setState(() {
        _currentView = mode;
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
      itemsPerPageOptions: const [5, 10, 20, 25, 50],
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
    print('🔄 TOU Screen: Opening create dialog');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => TimeOfUseFormDialog(
        onSaved: () {
          print('🔄 TOU Screen: onSaved callback triggered for create');
          // Trigger immediate refresh via callback
          _loadTimeOfUse();
        },
      ),
    );

    print('📥 TOU Screen: Create dialog returned result: $result');
    if (result == true) {
      print('✅ TOU Screen: Triggering data refresh after create (fallback)');
      await _loadTimeOfUse();
      print('✅ TOU Screen: Data refresh completed after create');
    }
  }

  Future<void> _editTimeOfUse(TimeOfUse timeOfUse) async {
    print('🔄 TOU Screen: Opening edit dialog for: ${timeOfUse.name}');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => TimeOfUseFormDialog(
        timeOfUse: timeOfUse,
        isReadOnly: false,
        onSaved: () {
          print('🔄 TOU Screen: onSaved callback triggered for edit');
          // Trigger immediate refresh via callback
          _loadTimeOfUse();
        },
      ),
    );

    print('📥 TOU Screen: Edit dialog returned result: $result');
    if (result == true) {
      print('✅ TOU Screen: Triggering data refresh after edit (fallback)');
      await _loadTimeOfUse();
      print('✅ TOU Screen: Data refresh completed after edit');
    }
  }

  Future<void> _viewTimeOfUseDetails(TimeOfUse timeOfUse) async {
    await showDialog(
      context: context,
      builder: (context) =>
          TimeOfUseFormDialog(timeOfUse: timeOfUse, isReadOnly: true),
    );
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

  Future<void> _deleteSelectedTimeOfUse() async {
    if (_selectedTimeOfUse.isEmpty) return;

    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Delete Selected Time of Use',
      message:
          'Are you sure you want to delete ${_selectedTimeOfUse.length} time of use item${_selectedTimeOfUse.length == 1 ? '' : 's'}?\nThis action cannot be undone.',
      confirmText: 'Delete All',
      cancelText: 'Cancel',
      confirmType: AppButtonType.danger,
      icon: Icons.delete_sweep,
    );

    if (confirmed == true) {
      final ids = _selectedTimeOfUse.map((tou) => tou.id ?? 0).toList();
      await _performDeleteTimeOfUseList(ids);
    }
  }

  Future<void> _performDeleteTimeOfUse(int id) async {
    setState(() => _isLoading = true);

    try {
      final response = await _timeOfUseService.deleteTimeOfUse(id);

      if (mounted) {
        if (response.success) {
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

  Future<void> _performDeleteTimeOfUseList(List<int> ids) async {
    setState(() => _isLoading = true);

    try {
      final response = await _timeOfUseService.deleteTimeOfUseList(ids);

      if (mounted) {
        if (response.success) {
          setState(() {
            _selectedTimeOfUse.clear();
          });
          AppToast.showSuccess(
            context,
            message: 'Time of use entries deleted successfully',
          );
          await _loadTimeOfUse();
        } else {
          setState(() => _isLoading = false);
          AppToast.showError(
            context,
            error: response.message ?? 'Failed to delete time of use entries',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.showError(
          context,
          error: 'Error deleting time of use entries: $e',
        );
      }
    }
  }

  @override
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

          // Pagination - Always visible like Devices module
          _buildPagination(),
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
          _buildSummaryCards(),
          const SizedBox(height: AppSizes.spacing8),

          // Filters and Actions
          _buildFiltersAndActions(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final activeTimeOfUse = _timeOfUseList.where((tou) => tou.active).length;
    final inactiveTimeOfUse = _timeOfUseList.where((tou) => !tou.active).length;
    final totalChannels = _timeOfUseList.fold<int>(
      0,
      (sum, tou) => sum + tou.timeOfUseDetails.length,
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
              'Total Time of Use',
              _totalItems.toString(),
              Icons.schedule_outlined,
              AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSizes.spacing12),
          Expanded(
            child: _buildStatCard(
              'Active',
              activeTimeOfUse.toString(),
              Icons.check_circle_outline,
              AppColors.success,
            ),
          ),
          const SizedBox(width: AppSizes.spacing12),
          Expanded(
            child: _buildStatCard(
              'Inactive',
              inactiveTimeOfUse.toString(),
              Icons.pause_circle_outline,
              AppColors.error,
            ),
          ),
          const SizedBox(width: AppSizes.spacing12),
          Expanded(
            child: _buildStatCard(
              'Total Channels',
              totalChannels.toString(),
              Icons.account_tree_outlined,
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

  Widget _buildFiltersAndActions() {
    return TimeOfUseFiltersAndActionsV2(
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
      child: BluNestDataTable<TimeOfUse>(
        data: _timeOfUseList,
        columns: TimeOfUseTableColumns.buildAllBluNestColumns(
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
    if (_isLoading && _timeOfUseList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final groupedTimeOfUse = _groupTimeOfUseByStatus();

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: groupedTimeOfUse.entries.map((entry) {
            return _buildStatusColumn(entry.key, entry.value);
          }).toList(),
        ),
      ),
    );
  }

  Map<String, List<TimeOfUse>> _groupTimeOfUseByStatus() {
    final Map<String, List<TimeOfUse>> grouped = {'Active': [], 'Inactive': []};

    for (final timeOfUse in _timeOfUseList) {
      if (timeOfUse.active) {
        grouped['Active']!.add(timeOfUse);
      } else {
        grouped['Inactive']!.add(timeOfUse);
      }
    }

    return grouped;
  }

  Widget _buildStatusColumn(String status, List<TimeOfUse> timeOfUseList) {
    Color statusColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'active':
        statusColor = AppColors.success;
        statusIcon = Icons.schedule_outlined;
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
                    '${timeOfUseList.length}',
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

          // Time of Use cards
          Expanded(
            child: timeOfUseList.isEmpty
                ? _buildEmptyState(status)
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSizes.spacing8),
                    itemCount: timeOfUseList.length,
                    itemBuilder: (context, index) {
                      return _buildTimeOfUseKanbanCard(timeOfUseList[index]);
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
            Icons.schedule_outlined,
            size: 48,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: AppSizes.spacing12),
          Text(
            'No ${status.toLowerCase()} time of use',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppSizes.fontSizeSmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeOfUseKanbanCard(TimeOfUse timeOfUse) {
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
        onTap: () => _viewTimeOfUseDetails(timeOfUse),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name, status, and actions
            Row(
              children: [
                Expanded(
                  child: Text(
                    timeOfUse.name,
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
                _buildTimeOfUseStatusChip(timeOfUse.active),
                const SizedBox(width: AppSizes.spacing4),
                _buildActionsDropdown(timeOfUse),
              ],
            ),
            const SizedBox(height: AppSizes.spacing12),

            // Time of Use details
            if (timeOfUse.code.isNotEmpty) ...[
              _buildDetailRow(Icons.code, 'Code', timeOfUse.code),
              const SizedBox(height: AppSizes.spacing8),
            ],

            if (timeOfUse.description.isNotEmpty) ...[
              _buildDetailRow(
                Icons.description,
                'Description',
                timeOfUse.description,
              ),
              const SizedBox(height: AppSizes.spacing8),
            ],

            _buildDetailRow(
              Icons.account_tree_outlined,
              'Channels',
              '${timeOfUse.totalChannels}',
            ),

            // Channel information display (if any)
            if (timeOfUse.timeOfUseDetails.isNotEmpty) ...[
              const SizedBox(height: AppSizes.spacing12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacing8,
                  vertical: AppSizes.spacing4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  border: Border.all(color: AppColors.info.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.layers, size: 14, color: AppColors.info),
                    const SizedBox(width: AppSizes.spacing4),
                    Text(
                      '${timeOfUse.totalTimeBands} configured TimeBand${timeOfUse.totalTimeBands == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeExtraSmall,
                        color: AppColors.info,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeOfUseStatusChip(bool isActive) {
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

  Widget _buildActionsDropdown(TimeOfUse timeOfUse) {
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
            _viewTimeOfUseDetails(timeOfUse);
            break;
          case 'edit':
            _editTimeOfUse(timeOfUse);
            break;
          case 'delete':
            _deleteTimeOfUse(timeOfUse);
            break;
        }
      },
    );
  }
}
