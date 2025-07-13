import 'package:flutter/material.dart';
import '../../../core/models/device.dart';
import '../../../core/models/device_group.dart';
import '../../../core/models/address.dart';
import '../../../core/services/device_service.dart';
import '../../../core/services/schedule_service.dart';
import '../../../core/services/api_service.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_input_field.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/devices/flutter_map_location_picker.dart';

class CreateEditDeviceDialog extends StatefulWidget {
  final Device? device;
  final VoidCallback? onSaved;

  const CreateEditDeviceDialog({super.key, this.device, this.onSaved});

  @override
  State<CreateEditDeviceDialog> createState() => _CreateEditDeviceDialogState();
}

class _CreateEditDeviceDialogState extends State<CreateEditDeviceDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  late DeviceService _deviceService;
  late ScheduleService _scheduleService;

  // Loading states
  bool _isSaving = false;
  bool _isLoadingDeviceGroups = false;
  bool _isLoadingSchedules = false;

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
  List<Map<String, dynamic>> _schedules = [];

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
    _tabController = TabController(length: 2, vsync: this);
    _deviceService = DeviceService(ApiService());
    _scheduleService = ScheduleService(ApiService());

    if (widget.device != null) {
      _populateFields();
    }

    _loadDropdownData();
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  Future<void> _loadDropdownData() async {
    setState(() {
      _isLoadingDeviceGroups = true;
      _isLoadingSchedules = true;
    });

    try {
      // Load device groups
      final deviceGroupsResponse = await _deviceService.getDeviceGroups(
        limit: 100,
        includeDevices: false,
      );

      if (deviceGroupsResponse.success) {
        setState(() {
          _deviceGroups = deviceGroupsResponse.data ?? [];
        });
      }

      // Load schedules
      final schedulesResponse = await _scheduleService.getSchedules(limit: 100);

      if (schedulesResponse.success) {
        setState(() {
          _schedules = schedulesResponse.data ?? [];
        });
      }
    } catch (e) {
      // Error loading dropdown data
    } finally {
      setState(() {
        _isLoadingDeviceGroups = false;
        _isLoadingSchedules = false;
      });
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
        status: _selectedStatus == 'None' ? '' : _selectedStatus,
        linkStatus: _selectedLinkStatus == 'None' ? '' : _selectedLinkStatus,
        active: true,
        deviceGroupId: _selectedDeviceGroupId ?? 0,
        addressId: widget.device?.addressId ?? '',
        addressText: _addressTextController.text.trim(),
        address: _selectedAddress,
        deviceChannels: widget.device?.deviceChannels ?? [],
        deviceAttributes: widget.device?.deviceAttributes ?? [],
      );

      // Save device
      final response = widget.device == null
          ? await _deviceService.createDevice(device)
          : await _deviceService.updateDevice(device);

      if (response.success) {
        // If LinkStatus is not None, trigger link to HES
        if (_selectedLinkStatus != 'None' && response.data != null) {
          try {
            await _deviceService.linkDeviceToHES(response.data!.id);
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
        width: 900,
        height: 700,
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

            // Tabs
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE1E5E9), width: 1),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF2563eb),
                unselectedLabelColor: const Color(0xFF64748b),
                indicatorColor: const Color(0xFF2563eb),
                tabs: const [
                  Tab(icon: Icon(Icons.settings), text: 'General'),
                  Tab(icon: Icon(Icons.location_on), text: 'Location'),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Container(
                color: const Color(0xFFF8FAFC),
                child: Form(
                  key: _formKey,
                  child: TabBarView(
                    controller: _tabController,
                    children: [_buildGeneralTab(), _buildLocationTab()],
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
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Cancel',
                      type: AppButtonType.secondary,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppButton(
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

  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // General Info Section
          AppCard(
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
                const SizedBox(height: 16),

                AppInputField(
                  controller: _modelController,
                  label: 'Model',
                  hintText: 'Enter device model (optional)',
                ),
                const SizedBox(height: 16),

                _buildDropdownField(
                  label: 'Device Type',
                  value: _selectedDeviceType,
                  items: _deviceTypes,
                  onChanged: (value) {
                    setState(() {
                      _selectedDeviceType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                _buildDeviceGroupDropdown(),
                const SizedBox(height: 16),

                _buildScheduleDropdown(),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Integration HES Section
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Integration HES',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1e293b),
                  ),
                ),
                const SizedBox(height: 24),

                _buildDropdownField(
                  label: 'Link Status',
                  value: _selectedLinkStatus,
                  items: _linkStatusOptions,
                  onChanged: (value) {
                    setState(() {
                      _selectedLinkStatus = value!;
                    });
                  },
                  helpText: _selectedLinkStatus != 'None'
                      ? 'Device will be linked to HES when saved'
                      : null,
                ),
                const SizedBox(height: 16),

                _buildDropdownField(
                  label: 'Status',
                  value: _selectedStatus,
                  items: _statusOptions,
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
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

                // Address text input
                AppInputField(
                  controller: _addressTextController,
                  label: 'Address Text',
                  hintText:
                      'Address will be filled automatically when location is selected',
                  maxLines: 2,
                  readOnly: true,
                ),
                const SizedBox(height: 24),

                // Flutter Map Location Picker
                SizedBox(
                  height: 500,
                  child: FlutterMapLocationPicker(
                    initialAddress: _selectedAddress,
                    onLocationChanged: (lat, lng, address) {
                      final newAddress = Address(
                        latitude: lat,
                        longitude: lng,
                        longText: address,
                        shortText: address,
                      );
                      _onMapLocationChanged(newAddress);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? helpText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1e293b),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFE1E5E9)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFE1E5E9)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFF2563eb)),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
          ),
        ),
        if (helpText != null) ...[
          const SizedBox(height: 4),
          Text(
            helpText,
            style: const TextStyle(fontSize: 12, color: Color(0xFF2563eb)),
          ),
        ],
      ],
    );
  }

  Widget _buildDeviceGroupDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Device Group',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1e293b),
          ),
        ),
        const SizedBox(height: 8),
        _isLoadingDeviceGroups
            ? Container(
                height: 56,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE1E5E9)),
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.white,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            : DropdownButtonFormField<int>(
                value: _selectedDeviceGroupId,
                items: [
                  const DropdownMenuItem<int>(value: null, child: Text('None')),
                  ..._deviceGroups.map((group) {
                    return DropdownMenuItem<int>(
                      value: group.id,
                      child: Text(group.name),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedDeviceGroupId = value;
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFFE1E5E9)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFFE1E5E9)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFF2563eb)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildScheduleDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Schedule',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1e293b),
          ),
        ),
        const SizedBox(height: 8),
        _isLoadingSchedules
            ? Container(
                height: 56,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE1E5E9)),
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.white,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            : DropdownButtonFormField<int>(
                value: _selectedScheduleId,
                items: [
                  const DropdownMenuItem<int>(value: null, child: Text('None')),
                  ..._schedules.map((schedule) {
                    return DropdownMenuItem<int>(
                      value: schedule['id'],
                      child: Text(schedule['name']),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedScheduleId = value;
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFFE1E5E9)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFFE1E5E9)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFF2563eb)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                ),
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
          shortText: _addressTextController.text,
          longText: _addressTextController.text,
        );
      });
    }
  }

  void _onMapLocationChanged(Address address) {
    setState(() {
      _latitudeController.text = address.latitude!.toStringAsFixed(6);
      _longitudeController.text = address.longitude!.toStringAsFixed(6);
      _addressTextController.text = address.longText;
      _selectedAddress = address;
    });
  }
}
