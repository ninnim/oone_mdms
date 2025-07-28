import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/site.dart';
import '../../../core/services/site_service.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/status_chip.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/common/app_confirm_dialog.dart';
import '../../widgets/common/app_lottie_state_widget.dart';
import '../../widgets/common/blunest_data_table.dart';
import '../../widgets/sites/site_form_dialog.dart';
import '../../widgets/sites/subsite_table_columns.dart';

class SiteDetailsScreen extends StatefulWidget {
  final int? siteId;
  final Site? site;

  const SiteDetailsScreen({super.key, this.siteId, this.site});

  @override
  State<SiteDetailsScreen> createState() => _SiteDetailsScreenState();
}

class _SiteDetailsScreenState extends State<SiteDetailsScreen> {
  late final SiteService _siteService;

  Site? _site;
  List<Site> _subSites = [];
  bool _isLoading = true;
  bool _isSubSitesLoading = false;
  String _error = '';

  // Selected state for multi-select operations
  final Set<Site> _selectedSubSites = {};

  @override
  void initState() {
    super.initState();
    _siteService = Provider.of<SiteService>(context, listen: false);

    // Initialize with provided site or fetch by ID
    if (widget.site != null) {
      _site = widget.site;
      _subSites = widget.site!.subSites ?? [];
      _isLoading = false;
      if (widget.site!.isMainSite) {
        _loadSubSites();
      }
    } else if (widget.siteId != null) {
      _loadSiteDetails();
    } else {
      setState(() {
        _error = 'No site ID or site data provided';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSiteDetails() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final response = await _siteService.getSiteById(
        widget.siteId!,
        includeSubSite: true,
      );

      if (response.success && response.data != null) {
        setState(() {
          _site = response.data!;
          _subSites = response.data!.subSites ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.message ?? 'Failed to load site details';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading site details: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSubSites() async {
    if (_site?.id == null) return;

    setState(() {
      _isSubSitesLoading = true;
    });

    try {
      final response = await _siteService.getSiteById(
        _site!.id!,
        includeSubSite: true,
      );

      if (response.success && response.data != null) {
        setState(() {
          _subSites = response.data!.subSites ?? [];
          _isSubSitesLoading = false;
        });
      } else {
        setState(() {
          _isSubSitesLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isSubSitesLoading = false;
      });
    }
  }

  Future<void> _refreshSubSites() async {
    if (_site == null) return;

    setState(() {
      _isSubSitesLoading = true;
    });

    try {
      final response = await _siteService.getSiteById(
        _site!.id!,
        includeSubSite: true,
      );

      if (response.success && response.data != null) {
        setState(() {
          _subSites = response.data!.subSites ?? [];
          _selectedSubSites.clear();
          _isSubSitesLoading = false;
        });
      } else {
        setState(() {
          _isSubSitesLoading = false;
        });
        AppToast.showError(
          context,
          error: response.message ?? 'Failed to refresh sub-sites',
        );
      }
    } catch (e) {
      setState(() {
        _isSubSitesLoading = false;
      });
      AppToast.showError(context, error: 'Error refreshing sub-sites: $e');
    }
  }

  void _createSubSite() {
    if (_site == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SiteFormDialog(
        site: null, // Create new sub site
        availableParentSites: [_site!], // Only allow this site as parent
        onSave: (newSite) async {
          try {
            final response = await _siteService.createSite(newSite);
            if (response.success) {
              _refreshSubSites(); // Refresh data from API
              AppToast.show(
                context,
                title: 'Success',
                message: 'Sub site created successfully',
                type: ToastType.success,
              );
            } else {
              AppToast.show(
                context,
                title: 'Error',
                message: response.message ?? 'Failed to create sub site',
                type: ToastType.error,
              );
            }
          } catch (e) {
            AppToast.show(
              context,
              title: 'Error',
              message: 'Failed to create sub site',
              type: ToastType.error,
            );
          }
        },
      ),
    );
  }

  void _editSubSite(Site subSite) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SiteFormDialog(
        site: subSite,
        availableParentSites: [_site!],
        onSave: (updatedSite) async {
          try {
            final response = await _siteService.updateSite(updatedSite);
            if (response.success) {
              _refreshSubSites(); // Refresh data from API
              AppToast.show(
                context,
                title: 'Success',
                message: 'Sub site updated successfully',
                type: ToastType.success,
              );
            } else {
              AppToast.show(
                context,
                title: 'Error',
                message: response.message ?? 'Failed to update sub site',
                type: ToastType.error,
              );
            }
          } catch (e) {
            AppToast.show(
              context,
              title: 'Error',
              message: 'Failed to update sub site',
              type: ToastType.error,
            );
          }
        },
      ),
    );
  }

  void _deleteSubSite(Site subSite) {
    showDialog(
      context: context,
      builder: (context) => AppConfirmDialog(
        title: 'Delete Sub Site',
        message:
            'Are you sure you want to delete "${subSite.name}"? This action cannot be undone.',
        confirmText: 'Delete',
        confirmType: AppButtonType.danger,
        onConfirm: () async {
          try {
            final response = await _siteService.deleteSite(subSite.id!);
            if (response.success) {
              _refreshSubSites();
              AppToast.showSuccess(
                context,
                message: 'Sub site deleted successfully',
              );
            } else {
              AppToast.showError(
                context,
                error: response.message ?? 'Failed to delete sub site',
              );
            }
          } catch (e) {
            AppToast.showError(context, error: 'Error deleting sub site: $e');
          }
        },
      ),
    );
  }

  void _editMainSite() {
    if (_site == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SiteFormDialog(
        site: _site,
        availableParentSites: const [],
        onSave: (updatedSite) async {
          try {
            final response = await _siteService.updateSite(updatedSite);
            if (response.success) {
              // Refresh the main site data from API
              final siteResponse = await _siteService.getSiteById(
                updatedSite.id!,
                includeSubSite: true,
              );
              if (siteResponse.success && siteResponse.data != null) {
                setState(() {
                  _site = siteResponse.data;
                  _subSites = siteResponse.data!.subSites ?? [];
                });
              }
              AppToast.show(
                context,
                title: 'Success',
                message: 'Site updated successfully',
                type: ToastType.success,
              );
            } else {
              AppToast.show(
                context,
                title: 'Error',
                message: response.message ?? 'Failed to update site',
                type: ToastType.error,
              );
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

  void _deleteSelectedSubSites() {
    if (_selectedSubSites.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AppConfirmDialog(
        title: 'Delete Sub Sites',
        message:
            'Are you sure you want to delete ${_selectedSubSites.length} selected sub sites? This action cannot be undone.',
        confirmText: 'Delete All',
        confirmType: AppButtonType.danger,
        onConfirm: () async {
          int successCount = 0;
          int failCount = 0;

          for (final subSite in _selectedSubSites) {
            try {
              final response = await _siteService.deleteSite(subSite.id!);
              if (response.success) {
                successCount++;
              } else {
                failCount++;
              }
            } catch (e) {
              failCount++;
            }
          }

          _refreshSubSites();

          if (successCount > 0) {
            AppToast.showSuccess(
              context,
              message: '$successCount sub site(s) deleted successfully',
            );
          }

          if (failCount > 0) {
            AppToast.showError(
              context,
              error: 'Failed to delete $failCount sub site(s)',
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with breadcrumbs
          _buildHeader(),
          // Main content
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _error.isNotEmpty
                ? _buildErrorState()
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Back button
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                color: AppColors.textSecondary,
                tooltip: 'Back to Sites',
              ),
              const SizedBox(width: AppSizes.spacing8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _site?.name ?? 'Site Details',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Site ID: ${_site?.id ?? 'Loading...'}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        if (_site != null) ...[
                          const SizedBox(width: AppSizes.spacing16),
                          StatusChip(
                            text: _site!.active ? 'Active' : 'Inactive',
                            type: _site!.active
                                ? StatusChipType.success
                                : StatusChipType.secondary,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (_site != null) ...[
                AppButton(
                  text: 'Edit Site',
                  onPressed: _editMainSite,
                  type: AppButtonType.secondary,
                  size: AppButtonSize.medium,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: AppLottieStateWidget.loading(title: 'Loading site details...'),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: AppLottieStateWidget.error(
        title: 'Error Loading Site',
        message: _error,
        buttonText: 'Try Again',
        onButtonPressed: _loadSiteDetails,
      ),
    );
  }

  Widget _buildContent() {
    if (_site == null) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sidebar with site info
        Container(
          width: 300,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.surface.withValues(alpha: 0.1)
                : AppColors.surface,
            border: Border(
              right: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: _buildSidebarContent(),
        ),
        // Main content area with sub-sites table
        Expanded(child: _buildMainContent()),
      ],
    );
  }

  Widget _buildSidebarContent() {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Site Information',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSizes.spacing16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Name', _site!.name),
                const SizedBox(height: AppSizes.spacing12),
                _buildInfoRow(
                  'Description',
                  _site!.description.isEmpty
                      ? 'No description'
                      : _site!.description,
                ),
                const SizedBox(height: AppSizes.spacing12),
                _buildInfoRow(
                  'Type',
                  _site!.isMainSite ? 'Main Site' : 'Sub Site',
                ),
                const SizedBox(height: AppSizes.spacing12),
                _buildInfoRow('Status', _site!.active ? 'Active' : 'Inactive'),
                const SizedBox(height: AppSizes.spacing12),
                _buildInfoRow('Sub Sites', '${_subSites.length}'),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.spacing24),
          Text(
            'Quick Actions',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSizes.spacing16),
          if (_site!.isMainSite) ...[
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: 'Create Sub Sites',
                onPressed: _createSubSite,
                type: AppButtonType.primary,
                icon: const Icon(Icons.add),
              ),
            ),
            const SizedBox(height: AppSizes.spacing8),
          ],
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: 'Edit Site',
              onPressed: _editMainSite,
              type: AppButtonType.secondary,
              icon: const Icon(Icons.edit),
            ),
          ),
          if (_selectedSubSites.isNotEmpty) ...[
            const SizedBox(height: AppSizes.spacing8),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: 'Delete Selected (${_selectedSubSites.length})',
                onPressed: _deleteSelectedSubSites,
                type: AppButtonType.danger,
                icon: const Icon(Icons.delete),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and actions
          Row(
            children: [
              Text(
                _site!.isMainSite ? 'Sub Sites' : 'Site Details',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (_site!.isMainSite) ...[
                const SizedBox(width: AppSizes.spacing8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_subSites.length}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (_site!.isMainSite) ...[
                AppButton(
                  text: 'Create Sub Site',
                  onPressed: _createSubSite,
                  type: AppButtonType.primary,
                  icon: const Icon(Icons.add),
                  size: AppButtonSize.medium,
                ),
                const SizedBox(width: AppSizes.spacing8),
                AppButton(
                  text: 'Refresh',
                  onPressed: _refreshSubSites,
                  type: AppButtonType.secondary,
                  icon: const Icon(Icons.refresh),
                  size: AppButtonSize.medium,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSizes.spacing16),
          // Sub-sites table or site details
          Expanded(
            child: _site!.isMainSite
                ? _buildSubSitesTable()
                : _buildSiteDetailsView(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubSitesTable() {
    if (_isSubSitesLoading) {
      return const Center(
        child: AppLottieStateWidget.loading(title: 'Loading sub sites...'),
      );
    }

    // Get table columns from SubSiteTableColumns
    final columns = SubSiteTableColumns.getBluNestColumns(
      context: context,
      onEdit: _editSubSite,
      onDelete: _deleteSubSite,
      subSites: _subSites,
    );

    return BluNestDataTable<Site>(
      columns: columns,
      data: _subSites,
      isLoading: _isSubSitesLoading,
      enableMultiSelect: true,
      selectedItems: _selectedSubSites,
      onSelectionChanged: (selected) {
        setState(() {
          _selectedSubSites.clear();
          _selectedSubSites.addAll(selected);
        });
      },
      emptyState: Center(
        child: AppLottieStateWidget.noData(
          title: 'No sub sites found',
          buttonText: 'Create First Sub Site',
          onButtonPressed: _createSubSite,
        ),
      ),
    );
  }

  Widget _buildSiteDetailsView() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Site Details',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSizes.spacing16),
            _buildInfoRow('ID', '${_site!.id}'),
            const SizedBox(height: AppSizes.spacing12),
            _buildInfoRow('Name', _site!.name),
            const SizedBox(height: AppSizes.spacing12),
            _buildInfoRow(
              'Description',
              _site!.description.isEmpty
                  ? 'No description'
                  : _site!.description,
            ),
            const SizedBox(height: AppSizes.spacing12),
            _buildInfoRow('Type', _site!.isMainSite ? 'Main Site' : 'Sub Site'),
            const SizedBox(height: AppSizes.spacing12),
            _buildInfoRow('Status', _site!.active ? 'Active' : 'Inactive'),
            if (_site!.parentId > 0) ...[
              const SizedBox(height: AppSizes.spacing12),
              _buildInfoRow('Parent Site ID', '${_site!.parentId}'),
            ],
          ],
        ),
      ),
    );
  }
}
