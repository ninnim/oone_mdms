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
import '../../../core/models/season.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/services/tou_service.dart';

class SeasonsScreen extends StatefulWidget {
  const SeasonsScreen({super.key});

  @override
  State<SeasonsScreen> createState() => _SeasonsScreenState();
}

class _SeasonsScreenState extends State<SeasonsScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final TouService _touService;
  bool _isLoading = false;
  List<Season> _seasons = [];
  Set<Season> _selectedSeasons = {};
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
    _loadSeasons();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSeasons() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _touService.getSeasons(
        search: _searchController.text,
        limit: _itemsPerPage,
        offset: (_currentPage - 1) * _itemsPerPage,
      );

      if (response.success && response.data != null) {
        setState(() {
          _seasons = response.data!;
          _totalItems =
              response.data!.length; // This should come from API paging
          _totalPages = (_totalItems / _itemsPerPage).ceil();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Failed to load seasons';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading seasons: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state
    if (_isLoading && _seasons.isEmpty) {
      return const AppLottieStateWidget.loading(
        title: 'Loading Seasons',
        message: 'Please wait while we fetch your season configurations...',
      );
    }

    // Show error state if error and no data
    if (_errorMessage.isNotEmpty && _seasons.isEmpty) {
      return AppLottieStateWidget.error(
        title: 'Failed to Load Seasons',
        message: _errorMessage,
        buttonText: 'Try Again',
        onButtonPressed: _loadSeasons,
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
    // Show no data state if no seasons after loading
    if (!_isLoading && _seasons.isEmpty && _errorMessage.isEmpty) {
      return AppLottieStateWidget.noData(
        title: 'No Seasons Found',
        message:
            'No seasons have been configured yet. Click "Add Season" to create your first season configuration.',
        buttonText: 'Add Season',
        onButtonPressed: _createSeason,
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildTableHeader(),
          if (_selectedSeasons.isNotEmpty) _buildMultiSelectToolbar(),
          Expanded(child: _buildSeasonsTable()),
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
            hintText: 'Search seasons',
            prefixIcon: const Icon(Icons.search, size: AppSizes.iconMedium),
            onChanged: (value) {
              _loadSeasons();
            },
          ),
        ),
        const SizedBox(width: AppSizes.spacing16),
        AppButton(
          text: 'Add Season',
          type: AppButtonType.primary,
          icon: const Icon(
            Icons.add,
            size: AppSizes.iconSmall,
            color: AppColors.textInverse,
          ),
          onPressed: () {
            _createSeason();
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
              'Seasons',
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
            onPressed: _loadSeasons,
            icon: const Icon(Icons.refresh, color: AppColors.error),
            tooltip: 'Retry',
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonsTable() {
    return BluNestDataTable<Season>(
      columns: [
        BluNestTableColumn<Season>(
          key: 'id',
          title: 'ID',
          builder: (season) => SizedBox(
            width: 60,
            child: Text(
              season.id.toString(),
              style: const TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        BluNestTableColumn<Season>(
          key: 'name',
          title: 'Name',
          builder: (season) => Expanded(
            flex: 2,
            child: Text(
              season.name,
              style: const TextStyle(
                fontSize: AppSizes.fontSizeMedium,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        BluNestTableColumn<Season>(
          key: 'description',
          title: 'Description',
          builder: (season) => Expanded(
            flex: 2,
            child: Text(
              season.description,
              style: const TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        BluNestTableColumn<Season>(
          key: 'monthRange',
          title: 'Month Range',
          builder: (season) => Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacing8,
                vertical: AppSizes.spacing4,
              ),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Text(
                season.monthRangeDisplay,
                style: const TextStyle(
                  fontSize: AppSizes.fontSizeSmall,
                  color: AppColors.info,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
        BluNestTableColumn<Season>(
          key: 'status',
          title: 'Status',
          builder: (season) => SizedBox(
            width: 80,
            child: StatusChip(
              text: season.active ? 'Active' : 'Inactive',
              type: season.active
                  ? StatusChipType.success
                  : StatusChipType.secondary,
            ),
          ),
        ),
        BluNestTableColumn<Season>(
          key: 'actions',
          title: 'Actions',
          builder: (season) => SizedBox(
            width: 120,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _viewSeasonDetails(season),
                  icon: const Icon(Icons.visibility, size: AppSizes.iconSmall),
                  tooltip: 'View Details',
                ),
                IconButton(
                  onPressed: () => _editSeason(season),
                  icon: const Icon(Icons.edit, size: AppSizes.iconSmall),
                  tooltip: 'Edit',
                ),
                IconButton(
                  onPressed: () => _deleteSeason(season),
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
      data: _seasons,
      isLoading: _isLoading,
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
      onRowTap: _viewSeasonDetails,
      onEdit: _editSeason,
      onDelete: _deleteSeason,
      onView: _viewSeasonDetails,
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
            '${_selectedSeasons.length} seasons selected',
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
        _loadSeasons();
      },
      onItemsPerPageChanged: (itemsPerPage) {
        setState(() {
          _itemsPerPage = itemsPerPage;
          _currentPage = 1;
          _totalPages = (_totalItems / _itemsPerPage).ceil();
        });
        _loadSeasons();
      },
      itemLabel: 'seasons',
      showItemsPerPageSelector: true,
    );
  }

  void _createSeason() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create season - Coming soon')),
    );
  }

  void _viewSeasonDetails(Season season) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('View details for ${season.name}')));
  }

  void _editSeason(Season season) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Edit ${season.name}')));
  }

  void _deleteSeason(Season season) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Season'),
        content: Text('Are you sure you want to delete "${season.name}"?'),
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
              _performDeleteSeason(season);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteSeason(Season season) async {
    try {
      final response = await _touService.deleteSeason(season.id);
      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Season "${season.name}" deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadSeasons();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Failed to delete season'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting season: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showBulkDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Seasons'),
        content: Text(
          'Are you sure you want to delete ${_selectedSeasons.length} seasons?',
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
    final selectedIds = _selectedSeasons.map((s) => s.id).toList();

    for (final id in selectedIds) {
      await _touService.deleteSeason(id);
    }

    setState(() {
      _selectedSeasons.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${selectedIds.length} seasons deleted'),
        backgroundColor: AppColors.success,
      ),
    );

    _loadSeasons();
  }
}
