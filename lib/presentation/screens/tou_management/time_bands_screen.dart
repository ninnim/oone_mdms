import 'package:flutter/material.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_input_field.dart';
import '../../widgets/common/blunest_data_table.dart';
import '../../widgets/common/status_chip.dart';
import '../../widgets/common/results_pagination.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/time_band.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/tou_service.dart';

class TimeBandsScreen extends StatefulWidget {
  const TimeBandsScreen({super.key});

  @override
  State<TimeBandsScreen> createState() => _TimeBandsScreenState();
}

class _TimeBandsScreenState extends State<TimeBandsScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final TouService _touService;
  bool _isLoading = false;
  List<TimeBand> _timeBands = [];
  Set<TimeBand> _selectedTimeBands = {};
  List<String> _hiddenColumns = [];
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  int _itemsPerPage = 25;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _touService = TouService(ApiService());
    _loadTimeBands();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTimeBands() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _touService.getTimeBands(
        search: _searchController.text,
        limit: _itemsPerPage,
        offset: (_currentPage - 1) * _itemsPerPage,
        includeTimeBandAttributes: true,
      );

      if (response.success && response.data != null) {
        setState(() {
          _timeBands = response.data!;
          // Note: API response should include paging info
          _totalItems = response.data!.length; // This should come from API
          _totalPages = (_totalItems / _itemsPerPage).ceil();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Failed to load time bands';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading time bands: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.spacing24),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: AppSizes.spacing24),
          _buildErrorMessage(),
          Expanded(
            child: AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildTableHeader(),
                  if (_selectedTimeBands.isNotEmpty) _buildMultiSelectToolbar(),
                  Expanded(child: _buildTimeBandsTable()),
                  _buildPagination(),
                ],
              ),
            ),
          ),
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
            hintText: 'Search time bands',
            prefixIcon: const Icon(Icons.search, size: AppSizes.iconMedium),
            onChanged: (value) {
              _loadTimeBands();
            },
          ),
        ),
        const SizedBox(width: AppSizes.spacing16),
        AppButton(
          text: 'Add Time Band',
          type: AppButtonType.primary,
          icon: const Icon(
            Icons.add,
            size: AppSizes.iconSmall,
            color: AppColors.textInverse,
          ),
          onPressed: () {
            _createTimeBand();
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
              'Time Bands',
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
            onPressed: _loadTimeBands,
            icon: const Icon(Icons.refresh, color: AppColors.error),
            tooltip: 'Retry',
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBandsTable() {
    return BluNestDataTable<TimeBand>(
      columns: [
        BluNestTableColumn<TimeBand>(
          key: 'id',
          title: 'ID',
          builder: (timeBand) => SizedBox(
            width: 60,
            child: Text(
              timeBand.id.toString(),
              style: const TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        BluNestTableColumn<TimeBand>(
          key: 'name',
          title: 'Name',
          builder: (timeBand) => Expanded(
            flex: 2,
            child: Text(
              timeBand.name,
              style: const TextStyle(
                fontSize: AppSizes.fontSizeMedium,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        BluNestTableColumn<TimeBand>(
          key: 'timeRange',
          title: 'Time Range',
          builder: (timeBand) => Expanded(
            child: Text(
              '${timeBand.startTime} - ${timeBand.endTime}',
              style: const TextStyle(
                fontSize: AppSizes.fontSizeMedium,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        BluNestTableColumn<TimeBand>(
          key: 'description',
          title: 'Description',
          builder: (timeBand) => Expanded(
            flex: 2,
            child: Text(
              timeBand.description,
              style: const TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        BluNestTableColumn<TimeBand>(
          key: 'status',
          title: 'Status',
          builder: (timeBand) => SizedBox(
            width: 80,
            child: StatusChip(
              text: timeBand.active ? 'Active' : 'Inactive',
              type: timeBand.active
                  ? StatusChipType.success
                  : StatusChipType.secondary,
            ),
          ),
        ),
        BluNestTableColumn<TimeBand>(
          key: 'attributes',
          title: 'Attributes',
          builder: (timeBand) => SizedBox(
            width: 80,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacing8,
                vertical: AppSizes.spacing4,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              ),
              child: Text(
                timeBand.timeBandAttributes.length.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: AppSizes.fontSizeSmall,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
        BluNestTableColumn<TimeBand>(
          key: 'actions',
          title: 'Actions',
          builder: (timeBand) => SizedBox(
            width: 120,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _viewTimeBandDetails(timeBand),
                  icon: const Icon(Icons.visibility, size: AppSizes.iconSmall),
                  tooltip: 'View Details',
                ),
                IconButton(
                  onPressed: () => _editTimeBand(timeBand),
                  icon: const Icon(Icons.edit, size: AppSizes.iconSmall),
                  tooltip: 'Edit',
                ),
                IconButton(
                  onPressed: () => _deleteTimeBand(timeBand),
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
      data: _timeBands,
      isLoading: _isLoading,
      enableMultiSelect: true,
      selectedItems: _selectedTimeBands,
      onSelectionChanged: (selectedItems) {
        setState(() {
          _selectedTimeBands = selectedItems;
        });
      },
      hiddenColumns: _hiddenColumns,
      onColumnVisibilityChanged: (hiddenColumns) {
        setState(() {
          _hiddenColumns = hiddenColumns;
        });
      },
      onRowTap: _viewTimeBandDetails,
      onEdit: _editTimeBand,
      onDelete: _deleteTimeBand,
      onView: _viewTimeBandDetails,
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
            '${_selectedTimeBands.length} time bands selected',
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
      startItem: startItem,
      endItem: endItem,
      onPageChanged: (page) {
        setState(() {
          _currentPage = page;
        });
        _loadTimeBands();
      },
      onItemsPerPageChanged: (itemsPerPage) {
        setState(() {
          _itemsPerPage = itemsPerPage;
          _currentPage = 1;
          _totalPages = (_totalItems / _itemsPerPage).ceil();
        });
        _loadTimeBands();
      },
      itemLabel: 'time bands',
      showItemsPerPageSelector: true,
    );
  }

  void _createTimeBand() {
    // TODO: Implement create time band modal
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create time band - Coming soon')),
    );
  }

  void _viewTimeBandDetails(TimeBand timeBand) {
    // TODO: Navigate to time band details
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View details for ${timeBand.name}')),
    );
  }

  void _editTimeBand(TimeBand timeBand) {
    // TODO: Implement edit time band modal
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Edit ${timeBand.name}')));
  }

  void _deleteTimeBand(TimeBand timeBand) {
    // TODO: Implement delete confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Time Band'),
        content: Text('Are you sure you want to delete "${timeBand.name}"?'),
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
              _performDeleteTimeBand(timeBand);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteTimeBand(TimeBand timeBand) async {
    try {
      final response = await _touService.deleteTimeBand(timeBand.id);
      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Time band "${timeBand.name}" deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadTimeBands();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Failed to delete time band'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting time band: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showBulkDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Time Bands'),
        content: Text(
          'Are you sure you want to delete ${_selectedTimeBands.length} time bands?',
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
    final selectedIds = _selectedTimeBands.map((tb) => tb.id).toList();

    for (final id in selectedIds) {
      await _touService.deleteTimeBand(id);
    }

    setState(() {
      _selectedTimeBands.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${selectedIds.length} time bands deleted'),
        backgroundColor: AppColors.success,
      ),
    );

    _loadTimeBands();
  }
}
