import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mdms_clone/core/constants/app_sizes.dart';
import '../../../core/models/device.dart';
import '../../../core/models/device_group.dart';
import '../../../core/models/address.dart';
import '../../../core/models/schedule.dart';
import '../../../core/services/device_service.dart';
import '../../../core/services/schedule_service.dart';
import '../../../core/services/service_locator.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_input_field.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/common/app_dropdown_field.dart';

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
  bool _deviceGroupsLoaded = false;
  bool _schedulesLoaded = false;

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
  String _selectedLinkStatus = 'None';
  String _selectedStatus = 'None';
  int? _selectedDeviceGroupId;
  int? _selectedScheduleId;
  Address? _selectedAddress;

  // Dropdown data
  List<DeviceGroup> _deviceGroups = [];
  List<Schedule> _schedules = [];

  // Device type options
  final List<String> _deviceTypes = ['None', 'Smart Meter', 'IoT'];

  // Link status options
  final List<String> _linkStatusOptions = ['None', 'MULTIDRIVE', 'E-POWER'];

  // Status options
  final List<String> _statusOptions = [
    'None',
    'Commissioned',
    'Decommissioned',
  ];

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
    _selectedLinkStatus = device.linkStatus.isNotEmpty
        ? device.linkStatus
        : 'None';
    _selectedStatus = device.status.isNotEmpty ? device.status : 'None';
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
        search: _scheduleSearchQuery.isNotEmpty ? _scheduleSearchQuery : '',
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

  Future<void> _saveDevice() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Create device object
      final device = Device(
        id: widget.device?.id ?? '',
        serialNumber: _serialNumberController.text.trim(),
        name: '',
        model: _modelController.text.trim(),
        deviceType: _selectedDeviceType == 'None' ? '' : _selectedDeviceType,
        manufacturer: widget.device?.manufacturer ?? '',
        status: _selectedStatus == 'None' ? 'None' : _selectedStatus,
        linkStatus: _selectedLinkStatus == 'None'
            ? 'None'
            : _selectedLinkStatus,
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
        // If LinkStatus is not None, trigger link to HES
        if (_selectedLinkStatus != 'None' && response.data != null) {
          try {
            await _deviceService.linkDeviceToHES(response.data!.id ?? '');
          } catch (e) {
            // Error linking to HES - continue even if HES linking fails
          }
        }

        if (mounted) {
          AppToast.showSuccess(
            context,
            title: widget.device == null ? 'Device Created' : 'Device Updated',
            message: widget.device == null
                ? 'Device created successfully'
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE1E5E9), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    widget.device == null ? 'Create Device' : 'Edit Device',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1e293b),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF8F9FA),
                      foregroundColor: const Color(0xFF64748b),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Container(
                color: const Color(0xFFF8FAFC),
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildGeneralInfoSection(),
                        const SizedBox(height: 32),
                        _buildLocationSection(),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                border: Border(
                  top: BorderSide(color: Color(0xFFE1E5E9), width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: AppSizes.buttonWidth,
                    child: AppButton(
                      size: AppButtonSize.small,
                      text: 'Cancel',
                      type: AppButtonType.outline,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: AppSizes.buttonW,
                    child: AppButton(
                      size: AppButtonSize.small,
                      text: _isSaving
                          ? 'Saving...'
                          : (widget.device == null
                                ? 'Create Device'
                                : 'Update Device'),
                      type: AppButtonType.primary,
                      onPressed: _isSaving ? null : _saveDevice,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralInfoSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'General Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1e293b),
            ),
          ),
          const SizedBox(height: 24),

          // First row: Serial Number and Model (2 columns)
          Row(
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
              const SizedBox(width: 16),
              Expanded(
                child: AppInputField(
                  controller: _modelController,
                  label: 'Model',
                  hintText: 'Enter device model (optional)',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Second row: Device Type, Device Group, and Schedule (3 columns)
          Row(
            children: [
              Expanded(child: _buildDeviceTypeDropdown()),
              const SizedBox(width: 16),
              Expanded(child: _buildDeviceGroupDropdown()),
              const SizedBox(width: 16),
              Expanded(child: _buildScheduleDropdown()),
            ],
          ),
          const SizedBox(height: 24),

          // Integration HES Section
          const Text(
            'Integration HES',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1e293b),
            ),
          ),
          const SizedBox(height: 16),

          // Link Status and Status in a row
          Row(
            children: [
              Expanded(child: _buildLinkStatusDropdown()),
              const SizedBox(width: 16),
              Expanded(child: _buildStatusDropdown()),
            ],
          ),
          if (_selectedLinkStatus != 'None') ...[
            const SizedBox(height: 4),
            Text(
              'Device will be linked to HES when saved',
              style: const TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                color: Color(0xFF2563eb),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Device Location',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1e293b),
            ),
          ),
          const SizedBox(height: 24),

          // Coordinates input
          Row(
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
              const SizedBox(width: 16),
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
          const SizedBox(height: 16),

          // Address text input with map dialog
          AppInputField(
            controller: _addressTextController,
            label: 'Address',
            hintText: 'Click map icon to select location',
            maxLines: 2,
            readOnly: true,
            onTap: _openMapDialog,
            suffixIcon: IconButton(
              onPressed: _openMapDialog,
              icon: const Icon(Icons.map, color: Color(0xFF2563eb)),
              tooltip: 'Open Map Selector',
            ),
          ),

          const SizedBox(height: 16),

          // Location coordinates display
          if (_selectedAddress?.latitude != null &&
              _selectedAddress?.longitude != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.pin_drop,
                    color: Color(0xFF64748b),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Coordinates: ${_selectedAddress!.latitude!.toStringAsFixed(6)}, ${_selectedAddress!.longitude!.toStringAsFixed(6)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF374151),
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
        AppSearchableDropdown<String>(
          label: 'Link Status',
          hintText: 'None',
          value: _selectedLinkStatus,
          height: AppSizes.inputHeight,
          items: _linkStatusOptions.map((status) {
            return DropdownMenuItem<String>(
              value: status,
              child: Text(
                status,
                style: const TextStyle(fontSize: AppSizes.fontSizeSmall),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedLinkStatus = value ?? 'None';
            });
          },
        ),
        // if (_selectedLinkStatus != 'None') ...[
        //   const SizedBox(height: 4),
        //   Text(
        //     'Device will be linked to HES when saved',
        //     style: const TextStyle(
        //       fontSize: AppSizes.fontSizeSmall,
        //       color: Color(0xFF2563eb),
        //     ),
        //   ),
        // ],
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      children: [
        AppSearchableDropdown<String>(
          label: 'Status',
          hintText: 'None',
          value: _selectedStatus,
          height: AppSizes.inputHeight,
          items: _statusOptions.map((status) {
            return DropdownMenuItem<String>(
              value: status,
              child: Text(
                status,
                style: const TextStyle(fontSize: AppSizes.fontSizeSmall),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedStatus = value ?? 'None';
            });
          },
        ),
        if (_selectedLinkStatus != 'None') ...[
          const SizedBox(height: 4),
          Container(),
          // Text(
          //   'Device will be linked to HES when saved',
          //   style: const TextStyle(
          //     fontSize: AppSizes.fontSizeSmall,
          //     color: Color(0xFF2563eb),
          //   ),
          // ),
        ],
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
