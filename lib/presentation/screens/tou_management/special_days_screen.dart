import 'package:flutter/material.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_input_field.dart';
import '../../widgets/common/blunest_data_table.dart';
import '../../widgets/common/status_chip.dart';
import '../../widgets/common/results_pagination.dart';
import '../../widgets/common/app_lottie_state_widget.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/special_day.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/services/tou_service.dart';

class SpecialDaysScreen extends StatefulWidget {
  const SpecialDaysScreen({super.key});

  @override
  State<SpecialDaysScreen> createState() => _SpecialDaysScreenState();
}

class _SpecialDaysScreenState extends State<SpecialDaysScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final TouService _touService;
  bool _isLoading = false;
  List<SpecialDay> _specialDays = [];
  Set<SpecialDay> _selectedSpecialDays = {};
  List<String> _hiddenColumns = [];
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  int _itemsPerPage = 25;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    // Use ServiceLocator to get properly configured API service
    final serviceLocator = ServiceLocator();
    final apiService = serviceLocator.apiService;
    _touService = TouService(apiService);
    _loadSpecialDays();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSpecialDays() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _touService.getSpecialDays(
        search: _searchController.text,
        limit: _itemsPerPage,
        offset: (_currentPage - 1) * _itemsPerPage,
        includeSpecialDayDetail: true,
      );

      if (response.success && response.data != null) {
        setState(() {
          _specialDays = response.data!;
          _totalItems =
              response.data!.length; // This should come from API paging
          _totalPages = (_totalItems / _itemsPerPage).ceil();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Failed to load special days';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading special days: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state
    if (_isLoading && _specialDays.isEmpty) {
      return const AppLottieStateWidget.loading(
        title: 'Loading Special Days',
        message:
            'Please wait while we fetch your special day configurations...',
      );
    }

    // Show error state if error and no data
    if (_errorMessage.isNotEmpty && _specialDays.isEmpty) {
      return AppLottieStateWidget.error(
        title: 'Failed to Load Special Days',
        message: _errorMessage,
        buttonText: 'Try Again',
        onButtonPressed: _loadSpecialDays,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppSizes.spacing24),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: AppSizes.spacing24),
          _buildErrorMessage(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // Show no data state if no special days after loading
    if (!_isLoading && _specialDays.isEmpty && _errorMessage.isEmpty) {
      return AppLottieStateWidget.noData(
        title: 'No Special Days Found',
        message:
            'No special days have been configured yet. Click "Add Special Day" to create your first special day configuration.',
        buttonText: 'Add Special Day',
        onButtonPressed: _createSpecialDay,
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildTableHeader(),
          if (_selectedSpecialDays.isNotEmpty) _buildMultiSelectToolbar(),
          Expanded(child: _buildSpecialDaysTable()),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: AppInputField(
            controller: _searchController,
            hintText: 'Search special days',
            prefixIcon: const Icon(Icons.search, size: AppSizes.iconMedium),
            onChanged: (value) {
              _loadSpecialDays();
            },
          ),
        ),
        const SizedBox(width: AppSizes.spacing16),
        AppButton(
          text: 'Add Special Day',
          type: AppButtonType.primary,
          icon: const Icon(
            Icons.add,
            size: AppSizes.iconSmall,
            color: AppColors.textInverse,
          ),
          onPressed: () {
            _createSpecialDay();
          },
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Special Days',
              style: TextStyle(
                fontSize: AppSizes.fontSizeLarge,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          AppInputField(
            hintText: 'Filter...',
            prefixIcon: const Icon(Icons.filter_list, size: AppSizes.iconSmall),
            onChanged: (value) {
              // Implement filter
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    if (_errorMessage.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spacing16),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: AppSizes.iconMedium,
          ),
          const SizedBox(width: AppSizes.spacing8),
          Expanded(
            child: Text(
              _errorMessage,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: AppSizes.fontSizeMedium,
              ),
            ),
          ),
          IconButton(
            onPressed: _loadSpecialDays,
            icon: const Icon(Icons.refresh, color: AppColors.error),
            tooltip: 'Retry',
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialDaysTable() {
    return BluNestDataTable<SpecialDay>(
      columns: [
        BluNestTableColumn<SpecialDay>(
          key: 'id',
          title: 'ID',
          builder: (specialDay) => SizedBox(
            width: 60,
            child: Text(
              specialDay.id.toString(),
              style: const TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        BluNestTableColumn<SpecialDay>(
          key: 'name',
          title: 'Name',
          builder: (specialDay) => Expanded(
            flex: 2,
            child: Text(
              specialDay.name,
              style: const TextStyle(
                fontSize: AppSizes.fontSizeMedium,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        BluNestTableColumn<SpecialDay>(
          key: 'description',
          title: 'Description',
          builder: (specialDay) => Expanded(
            flex: 2,
            child: Text(
              specialDay.description,
              style: const TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        BluNestTableColumn<SpecialDay>(
          key: 'details',
          title: 'Details',
          builder: (specialDay) => SizedBox(
            width: 80,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacing8,
                vertical: AppSizes.spacing4,
              ),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              ),
              child: Text(
                specialDay.specialDayDetails.length.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: AppSizes.fontSizeSmall,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              ),
            ),
          ),
        ),
        BluNestTableColumn<SpecialDay>(
          key: 'dateRanges',
          title: 'Date Ranges',
          builder: (specialDay) => Expanded(
            flex: 2,
            child: specialDay.specialDayDetails.isNotEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: specialDay.specialDayDetails.take(2).map((
                      detail,
                    ) {
                      return Container(
                        margin: const EdgeInsets.only(
                          bottom: AppSizes.spacing4,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.spacing6,
                          vertical: AppSizes.spacing2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusSmall,
                          ),
                          border: Border.all(
                            color: AppColors.info.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          detail.dateRangeDisplay,
                          style: const TextStyle(
                            fontSize: AppSizes.fontSizeExtraSmall,
                            color: AppColors.info,
                          ),
                        ),
                      );
                    }).toList(),
                  )
                : const Text(
                    'No date ranges',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeSmall,
                      color: AppColors.textTertiary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
          ),
        ),
        BluNestTableColumn<SpecialDay>(
          key: 'status',
          title: 'Status',
          builder: (specialDay) => SizedBox(
            width: 80,
            child: StatusChip(
              text: specialDay.active ? 'Active' : 'Inactive',
              type: specialDay.active
                  ? StatusChipType.success
                  : StatusChipType.secondary,
            ),
          ),
        ),
        BluNestTableColumn<SpecialDay>(
          key: 'actions',
          title: 'Actions',
          builder: (specialDay) => SizedBox(
            width: 120,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _viewSpecialDayDetails(specialDay),
                  icon: const Icon(Icons.visibility, size: AppSizes.iconSmall),
                  tooltip: 'View Details',
                ),
                IconButton(
                  onPressed: () => _editSpecialDay(specialDay),
                  icon: const Icon(Icons.edit, size: AppSizes.iconSmall),
                  tooltip: 'Edit',
                ),
                IconButton(
                  onPressed: () => _deleteSpecialDay(specialDay),
                  icon: const Icon(
                    Icons.delete,
                    size: AppSizes.iconSmall,
                    color: AppColors.error,
                  ),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ),
        ),
      ],
      data: _specialDays,
      isLoading: _isLoading,
      enableMultiSelect: true,
      selectedItems: _selectedSpecialDays,
      onSelectionChanged: (selectedItems) {
        setState(() {
          _selectedSpecialDays = selectedItems;
        });
      },
      hiddenColumns: _hiddenColumns,
      onColumnVisibilityChanged: (hiddenColumns) {
        setState(() {
          _hiddenColumns = hiddenColumns;
        });
      },
      onRowTap: _viewSpecialDayDetails,
      onEdit: _editSpecialDay,
      onDelete: _deleteSpecialDay,
      onView: _viewSpecialDayDetails,
    );
  }

  Widget _buildMultiSelectToolbar() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        border: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Text(
            '${_selectedSpecialDays.length} special days selected',
            style: const TextStyle(
              fontSize: AppSizes.fontSizeMedium,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
          const Spacer(),
          AppButton(
            text: 'Delete Selected',
            type: AppButtonType.outline,
            size: AppButtonSize.small,
            onPressed: () => _showBulkDeleteConfirmation(),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    final startItem = (_currentPage - 1) * _itemsPerPage + 1;
    final endItem = (_currentPage * _itemsPerPage) > _totalItems
        ? _totalItems
        : _currentPage * _itemsPerPage;

    return ResultsPagination(
      currentPage: _currentPage,
      totalPages: _totalPages,
      totalItems: _totalItems,
      itemsPerPage: _itemsPerPage,
      itemsPerPageOptions: const [
        5,
        10,
        20,
        25,
        50,
      ], // Include 25 to match _itemsPerPage default
      startItem: startItem,
      endItem: endItem,
      onPageChanged: (page) {
        setState(() {
          _currentPage = page;
        });
        _loadSpecialDays();
      },
      onItemsPerPageChanged: (itemsPerPage) {
        setState(() {
          _itemsPerPage = itemsPerPage;
          _currentPage = 1;
          _totalPages = (_totalItems / _itemsPerPage).ceil();
        });
        _loadSpecialDays();
      },
      itemLabel: 'special days',
      showItemsPerPageSelector: true,
    );
  }

  void _createSpecialDay() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create special day - Coming soon')),
    );
  }

  void _viewSpecialDayDetails(SpecialDay specialDay) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View details for ${specialDay.name}')),
    );
  }

  void _editSpecialDay(SpecialDay specialDay) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Edit ${specialDay.name}')));
  }

  void _deleteSpecialDay(SpecialDay specialDay) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Special Day'),
        content: Text('Are you sure you want to delete "${specialDay.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          AppButton(
            text: 'Delete',
            type: AppButtonType.danger,
            size: AppButtonSize.small,
            onPressed: () {
              Navigator.of(context).pop();
              _performDeleteSpecialDay(specialDay);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteSpecialDay(SpecialDay specialDay) async {
    try {
      final response = await _touService.deleteSpecialDay(specialDay.id);
      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Special day "${specialDay.name}" deleted successfully',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        _loadSpecialDays();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Failed to delete special day'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting special day: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showBulkDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Special Days'),
        content: Text(
          'Are you sure you want to delete ${_selectedSpecialDays.length} special days?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          AppButton(
            text: 'Delete All',
            type: AppButtonType.danger,
            size: AppButtonSize.small,
            onPressed: () {
              Navigator.of(context).pop();
              _performBulkDelete();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _performBulkDelete() async {
    final selectedIds = _selectedSpecialDays.map((sd) => sd.id).toList();

    for (final id in selectedIds) {
      await _touService.deleteSpecialDay(id);
    }

    setState(() {
      _selectedSpecialDays.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${selectedIds.length} special days deleted'),
        backgroundColor: AppColors.success,
      ),
    );

    _loadSpecialDays();
  }
}
