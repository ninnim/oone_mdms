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
import '../../widgets/common/kanban_view.dart';
import '../../widgets/common/results_pagination.dart';
import '../../widgets/common/status_chip.dart';
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
  List<String> _hiddenColumns = ['description', 'active'];

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
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _timeOfUseService.getTimeOfUse(
        search: _searchQuery.isEmpty ? '' : _searchQuery,
        offset: (_currentPage - 1) * _itemsPerPage,
        limit: _itemsPerPage,
      );

      if (response.success && response.data != null) {
        if (mounted) {
          setState(() {
            _timeOfUseList = response.data!;
            _totalItems = _timeOfUseList.length;
            _totalPages = (_totalItems / _itemsPerPage)
                .ceil()
                .clamp(1, double.infinity)
                .toInt();
            _isLoading = false;
          });
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

  void _handlePageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _loadTimeOfUse();
  }

  void _handlePageSizeChanged(int pageSize) {
    setState(() {
      _itemsPerPage = pageSize;
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

  Future<void> _createTimeOfUse() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const TimeOfUseFormDialog(),
    );

    if (result == true) {
      await _loadTimeOfUse();
    }
  }

  Future<void> _editTimeOfUse(TimeOfUse timeOfUse) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) =>
          TimeOfUseFormDialog(timeOfUse: timeOfUse, isReadOnly: false),
    );

    if (result == true) {
      await _loadTimeOfUse();
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AppConfirmDialog(
        title: 'Delete Time of Use',
        message:
            'Are you sure you want to delete "${timeOfUse.name}"? This action cannot be undone.',
        confirmText: 'Delete',
        cancelText: 'Cancel',
        confirmType: AppButtonType.danger,
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      try {
        final response = await _timeOfUseService.deleteTimeOfUse(
          timeOfUse.id ?? 0,
        );

        if (mounted) {
          setState(() => _isLoading = false);

          if (response.success) {
            AppToast.showSuccess(
              context,
              message: 'Time of use deleted successfully',
            );
            await _loadTimeOfUse();
          } else {
            AppToast.showError(
              context,
              error: response.message ?? 'Failed to delete time of use',
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          AppToast.showError(
            context,
            error: 'Error deleting time of use: ${e.toString()}',
          );
        }
      }
    }
  }

  Future<void> _bulkDeleteTimeOfUse() async {
    if (_selectedTimeOfUse.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AppConfirmDialog(
        title: 'Delete Selected Time of Use',
        message:
            'Are you sure you want to delete ${_selectedTimeOfUse.length} time of use(s)? This action cannot be undone.',
        confirmText: 'Delete All',
        cancelText: 'Cancel',
        confirmType: AppButtonType.danger,
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      try {
        for (final timeOfUse in _selectedTimeOfUse) {
          await _timeOfUseService.deleteTimeOfUse(timeOfUse.id ?? 0);
        }

        if (mounted) {
          setState(() {
            _selectedTimeOfUse.clear();
            _isLoading = false;
          });
          AppToast.showSuccess(
            context,
            message: 'Selected time of use deleted successfully',
          );
          await _loadTimeOfUse();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          AppToast.showError(
            context,
            error: 'Error deleting time of use: ${e.toString()}',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary stats cards
            _buildSummaryCards(),
            const SizedBox(height: AppSizes.spacing24),

            // Filters and actions
            _buildFiltersAndActions(),
            const SizedBox(height: AppSizes.spacing16),

            // Content
            Expanded(child: _buildContent()),

            // Pagination
            _buildPagination(),
          ],
        ),
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
      availableColumns: TimeOfUseTableColumns.getAllColumnKeys(),
      hiddenColumns: _hiddenColumns,
      onColumnVisibilityChanged: (hiddenColumns) {
        setState(() {
          _hiddenColumns = hiddenColumns;
        });
      },
      onExport: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export feature coming soon')),
        );
      },
    );
  }

  Widget _buildContent() {
    if (_isLoading && _timeOfUseList.isEmpty) {
      return const AppLottieStateWidget.loading(
        message: 'Loading time of use...',
      );
    }

    if (_errorMessage.isNotEmpty) {
      return AppLottieStateWidget.error(
        message: _errorMessage,
        onButtonPressed: _loadTimeOfUse,
      );
    }

    if (_timeOfUseList.isEmpty) {
      return AppLottieStateWidget.noData(
        message: _searchQuery.isEmpty
            ? 'No time of use configurations found'
            : 'No time of use found matching "$_searchQuery"',
        onButtonPressed: _searchQuery.isEmpty
            ? null
            : () {
                setState(() => _searchQuery = '');
                _loadTimeOfUse();
              },
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
    final visibleColumns = TimeOfUseTableColumns.getAllColumnKeys()
        .where((key) => !_hiddenColumns.contains(key))
        .toList();

    return BluNestDataTable<TimeOfUse>(
      data: _timeOfUseList,
      columns: TimeOfUseTableColumns.buildBluNestColumns(
        visibleColumns: visibleColumns,
        sortBy: _sortBy,
        sortAscending: _sortAscending,
        onEdit: _editTimeOfUse,
        onDelete: _deleteTimeOfUse,
        onView: _viewTimeOfUseDetails,
      ),
      selectedItems: _selectedTimeOfUse,
      onSelectionChanged: (selectedItems) {
        setState(() {
          _selectedTimeOfUse = selectedItems;
        });
      },
      onSort: (String sortBy, bool ascending) => _handleSort(sortBy),
      sortBy: _sortBy,
      sortAscending: _sortAscending,
      isLoading: _isLoading,
      hiddenColumns: _hiddenColumns,
      onColumnVisibilityChanged: (hiddenColumns) {
        setState(() {
          _hiddenColumns = hiddenColumns;
        });
      },
    );
  }

  Widget _buildKanbanView() {
    return KanbanView<TimeOfUse>(
      columns: [
        KanbanColumn<TimeOfUse>(
          id: 'active',
          title: 'Active Time of Use',
          color: AppColors.success,
          icon: Icons.schedule_outlined,
        ),
        KanbanColumn<TimeOfUse>(
          id: 'inactive',
          title: 'Inactive Time of Use',
          color: AppColors.textSecondary,
          icon: Icons.pause_circle,
        ),
      ],
      items: _timeOfUseList,
      getItemColumn: (timeOfUse) => timeOfUse.active ? 'active' : 'inactive',
      cardBuilder: (timeOfUse) => _buildTimeOfUseKanbanCard(timeOfUse),
      onItemTapped: _viewTimeOfUseDetails,
      isLoading: _isLoading,
      enableDragDrop: false,
    );
  }

  Widget _buildTimeOfUseKanbanCard(TimeOfUse timeOfUse) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spacing12),
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with name and status
          Row(
            children: [
              Expanded(
                child: Text(
                  timeOfUse.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: AppSizes.fontSizeMedium,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              StatusChip(
                text: timeOfUse.active ? 'Active' : 'Inactive',
                compact: true,
                type: timeOfUse.active
                    ? StatusChipType.success
                    : StatusChipType.secondary,
              ),
            ],
          ),

          const SizedBox(height: AppSizes.spacing8),

          // Code
          if (timeOfUse.code.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacing8,
                vertical: AppSizes.spacing4,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              ),
              child: Text(
                'Code: ${timeOfUse.code}',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: AppSizes.fontSizeSmall,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.spacing8),
          ],

          // Description
          if (timeOfUse.description.isNotEmpty) ...[
            Text(
              timeOfUse.description,
              style: const TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSizes.spacing8),
          ],

          // Channels count
          if (timeOfUse.timeOfUseDetails.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.account_tree_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSizes.spacing4),
                Text(
                  '${timeOfUse.timeOfUseDetails.length} channel(s)',
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeSmall,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacing8),
          ],

          // Actions dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                alignment: Alignment.center,
                height: AppSizes.spacing40,
                child: PopupMenuButton<String>(
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
                          Icon(
                            Icons.visibility,
                            size: 16,
                            color: AppColors.primary,
                          ),
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
                          Text(
                            'Delete',
                            style: TextStyle(color: AppColors.error),
                          ),
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
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    if (_timeOfUseList.isEmpty || _isLoading) return const SizedBox.shrink();

    final startItem = ((_currentPage - 1) * _itemsPerPage) + 1;
    final endItem = (_currentPage * _itemsPerPage).clamp(0, _totalItems);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing16),
      child: Column(
        children: [
          // Selected items info (if any)
          if (_selectedTimeOfUse.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(AppSizes.spacing12),
              margin: const EdgeInsets.only(bottom: AppSizes.spacing12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: AppSizes.spacing8),
                  Expanded(
                    child: Text(
                      '${_selectedTimeOfUse.length} time of use(s) selected',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  AppButton(
                    text: 'Delete Selected',
                    type: AppButtonType.outline,
                    size: AppButtonSize.small,
                    onPressed: _bulkDeleteTimeOfUse,
                  ),
                  const SizedBox(width: AppSizes.spacing8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedTimeOfUse.clear();
                      });
                    },
                    child: Text(
                      'Clear Selection',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),

          // Pagination controls
          ResultsPagination(
            currentPage: _currentPage,
            totalPages: _totalPages,
            totalItems: _totalItems,
            startItem: startItem,
            endItem: endItem,
            onPageChanged: (page) => _handlePageChanged(page),
            itemsPerPage: _itemsPerPage,
            onItemsPerPageChanged: _handlePageSizeChanged,
          ),
        ],
      ),
    );
  }
}
