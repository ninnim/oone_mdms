import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mdms_clone/core/constants/app_sizes.dart';
import '../../../core/models/device.dart';
import '../../../core/models/device_group.dart';
import '../../../core/models/address.dart';
import '../../../core/models/schedule.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../core/services/device_service.dart';
import '../../../core/services/schedule_service.dart';
import '../../../core/services/service_locator.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_input_field.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/common/app_dropdown_field.dart';
import '../../widgets/common/app_dialog_header.dart';

import '../../widgets/devices/interactive_map_dialog.dart';

class CreateEditDeviceDialog extends StatefulWidget {
  final Device? device;
  final VoidCallback? onSaved;
  final int? presetDeviceGroupId;

  const CreateEditDeviceDialog({
    super.key,
    this.device,
    this.onSaved,
    this.presetDeviceGroupId,
  });

  @override
  State<CreateEditDeviceDialog> createState() => _CreateEditDeviceDialogState();
}

class _CreateEditDeviceDialogState extends State<CreateEditDeviceDialog> {
  final _formKey = GlobalKey<FormState>();
  late DeviceService _deviceService;
  late ScheduleService _scheduleService;

  // Loading states
  bool _isSaving = false;
  bool _isLoadingDeviceGroups = false;
  bool _isLoadingSchedules = false;
  bool _isLoadingStatusOptions = false;
  bool _deviceGroupsLoaded = false;
  bool _schedulesLoaded = false;

  // Mode tracking
  bool get _isCreateMode => widget.device == null;

  // Pagination states
  int _deviceGroupsPage = 1;
  final int _deviceGroupsLimit = 10;
  bool _hasMoreDeviceGroups = true;
  String _deviceGroupSearchQuery = '';

  int _schedulesPage = 1;
  final int _schedulesLimit = 10;
  bool _hasMoreSchedules = true;
  String _scheduleSearchQuery = '';

  // Form controllers
  final TextEditingController _serialNumberController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _addressTextController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  // Form data
  String _selectedDeviceType = 'None';
  int? _selectedDeviceGroupId;
  int? _selectedScheduleId;
  String _selectedStatus = 'None';
  String _selectedLinkStatus = 'None';
  Address? _selectedAddress;

  // Dropdown data
  List<DeviceGroup> _deviceGroups = [];
  List<Schedule> _schedules = [];

  // Device type options
  final List<String> _deviceTypes = ['None', 'Smart Meter', 'IoT'];

  // Status options (will be populated from API or defaults)
  List<String> _statusOptions = ['None'];
  List<String> _linkStatusOptions = ['None'];

  @override
  void initState() {
    super.initState();

    // Use ServiceLocator to get properly configured API service
    final serviceLocator = ServiceLocator();
    final apiService = serviceLocator.apiService;
    _deviceService = DeviceService(apiService);
    _scheduleService = ScheduleService(apiService);

    if (widget.device != null) {
      _populateFields();
    } else if (widget.presetDeviceGroupId != null) {
      // Set the preset device group ID for new devices
      _selectedDeviceGroupId = widget.presetDeviceGroupId;
    }

    // Load dropdown data immediately to ensure proper display
    _loadDeviceGroups();
    _loadSchedules();
    _loadStatusOptions();
  }

