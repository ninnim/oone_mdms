import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/app_lottie_state_widget.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_confirm_dialog.dart';
import '../../widgets/common/blunest_data_table.dart';
import '../../widgets/common/results_pagination.dart';
import '../../widgets/common/kanban_view.dart';
import '../../widgets/special_days/special_day_filters_and_actions_v2.dart';
import '../../widgets/special_days/special_day_form_dialog.dart';
import '../../widgets/special_days/special_day_detail_form_dialog.dart';
import '../../widgets/special_days/special_day_table_columns.dart';
import '../../widgets/special_days/special_day_summary_card.dart';
import '../../widgets/special_days/special_day_kanban_view.dart';
import '../../widgets/special_days/special_day_detail_table_columns.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/models/special_day.dart';
import '../../../core/services/special_day_service.dart';

class SpecialDaysScreen extends StatefulWidget {
  final Function(List<String>)? onBreadcrumbUpdate;

  const SpecialDaysScreen({super.key, this.onBreadcrumbUpdate});

  @override
  State<SpecialDaysScreen> createState() => _SpecialDaysScreenState();
}

class _SpecialDaysScreenState extends State<SpecialDaysScreen> {
  late SpecialDayService _specialDayService;

  // State management
  List<SpecialDay> _specialDays = [];
  List<SpecialDay> _filteredSpecialDays = [];
  Set<SpecialDay> _selectedSpecialDays = {};

  bool _isLoading = false;
  String? _errorMessage;

  // Filtering & Search
  String _searchQuery = '';

  // View Mode
  SpecialDayViewMode _currentViewMode = SpecialDayViewMode.table;

  // Sidebar state
  bool _isSidebarOpen = false;
  SpecialDay? _selectedSpecialDayForDetails;
  List<SpecialDayDetail> _specialDayDetails = [];
  bool _isLoadingDetails = false;

  // Sorting
  String _sortBy = 'name';
  bool _sortAscending = true;

  // Table Configuration
  final List<String> _availableColumns = [
    'No.',
    'Name',
    'Description',
    'Special Day Details',
    'Status',
    'Actions',
  ];
  List<String> _hiddenColumns = [];

  // Sub-details table sorting
  String? _subDetailsSortColumn;
  bool _subDetailsSortAscending = true;

  // Pagination
  int _currentPage = 1;
  int _itemsPerPage = 10;
  int get _totalPages => (_filteredSpecialDays.length / _itemsPerPage).ceil();
  int get _offset => (_currentPage - 1) * _itemsPerPage;
  List<SpecialDay> get _paginatedSpecialDays {
    final start = _offset;
    final end = (start + _itemsPerPage).clamp(0, _filteredSpecialDays.length);
    return _filteredSpecialDays.sublist(start, end);
  }

  @override
  void initState() {
    super.initState();
    _specialDayService = Provider.of<SpecialDayService>(context, listen: false);
    _loadSpecialDays();
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

  void _onViewModeChanged(SpecialDayViewMode mode) {
    setState(() {
      _currentViewMode = mode;
    });
  }

  void _handleSort(String column, bool ascending) {
    setState(() {
      _sortBy = column;
      _sortAscending = ascending;
    });
    _applyFilters();
  }

  void _onSpecialDaySelected(SpecialDay specialDay) {
    setState(() {
      _selectedSpecialDayForDetails = specialDay;
      _isSidebarOpen = true;
    });
    _loadSpecialDayDetails(specialDay.id);
  }

  void _onSidebarClosed() {
    setState(() {
      _isSidebarOpen = false;
      _selectedSpecialDayForDetails = null;
      _specialDayDetails = [];
    });
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });

