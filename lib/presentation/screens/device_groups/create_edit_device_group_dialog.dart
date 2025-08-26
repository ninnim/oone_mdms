import 'package:flutter/material.dart';
import 'package:mdms_clone/presentation/widgets/common/app_lottie_state_widget.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../core/models/device_group.dart';
import '../../../core/models/device.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../core/services/device_group_service.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_input_field.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/common/app_dialog_header.dart';
import '../../widgets/common/status_chip.dart';
import '../../widgets/common/blunest_data_table.dart';
import '../../widgets/common/results_pagination.dart';
import '../../themes/app_theme.dart';

class CreateEditDeviceGroupDialog extends StatefulWidget {
  final DeviceGroup? deviceGroup;
  final VoidCallback? onSaved;
  final bool isReadOnly; // New parameter for view-only mode

  const CreateEditDeviceGroupDialog({
    super.key,
    this.deviceGroup,
    this.onSaved,
    this.isReadOnly = false,
  });

  @override
  State<CreateEditDeviceGroupDialog> createState() =>
      _CreateEditDeviceGroupDialogState();
}

class _CreateEditDeviceGroupDialogState
    extends State<CreateEditDeviceGroupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();

  late final DeviceGroupService _deviceGroupService;

  bool _isLoading = false;
  bool _isActive = true;
  bool _isLoadingDevices = false;
  bool _isSearching = false; // Add search indicator
  bool _isInEditMode = false; // Track if we're in edit mode

  List<Device> _availableDevices = [];
  Set<Device> _selectedDevices = {};
  List<Device> _originalDevices = [];
  String _deviceSearchQuery = '';

  // Pagination for device selection
  int _deviceCurrentPage = 1;
  int _deviceItemsPerPage = 25;
  int _totalDevices = 0;

  // Sorting for device table
  String? _sortBy;
  bool _sortAscending = true;

  // Column visibility for device table
  List<String> _hiddenColumns = [];

  // Search debouncing
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _deviceGroupService = Provider.of<DeviceGroupService>(
      context,
      listen: false,
    );

    // Initialize edit mode based on read-only state
    _isInEditMode = !widget.isReadOnly;

    // Initialize search query
    _deviceSearchQuery = '%%'; // Default search to get all devices

    if (widget.deviceGroup != null) {
      _nameController.text = widget.deviceGroup!.name ?? '';
      _descriptionController.text = widget.deviceGroup!.description ?? '';
      _isActive = widget.deviceGroup!.active ?? true;
      _originalDevices = List.from(widget.deviceGroup!.devices ?? []);
      _selectedDevices = Set.from(widget.deviceGroup!.devices ?? []);
    }

    _loadAvailableDevices();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    _searchTimer?.cancel(); // Cancel any pending search timer
    super.dispose();
  }

  Future<void> _loadAvailableDevices() async {
    setState(() => _isLoadingDevices = true);

    try {
      // Calculate offset from page number
      final offset = (_deviceCurrentPage - 1) * _deviceItemsPerPage;

      final response = await _deviceGroupService.getAvailableDevices(
        search: _deviceSearchQuery,
        offset: offset,
        limit: _deviceItemsPerPage,
      );

      if (response.success && response.data != null) {
        setState(() {
          _availableDevices = response.data!;
          // Use the total count from API paging if available
          _totalDevices = response.paging?.item.total ?? 0;
        });

        // Apply sorting after loading data
        _sortDevices();
      }
    } catch (e) {
      print('Error loading available devices: $e');
    } finally {
      setState(() => _isLoadingDevices = false);
    }
  }

  void _onSearchChanged(String query) {
    // Cancel any existing timer
    _searchTimer?.cancel();

    // Show searching indicator only if there's actual input change
    if (_deviceSearchQuery != query) {
      setState(() {
        _isSearching = true;
      });
    }

    // Set up a new timer with 800ms delay (increased for better UX)
    _searchTimer = Timer(const Duration(milliseconds: 800), () {
      final formattedQuery = query.trim().isEmpty ? '%%' : '%${query.trim()}%';

      // Only search if the query actually changed
      if (_deviceSearchQuery != formattedQuery) {
        setState(() {
          _deviceSearchQuery = formattedQuery;
          _deviceCurrentPage = 1; // Reset to first page when searching
          _isSearching = false;
        });
        _loadAvailableDevices();
      } else {
        setState(() {
          _isSearching = false;
        });
      }
    });
  }

  void _onSort(String columnKey, bool ascending) {
    setState(() {
      _sortBy = columnKey;
      _sortAscending = ascending;
    });

    // Apply local sorting to current data
    _sortDevices();
  }

  void _onColumnVisibilityChanged(List<String> hiddenColumns) {
    setState(() {
      _hiddenColumns = hiddenColumns;
    });
  }

  void _sortDevices() {
    if (_sortBy == null) return;

    _availableDevices.sort((a, b) {
      dynamic valueA;
      dynamic valueB;

      switch (_sortBy) {
        case 'serialNumber':
          valueA = a.serialNumber.toLowerCase();
          valueB = b.serialNumber.toLowerCase();
          break;
        case 'model':
          valueA = a.model.toLowerCase();
          valueB = b.model.toLowerCase();
          break;
        case 'deviceType':
          valueA = a.deviceType.toLowerCase();
          valueB = b.deviceType.toLowerCase();
          break;
        case 'status':
          valueA = a.status.toLowerCase();
          valueB = b.status.toLowerCase();
          break;
        case 'linkStatus':
          valueA = a.linkStatus.toLowerCase();
          valueB = b.linkStatus.toLowerCase();
          break;
        default:
          return 0;
      }

      final comparison = valueA.compareTo(valueB);
      return _sortAscending ? comparison : -comparison;
    });
  }

  List<String> _getDeviceIdsToAdd() {
    return _selectedDevices
        .where(
          (device) => !_originalDevices.any((orig) => orig.id == device.id),
        )
        .map((device) => device.id?.toString() ?? '0')
        .toList();
  }

  List<String> _getDeviceIdsToRemove() {
    return _originalDevices
        .where((device) => !_selectedDevices.any((sel) => sel.id == device.id))
        .map((device) => device.id?.toString() ?? '0')
        .toList();
  }

  Future<List<Device>> _fetchAllAvailableDevices() async {
    try {
      // Fetch all available devices without pagination
      final response = await _deviceGroupService.getAvailableDevices(
        search: _deviceSearchQuery.isEmpty ? '%%' : '%$_deviceSearchQuery%',
        offset: 0,
        limit: 10000, // Large limit to get all items
      );

      if (response.success && response.data != null) {
        return response.data!;
      } else {
        throw Exception(response.message ?? 'Failed to fetch all devices');
      }
    } catch (e) {
      throw Exception('Error fetching all available devices: $e');
    }
  }

  // Mode tracking helpers
  bool get _isEditMode => _isInEditMode;
  bool get _isViewMode => widget.isReadOnly && !_isInEditMode;
  bool get _isCreateMode => widget.deviceGroup == null;

  void _switchToEditMode() {
    setState(() {
      _isInEditMode = true;
    });
  }

  Future<void> _saveDeviceGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final deviceGroup = DeviceGroup(
        id: widget.deviceGroup?.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        active: _isActive,
        devices: _selectedDevices.toList(), // Convert Set to List
      );

      final deviceIdsToAdd = _getDeviceIdsToAdd();
      final deviceIdsToRemove = _getDeviceIdsToRemove();

      final response = widget.deviceGroup == null
          ? await _deviceGroupService.createDeviceGroup(
              deviceGroup,
              deviceIds: deviceIdsToAdd,
              removedDeviceIds: deviceIdsToRemove,
            )
          : await _deviceGroupService.updateDeviceGroup(
              deviceGroup,
              deviceIds: deviceIdsToAdd,
              removedDeviceIds: deviceIdsToRemove,
            );

      if (response.success) {
        if (mounted) {
          AppToast.show(
            context,
            title: 'Success',
            message: widget.deviceGroup == null
                ? 'Device group created successfully'
                : 'Device group updated successfully',
            type: ToastType.success,
          );

          widget.onSaved?.call();
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          AppToast.show(
            context,
            title: 'Error',
            message: response.message ?? 'Failed to save device group',
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          title: 'Error',
          message: 'Failed to save device group: $e',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildDeviceSelectionSection() {
    final isMobile = ResponsiveHelper.shouldUseCompactUI(context);

    // Safe pagination calculation to avoid clamp errors
    final totalPages = _totalDevices > 0
        ? (_totalDevices / _deviceItemsPerPage).ceil()
        : 1;
    final startIndex = _totalDevices > 0
        ? (_deviceCurrentPage - 1) * _deviceItemsPerPage + 1
        : 0;
    final endIndex = _totalDevices > 0
        ? (_deviceCurrentPage * _deviceItemsPerPage).clamp(1, _totalDevices)
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Expanded(
              child: Text(
                'Device Selection',
                style: TextStyle(
                  fontSize: isMobile
                      ? AppSizes.fontSizeMedium
                      : AppSizes.fontSizeLarge,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimaryColor,
                ),
              ),
            ),
            if (_selectedDevices.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacing8,
                  vertical: AppSizes.spacing4,
                ),
                decoration: BoxDecoration(
                  color: context.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  border: Border.all(
                    color: context.primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '${_selectedDevices.length} selected',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeSmall,
                    fontWeight: FontWeight.w500,
                    color: context.primaryColor,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getSpacing(context)),

        // Search field
        AppInputField.search(
          controller: _searchController,
          hintText: 'Search devices by serial number, model, or type...',
          onChanged: _onSearchChanged,
          enabled: _isEditMode && !_isLoading && !_isLoadingDevices,
          prefixIcon: Icon(Icons.search, size: AppSizes.iconSmall),
        ),
        SizedBox(height: ResponsiveHelper.getSpacing(context)),

        // Device table container with responsive height
        Container(
          height: isMobile ? 300 : 400,
          decoration: BoxDecoration(
            color: context.surfaceColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            border: Border.all(color: context.borderColor.withOpacity(0.5)),
          ),
          child: _isLoadingDevices || _isSearching
              ? AppLottieStateWidget.loading(lottieSize: 80)
              : _availableDevices.isEmpty
              ? AppLottieStateWidget.noData(
                  title: 'No Devices Found',
                  message: _deviceSearchQuery.contains('%%')
                      ? 'No devices available for selection.'
                      : 'No devices match your search criteria.',
                  lottieSize: 80,
                  titleColor: context.primaryColor,
                  messageColor: context.textSecondaryColor,
                )
              : Column(
                  children: [
                    Expanded(
                      child: BluNestDataTable<Device>(
                        columns: _buildDeviceTableColumns(),
                        data: _availableDevices,
                        enableMultiSelect: _isEditMode,
                        selectedItems: _selectedDevices
                            .where(
                              (selected) => _availableDevices.any(
                                (device) => device.id == selected.id,
                              ),
                            )
                            .toSet(),
                        onSelectionChanged: (selectedItems) {
                          if (_isEditMode) {
                            setState(() {
                              // Remove deselected items from current page
                              final currentPageDeviceIds = _availableDevices
                                  .map((d) => d.id)
                                  .toSet();
                              _selectedDevices.removeWhere(
                                (device) =>
                                    currentPageDeviceIds.contains(device.id),
                              );

                              // Add newly selected items
                              _selectedDevices.addAll(selectedItems);
                            });
                          }
                        },
                        sortBy: _sortBy,
                        sortAscending: _sortAscending,
                        onSort: _onSort,
                        hiddenColumns: _hiddenColumns,
                        onColumnVisibilityChanged: _onColumnVisibilityChanged,
                        isLoading: false,
                        totalItemsCount: _totalDevices,
                        onSelectAllItems: _isEditMode
                            ? _fetchAllAvailableDevices
                            : null,
                      ),
                    ),

                    // Pagination
                    if (_totalDevices > 0)
                      Container(
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          border: Border(
                            top: BorderSide(
                              color: context.borderColor.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                        ),
                        child: ResultsPagination(
                          currentPage: _deviceCurrentPage,
                          totalPages: totalPages,
                          totalItems: _totalDevices,
                          itemsPerPage: _deviceItemsPerPage,
                          itemsPerPageOptions: const [5, 10, 20, 25, 50],
                          startItem: startIndex,
                          endItem: endIndex,
                          itemLabel: 'devices',
                          onPageChanged: (page) {
                            setState(() {
                              _deviceCurrentPage = page;
                            });
                            _loadAvailableDevices();
                          },
                          onItemsPerPageChanged: (itemsPerPage) {
                            setState(() {
                              _deviceItemsPerPage = itemsPerPage;
                              _deviceCurrentPage = 1;
                            });
                            _loadAvailableDevices();
                          },
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  List<BluNestTableColumn<Device>> _buildDeviceTableColumns() {
    final isMobile = ResponsiveHelper.shouldUseCompactUI(context);

    return [
      BluNestTableColumn<Device>(
        key: 'serialNumber',
        title: 'Serial Number',
        flex: isMobile ? 2 : 2,
        sortable: true,
        builder: (device) => Text(
          device.serialNumber.isNotEmpty ? device.serialNumber : 'Unknown',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: context.primaryColor,
          ),
        ),
      ),
      BluNestTableColumn<Device>(
        key: 'model',
        title: 'Model',
        flex: isMobile ? 2 : 2,
        sortable: true,
        builder: (device) => Text(
          device.model.isNotEmpty ? device.model : 'None',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: context.textPrimaryColor),
        ),
      ),
      // BluNestTableColumn<Device>(
      //   key: 'deviceType',
      //   title: 'Type',
      //   flex: isMobile ? 1 : 1,
      //   sortable: true,
      //   builder: (device) => device.deviceType.isNotEmpty
      //       ? StatusChip(
      //           text: device.deviceType,
      //           type: StatusChipType.info,
      //           compact: true,
      //         )
      //       : Text('-'),
      // ),
      BluNestTableColumn<Device>(
        key: 'status',
        title: 'Status',
        flex: isMobile ? 1 : 1,
        sortable: true,
        builder: (device) => Container(
          alignment: Alignment.centerLeft,
          child: StatusChip(
            text: device.status,
            type: device.status == 'Commissioned'
                ? StatusChipType.success
                : device.status == 'Discommissioned'
                ? StatusChipType.construction
                : device.status == 'None'
                ? StatusChipType.none
                : StatusChipType.none,
            compact: true,
          ),
        ),
      ),
      BluNestTableColumn<Device>(
        key: 'linkStatus',
        title: 'Link Status',
        flex: isMobile ? 1 : 1,
        sortable: true,
        builder: (device) => Container(
          alignment: Alignment.centerLeft,
          child: StatusChip(
            text: device.linkStatus,
            type: device.linkStatus == 'MULTIDRIVE'
                ? StatusChipType.commissioned
                : device.linkStatus == 'E-POWER'
                ? StatusChipType.warning
                : device.linkStatus == 'None'
                ? StatusChipType.none
                : StatusChipType.none,
            compact: true,
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Use ResponsiveHelper for consistent responsive behavior
    final dialogConstraints = ResponsiveHelper.getDialogConstraints(context);

    // Dialog configuration based on mode
    DialogType dialogType;
    String dialogTitle;
    String dialogSubtitle;

    if (_isCreateMode) {
      dialogType = DialogType.create;
      dialogTitle = 'Create Device Group';
      dialogSubtitle = 'Group devices for easier management and control';
    } else if (_isViewMode) {
      dialogType = DialogType.view;
      dialogTitle = 'Device Group Details';
      dialogSubtitle = 'View device group information and assigned devices';
    } else {
      dialogType = DialogType.edit;
      dialogTitle = 'Edit Device Group';
      dialogSubtitle = 'Modify device group settings and device assignments';
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      child: ConstrainedBox(
        constraints: dialogConstraints,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppDialogHeader(
              type: dialogType,
              title: dialogTitle,
              subtitle: dialogSubtitle,
              onClose: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: _buildBody(),
              ),
            ),
            Container(
              padding: ResponsiveHelper.getPadding(context),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: context.borderColor)),
              ),
              child: ResponsiveHelper.shouldUseCompactUI(context)
                  ? _buildMobileFooter()
                  : _buildDesktopFooter(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Container(
      padding: ResponsiveHelper.getPadding(context),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Information Section
            _buildGroupInformationSection(),
            SizedBox(height: ResponsiveHelper.getSpacing(context) * 2),

            // Device Selection Section
            _buildDeviceSelectionSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupInformationSection() {
    final isMobile = ResponsiveHelper.shouldUseCompactUI(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Group Information',
          style: TextStyle(
            fontSize: isMobile
                ? AppSizes.fontSizeMedium
                : AppSizes.fontSizeLarge,
            fontWeight: FontWeight.w600,
            color: context.textPrimaryColor,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getSpacing(context)),

        // Responsive layout for form fields
        isMobile
            ? Column(
                children: [
                  AppInputField(
                    label: 'Group Name',
                    controller: _nameController,
                    hintText: 'Enter device group name',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Group name is required';
                      }
                      if (value.trim().length < 2) {
                        return 'Group name must be at least 2 characters';
                      }
                      return null;
                    },
                    enabled: _isEditMode && !_isLoading,
                  ),
                  SizedBox(height: ResponsiveHelper.getSpacing(context)),
                  AppInputField(
                    label: 'Description',
                    controller: _descriptionController,
                    hintText: 'Enter group description',
                    enabled: _isEditMode && !_isLoading,
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: AppInputField(
                      label: 'Group Name',
                      controller: _nameController,
                      hintText: 'Enter device group name',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Group name is required';
                        }
                        if (value.trim().length < 2) {
                          return 'Group name must be at least 2 characters';
                        }
                        return null;
                      },
                      enabled: _isEditMode && !_isLoading,
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getSpacing(context) * 2),
                  Expanded(
                    child: AppInputField(
                      label: 'Description',
                      controller: _descriptionController,
                      hintText: 'Enter group description',
                      enabled: _isEditMode && !_isLoading,
                    ),
                  ),
                ],
              ),
      ],
    );
  }

  // Mobile footer - vertical button layout
  Widget _buildMobileFooter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isViewMode)
          AppButton(text: 'Edit', onPressed: _switchToEditMode)
        else
          AppButton(
            text: _isLoading
                ? 'Saving...'
                : (_isCreateMode ? 'Create Group' : 'Update Group'),
            onPressed: _isLoading ? null : _saveDeviceGroup,
            isLoading: _isLoading,
          ),
        const SizedBox(height: AppSizes.spacing8),
        AppButton(
          text: 'Cancel',
          type: AppButtonType.outline,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  // Desktop footer - horizontal button layout
  Widget _buildDesktopFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AppButton(
          text: 'Cancel',
          type: AppButtonType.outline,
          onPressed: () => Navigator.of(context).pop(),
        ),
        SizedBox(width: ResponsiveHelper.getSpacing(context)),
        if (_isViewMode)
          AppButton(text: 'Edit', onPressed: _switchToEditMode)
        else
          AppButton(
            text: _isLoading
                ? 'Saving...'
                : (_isCreateMode ? 'Create Group' : 'Update Group'),
            onPressed: _isLoading ? null : _saveDeviceGroup,
            isLoading: _isLoading,
          ),
      ],
    );
  }
}
