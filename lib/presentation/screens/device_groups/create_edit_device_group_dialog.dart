import 'package:flutter/material.dart';
import 'package:mdms_clone/presentation/widgets/common/app_lottie_state_widget.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../core/models/device_group.dart';
import '../../../core/models/device.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/device_group_service.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_input_field.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/common/status_chip.dart';
import '../../widgets/common/blunest_data_table.dart';
import '../../widgets/common/results_pagination.dart';

class CreateEditDeviceGroupDialog extends StatefulWidget {
  final DeviceGroup? deviceGroup;
  final VoidCallback? onSaved;

  const CreateEditDeviceGroupDialog({
    super.key,
    this.deviceGroup,
    this.onSaved,
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
        // Header, Search field and selected count in one row
        // Header
        const Text(
          'Select Devices',
          style: TextStyle(
            fontSize: AppSizes.fontSizeLarge,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.spacing16),

        Row(
          children: [
            // Search field - styled exactly like device screen
            Expanded(
              child: AppInputField(
                controller: _searchController,
                hintText: 'Search devices...',
                onChanged: _onSearchChanged,
                enabled: !_isLoading && !_isLoadingDevices,
                // prefixIcon: _isSearching
                //     ? const SizedBox(
                //         width: 16,
                //         height: 16,
                //         child: CircularProgressIndicator(strokeWidth: 2),
                //       )
                //     : const Icon(Icons.search, size: 20),
              ),
            ),
            // const SizedBox(width: AppSizes.spacing16),
            // const Spacer(),

            // // Selected count
            // StatusChip(
            //   text: '${_selectedDevices.length} selected',
            //   type: StatusChipType.info,
            //   // compact: true,
            // ),
          ],
        ),
        const SizedBox(height: AppSizes.spacing16),

        // Device selection table
        Container(
          height: 400,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          ),
          child: _isLoadingDevices || _isSearching
              ? AppLottieStateWidget.loading(lottieSize: 80)
              : _availableDevices.isEmpty
              ? AppLottieStateWidget.noData(
                  title: 'No Devices Found',
                  message: 'No devices match your search criteria.',
                  lottieSize: 100,
                  titleColor: AppColors.primary,
                  messageColor: AppColors.textSecondary,
                )
              : Column(
                  children: [
                    Expanded(
                      child: BluNestDataTable<Device>(
                        columns: _buildDeviceTableColumns(),
                        data: _availableDevices,
                        enableMultiSelect: true,
                        selectedItems: _selectedDevices
                            .where(
                              (selected) => _availableDevices.any(
                                (device) => device.id == selected.id,
                              ),
                            )
                            .toSet(),
                        onSelectionChanged: (selectedItems) {
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
                        },
                        // Add sorting functionality
                        sortBy: _sortBy,
                        sortAscending: _sortAscending,
                        onSort: _onSort,
                        // Add column visibility functionality
                        hiddenColumns: _hiddenColumns,
                        onColumnVisibilityChanged: _onColumnVisibilityChanged,
                        isLoading: false,
                      ),
                    ),

                    // Pagination - show if we have devices, matching device_groups_screen behavior
                    if (_totalDevices > 0)
                      Container(
                        //padding: const EdgeInsets.all(AppSizes.spacing16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border(
                            top: BorderSide(
                              color: AppColors.border.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                        ),
                        child: ResultsPagination(
                          currentPage: _deviceCurrentPage,
                          totalPages: totalPages,
                          totalItems: _totalDevices,
                          itemsPerPage: _deviceItemsPerPage,
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
    return [
      BluNestTableColumn<Device>(
        key: 'serialNumber',
        title: 'Serial Number',
        flex: 2,
        sortable: true,
        builder: (device) => Text(
          device.serialNumber.isNotEmpty ? device.serialNumber : 'Unknown',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
      BluNestTableColumn<Device>(
        key: 'model',
        title: 'Model',
        flex: 2,
        sortable: true,
        builder: (device) => Text(
          device.model.isNotEmpty ? device.model : 'None',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      ),
      BluNestTableColumn<Device>(
        key: 'deviceType',
        title: 'Type',
        flex: 1,
        sortable: true,
        builder: (device) => device.deviceType.isNotEmpty
            ? StatusChip(
                text: device.deviceType,
                type: StatusChipType.info,
                compact: true,
              )
            : const Text('-'),
      ),
      BluNestTableColumn<Device>(
        key: 'status',
        title: 'Status',
        flex: 1,
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
            //  height: AppSizes.spacing40,
            compact: true,
            //padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing8),
          ),
        ),
      ),
      BluNestTableColumn<Device>(
        key: 'linkStatus',
        title: 'Link Status',
        flex: 1,
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
            //  height: AppSizes.spacing40,
            //padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing8),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      child: SizedBox(
        // width: 800,
        // height: MediaQuery.of(context).size.height * 0.85,
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        //  constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppSizes.spacing16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Text(
                    '${widget.deviceGroup == null ? 'Add' : 'Edit'} Device Group',
                    style: const TextStyle(
                      fontSize: AppSizes.fontSizeLarge,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  // const SizedBox(width: AppSizes.spacing8),
                  // StatusChip(
                  //   text: '${_selectedDevices.length} devices',
                  //   type: StatusChipType.info,
                  //   compact: true,
                  // ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.spacing16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Group Information - Single Row Layout
                      Row(
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
                              enabled: !_isLoading,
                            ),
                          ),
                          const SizedBox(width: AppSizes.spacing16),
                          Expanded(
                            child: AppInputField(
                              label: 'Description',
                              controller: _descriptionController,
                              hintText: 'Enter group description (optional)',
                              enabled: !_isLoading,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.spacing16),

                      // Device Selection Section
                      _buildDeviceSelectionSection(),
                    ],
                  ),
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(AppSizes.spacing16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    text: 'Cancel',
                    type: AppButtonType.outline,
                  ),
                  const SizedBox(width: AppSizes.spacing12),
                  AppButton(
                    onPressed: _isLoading ? null : _saveDeviceGroup,
                    text: _isLoading
                        ? 'Saving...'
                        : (widget.deviceGroup == null
                              ? 'Create Group'
                              : 'Update Group'),
                    type: AppButtonType.primary,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