    // If we're opening the sidebar and have a selected special day, refresh its details
    if (_isSidebarOpen && _selectedSpecialDayForDetails != null) {
      _loadSpecialDayDetails(_selectedSpecialDayForDetails!.id);
    }
  }

  void _closeSidebarCompletely() {
    setState(() {
      _isSidebarOpen = false;
      _selectedSpecialDayForDetails = null;
      _specialDayDetails = [];
    });
  }

  // Data loading and processing
  Future<void> _loadSpecialDays() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _specialDayService.getSpecialDays(
        search: _searchQuery.isEmpty ? '%%' : '%$_searchQuery%',
        offset: 0,
        limit: 1000, // Load all for local filtering
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (response.success && response.data != null) {
            _specialDays = response.data!;
            print('🔄 Loaded ${_specialDays.length} special days from API');
            _applyFilters();
          } else {
            _errorMessage = response.message ?? 'Failed to load special days';
            _specialDays = [];
            _filteredSpecialDays = [];
            print('❌ Failed to load special days: $_errorMessage');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Network error: Please check your connection';
          _specialDays = [];
          _filteredSpecialDays = [];
        });
      }
    }
  }

  Future<void> _loadSpecialDayDetails(int specialDayId) async {
    setState(() {
      _isLoadingDetails = true;
    });

    try {
      final response = await _specialDayService.getSpecialDayById(
        specialDayId,
        includeSpecialDayDetail: true,
      );

      if (mounted) {
        setState(() {
          _isLoadingDetails = false;
          if (response.success && response.data != null) {
            _specialDayDetails = response.data!.specialDayDetails;
          } else {
            _specialDayDetails = [];
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDetails = false;
          _specialDayDetails = [];
        });
      }
    }
  }

  void _applyFilters() {
    List<SpecialDay> filtered = List.from(_specialDays);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((specialDay) {
        return specialDay.name.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            specialDay.description.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
      }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      int result = 0;
      switch (_sortBy) {
        case 'name':
          result = a.name.compareTo(b.name);
          break;
        case 'description':
          result = a.description.compareTo(b.description);
          break;
        case 'active':
          result = a.active.toString().compareTo(b.active.toString());
          break;
        default:
          result = a.name.compareTo(b.name);
      }
      return _sortAscending ? result : -result;
    });

    setState(() {
      _filteredSpecialDays = filtered;
      // Reset to first page if current page is beyond the new total
      final newTotalPages = (_filteredSpecialDays.length / _itemsPerPage)
          .ceil();
      if (_currentPage > newTotalPages && newTotalPages > 0) {
        _currentPage = 1;
      }
      print(
        '🔄 Applied filters: ${_filteredSpecialDays.length} items, $_totalPages pages',
      );
    });
  }

  // CRUD Operations
  Future<void> _createSpecialDay() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SpecialDayFormDialog(
        onSave: (specialDay) async {
          final response = await _specialDayService.createSpecialDay(
            specialDay,
          );
          if (response.success) {
            await _loadSpecialDays();
            if (mounted) {
              AppToast.show(
                context,
                title: 'Success',
                message: 'Special day created successfully',
                type: ToastType.success,
              );
            }
          } else {
            if (mounted) {
              AppToast.show(
                context,
                title: 'Error',
                message: response.message ?? 'Failed to create special day',
                type: ToastType.error,
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _editSpecialDay(SpecialDay specialDay) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SpecialDayFormDialog(
        specialDay: specialDay,
        onSave: (specialDay) async {
          final response = await _specialDayService.updateSpecialDay(
            specialDay,
          );
          if (response.success) {
            await _loadSpecialDays();
            if (mounted) {
              AppToast.show(
                context,
                title: 'Success',
                message: 'Special day updated successfully',
                type: ToastType.success,
              );
            }
          } else {
            if (mounted) {
              AppToast.show(
                context,
                title: 'Error',
                message: response.message ?? 'Failed to update special day',
                type: ToastType.error,
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _deleteSpecialDay(SpecialDay specialDay) async {
    print(
      '🗑️ Delete special day called for: ${specialDay.name} (ID: ${specialDay.id})',
    );

    final confirm = await AppConfirmDialog.show(
      context,
      title: 'Delete Special Day',
      message:
          'Are you sure you want to delete "${specialDay.name}"? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      confirmType: AppButtonType.danger,
      icon: Icons.delete_outline,
    );

    print('🗑️ Delete confirmation result: $confirm');

    if (confirm == true) {
      print(
        '🗑️ Starting delete operation for special day ID: ${specialDay.id}',
      );

      setState(() {
        _isLoading = true;
      });

      try {
        print('🗑️ Calling API delete service...');
        final response = await _specialDayService.deleteSpecialDay(
          specialDay.id,
        );

        print(
          '🗑️ Delete API response: success=${response.success}, message=${response.message}',
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          if (response.success) {
            print('🗑️ Delete successful, showing success toast');
            AppToast.showSuccess(
              context,
              title: 'Special Day Deleted',
              message:
                  'Special day "${specialDay.name}" has been successfully deleted.',
            );

            print('🗑️ Reloading special days list...');
            await _loadSpecialDays();

            // Close sidebar if this special day was selected
            if (_selectedSpecialDayForDetails?.id == specialDay.id) {
              print('🗑️ Closing sidebar as deleted item was selected');
              _onSidebarClosed();
            }
          } else {
            print('🗑️ Delete failed, showing error toast');
            AppToast.showError(
              context,
              error: response.message ?? 'Failed to delete special day',
              title: 'Delete Failed',
              errorContext: 'special_day_delete',
            );
          }
        }
      } catch (e) {
        print('🗑️ Delete operation threw exception: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          AppToast.showError(
            context,
            error: 'Network error: Please check your connection',
            title: 'Connection Error',
            errorContext: 'special_day_delete_network',
          );
        }
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadSpecialDays();
  }

  // Special Day Detail CRUD Operations
  Future<void> _createSpecialDayDetail(SpecialDay specialDay) async {
    final availableParentSpecialDays = [
      specialDay,
    ]; // Only allow current special day as parent

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SpecialDayDetailFormDialog(
        availableParentSpecialDays: availableParentSpecialDays,
        preferredParentId: specialDay.id, // Auto-select the current special day
        onSave: (detail) async {
          final response = await _specialDayService.createSpecialDayDetail(
            detail,
          );
          if (response.success) {
            _loadSpecialDayDetails(specialDay.id);
            if (mounted) {
              AppToast.show(
                context,
                title: 'Success',
                message: 'Special day detail created successfully',
                type: ToastType.success,
              );
            }
          } else {
            if (mounted) {
              AppToast.show(
                context,
                title: 'Error',
                message:
                    response.message ?? 'Failed to create special day detail',
                type: ToastType.error,
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _editSpecialDayDetail(SpecialDayDetail detail) async {
    final availableParentSpecialDays = [
      _selectedSpecialDayForDetails!,
    ]; // Only allow current special day as parent

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SpecialDayDetailFormDialog(
        specialDayDetail: detail,
        availableParentSpecialDays: availableParentSpecialDays,
        preferredParentId: _selectedSpecialDayForDetails!.id,
        onSave: (detail) async {
          final response = await _specialDayService.updateSpecialDayDetail(
            detail,
          );
          if (response.success) {
            _loadSpecialDayDetails(_selectedSpecialDayForDetails!.id);
            if (mounted) {
              AppToast.show(
                context,
                title: 'Success',
                message: 'Special day detail updated successfully',
                type: ToastType.success,
              );
            }
          } else {
            if (mounted) {
              AppToast.show(
                context,
                title: 'Error',
                message:
                    response.message ?? 'Failed to update special day detail',
                type: ToastType.error,
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _deleteSpecialDayDetail(SpecialDayDetail detail) async {
    print(
      '🗑️ Delete special day detail called for: ${detail.name} (ID: ${detail.id})',
    );

    final confirm = await AppConfirmDialog.show(
      context,
      title: 'Delete Special Day Detail',
      message:
          'Are you sure you want to delete this special day detail? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      confirmType: AppButtonType.danger,
      icon: Icons.delete_outline,
    );

    print('🗑️ Delete detail confirmation result: $confirm');

    if (confirm == true) {
      print(
        '🗑️ Starting delete operation for special day detail ID: ${detail.id}',
      );

      try {
        print('🗑️ Calling API delete detail service...');
        final response = await _specialDayService.deleteSpecialDayDetail(
          detail.id,
        );

        print(
          '🗑️ Delete detail API response: success=${response.success}, message=${response.message}',
        );

        if (mounted) {
          if (response.success) {
            print('🗑️ Delete detail successful, showing success toast');
            AppToast.showSuccess(
              context,
              title: 'Detail Deleted',
              message: 'Special day detail has been successfully deleted.',
            );
            // Refresh special day details
            print('🗑️ Reloading special day details...');
            _loadSpecialDayDetails(_selectedSpecialDayForDetails!.id);
          } else {
            print('🗑️ Delete detail failed, showing error toast');
            AppToast.showError(
              context,
              error: response.message ?? 'Failed to delete special day detail',
              title: 'Delete Failed',
              errorContext: 'special_day_detail_delete',
            );
          }
        }
      } catch (e) {
        print('🗑️ Delete detail operation threw exception: $e');
        if (mounted) {
          AppToast.showError(
            context,
            error: 'Network error: Please check your connection',
            title: 'Connection Error',
            errorContext: 'special_day_detail_delete_network',
          );
        }
      }
    }
  }

  // UI Builders
  Widget _buildHeader() {
    return Column(
      children: [
        SpecialDayFiltersAndActionsV2(
          onSearchChanged: _onSearchChanged,
          onViewModeChanged: _onViewModeChanged,
          onAddSpecialDay: _createSpecialDay,
          onRefresh: _refreshData,
          currentViewMode: _currentViewMode,
        ),
        const SizedBox(height: AppSizes.spacing16),
        SpecialDaySummaryCard(specialDays: _filteredSpecialDays),
      ],
    );
  }

  Widget _buildContent() {
    // Show full-screen loading only if no data exists yet
    if (_isLoading && _specialDays.isEmpty) {
      return const Center(
        child: AppLottieStateWidget.loading(
          title: 'Loading Special Days',
          lottieSize: 100,
          message: 'Please wait while we fetch your special days.',
        ),
      );
    }

    if (_errorMessage != null && _specialDays.isEmpty) {
      return AppLottieStateWidget.error(
        title: 'Error Loading Special Days',
        message: _errorMessage!,
        buttonText: 'Try Again',
        onButtonPressed: _loadSpecialDays,
      );
    }

    if (_filteredSpecialDays.isEmpty && !_isLoading) {
      return AppLottieStateWidget.noData(
        title: _searchQuery.isNotEmpty ? 'No Results Found' : 'No Special Days',
        message: _searchQuery.isNotEmpty
            ? 'No special days match your search criteria.'
            : 'Start by creating your first special day.',
        buttonText: 'Create Special Day',
        onButtonPressed: _createSpecialDay,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      child: _buildViewContent(),
    );
  }

  Widget _buildViewContent() {
    return _currentViewMode == SpecialDayViewMode.table
        ? _buildTableView()
        : _buildKanbanView();
  }

  Widget _buildTableView() {
    return BluNestDataTable<SpecialDay>(
      columns: _buildTableColumns(),
      data: _paginatedSpecialDays,
      isLoading: _isLoading,
      onSort: _handleSort,
      sortBy: _sortBy,
      sortAscending: _sortAscending,
      selectedItems: _selectedSpecialDays,
      onSelectionChanged: (selection) {
        setState(() {
          _selectedSpecialDays = selection;
        });
      },
      onRowTap: _onSpecialDaySelected,
      enableMultiSelect: true,
      hiddenColumns: _hiddenColumns,
      onColumnVisibilityChanged: (hiddenColumns) {
        setState(() {
          _hiddenColumns = hiddenColumns;
        });
      },
      emptyState: AppLottieStateWidget.noData(
        title: 'No Special Days',
        message: 'No special days found for the current filter criteria.',
        lottieSize: 120,
      ),
    );
  }

  List<BluNestTableColumn<SpecialDay>> _buildTableColumns() {
    return SpecialDayTableColumns.buildBluNestColumns(
      visibleColumns: _availableColumns
          .where((col) => !_hiddenColumns.contains(col))
          .toList(),
      sortBy: _sortBy,
      sortAscending: _sortAscending,
      onSort: _handleSort,
      onEdit: _editSpecialDay,
      onDelete: _deleteSpecialDay,
      onView: _onSpecialDaySelected,
      currentPage: _currentPage,
      itemsPerPage: _itemsPerPage,
      specialDays: _paginatedSpecialDays,
    );
  }

  Widget _buildKanbanView() {
    return KanbanView<SpecialDay>(
      columns: [
        KanbanColumn<SpecialDay>(
          id: 'active',
          title: 'Active Special Days',
          color: AppColors.success,
          icon: Icons.check_circle,
        ),
        KanbanColumn<SpecialDay>(
          id: 'inactive',
          title: 'Inactive Special Days',
          color: AppColors.textSecondary,
          icon: Icons.pause_circle,
        ),
      ],
      items: _paginatedSpecialDays,
      getItemColumn: (specialDay) => specialDay.active ? 'active' : 'inactive',
      cardBuilder: (specialDay) => SpecialDayKanbanView.buildSpecialDayCard(
        specialDay,
        onEdit: _editSpecialDay,
        onDelete: _deleteSpecialDay,
        onView: _onSpecialDaySelected,
      ),
      onItemTapped: _onSpecialDaySelected,
      isLoading: _isLoading,
      emptyState: AppLottieStateWidget.noData(
        title: 'No Special Days',
        message: 'No special days found for the current filter criteria.',
        lottieSize: 120,
      ),
    );
  }

  Widget _buildPagination() {
    final startItem = (_currentPage - 1) * _itemsPerPage + 1;
    final endItem = (_currentPage * _itemsPerPage) > _filteredSpecialDays.length
        ? _filteredSpecialDays.length
        : _currentPage * _itemsPerPage;

    return ResultsPagination(
      currentPage: _currentPage,
      totalPages: _totalPages,
      totalItems: _filteredSpecialDays.length,
      itemsPerPage: _itemsPerPage,
      startItem: startItem,
      endItem: endItem,
      onPageChanged: (page) {
        setState(() {
          _currentPage = page;
        });
        _loadSpecialDays();
      },
      onItemsPerPageChanged: (newItemsPerPage) {
        setState(() {
          _itemsPerPage = newItemsPerPage;
          _currentPage = 1;
        });
        _loadSpecialDays();
      },
      // itemLabel: 'special days',
    showItemsPerPageSelector: true,
    );
  }

  Widget _buildSidebarContent() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.spacing8),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSizes.spacing8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
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
                if (_isSidebarOpen) ...[
                  const SizedBox(width: AppSizes.spacing8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Special Day Details',
                          style: TextStyle(fontSize: AppSizes.fontSizeLarge),
                        ),
                        const SizedBox(height: AppSizes.spacing4),
                        Text(
                          'Parent: ${_selectedSpecialDayForDetails?.name ?? ''}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                  AppButton(
                    text: 'Add Detail',
                    onPressed: () =>
                        _createSpecialDayDetail(_selectedSpecialDayForDetails!),
                    type: AppButtonType.primary,
                    size: AppButtonSize.small,
                    icon: const Icon(Icons.add, size: AppSizes.iconSmall),
                  ),
                ],
              ],
            ),
          ),
          // Content
          if (_isSidebarOpen)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.spacing16),
                child: _buildSpecialDayDetailsTable(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCollapsedSidebar() {
    // return Container(
    //   padding: const EdgeInsets.all(AppSizes.spacing8),
    //   child: Column(
    //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //     children: [
    //       IconButton(
    //         onPressed: _toggleSidebar,
    //         icon: const Icon(Icons.keyboard_arrow_left, size: 20),
    //         tooltip: 'Expand sidebar',
    //         style: IconButton.styleFrom(
    //           backgroundColor: AppColors.surface,
    //           foregroundColor: AppColors.textSecondary,
    //           padding: const EdgeInsets.all(6),
    //           minimumSize: const Size(28, 28),
    //           shape: RoundedRectangleBorder(
    //             borderRadius: BorderRadius.circular(4),
    //             side: BorderSide(color: AppColors.border),
    //           ),
    //         ),
    //       ),
    //       const SizedBox(height: AppSizes.spacing8),
    //       if (_selectedSpecialDayForDetails != null) ...[
    //         SizedBox(
    //           height: 200, // Fixed height instead of Expanded
    //           child: RotatedBox(
    //             quarterTurns: 3,
    //             child: Text(
    //               _selectedSpecialDayForDetails!.name,
    //               style: TextStyle(
    //                 fontSize: AppSizes.fontSizeLarge,
    //                 color: AppColors.textSecondary,
    //                 fontWeight: FontWeight.w500,
    //               ),
    //               textAlign: TextAlign.center,
    //               overflow: TextOverflow.ellipsis,
    //             ),
    //           ),
    //         ),
    //       ],
    //       // const Spacer(),
    //       const SizedBox(height: AppSizes.spacing8),
    //       IconButton(
    //         onPressed: _closeSidebarCompletely,
    //         icon: const Icon(Icons.close, size: AppSizes.iconSmall),
    //         tooltip: 'Close sidebar',
    //         style: IconButton.styleFrom(
    //           backgroundColor: AppColors.surface,
    //           foregroundColor: AppColors.textTertiary,
    //           padding: const EdgeInsets.all(4),
    //           minimumSize: const Size(30, 30),
    //           shape: RoundedRectangleBorder(
    //             borderRadius: BorderRadius.circular(4),
    //             side: BorderSide(color: AppColors.borderLight),
    //           ),
    //         ),
    //       ),
    //       const SizedBox(height: AppSizes.spacing8),
    //     ],
    //   ),
    // );
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
          if (_selectedSpecialDayForDetails != null)
            SizedBox(
              height: 200, // Fixed height instead of Expanded
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(
                  _selectedSpecialDayForDetails!.name,
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

  Widget _buildSpecialDayDetailsTable() {
    if (_isLoadingDetails) {
      return const AppLottieStateWidget.loading(
        message: 'Loading special day details...',
        lottieSize: 100,
      );
    }

    //EmptyData
    // if (_specialDayDetails.isEmpty) {
    //   return AppLottieStateWidget.noData(
    //     title: 'No Details',
    //     message: 'This special day has no details yet.',
    //     lottieSize: 120,
    //   );
    // }

    List<SpecialDayDetail> sortedDetails = List.from(_specialDayDetails);
    if (_subDetailsSortColumn != null) {
      sortedDetails.sort((a, b) {
        int result = 0;
        switch (_subDetailsSortColumn) {
          case 'name':
            result = a.name.compareTo(b.name);
            break;
          case 'startDate':
            result = a.startDate.compareTo(b.startDate);
            break;
          case 'endDate':
            result = a.endDate.compareTo(b.endDate);
            break;
          case 'description':
            result = a.description.compareTo(b.description);
            break;
          default:
            result = a.name.compareTo(b.name);
        }
        return _subDetailsSortAscending ? result : -result;
      });
    }

    final columns = SpecialDayDetailTableColumns.getBluNestColumns(
      context: context,
      onEdit: _editSpecialDayDetail,
      onDelete: _deleteSpecialDayDetail,
      sortColumn: _subDetailsSortColumn,
      sortAscending: _subDetailsSortAscending,
      specialDayDetails: sortedDetails,
    );

    print(
      '🔄 Building special day details table with ${sortedDetails.length} items',
    );

    return BluNestDataTable<SpecialDayDetail>(
      key: ValueKey(
        'special_day_details_table_${_selectedSpecialDayForDetails?.id}_${_specialDayDetails.length}',
      ),
      columns: columns,
      data: sortedDetails,
      isLoading: _isLoadingDetails,
      sortBy: _subDetailsSortColumn,
      sortAscending: _subDetailsSortAscending,
      onSort: (column, ascending) {
        print(
          '🔄 Special day details table sort changed: $column, ascending: $ascending',
        );
        setState(() {
          _subDetailsSortColumn = column;
          _subDetailsSortAscending = ascending;
        });
      },
      emptyState: AppLottieStateWidget.noData(
        title: 'No Special Day Details',
        message: 'This special day has no details yet.',
        lottieSize: 120,
      ),
    );
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
                // Always show pagination area, even if empty
                _buildPagination(),
              ],
            ),
          ),
          // Sticky sidebar
          if (_selectedSpecialDayForDetails != null)
            Container(
              width: _isSidebarOpen ? 550 : 60,
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
}