  @override
  void dispose() {
    _serialNumberController.dispose();
    _modelController.dispose();
    _addressTextController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  void _populateFields() {
    final device = widget.device!;
    _serialNumberController.text = device.serialNumber;
    _modelController.text = device.model;
    _addressTextController.text = device.addressText;
    _selectedDeviceType = device.deviceType.isNotEmpty
        ? device.deviceType
        : 'None';

    // Populate actual status values from device
    _selectedStatus = device.status.isNotEmpty ? device.status : 'None';
    _selectedLinkStatus = device.linkStatus.isNotEmpty
        ? device.linkStatus
        : 'None';

    // Add the current device's statuses to the options if they're not already there
    if (!_statusOptions.contains(_selectedStatus)) {
      _statusOptions.add(_selectedStatus);
    }
    if (!_linkStatusOptions.contains(_selectedLinkStatus)) {
      _linkStatusOptions.add(_selectedLinkStatus);
    }

    _selectedDeviceGroupId = device.deviceGroupId != 0
        ? device.deviceGroupId
        : null;

    if (device.address != null) {
      _selectedAddress = device.address;
      _latitudeController.text = device.address!.latitude?.toString() ?? '';
      _longitudeController.text = device.address!.longitude?.toString() ?? '';
    }
  }

  Future<void> _loadDeviceGroups({
    bool loadMore = false,
    String? searchQuery,
  }) async {
    if (_isLoadingDeviceGroups) return;

    // If loading more, but no more data available, return
    if (loadMore && !_hasMoreDeviceGroups) return;

    setState(() {
      _isLoadingDeviceGroups = true;

      // Reset for new search or first load
      if (!loadMore) {
        _deviceGroupsPage = 1;
        _deviceGroups.clear();
        _hasMoreDeviceGroups = true;
      }

      if (searchQuery != null) {
        _deviceGroupSearchQuery = searchQuery;
      }
    });

    try {
      if (kDebugMode) {
        print(
          'Loading device groups: page=$_deviceGroupsPage, loadMore=$loadMore, searchQuery=$searchQuery',
        );
        print('Current selected device group ID: $_selectedDeviceGroupId');
      }

      final deviceGroupsResponse = await _deviceService.getDeviceGroups(
        limit: _deviceGroupsLimit,
        offset: loadMore ? (_deviceGroupsPage - 1) * _deviceGroupsLimit : 0,
        search: _deviceGroupSearchQuery.isNotEmpty
            ? _deviceGroupSearchQuery
            : '',
        includeDevices: false,
      );

      if (deviceGroupsResponse.success && mounted) {
        final newGroups = deviceGroupsResponse.data ?? [];

        if (kDebugMode) {
          print('Device groups loaded: ${newGroups.length} groups');
          print(
            'Total device groups: ${loadMore ? _deviceGroups.length + newGroups.length : newGroups.length}',
          );
          if (_selectedDeviceGroupId != null) {
            final hasSelected = newGroups.any(
              (g) => g.id == _selectedDeviceGroupId,
            );
            print(
              'Selected device group $_selectedDeviceGroupId found in loaded groups: $hasSelected',
            );
          }
        }

        setState(() {
          if (loadMore) {
            _deviceGroups.addAll(newGroups);
          } else {
            _deviceGroups = newGroups;
          }

          _deviceGroupsLoaded = true;
          _hasMoreDeviceGroups = newGroups.length >= _deviceGroupsLimit;

          if (loadMore) {
            _deviceGroupsPage++;
          }

          // Validate selected device group still exists
          if (_selectedDeviceGroupId != null) {
            final uniqueGroups = _getUniqueDeviceGroups();
            final groupExists = uniqueGroups.any(
              (group) => group.id == _selectedDeviceGroupId,
            );
            if (!groupExists) {
              if (kDebugMode) {
                print(
                  'Selected device group ID $_selectedDeviceGroupId not found in available groups, resetting to null',
                );
              }
              _selectedDeviceGroupId = null;
            }
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading device groups: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDeviceGroups = false;
        });
      }
    }
  }

  Future<void> _loadSchedules({
    bool loadMore = false,
    String? searchQuery,
  }) async {
    if (_isLoadingSchedules) return;

    // If loading more, but no more data available, return
    if (loadMore && !_hasMoreSchedules) return;

    setState(() {
      _isLoadingSchedules = true;

      // Reset for new search or first load
      if (!loadMore) {
        _schedulesPage = 1;
        _schedules.clear();
        _hasMoreSchedules = true;
      }

      if (searchQuery != null) {
        _scheduleSearchQuery = searchQuery;
      }
    });

    try {
      final schedulesResponse = await _scheduleService.getSchedules(
        limit: _schedulesLimit,
        offset: loadMore ? (_schedulesPage - 1) * _schedulesLimit : 0,
        search: _scheduleSearchQuery.isNotEmpty ? _scheduleSearchQuery : null,
      );

      if (schedulesResponse.success && mounted) {
        final newSchedules = schedulesResponse.data ?? [];

        setState(() {
          if (loadMore) {
            _schedules.addAll(newSchedules);
          } else {
            _schedules = newSchedules;
          }

          _schedulesLoaded = true;
          _hasMoreSchedules = newSchedules.length >= _schedulesLimit;

          if (loadMore) {
            _schedulesPage++;
          }

          // Validate selected schedule still exists
          if (_selectedScheduleId != null) {
            final uniqueSchedules = _getUniqueSchedules();
            final scheduleExists = uniqueSchedules.any(
              (schedule) => schedule.id == _selectedScheduleId,
            );
            if (!scheduleExists) {
              if (kDebugMode) {
                print(
                  'Selected schedule ID $_selectedScheduleId not found in available schedules, resetting to null',
                );
              }
              _selectedScheduleId = null;
            }
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading schedules: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSchedules = false;
        });
      }
    }
  }

  Future<void> _loadStatusOptions() async {
    if (_isLoadingStatusOptions) return;

    setState(() {
      _isLoadingStatusOptions = true;
    });

    try {
      // Try to get status options from existing devices in the system
      final devicesResponse = await _deviceService.getDevices(
        limit: 100, // Get a sample of devices to extract status values
      );

      List<String> statusOptions = ['None'];
      List<String> linkStatusOptions = ['None'];

      if (devicesResponse.success && devicesResponse.data != null) {
        // Extract unique status values from existing devices
        final devices = devicesResponse.data!;
        final statusSet = <String>{};
        final linkStatusSet = <String>{};

        for (final device in devices) {
          if (device.status.isNotEmpty && device.status != 'None') {
            statusSet.add(device.status);
          }
          if (device.linkStatus.isNotEmpty && device.linkStatus != 'None') {
            linkStatusSet.add(device.linkStatus);
          }
        }

        // Add found statuses to options
        statusOptions.addAll(statusSet.toList()..sort());
        linkStatusOptions.addAll(linkStatusSet.toList()..sort());

        if (kDebugMode) {
          print('Loaded status options from API: $statusOptions');
          print('Loaded link status options from API: $linkStatusOptions');
        }
      }

      // Fallback to default options if no statuses found from API
      if (statusOptions.length == 1) {
        statusOptions.addAll([
          'Active',
          'Inactive',
          'Connected',
          'Disconnected',
          'Online',
          'Offline',
          'Error',
          'Maintenance',
        ]);
      }

      if (linkStatusOptions.length == 1) {
        linkStatusOptions.addAll([
          'Linked',
          'Unlinked',
          'Pending',
          'Failed',
          'Synchronized',
          'Out of Sync',
        ]);
      }

      if (mounted) {
        setState(() {
          _statusOptions = statusOptions;
          _linkStatusOptions = linkStatusOptions;

          // Ensure selected values are in the options
          if (!_statusOptions.contains(_selectedStatus)) {
            _statusOptions.add(_selectedStatus);
          }
          if (!_linkStatusOptions.contains(_selectedLinkStatus)) {
            _linkStatusOptions.add(_selectedLinkStatus);
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading status options from API: $e');
      }

      // Fallback to default options on error
      if (mounted) {
        setState(() {
          _statusOptions = [
            'None',
            'Active',
            'Inactive',
            'Connected',
            'Disconnected',
            'Online',
            'Offline',
            'Error',
            'Maintenance',
          ];
          _linkStatusOptions = [
            'None',
            'Linked',
            'Unlinked',
            'Pending',
            'Failed',
            'Synchronized',
            'Out of Sync',
          ];

          // Ensure selected values are in the options
          if (!_statusOptions.contains(_selectedStatus)) {
            _statusOptions.add(_selectedStatus);
          }
          if (!_linkStatusOptions.contains(_selectedLinkStatus)) {
            _linkStatusOptions.add(_selectedLinkStatus);
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStatusOptions = false;
        });
      }
    }
  }

  Future<void> _saveDevice() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Create device object - preserve original status values since they're view-only
      final device = Device(
        id: widget.device?.id ?? '',
        serialNumber: _serialNumberController.text.trim(),
        name: '',
        model: _modelController.text.trim(),
        deviceType: _selectedDeviceType == 'None' ? '' : _selectedDeviceType,
        manufacturer: widget.device?.manufacturer ?? '',
        status:
            widget.device?.status ?? 'None', // Keep original status - view only
        linkStatus:
            widget.device?.linkStatus ??
            'None', // Keep original link status - view only
        active: true,
        deviceGroupId: _selectedDeviceGroupId ?? 0, // 0 means "None"
        addressId: widget.device?.addressId ?? '',
        addressText: _addressTextController.text.trim(),
        address: _selectedAddress,
        deviceChannels: [], // Keep empty as requested
        deviceAttributes: widget.device?.deviceAttributes ?? [],
      );

      if (kDebugMode) {
        print('devicejob${device.toJson()}');
      }

      // Save device
      final response = widget.device == null
          ? await _deviceService.createDevice(device)
          : await _deviceService.updateDevice(device);

      if (response.success) {
        // Link to HES only for CREATE mode (new devices)
        if (widget.device == null && response.data != null) {
          try {
            await _deviceService.linkDeviceToHES(response.data!.id ?? '');
            if (kDebugMode) {
              print('Device linked to HES successfully');
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error linking device to HES: $e');
            }
            // Continue even if HES linking fails - don't block the success flow
          }
        }

        if (mounted) {
          AppToast.showSuccess(
            context,
            title: widget.device == null ? 'Device Created' : 'Device Updated',
            message: widget.device == null
                ? 'Device created and linked to HES successfully'
                : 'Device updated successfully',
          );

          widget.onSaved?.call();
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          AppToast.showError(
            context,
            title: 'Error',
            error: 'Error: ${response.message}',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(
          context,
          title: 'Error',
          error: 'Error saving device: $e',
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use ResponsiveHelper for consistent responsive behavior
    final dialogConstraints = ResponsiveHelper.getDialogConstraints(context);
    final isMobile = ResponsiveHelper.shouldUseCompactUI(context);

    // Dialog configuration
    const dialogType = DialogType.create;
    final dialogTitle = _isCreateMode ? 'Create Device' : 'Edit Device';
    final dialogSubtitle = _isCreateMode
        ? 'Add a new device to your system'
        : 'Update device information and settings';

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      child: ConstrainedBox(
        constraints: dialogConstraints,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            AppDialogHeader(
              type: dialogType,
              title: dialogTitle,
              subtitle: dialogSubtitle,
              onClose: () => Navigator.of(context).pop(),
            ),

            // Body
            Expanded(child: _buildBody()),

            // Footer
            Container(
              padding: EdgeInsets.all(ResponsiveHelper.getSpacing(context)),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(
                    color: AppColors.border.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppSizes.radiusMedium),
                  bottomRight: Radius.circular(AppSizes.radiusMedium),
                ),
              ),
              child: isMobile ? _buildMobileFooter() : _buildDesktopFooter(),
            ),
          ],
        ),
      ),
    );
  }

  // Responsive body with form content
  Widget _buildBody() {
    return Container(
      color: AppColors.background,
      padding: EdgeInsets.all(ResponsiveHelper.getSpacing(context)),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGeneralInfoSection(),
              SizedBox(height: ResponsiveHelper.getSpacing(context) * 2),
              _buildLocationSection(),
            ],
          ),
        ),
      ),
    );
  }

  // Mobile footer - vertical button layout
  Widget _buildMobileFooter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButton(
          text: _isSaving
              ? 'Saving...'
              : (_isCreateMode ? 'Create Device' : 'Update Device'),
          onPressed: _isSaving ? null : _saveDevice,
          isLoading: _isSaving,
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
        AppButton(
          text: _isSaving
              ? 'Saving...'
              : (_isCreateMode ? 'Create Device' : 'Update Device'),
          onPressed: _isSaving ? null : _saveDevice,
          isLoading: _isSaving,
        ),
      ],
    );
  }

  Widget _buildGeneralInfoSection() {
    final isMobile = ResponsiveHelper.shouldUseCompactUI(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: AppColors.border.withOpacity(0.1)),
      ),
      padding: EdgeInsets.all(ResponsiveHelper.getSpacing(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'General Information',
                style: TextStyle(
                  fontSize: isMobile
                      ? AppSizes.fontSizeMedium
                      : AppSizes.fontSizeLarge,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Serial number is required for device identification.',
                textStyle: const TextStyle(
                  fontSize: AppSizes.fontSizeSmall,
                  color: Colors.white,
                ),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
                preferBelow: false,
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getSpacing(context)),

          // First row: Serial Number and Model (responsive)
          isMobile
              ? Column(
                  children: [
                    AppInputField(
                      controller: _serialNumberController,
                      label: 'Serial Number *',
                      hintText: 'Enter device serial number',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Serial number is required';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: ResponsiveHelper.getSpacing(context)),
                    AppInputField(
                      controller: _modelController,
                      label: 'Model',
                      hintText: 'Enter model',
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: AppInputField(
                        controller: _serialNumberController,
                        label: 'Serial Number *',
                        hintText: 'Enter device serial number',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Serial number is required';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.getSpacing(context)),
                    Expanded(
                      child: AppInputField(
                        controller: _modelController,
                        label: 'Model',
                        hintText: 'Enter model',
                      ),
                    ),
                  ],
                ),
          SizedBox(height: ResponsiveHelper.getSpacing(context)),

          // Dropdowns section (responsive layout)
          isMobile
              ? Column(
                  children: [
                    _buildDeviceTypeDropdown(),
                    SizedBox(height: ResponsiveHelper.getSpacing(context)),
                    _buildDeviceGroupDropdown(),
                    SizedBox(height: ResponsiveHelper.getSpacing(context)),
                    _buildScheduleDropdown(),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildDeviceTypeDropdown()),
                    SizedBox(width: ResponsiveHelper.getSpacing(context)),
                    Expanded(child: _buildDeviceGroupDropdown()),
                    SizedBox(width: ResponsiveHelper.getSpacing(context)),
                    Expanded(child: _buildScheduleDropdown()),
                  ],
                ),
          SizedBox(height: ResponsiveHelper.getSpacing(context) * 2),

          // Integration HES Section Header
          Row(
            children: [
              Text(
                'Integration HES',
                style: TextStyle(
                  fontSize: isMobile
                      ? AppSizes.fontSizeSmall
                      : AppSizes.fontSizeMedium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: _isCreateMode
                    ? 'When the device is created. Status and link status will be managed by the HES system.'
                    : 'This device is integrated with HES.',
                textStyle: const TextStyle(
                  fontSize: AppSizes.fontSizeSmall,
                  color: Colors.white,
                ),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
                preferBelow: false,
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              if (_isLoadingStatusOptions && !_isCreateMode) ...[
                SizedBox(width: ResponsiveHelper.getSpacing(context) / 2),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: ResponsiveHelper.getSpacing(context)),

          // Link Status and Status (responsive layout)
          isMobile
              ? Column(
                  children: [
                    _buildLinkStatusDropdown(),
                    SizedBox(height: ResponsiveHelper.getSpacing(context)),
                    _buildStatusDropdown(),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildLinkStatusDropdown()),
                    SizedBox(width: ResponsiveHelper.getSpacing(context)),
                    Expanded(child: _buildStatusDropdown()),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    final isMobile = ResponsiveHelper.shouldUseCompactUI(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: AppColors.border.withOpacity(0.1)),
      ),
      padding: EdgeInsets.all(ResponsiveHelper.getSpacing(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Device Location',
                style: TextStyle(
                  fontSize: isMobile
                      ? AppSizes.fontSizeMedium
                      : AppSizes.fontSizeLarge,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message:
                    'Enter coordinates manually or interactive map to select a location.',
                textStyle: const TextStyle(
                  fontSize: AppSizes.fontSizeSmall,
                  color: Colors.white,
                ),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
                preferBelow: false,
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getSpacing(context)),

          // Coordinates input (responsive layout)
          isMobile
              ? Column(
                  children: [
                    AppInputField(
                      controller: _latitudeController,
                      label: 'Latitude',
                      hintText: 'Enter latitude',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (value) {
                        _updateMapFromCoordinates();
                      },
                    ),
                    SizedBox(height: ResponsiveHelper.getSpacing(context)),
                    AppInputField(
                      controller: _longitudeController,
                      label: 'Longitude',
                      hintText: 'Enter longitude',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (value) {
                        _updateMapFromCoordinates();
                      },
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: AppInputField(
                        controller: _latitudeController,
                        label: 'Latitude',
                        hintText: 'Enter latitude',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (value) {
                          _updateMapFromCoordinates();
                        },
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.getSpacing(context)),
                    Expanded(
                      child: AppInputField(
                        controller: _longitudeController,
                        label: 'Longitude',
                        hintText: 'Enter longitude',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (value) {
                          _updateMapFromCoordinates();
                        },
                      ),
                    ),
                  ],
                ),
          SizedBox(height: ResponsiveHelper.getSpacing(context)),

          // Address text input with map dialog
          AppInputField(
            controller: _addressTextController,
            label: 'Address',
            hintText: 'Click map icon to select location',
            maxLines: 2,
            readOnly: true,
            onTap: _openMapDialog,
            suffixIcon: Tooltip(
              message: 'Open interactive map to select device location',
              textStyle: const TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                color: Colors.white,
              ),
              decoration: BoxDecoration(
                color: AppColors.textPrimary.withOpacity(0.9),
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              ),
              child: IconButton(
                onPressed: _openMapDialog,
                icon: Icon(Icons.map, color: AppColors.primary),
                tooltip: '', // Empty to prevent default tooltip
              ),
            ),
          ),

          SizedBox(height: ResponsiveHelper.getSpacing(context)),

          // Location coordinates display
          if (_selectedAddress?.latitude != null &&
              _selectedAddress?.longitude != null)
            Container(
              padding: EdgeInsets.all(ResponsiveHelper.getSpacing(context)),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                border: Border.all(color: AppColors.border.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.pin_drop,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Coordinates: ${_selectedAddress!.latitude!.toStringAsFixed(6)}, ${_selectedAddress!.longitude!.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeSmall,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeviceGroupDropdown() {
    return AppSearchableDropdown<int>(
      label: 'Device Group',
      hintText: 'None',
      value: _getSafeDeviceGroupValue(),
      height: AppSizes.inputHeight,
      items: [
        const DropdownMenuItem<int>(
          value: null,
          child: Text(
            'None',
            style: TextStyle(fontSize: AppSizes.fontSizeSmall),
          ),
        ),
        ..._getUniqueDeviceGroups().map((group) {
          return DropdownMenuItem<int>(
            value: group.id,
            child: Text(
              group.name ?? 'None',
              style: const TextStyle(fontSize: AppSizes.fontSizeSmall),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }),
      ],
      isLoading: _isLoadingDeviceGroups,
      hasMore: _hasMoreDeviceGroups,
      searchQuery: _deviceGroupSearchQuery,
      onChanged: (value) {
        setState(() {
          _selectedDeviceGroupId = value;
        });
      },
      onTap: () {
        // Load device groups when dropdown is tapped
        if (!_deviceGroupsLoaded && !_isLoadingDeviceGroups) {
          _loadDeviceGroups();
        }
      },
      onSearchChanged: (query) {
        _loadDeviceGroups(searchQuery: query);
      },
      onLoadMore: () {
        _loadDeviceGroups(loadMore: true);
      },
    );
  }

  Widget _buildScheduleDropdown() {
    return AppSearchableDropdown<int>(
      label: 'Schedule',
      hintText: 'None',
      value: _getSafeScheduleValue(),
      height: AppSizes.inputHeight,
      items: [
        const DropdownMenuItem<int>(
          value: null,
          child: Text(
            'None',
            style: TextStyle(fontSize: AppSizes.fontSizeSmall),
          ),
        ),
        ..._getUniqueSchedules().map((schedule) {
          return DropdownMenuItem<int>(
            value: schedule.id,
            child: Text(
              schedule.name ?? 'Unnamed Schedule',
              style: const TextStyle(fontSize: AppSizes.fontSizeSmall),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }),
      ],
      isLoading: _isLoadingSchedules,
      hasMore: _hasMoreSchedules,
      searchQuery: _scheduleSearchQuery,
      onChanged: (value) {
        setState(() {
          _selectedScheduleId = value;
        });
      },
      onTap: () {
        // Load schedules when dropdown is tapped
        if (!_schedulesLoaded && !_isLoadingSchedules) {
          _loadSchedules();
        }
      },
      onSearchChanged: (query) {
        _loadSchedules(searchQuery: query);
      },
      onLoadMore: () {
        _loadSchedules(loadMore: true);
      },
    );
  }

  Widget _buildDeviceTypeDropdown() {
    return AppSearchableDropdown<String>(
      label: 'Device Type',
      hintText: 'None',
      value: _selectedDeviceType,
      height: AppSizes.inputHeight,
      items: _deviceTypes.map((type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(
            type,
            style: const TextStyle(fontSize: AppSizes.fontSizeSmall),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedDeviceType = value ?? 'None';
        });
      },
    );
  }

  Widget _buildLinkStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AppSearchableDropdown<String>(
                label: 'Link Status',
                hintText: 'None',
                value: _selectedLinkStatus,
                height: AppSizes.inputHeight,
                enabled: false, // Always disabled - view only
                items: _linkStatusOptions.map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(
                      status,
                      style: const TextStyle(
                        fontSize: AppSizes.fontSizeSmall,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: null, // Always null - view only
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AppSearchableDropdown<String>(
                label: 'Status',
                hintText: 'None',
                value: _selectedStatus,
                height: AppSizes.inputHeight,
                enabled: false, // Always disabled - view only
                items: _statusOptions.map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(
                      status,
                      style: const TextStyle(
                        fontSize: AppSizes.fontSizeSmall,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: null, // Always null - view only
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _updateMapFromCoordinates() {
    final lat = double.tryParse(_latitudeController.text);
    final lng = double.tryParse(_longitudeController.text);

    if (lat != null && lng != null) {
      setState(() {
        _selectedAddress = Address(
          id: _selectedAddress?.id ?? '',
          latitude: lat,
          longitude: lng,
          street: _addressTextController.text,
          city: '',
          state: '',
          postalCode: '',
          country: '',
        );
      });
    }
  }

  // Open interactive map dialog
  void _openMapDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => InteractiveMapDialog(
        initialAddress: _selectedAddress,
        onLocationSelected: (address) {
          setState(() {
            _selectedAddress = address;
            _addressTextController.text = address.street ?? '';
            _latitudeController.text = address.latitude?.toString() ?? '';
            _longitudeController.text = address.longitude?.toString() ?? '';
          });
        },
      ),
    );
  }

  // Get unique device groups to prevent dropdown duplicates
  List<DeviceGroup> _getUniqueDeviceGroups() {
    final seen = <int>{};
    final allGroups = <DeviceGroup>[];

    // First, add the current device's group if it exists and is not already in the list
    if (widget.device?.deviceGroup != null) {
      final currentGroup = widget.device!.deviceGroup!;
      if (currentGroup.id != null && !seen.contains(currentGroup.id)) {
        allGroups.add(currentGroup);
        seen.add(currentGroup.id!);
      }
    }

    // Then add the loaded groups, skipping duplicates
    for (final group in _deviceGroups) {
      if (group.id != null && !seen.contains(group.id)) {
        allGroups.add(group);
        seen.add(group.id!);
      } else if (seen.contains(group.id)) {
        if (kDebugMode) {
          print(
            'Duplicate device group found with ID: ${group.id}, Name: ${group.name}',
          );
        }
      }
    }

    return allGroups;
  }

  // Validate and get a safe device group value for the dropdown
  int? _getSafeDeviceGroupValue() {
    if (_selectedDeviceGroupId == null) return null;

    final uniqueGroups = _getUniqueDeviceGroups();

    // If groups are still loading, keep the selected value
    if (uniqueGroups.isEmpty && _isLoadingDeviceGroups) {
      return _selectedDeviceGroupId;
    }

    final groupExists = uniqueGroups.any(
      (group) => group.id == _selectedDeviceGroupId,
    );

    if (!groupExists) {
      if (kDebugMode) {
        print(
          'Selected device group ID $_selectedDeviceGroupId not found in dropdown (groups loaded: ${uniqueGroups.length})',
        );
      }
      // Only reset if we're sure the groups have been loaded
      if (!_isLoadingDeviceGroups && uniqueGroups.isNotEmpty) {
        _selectedDeviceGroupId = null;
        return null;
      }
      // Otherwise, keep the value while loading
      return _selectedDeviceGroupId;
    }

    return _selectedDeviceGroupId;
  }

  // Get unique schedules to prevent dropdown duplicates
  List<Schedule> _getUniqueSchedules() {
    final seen = <int>{};
    return _schedules.where((schedule) {
      final id = schedule.id;
      if (id == null || seen.contains(id)) {
        if (kDebugMode && id != null) {
          print(
            'Duplicate schedule found with ID: $id, Name: ${schedule.name}',
          );
        }
        return false;
      }
      seen.add(id);
      return true;
    }).toList();
  }

  // Validate and get a safe schedule value for the dropdown
  int? _getSafeScheduleValue() {
    if (_selectedScheduleId == null) return null;

    final uniqueSchedules = _getUniqueSchedules();
    final scheduleExists = uniqueSchedules.any(
      (schedule) => schedule.id == _selectedScheduleId,
    );

    if (!scheduleExists) {
      if (kDebugMode) {
        print(
          'Selected schedule ID $_selectedScheduleId not found in dropdown, resetting to null',
        );
      }
      // Reset the invalid value immediately to prevent dropdown assertion
      _selectedScheduleId = null;
      return null;
    }

    return _selectedScheduleId;
  }
}
