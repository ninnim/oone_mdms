import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mdms_clone/presentation/widgets/common/app_tabs.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/device.dart';
import '../../../core/models/device_group.dart';
import '../../../core/models/address.dart';
import '../../../core/services/device_service.dart';
import '../../../core/services/schedule_service.dart';
import '../../../core/services/service_locator.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_input_field.dart';
import '../../widgets/common/app_dropdown_field.dart';
import '../../widgets/common/results_pagination.dart';
import '../../widgets/common/blunest_data_table.dart';
import '../../widgets/common/app_lottie_state_widget.dart';
import '../../widgets/devices/device_location_viewer.dart';
import '../../widgets/devices/interactive_map_dialog.dart';
import '../../widgets/devices/metrics_table_columns.dart';
import '../../widgets/devices/billing_table_columns.dart';
import '../../widgets/common/custom_date_range_picker.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/common/app_confirm_dialog.dart';
import '../../routes/app_router.dart';

class Device360DetailsScreen extends StatefulWidget {
  final Device device;
  final VoidCallback? onBack;
  final Function(Device, Map<String, dynamic>)? onNavigateToBillingReadings;

  const Device360DetailsScreen({
    super.key,
    required this.device,
    this.onBack,
    this.onNavigateToBillingReadings,
  });

  @override
  State<Device360DetailsScreen> createState() => _Device360DetailsScreenState();
}

class _Device360DetailsScreenState extends State<Device360DetailsScreen> {
  late DeviceService _deviceService;
  late ScheduleService _scheduleService;
  int _currentTabIndex = 0;

  Device? _deviceDetails;
  List<DeviceChannel>? _deviceChannels;
  Map<String, dynamic>? _deviceMetrics;
  Map<String, dynamic>? _deviceBilling;
  bool _isLoading = true;
  String? _error;

  // Tab-specific loading states
  bool _overviewLoaded = false;
  bool _channelsLoaded = false;
  bool _metricsLoaded = false;
  bool _billingLoaded = false;
  bool _locationLoaded = false;

  // Billing-specific state
  int _billingCurrentPage = 1;
  int _billingItemsPerPage = 10;
  String? _billingSortBy;
  bool _billingSortAscending = true;

  // Tab-specific loading indicators
  bool _loadingOverview = false;
  bool _loadingChannels = false;
  bool _loadingMetrics = false;
  bool _loadingBilling = false;
  bool _loadingLocation = false;

  // Metrics tab state
  bool _isTableView = true;
  int _metricsCurrentPage = 1;
  int _metricsItemsPerPage = 10;
  DateTime _metricsStartDate = DateTime.now().subtract(
    const Duration(days: 30),
  );
  DateTime _metricsEndDate = DateTime.now();

  // Metrics sorting
  String? _metricsSortBy;
  bool _metricsSortAscending = true;

  // Overview edit mode state
  bool _isEditingOverview = false;
  bool _savingOverview = false;
  final GlobalKey<FormState> _overviewFormKey = GlobalKey<FormState>();

  // Edit mode controllers
  final TextEditingController _serialNumberEditController =
      TextEditingController();
  final TextEditingController _modelEditController = TextEditingController();
  final TextEditingController _addressEditController = TextEditingController();

  // Edit mode form data
  String _selectedDeviceTypeEdit = 'None';
  String _selectedLinkStatusEdit = 'None';
  String _selectedStatusEdit = 'None';
  int? _selectedDeviceGroupIdEdit;
  Address? _selectedAddressEdit;

  // Dropdown data for edit mode
  List<DeviceGroup> _deviceGroups = [];
  bool _isLoadingDeviceGroups = false;
  String _deviceGroupSearchQuery = '';
  bool _hasMoreDeviceGroups = false;

  // Schedule dropdown data
  List<Map<String, dynamic>> _schedules = [];
  bool _isLoadingSchedules = false;
  String _scheduleSearchQuery = '';
  bool _hasMoreSchedules = true;
  int? _selectedScheduleIdEdit;

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
    _deviceService = Provider.of<DeviceService>(context, listen: false);

    // Use ServiceLocator to get API service for schedule service
    final serviceLocator = ServiceLocator();
    final apiService = serviceLocator.apiService;
    _scheduleService = ScheduleService(apiService);

    // Initialize edit fields if device is provided
    _initializeEditFields();

    // Load initial overview data
    _loadOverviewData();
  }

  void _initializeEditFields() {
    if (widget.device != null) {
      // Initialize form fields with device data
      _serialNumberEditController.text = widget.device!.serialNumber ?? '';
      _modelEditController.text = widget.device!.model ?? '';

      // Initialize dropdown selections
      _selectedDeviceTypeEdit = widget.device!.deviceType ?? 'None';
      _selectedStatusEdit = widget.device!.status ?? 'None';
      _selectedLinkStatusEdit = widget.device!.linkStatus ?? 'None';

      // Initialize device group selection if available
      if (widget.device!.deviceGroupId != null) {
        _selectedDeviceGroupIdEdit = widget.device!.deviceGroupId;
      }

      // Initialize schedule selection if available
      // Note: Device model doesn't have scheduleId field yet, add this when model is updated
      // if (widget.device!.scheduleId != null) {
      //   _selectedScheduleIdEdit = widget.device!.scheduleId;
      // }
    }
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentTabIndex = index;
    });

    switch (index) {
      case 0: // Overview
        if (!_overviewLoaded) _loadOverviewData();
        break;
      case 1: // Channels
        if (!_channelsLoaded) _loadChannelsData();
        break;
      case 2: // Metrics
        if (!_metricsLoaded) _loadMetricsData();
        break;
      case 3: // Billing
        if (!_billingLoaded) _loadBillingData();
        break;
      case 4: // Location
        if (!_locationLoaded) _loadLocationData();
        break;
    }
  }

  @override
  void dispose() {
    _serialNumberEditController.dispose();
    _modelEditController.dispose();
    _addressEditController.dispose();
    super.dispose();
  }

  // Helper method to get device group name
  String? _getDeviceGroupName() {
    if (widget.device.deviceGroupId == 0) {
      return 'None';
    }

    final deviceGroup = _deviceGroups.firstWhere(
      (group) => group.id == widget.device.deviceGroupId,
      orElse: () => DeviceGroup(
        id: 0,
        name: 'None',
        description: '',
        active: false,
        devices: [],
      ),
    );
    return deviceGroup.name;
  }

  // Start editing overview
  void _startEditingOverview() {
    setState(() {
      _isEditingOverview = true;
    });
    // _loadDropdownDataForEdit();
    _populateEditFields();
  }

  // Cancel editing overview
  void _cancelEditingOverview() {
    setState(() {
      _isEditingOverview = false;
      _savingOverview = false;
    });
    _clearEditFields();
  }

  // Populate edit fields with current device data
  void _populateEditFields() {
    _serialNumberEditController.text = widget.device.serialNumber;
    _modelEditController.text = widget.device.model;
    _addressEditController.text = widget.device.addressText;
    _selectedDeviceTypeEdit = widget.device.deviceType.isNotEmpty
        ? widget.device.deviceType
        : 'None';
    _selectedLinkStatusEdit = widget.device.linkStatus.isNotEmpty
        ? widget.device.linkStatus
        : 'None';
    _selectedStatusEdit = widget.device.status.isNotEmpty
        ? widget.device.status
        : 'None';
    _selectedDeviceGroupIdEdit = widget.device.deviceGroupId != 0
        ? widget.device.deviceGroupId
        : null;
    _selectedAddressEdit = widget.device.address;
    // For now, initialize schedule to null - will be set when Device model includes scheduleId
    _selectedScheduleIdEdit = null;
  }

  // Clear edit fields
  void _clearEditFields() {
    _serialNumberEditController.clear();
    _modelEditController.clear();
    _addressEditController.clear();
    _selectedDeviceTypeEdit = 'None';
    _selectedLinkStatusEdit = 'None';
    _selectedStatusEdit = 'None';
    _selectedDeviceGroupIdEdit = null;
    _selectedAddressEdit = null;
    _selectedScheduleIdEdit = null;
  }

  // Load dropdown data for edit mode
  Future<void> _loadDropdownDataForEdit() async {
    setState(() {
      _isLoadingDeviceGroups = true;
      _isLoadingSchedules = true;
    });

    try {
      // Clear search queries and load initial data
      _deviceGroupSearchQuery = '';
      _scheduleSearchQuery = '';

      // Load device groups and schedules in parallel
      await Future.wait([
        _loadDeviceGroups(reset: true),
        _loadSchedules(reset: true),
      ]);
    } catch (e) {
      // Error loading dropdown data
      print('Error loading dropdown data: $e');
    } finally {
      setState(() {
        _isLoadingDeviceGroups = false;
        _isLoadingSchedules = false;
      });
    }
  }

  // Load device groups with search and pagination
  Future<void> _loadDeviceGroups({bool reset = false}) async {
    if (reset) {
      _deviceGroups.clear();
      // Don't clear search query when resetting for search
    }

    setState(() {
      _isLoadingDeviceGroups = true;
    });

    try {
      final response = await _deviceService.getDeviceGroups(
        limit: 20,
        offset: reset ? 0 : _deviceGroups.length,
        search: _deviceGroupSearchQuery.isNotEmpty
            ? _deviceGroupSearchQuery
            : '',
        includeDevices: false,
      );

      if (response.success) {
        final newGroups = response.data ?? [];
        setState(() {
          if (reset) {
            _deviceGroups = newGroups;
          } else {
            _deviceGroups.addAll(newGroups);
          }
          _hasMoreDeviceGroups = newGroups.length >= 20;
        });
      }
    } catch (e) {
      print('Error loading device groups: $e');
    } finally {
      setState(() {
        _isLoadingDeviceGroups = false;
      });
    }
  }

  // Handle device group search
  void _onDeviceGroupSearchChanged(String query) {
    _deviceGroupSearchQuery = query;
    _loadDeviceGroups(reset: true);
  }

  // Handle load more device groups
  void _onLoadMoreDeviceGroups() {
    if (!_isLoadingDeviceGroups && _hasMoreDeviceGroups) {
      _loadDeviceGroups();
    }
  }

  // Load schedules with search and pagination
  Future<void> _loadSchedules({bool reset = false}) async {
    if (reset) {
      _schedules.clear();
      // Don't clear search query when resetting for search
    }

    setState(() {
      _isLoadingSchedules = true;
    });

    try {
      final response = await _scheduleService.getSchedules(
        limit: 20,
        offset: reset ? 0 : _schedules.length,
        search: _scheduleSearchQuery.isNotEmpty ? _scheduleSearchQuery : '',
      );

      if (response.success) {
        final newSchedules = response.data ?? [];
        setState(() {
          if (reset) {
            _schedules = newSchedules;
          } else {
            _schedules.addAll(newSchedules);
          }
          _hasMoreSchedules = newSchedules.length >= 20;
        });
      }
    } catch (e) {
      print('Error loading schedules: $e');
    } finally {
      setState(() {
        _isLoadingSchedules = false;
      });
    }
  }

  // Handle schedule search
  void _onScheduleSearchChanged(String query) {
    _scheduleSearchQuery = query;
    _loadSchedules(reset: true);
  }

  // Handle load more schedules
  void _onLoadMoreSchedules() {
    if (!_isLoadingSchedules && _hasMoreSchedules) {
      _loadSchedules();
    }
  }

  // Save overview changes
  Future<void> _saveOverviewChanges() async {
    if (!_overviewFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _savingOverview = true;
    });

    try {
      // Create updated device object with proper null safety
      final updatedDevice = Device(
        id: widget.device.id,
        serialNumber: _serialNumberEditController.text.trim(),
        name: widget.device.name,
        model: _modelEditController.text.trim(),
        deviceType: _selectedDeviceTypeEdit == 'None'
            ? ''
            : _selectedDeviceTypeEdit,
        manufacturer: widget.device.manufacturer,
        status: _selectedStatusEdit == 'None' ? 'None' : _selectedStatusEdit,
        linkStatus: _selectedLinkStatusEdit == 'None'
            ? 'None'
            : _selectedLinkStatusEdit,
        active: widget.device.active,
        deviceGroupId: _selectedDeviceGroupIdEdit ?? 0,
        addressId: widget.device.addressId,
        addressText: _addressEditController.text.trim(),
        address: _selectedAddressEdit,
        deviceChannels:
            [], //widget.device.deviceChannels, // Keep existing channels
        deviceAttributes:
            widget.device.deviceAttributes, // Keep existing attributes
      );

      // Save device
      final response = await _deviceService.updateDevice(updatedDevice);

      if (response.success) {
        // If LinkStatus is not None, trigger link to HES
        if (_selectedLinkStatusEdit != 'None' && response.data != null) {
          try {
            await _deviceService.linkDeviceToHES(response.data!.id ?? '');
          } catch (e) {
            // Error linking to HES - continue even if HES linking fails
            print('Error linking to HES: $e');
          }
        }

        if (mounted) {
          AppToast.showSuccess(
            context,
            title: 'Device Updated',
            message: 'Device information updated successfully',
          );

          // Exit edit mode and refresh data
          setState(() {
            _isEditingOverview = false;
            _savingOverview = false;
          });

          // Refresh overview data
          _overviewLoaded = false;
          await _loadOverviewData();
        }
      } else {
        if (mounted) {
          AppToast.showError(
            context,
            title: 'Update Failed',
            error: response.message ?? 'Unknown error occurred',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(
          context,
          title: 'Update Failed',
          error: 'Error updating device: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _savingOverview = false;
        });
      }
    }
  }

  // Build dropdown field for edit mode

  // Build device group dropdown for edit mode
  Widget _buildDeviceGroupEditDropdown() {
    // Create dropdown items from device groups
    final List<DropdownMenuItem<int?>> items = [
      DropdownMenuItem<int?>(
        value: null,
        child: Text(
          'None',
          style: TextStyle(
            fontSize: AppSizes.fontSizeSmall,
            color: Color(0xFF374151),
          ),
        ),
      ),
      DropdownMenuItem<int?>(
        value: widget.device.deviceGroupData?['Id'] ?? 0,
        child: Text(
          widget.device.deviceGroupData?['Name']?.toString() ?? 'None',
          style: TextStyle(
            fontSize: AppSizes.fontSizeSmall,
            color: Color(0xFF374151),
          ),
        ),
      ),
      // ..._deviceGroups
      //     .map(
      //       (group) => DropdownMenuItem<int?>(
      //         value: group.id,
      //         child: Text(
      //           group.name ?? 'None',
      //           style: const TextStyle(
      //             fontSize: AppSizes.fontSizeSmall,
      //             color: Color(0xFF374151),
      //           ),
      //         ),
      //       ),
      //     )
      //     .toList(),
    ];

    return AppSearchableDropdown<int?>(
      label: 'Device Group',
      hintText: 'None',
      value: _selectedDeviceGroupIdEdit,
      height: AppSizes.inputHeight,
      items: items,
      isLoading: _isLoadingDeviceGroups,
      hasMore: _hasMoreDeviceGroups,
      searchQuery: _deviceGroupSearchQuery,
      onChanged: (int? value) {
        setState(() {
          _selectedDeviceGroupIdEdit = value;
        });
      },
      onTap: () {
        if (_deviceGroups.isEmpty && !_isLoadingDeviceGroups) {
          _loadDeviceGroups(reset: true);
        }
      },
      onSearchChanged: _onDeviceGroupSearchChanged,
      onLoadMore: _onLoadMoreDeviceGroups,
      debounceDelay: const Duration(milliseconds: 500),
    );
  }

  // Build schedule dropdown for edit mode
  Widget _buildScheduleEditDropdown() {
    // Create dropdown items from schedules
    final List<DropdownMenuItem<int?>> items = [
      const DropdownMenuItem<int?>(
        value: null,
        child: Text(
          'None',
          style: TextStyle(
            fontSize: AppSizes.fontSizeSmall,
            color: Color(0xFF374151),
          ),
        ),
      ),
      ..._schedules
          .map(
            (schedule) => DropdownMenuItem<int?>(
              value: schedule['id'],
              child: Text(
                schedule['name'],
                style: const TextStyle(
                  fontSize: AppSizes.fontSizeSmall,
                  color: Color(0xFF374151),
                ),
              ),
            ),
          )
          .toList(),
    ];

    return AppSearchableDropdown<int?>(
      label: 'Schedule',
      hintText: 'Select Schedule',
      value: _selectedScheduleIdEdit,
      height: AppSizes.inputHeight,
      items: items,
      isLoading: _isLoadingSchedules,
      hasMore: _hasMoreSchedules,
      searchQuery: _scheduleSearchQuery,
      onChanged: (int? value) {
        setState(() {
          _selectedScheduleIdEdit = value;
        });
      },
      onTap: () {
        if (_schedules.isEmpty && !_isLoadingSchedules) {
          _loadSchedules(reset: true);
        }
      },
      onSearchChanged: _onScheduleSearchChanged,
      onLoadMore: _onLoadMoreSchedules,
      debounceDelay: const Duration(milliseconds: 500),
    );
  }

  // Build device type dropdown for edit mode
  Widget _buildDeviceTypeEditDropdown() {
    return AppSearchableDropdown<String>(
      label: 'Device Type',
      hintText: 'None',
      value: _selectedDeviceTypeEdit,
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
          _selectedDeviceTypeEdit = value ?? 'None';
        });
      },
    );
  }

  // Build status dropdown for edit mode
  Widget _buildStatusEditDropdown() {
    return AppSearchableDropdown<String>(
      label: 'Status',
      hintText: 'None',
      value: _selectedStatusEdit,
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
          _selectedStatusEdit = value ?? 'None';
        });
      },
    );
  }

  // Build link status dropdown for edit mode
  Widget _buildLinkStatusEditDropdown() {
    return AppSearchableDropdown<String>(
      label: 'Link Status',
      hintText: 'None',
      value: _selectedLinkStatusEdit,
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
          _selectedLinkStatusEdit = value ?? 'None';
        });
      },
    );
  }

  // Open interactive map dialog
  void _openMapDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => InteractiveMapDialog(
        initialAddress: _selectedAddressEdit,
        onLocationSelected: (address) {
          setState(() {
            _selectedAddressEdit = address;
            _addressEditController.text = address.street ?? '';
          });
        },
      ),
    );
  }

  // Overview tab - Load basic device info and groups
  Future<void> _loadOverviewData() async {
    if (_overviewLoaded || _loadingOverview) return;

    setState(() {
      _loadingOverview = true;
      _isLoading = true;
      _error = null;
    });

    try {
      // Load device details
      final deviceDetailsResponse = await _deviceService.getDeviceById(
        widget.device.id ?? '',
      );

      if (deviceDetailsResponse.success) {
        _deviceDetails = deviceDetailsResponse.data;
      }

      setState(() {
        _overviewLoaded = true;
        _loadingOverview = false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load overview data: $e';
        _loadingOverview = false;
        _isLoading = false;
      });
    }
  }

  // Channels tab - Load device channels
  Future<void> _loadChannelsData() async {
    if (_channelsLoaded || _loadingChannels) return;

    setState(() {
      _loadingChannels = true;
    });

    try {
      print('Loading channels data for device: ${widget.device.id}');

      // Device channels are typically included in device details
      if (_deviceDetails == null) {
        final deviceDetailsResponse = await _deviceService.getDeviceById(
          widget.device.id ?? '',
        );
        if (deviceDetailsResponse.success) {
          _deviceDetails = deviceDetailsResponse.data;
          _deviceChannels = _deviceDetails?.deviceChannels;
        }
      } else {
        _deviceChannels = _deviceDetails?.deviceChannels;
      }

      print('Device channels loaded: ${_deviceChannels?.length}');

      setState(() {
        _channelsLoaded = true;
        _loadingChannels = false;
      });
    } catch (e) {
      print('Error loading channels data: $e');
      setState(() {
        _loadingChannels = false;
      });
    }
  }

  // Metrics tab - Load device metrics with current filters
  Future<void> _loadMetricsData() async {
    if (_loadingMetrics) return;

    setState(() {
      _loadingMetrics = true;
    });

    try {
      print('Loading metrics data for device: ${widget.device.id}');
      print(
        'Date range: ${_metricsStartDate.toIso8601String()} to ${_metricsEndDate.toIso8601String()}',
      );

      final metricsResponse = await _deviceService.getDeviceMetrics(
        widget.device.id ?? '',
        startDate: _metricsStartDate.toIso8601String(),
        endDate: _metricsEndDate.toIso8601String(),
        limit: 100, // Get more data for pagination
        offset: 0,
      );

      print('Metrics response: ${metricsResponse.success}');

      if (metricsResponse.success) {
        _deviceMetrics = metricsResponse.data;
        print('Metrics loaded successfully');
        print('Metrics keys: ${_deviceMetrics?.keys}');
        if (_deviceMetrics?['DeviceMetrics']?['Metrics'] != null) {
          final metrics = _deviceMetrics!['DeviceMetrics']['Metrics'] as List;
          print('Number of metrics: ${metrics.length}');
        }
      } else {
        print('Metrics error: ${metricsResponse.message}');
        // Create empty structure for error handling
        _deviceMetrics = {
          'DeviceMetrics': {
            'Metrics': [],
            'Status': 'Error: ${metricsResponse.message}',
          },
        };
      }

      setState(() {
        _metricsLoaded = true;
        _loadingMetrics = false;
      });
    } catch (e) {
      print('Error loading metrics data: $e');
      setState(() {
        _loadingMetrics = false;
        _deviceMetrics = {
          'DeviceMetrics': {'Metrics': [], 'Status': 'Error: $e'},
        };
      });
    }
  }

  // Billing tab - Load device billing data
  Future<void> _loadBillingData() async {
    if (_loadingBilling) return;

    setState(() {
      _loadingBilling = true;
    });

    try {
      print('Loading billing data for device: ${widget.device.id}');

      final billingResponse = await _deviceService.getDeviceBilling(
        widget.device.id ?? '',
      );
      print('Billing response: ${billingResponse.success}');

      if (billingResponse.success) {
        _deviceBilling = billingResponse.data;
        print('Billing loaded successfully');
        print('Billing keys: ${_deviceBilling?.keys}');
      } else {
        print('Billing error: ${billingResponse.message}');
        _deviceBilling = {
          'error': billingResponse.message,
          'DeviceBilling': null,
        };
      }

      setState(() {
        _billingLoaded = true;
        _loadingBilling = false;
      });
    } catch (e) {
      print('Error loading billing data: $e');
      setState(() {
        _loadingBilling = false;
        _deviceBilling = {
          'error': 'Failed to load billing data: $e',
          'DeviceBilling': null,
        };
      });
    }
  }

  // Location tab - Already have address info from device
  Future<void> _loadLocationData() async {
    if (_locationLoaded || _loadingLocation) return;

    setState(() {
      _loadingLocation = true;
    });

    try {
      print('Loading location data for device: ${widget.device.id}');

      // Location data comes from device.address, no additional API call needed
      // But we can load additional location details if needed

      setState(() {
        _locationLoaded = true;
        _loadingLocation = false;
      });
    } catch (e) {
      print('Error loading location data: $e');
      setState(() {
        _loadingLocation = false;
      });
    }
  }

  // Refresh metrics data when filters change
  void _refreshMetricsData() {
    print('Refreshing metrics data with new filters');
    setState(() {
      _metricsLoaded = false;
      _deviceMetrics = null;
      _metricsCurrentPage = 1;
    });
    _loadMetricsData();
  }

  // Refresh current tab data
  Future<void> _refreshCurrentTabData() async {
    final int tabIndex = _currentTabIndex;
    print('Refreshing tab data for index: $tabIndex');

    switch (tabIndex) {
      case 0: // Overview
        setState(() {
          _overviewLoaded = false;
          _deviceDetails = null;
        });
        await _loadOverviewData();
        break;
      case 1: // Channels
        setState(() {
          _channelsLoaded = false;
          _deviceChannels = null;
        });
        await _loadChannelsData();
        break;
      case 2: // Metrics
        setState(() {
          _metricsLoaded = false;
          _deviceMetrics = null;
          _metricsCurrentPage = 1;
        });
        await _loadMetricsData();
        break;
      case 3: // Billing
        setState(() {
          _billingLoaded = false;
          _deviceBilling = null;
        });
        await _loadBillingData();
        break;
      case 4: // Location
        setState(() {
          _locationLoaded = false;
        });
        await _loadLocationData();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header section
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacing24,
            vertical: AppSizes.spacing16,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFE1E5E9), width: 1),
            ),
          ),
          child: Row(
            children: [
              // if (widget.onBack != null) ...[
              //   IconButton(
              //     icon: const Icon(Icons.arrow_back),
              //     onPressed: widget.onBack,
              //     tooltip: 'Back to Devices',
              //   ),
              //   const SizedBox(width: 16),
              // ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Device 360°',
                      style: const TextStyle(
                        fontSize: AppSizes.fontSizeXLarge,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1e293b),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Text(
                    //   'Serial: ${widget.device.serialNumber}',
                    //   style: const TextStyle(
                    //     fontSize: 16,
                    //     color: Color(0xFF64748b),
                    //   ),
                    // ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      // crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // StatusChip.fromDeviceStatus(
                        //   widget.device.status,
                        //   compact: true,
                        // ),

                        // const SizedBox(width: 16),
                        Expanded(
                          flex: 0,
                          child: _buildInfoRow(
                            '',
                            widget.device.status,
                            icon: Icons.power_settings_new,
                            showStatusChip: true,
                            showLabel: false,
                          ),
                        ),
                        SizedBox(width: AppSizes.spacing4),
                        Expanded(
                          flex: 0,
                          child: _buildInfoRow(
                            '',
                            widget.device.linkStatus,
                            icon: Icons.link,
                            showStatusChip: true,
                            showLabel: false,
                          ),
                        ),
                        // Expanded(flex: 4, child: Container()),
                        // StatusChip(
                        //   text: 'Link: ${widget.device.linkStatus}',
                        //   compact: true,
                        //   type: StatusChipType.info,
                        // ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildActionButtons(),
            ],
          ),
        ),

        // Content section with AppTabs
        Expanded(
          child: _isLoading
              ? const Center(
                  child: AppLottieStateWidget.loading(
                    title: 'Loading Device Details',
                    message: 'Please wait while we fetch device details.',
                    lottieSize: 80,
                    titleColor: AppColors.primary,
                    messageColor: AppColors.secondary,
                  ),
                )
              : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Color(0xFFef4444),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFFef4444),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Retry loading current tab data
                          final int tabIndex = _currentTabIndex;
                          switch (tabIndex) {
                            case 0:
                              setState(() {
                                _overviewLoaded = false;
                                _error = null;
                              });
                              _loadOverviewData();
                              break;
                            case 1:
                              setState(() {
                                _channelsLoaded = false;
                                _error = null;
                              });
                              _loadChannelsData();
                              break;
                            case 2:
                              setState(() {
                                _metricsLoaded = false;
                                _error = null;
                              });
                              _loadMetricsData();
                              break;
                            case 3:
                              setState(() {
                                _billingLoaded = false;
                                _error = null;
                              });
                              _loadBillingData();
                              break;
                            case 4:
                              setState(() {
                                _locationLoaded = false;
                                _error = null;
                              });
                              _loadLocationData();
                              break;
                          }
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : AppPillTabs(
                  initialIndex: _currentTabIndex,
                  onTabChanged: _onTabChanged,
                  //  isScrollable: true,
                  tabs: [
                    AppTab(
                      label: 'Overview',
                      icon: Icon(Icons.dashboard, size: AppSizes.iconSmall),
                      content: _buildOverviewTab(),
                    ),
                    AppTab(
                      label: 'Channels',
                      icon: Icon(Icons.device_hub, size: AppSizes.iconSmall),
                      content: _buildChannelsTab(),
                    ),
                    AppTab(
                      label: 'Metrics',
                      icon: Icon(Icons.analytics, size: AppSizes.iconSmall),
                      content: _buildMetricsTab(),
                    ),
                    AppTab(
                      label: 'Billing',
                      icon: Icon(Icons.receipt, size: AppSizes.iconSmall),
                      content: _buildBillingTab(),
                    ),
                    AppTab(
                      label: 'Location',
                      icon: Icon(Icons.location_on, size: AppSizes.iconSmall),
                      content: _buildLocationTab(),
                    ),
                  ],
                  // selectedColor:
                  //     Colors.blue, // Background color for selected tab
                  // unselectedColor: Colors.grey.withOpacity(
                  //   0.2,
                  // ), // Background for unselected
                  // selectedTextColor:
                  //     Colors.white, // Text and icon color when selected
                  // unselectedTextColor:
                  //     Colors.grey, // Text and icon color when unselected
                ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ping Device
        IconButton(
          padding: const EdgeInsets.all(AppSizes.spacing8),
          constraints: const BoxConstraints(
            minWidth: AppSizes.spacing32,
            minHeight: AppSizes.spacing32,
          ),
          iconSize: AppSizes.iconSmall,
          onPressed: () => _performDeviceAction('ping'),
          icon: const Icon(Icons.network_ping),
          tooltip: 'Ping Device',
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF10b981).withOpacity(0.1),
            foregroundColor: const Color(0xFF10b981),
          ),
        ),
        const SizedBox(width: 8),

        // Link HES
        IconButton(
          padding: const EdgeInsets.all(AppSizes.spacing8),
          constraints: const BoxConstraints(
            minWidth: AppSizes.spacing32,
            minHeight: AppSizes.spacing32,
          ),
          iconSize: AppSizes.iconSmall,
          onPressed: () => _performDeviceAction('link_hes'),
          icon: const Icon(Icons.link),
          tooltip: 'Link to HES',
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF2563eb).withOpacity(0.1),
            foregroundColor: const Color(0xFF2563eb),
          ),
        ),
        const SizedBox(width: 8),

        // Commission Device
        IconButton(
          padding: const EdgeInsets.all(AppSizes.spacing8),
          constraints: const BoxConstraints(
            minWidth: AppSizes.spacing32,
            minHeight: AppSizes.spacing32,
          ),
          iconSize: AppSizes.iconSmall,
          onPressed: () => _performDeviceAction('commission'),
          icon: const Icon(Icons.check_circle),
          tooltip: 'Commission Device',
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFf59e0b).withOpacity(0.1),
            foregroundColor: const Color(0xFFf59e0b),
          ),
        ),
        const SizedBox(width: 8),

        // More Actions
        PopupMenuButton<String>(
          padding: const EdgeInsets.all(AppSizes.spacing8),
          constraints: const BoxConstraints(
            minWidth: AppSizes.spacing32,
            minHeight: AppSizes.spacing32,
          ),
          onSelected: _performDeviceAction,
          icon: const Icon(Icons.more_vert),
          tooltip: 'More Actions',
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh, size: 20),
                  SizedBox(width: 8),
                  Text('Refresh Data'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download, size: 20),
                  SizedBox(width: 8),
                  Text('Export Data'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings, size: 20),
                  SizedBox(width: 8),
                  Text('Device Settings'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _performDeviceAction(String action) async {
    switch (action) {
      case 'ping':
        await _pingDevice();
        break;
      case 'link_hes':
        await _linkToHES();
        break;
      case 'commission':
        await _commissionDevice();
        break;
      case 'refresh':
        await _refreshCurrentTabData();
        break;
      case 'export':
        _exportDeviceData();
        break;
      case 'settings':
        _showDeviceSettings();
        break;
    }
  }

  Future<void> _pingDevice() async {
    AppToast.showInfo(
      context,
      title: 'Device Ping',
      message: 'Pinging device...',
    );

    try {
      final response = await _deviceService.pingDevice(widget.device.id ?? '');

      if (response.success && mounted) {
        AppToast.showSuccess(
          context,
          title: 'Ping Success',
          message: 'Device ping successful - Device is online',
        );
      } else if (mounted) {
        AppToast.showError(
          context,
          title: 'Ping Failed',
          error: 'Ping failed: ${response.message}',
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(
          context,
          title: 'Error',
          error: 'Error pinging device: $e',
        );
      }
    }
  }

  Future<void> _linkToHES() async {
    try {
      final response = await _deviceService.linkDeviceToHES(
        widget.device.id ?? '',
      );

      if (response.success && mounted) {
        AppToast.showSuccess(
          context,
          title: 'Link Success',
          message: 'Device linked to HES successfully',
        );
        // Refresh device data
        await _refreshCurrentTabData();
      } else if (mounted) {
        AppToast.showError(
          context,
          title: 'Link Failed',
          error: 'Failed to link device: ${response.message}',
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(
          context,
          title: 'Error',
          error: 'Error linking device: $e',
        );
      }
    }
  }

  Future<void> _commissionDevice() async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Commission Device',
      message:
          'Are you sure you want to commission device ${widget.device.serialNumber}?\n\nThis action will make the device active and ready for operation.',
      confirmText: 'Commission',
      confirmColor: AppColors.warning,
    );

    if (confirmed == true) {
      try {
        final response = await _deviceService.commissionDevice(
          widget.device.id ?? '',
        );

        if (response.success && mounted) {
          AppToast.showSuccess(
            context,
            title: 'Commission Success',
            message: 'Device commissioned successfully',
          );
          // Refresh device data
          await _refreshCurrentTabData();
        } else if (mounted) {
          AppToast.showError(
            context,
            title: 'Commission Failed',
            error: 'Failed to commission device: ${response.message}',
          );
        }
      } catch (e) {
        if (mounted) {
          AppToast.showError(
            context,
            title: 'Error',
            error: 'Error commerrorissioning device: $e',
          );
        }
      }
    }
  }

  void _exportDeviceData() {
    AppToast.showInfo(
      context,
      title: 'Export',
      message: 'Exporting device data...',
    );
  }

  void _showDeviceSettings() {
    AppToast.showInfo(
      context,
      title: 'Settings',
      message: 'Device settings will be available soon',
    );
  }

  Widget _buildOverviewTab() {
    if (_loadingOverview && !_overviewLoaded) {
      return const Center(
        child: AppLottieStateWidget.loading(
          title: 'Loading Overview',
          message: 'Loading device overview...',
          lottieSize: 80,
          titleColor: AppColors.primary,
          messageColor: AppColors.secondary,
        ),
      );
    }

    return _isEditingOverview
        ? _buildOverviewEditMode()
        : _buildOverviewViewMode();
  }

  Widget _buildOverviewViewMode() {
    if (kDebugMode) {
      print(
        'Building overview view mode for device: ${widget.device.deviceGroupData}',
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Edit button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Device Overview',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeLarge,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1e293b),
                ),
              ),
              AppButton(
                text: 'Edit Device',
                type: AppButtonType.outline,
                size: AppButtonSize.small,
                onPressed: _startEditingOverview,
                icon: const Icon(Icons.edit, size: AppSizes.iconSmall),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing16),

          // General Information Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: AppSizes.iconSmall,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'General Information',
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeMedium,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1e293b),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.spacing16),
                _buildInfoRow(
                  'Serial Number',
                  widget.device.serialNumber,
                  icon: Icons.qr_code,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Device Type',
                  widget.device.deviceType.isEmpty
                      ? 'Not specified'
                      : widget.device.deviceType,
                  icon: Icons.category,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Model',
                  widget.device.model.isEmpty
                      ? 'Not specified'
                      : widget.device.model,
                  icon: Icons.memory,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Manufacturer',
                  widget.device.manufacturer.isEmpty
                      ? 'Not specified'
                      : widget.device.manufacturer,
                  icon: Icons.business,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Device Group',
                  widget.device.deviceGroupData?['Name']?.toString() ?? 'None',
                  // widget.device.deviceGroupId.toString() == '0'
                  //     ? 'None'
                  //     : _getDeviceGroupName(),
                  icon: Icons.group_work,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.spacing16),

          // Integration Information Card
          // AppCard(
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       Row(
          //         children: [
          //           Icon(
          //             Icons.integration_instructions,
          //             size: 20,
          //             color: AppColors.primary,
          //           ),
          //           const SizedBox(width: 8),
          //           const Text(
          //             'Integration Information',
          //             style: TextStyle(
          //               fontSize: 18,
          //               fontWeight: FontWeight.w600,
          //               color: Color(0xFF1e293b),
          //             ),
          //           ),
          //         ],
          //       ),
          //       const SizedBox(height: 20),
          //       Row(
          //         children: [
          //           Expanded(
          //             child: Column(
          //               crossAxisAlignment: CrossAxisAlignment.start,
          //               children: [
          //                 _buildInfoRow(
          //                   'Status',
          //                   widget.device.status,
          //                   icon: Icons.power_settings_new,
          //                   showStatusChip: true,
          //                 ),
          //               ],
          //             ),
          //           ),
          //           const SizedBox(width: 24),
          //           Expanded(
          //             child: Column(
          //               crossAxisAlignment: CrossAxisAlignment.start,
          //               children: [
          //                 _buildInfoRow(
          //                   'Link Status',
          //                   widget.device.linkStatus,
          //                   icon: Icons.link,
          //                   showStatusChip: true,
          //                 ),
          //               ],
          //             ),
          //           ),
          //         ],
          //       ),
          //     ],
          //   ),
          // ),
          // const SizedBox(height: 24),

          // Location Information Card
          if (widget.device.address != null ||
              widget.device.addressText.isNotEmpty)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: AppSizes.iconSmall,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Location Information',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeMedium,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1e293b),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.spacing16),
                  if (widget.device.addressText.isNotEmpty)
                    _buildInfoRow(
                      'Address',
                      widget.device.addressText,
                      icon: Icons.home,
                    ),
                  if (widget.device.address != null) ...[
                    if (widget.device.addressText.isNotEmpty)
                      const SizedBox(height: 12),
                    _buildInfoRow(
                      'Street',
                      widget.device.address!.street ?? 'Not specified',
                      icon: Icons.place,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoRow(
                            'City',
                            widget.device.address!.city ?? 'Not specified',
                            icon: Icons.location_city,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoRow(
                            'State',
                            widget.device.address!.state ?? 'Not specified',
                            icon: Icons.map,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoRow(
                            'Postal Code',
                            widget.device.address!.postalCode ??
                                'Not specified',
                            icon: Icons.local_post_office,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoRow(
                            'Country',
                            widget.device.address!.country ?? 'Not specified',
                            icon: Icons.flag,
                          ),
                        ),
                      ],
                    ),
                    if (widget.device.address!.latitude != null &&
                        widget.device.address!.longitude != null) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Coordinates',
                        '${widget.device.address!.latitude?.toStringAsFixed(6)}, ${widget.device.address!.longitude?.toStringAsFixed(6)}',
                        icon: Icons.gps_fixed,
                      ),
                    ],
                  ],
                ],
              ),
            ),

          // Device Attributes Card
          if (_deviceDetails?.deviceAttributes != null &&
              _deviceDetails!.deviceAttributes.isNotEmpty) ...[
            const SizedBox(height: AppSizes.spacing16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.settings_outlined,
                        size: AppSizes.iconSmall,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Device Attributes',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeMedium,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1e293b),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.spacing16),
                  ..._deviceDetails!.deviceAttributes.asMap().entries.map((
                    entry,
                  ) {
                    final index = entry.key;
                    final attribute = entry.value;
                    return Column(
                      children: [
                        Container(
                          height: AppSizes.inputHeight,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusMedium,
                            ),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.label,
                                size: AppSizes.iconMedium,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  attribute.name
                                      .replaceAll('_', ' ')
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF475569),
                                    fontSize: AppSizes.fontSizeSmall,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  attribute.value,

                                  style: const TextStyle(
                                    color: Color(0xFF64748b),
                                    fontSize: AppSizes.fontSizeSmall,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (index < _deviceDetails!.deviceAttributes.length - 1)
                          const SizedBox(height: 8),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOverviewEditMode() {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 50),
        child: Form(
          key: _overviewFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Edit Device Information',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeLarge,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1e293b),
                ),
              ),
              const SizedBox(height: AppSizes.spacing16),

              // General Information Card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'General Information',
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeMedium,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1e293b),
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacing16),
                    Row(
                      children: [
                        Expanded(
                          child: AppInputField(
                            controller: _serialNumberEditController,

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
                        const SizedBox(width: AppSizes.spacing16),
                        Expanded(
                          child: AppInputField(
                            controller: _modelEditController,
                            label: 'Model',
                            hintText: 'Enter device model (optional)',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.spacing16),
                    Row(
                      //  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: _buildDeviceTypeEditDropdown()),
                        const SizedBox(width: AppSizes.spacing16),
                        Expanded(child: _buildDeviceGroupEditDropdown()),
                        const SizedBox(width: AppSizes.spacing16),
                        Expanded(child: _buildScheduleEditDropdown()),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.spacing16),

              // Integration Information Card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Integration Information',
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeMedium,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1e293b),
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacing16),
                    Row(
                      children: [
                        Expanded(child: _buildStatusEditDropdown()),
                        const SizedBox(width: AppSizes.spacing16),
                        Expanded(child: _buildLinkStatusEditDropdown()),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.spacing16),

              // Location Information Card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Location Information',
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeMedium,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1e293b),
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacing16),

                    // Address input with map icon
                    AppInputField(
                      controller: _addressEditController,
                      label: 'Address',
                      hintText:
                          'Enter device address or click map icon to select',
                      maxLines: 1,
                      readOnly: true,
                      onTap: _openMapDialog,
                      suffixIcon: IconButton(
                        onPressed: _openMapDialog,
                        icon: const Icon(Icons.map, color: Color(0xFF2563eb)),
                        tooltip: 'Open Map Selector',
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacing16),

                    // Location coordinates display
                    if (_selectedAddressEdit?.latitude != null &&
                        _selectedAddressEdit?.longitude != null)
                      Container(
                        height: AppSizes.inputHeight,
                        padding: const EdgeInsets.all(AppSizes.spacing8),
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
                              size: AppSizes.iconMedium,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Coordinates: ${_selectedAddressEdit!.latitude!.toStringAsFixed(6)}, ${_selectedAddressEdit!.longitude!.toStringAsFixed(6)}',
                              style: const TextStyle(
                                fontSize: AppSizes.fontSizeSmall,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Device Attributes Card (if exists)
              if (_deviceDetails?.deviceAttributes != null &&
                  _deviceDetails!.deviceAttributes.isNotEmpty) ...[
                const SizedBox(height: 24),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Device Attributes',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeMedium,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1e293b),
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacing16),
                      const Text(
                        'Note: Device attributes are managed through the system configuration.',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeMedium,
                          color: Color(0xFF64748b),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacing12),
                      ..._deviceDetails!.deviceAttributes.map(
                        (attribute) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(AppSizes.spacing8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusMedium,
                            ),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  attribute.name
                                      .replaceAll('_', ' ')
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: AppSizes.fontSizeSmall,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSizes.spacing16),
                              Expanded(
                                child: Text(
                                  attribute.value,
                                  style: const TextStyle(
                                    fontSize: AppSizes.fontSizeSmall,
                                    color: Color(0xFF64748b),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE1E5E9), width: 1)),
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            // crossAxisAlignment: CrossAxisAlignment.,
            mainAxisAlignment: MainAxisAlignment.end,

            children: [
              SizedBox(
                width: 100,
                child: AppButton(
                  size: AppButtonSize.small,
                  text: 'Cancel',
                  type: AppButtonType.outline,
                  onPressed: _cancelEditingOverview,
                  fullWidth: true,
                ),
              ),
              const SizedBox(width: AppSizes.spacing16),
              SizedBox(
                width: 100,
                child: AppButton(
                  size: AppButtonSize.small,
                  text: _savingOverview ? 'Saving...' : 'Save',
                  type: AppButtonType.primary,
                  onPressed: _savingOverview ? null : _saveOverviewChanges,
                  icon: _savingOverview
                      ? null
                      : const Icon(Icons.save, size: AppSizes.iconMedium),
                  fullWidth: true,
                  isLoading: _savingOverview,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _buildOverviewEditMode() {
  //   return Scaffold(
  //     body: SingleChildScrollView(
  //       padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
  //       child: Form(
  //         key: _overviewFormKey,
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             // Header
  //             const Text(
  //               'Edit Device Information',
  //               style: TextStyle(
  //                 fontSize: 20,
  //                 fontWeight: FontWeight.w600,
  //                 color: Color(0xFF1e293b),
  //               ),
  //             ),
  //             const SizedBox(height: 24),

  //             // General Information Card
  //             AppCard(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   const Text(
  //                     'General Information',
  //                     style: TextStyle(
  //                       fontSize: 18,
  //                       fontWeight: FontWeight.w600,
  //                       color: Color(0xFF1e293b),
  //                     ),
  //                   ),

  //                   const SizedBox(height: 24),
  //                   AppInputField(
  //                     controller: _serialNumberEditController,
  //                     label: 'Serial Number *',
  //                     hintText: 'Enter device serial number',
  //                     validator: (value) {
  //                       if (value == null || value.trim().isEmpty) {
  //                         return 'Serial number is required';
  //                       }
  //                       return null;
  //                     },
  //                   ),

  //                   const SizedBox(height: 16),
  //                   AppInputField(
  //                     controller: _modelEditController,
  //                     label: 'Model',
  //                     hintText: 'Enter device model (optional)',
  //                   ),

  //                   _buildEditDropdownField(
  //                     label: 'Device Type',
  //                     value: _selectedDeviceTypeEdit,
  //                     items: _deviceTypes,
  //                     onChanged: (value) {
  //                       if (value != null) {
  //                         setState(() {
  //                           _selectedDeviceTypeEdit = value;
  //                         });
  //                       }
  //                     },
  //                   ),
  //                   const SizedBox(height: 16),

  //                   _buildDeviceGroupEditDropdown(),
  //                 ],
  //               ),
  //             ),
  //             const SizedBox(height: 24),

  //             // Integration Information Card
  //             AppCard(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   const Text(
  //                     'Integration Information',
  //                     style: TextStyle(
  //                       fontSize: 18,
  //                       fontWeight: FontWeight.w600,
  //                       color: Color(0xFF1e293b),
  //                     ),
  //                   ),
  //                   const SizedBox(height: 24),

  //                   Row(
  //                     children: [
  //                       Expanded(
  //                         child: _buildEditDropdownField(
  //                           label: 'Status',
  //                           value: _selectedStatusEdit,
  //                           items: _statusOptions,
  //                           onChanged: (value) {
  //                             if (value != null) {
  //                               setState(() {
  //                                 _selectedStatusEdit = value;
  //                               });
  //                             }
  //                           },
  //                         ),
  //                       ),
  //                       const SizedBox(width: 16),
  //                       Expanded(
  //                         child: _buildEditDropdownField(
  //                           label: 'Link Status',
  //                           value: _selectedLinkStatusEdit,
  //                           items: _linkStatusOptions,
  //                           onChanged: (value) {
  //                             if (value != null) {
  //                               setState(() {
  //                                 _selectedLinkStatusEdit = value;
  //                               });
  //                             }
  //                           },
  //                           helpText: _selectedLinkStatusEdit != 'None'
  //                               ? 'Device will be linked to HES when saved'
  //                               : null,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             const SizedBox(height: 24),

  //             // Location Information Card
  //             AppCard(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   const Text(
  //                     'Location Information',
  //                     style: TextStyle(
  //                       fontSize: 18,
  //                       fontWeight: FontWeight.w600,
  //                       color: Color(0xFF1e293b),
  //                     ),
  //                   ),
  //                   const SizedBox(height: 24),

  //                   AppInputField(
  //                     controller: _addressEditController,
  //                     label: 'Address',
  //                     hintText: 'Enter device address',
  //                     maxLines: 2,
  //                   ),
  //                   const SizedBox(height: 16),

  //                   // Map Location Picker
  //                   Container(
  //                     height: 300,
  //                     decoration: BoxDecoration(
  //                       borderRadius: BorderRadius.circular(8),
  //                       border: Border.all(color: const Color(0xFFE2E8F0)),
  //                     ),
  //                     child: FlutterMapLocationPicker(
  //                       initialAddress: _selectedAddressEdit,
  //                       onLocationChanged: (lat, lng, address) {
  //                         // Use post-frame callback to avoid setState during build
  //                         WidgetsBinding.instance.addPostFrameCallback((_) {
  //                           if (mounted) {
  //                             setState(() {
  //                               _selectedAddressEdit = Address(
  //                                 id: _selectedAddressEdit?.id ?? '',
  //                                 street: address,
  //                                 city: '',
  //                                 state: '',
  //                                 postalCode: '',
  //                                 country: '',
  //                                 latitude: lat,
  //                                 longitude: lng,
  //                               );
  //                             });
  //                           }
  //                         });
  //                       },
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),

  //             // Device Attributes Card (if exists)
  //             if (_deviceDetails?.deviceAttributes != null &&
  //                 _deviceDetails!.deviceAttributes.isNotEmpty) ...[
  //               const SizedBox(height: 24),
  //               AppCard(
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     const Text(
  //                       'Device Attributes',
  //                       style: TextStyle(
  //                         fontSize: 18,
  //                         fontWeight: FontWeight.w600,
  //                         color: Color(0xFF1e293b),
  //                       ),
  //                     ),
  //                     const SizedBox(height: 16),
  //                     const Text(
  //                       'Note: Device attributes are managed through the system configuration.',
  //                       style: TextStyle(
  //                         fontSize: 14,
  //                         color: Color(0xFF64748b),
  //                         fontStyle: FontStyle.italic,
  //                       ),
  //                     ),
  //                     const SizedBox(height: 12),
  //                     ..._deviceDetails!.deviceAttributes.map(
  //                       (attribute) => Container(
  //                         margin: const EdgeInsets.only(bottom: 8),
  //                         padding: const EdgeInsets.all(12),
  //                         decoration: BoxDecoration(
  //                           color: const Color(0xFFF8FAFC),
  //                           borderRadius: BorderRadius.circular(8),
  //                           border: Border.all(color: const Color(0xFFE2E8F0)),
  //                         ),
  //                         child: Row(
  //                           children: [
  //                             Expanded(
  //                               child: Text(
  //                                 attribute.name
  //                                     .replaceAll('_', ' ')
  //                                     .toUpperCase(),
  //                                 style: const TextStyle(
  //                                   fontWeight: FontWeight.w500,
  //                                   color: Color(0xFF475569),
  //                                 ),
  //                               ),
  //                             ),
  //                             const SizedBox(width: 16),
  //                             Expanded(
  //                               child: Text(
  //                                 attribute.value,
  //                                 style: const TextStyle(
  //                                   color: Color(0xFF64748b),
  //                                 ),
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ],
  //           ],
  //         ),
  //       ),
  //     ),
  //     bottomNavigationBar: Container(
  //       padding: const EdgeInsets.all(24),
  //       decoration: const BoxDecoration(
  //         color: Colors.white,
  //         border: Border(top: BorderSide(color: Color(0xFFE1E5E9), width: 1)),
  //         boxShadow: [
  //           BoxShadow(
  //             color: Color(0x1A000000),
  //             blurRadius: 8,
  //             offset: Offset(0, -2),
  //           ),
  //         ],
  //       ),
  //       child: SafeArea(
  //         child: Row(
  //           children: [
  //             Expanded(
  //               child: AppButton(
  //                 text: 'Cancel',
  //                 type: AppButtonType.secondary,
  //                 onPressed: _cancelEditingOverview,
  //                 fullWidth: true,
  //               ),
  //             ),
  //             const SizedBox(width: 16),
  //             Expanded(
  //               child: AppButton(
  //                 text: _savingOverview ? 'Saving...' : 'Save Changes',
  //                 type: AppButtonType.primary,
  //                 onPressed: _savingOverview ? null : _saveOverviewChanges,
  //                 icon: _savingOverview
  //                     ? null
  //                     : const Icon(Icons.save, size: 18),
  //                 fullWidth: true,
  //                 isLoading: _savingOverview,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildChannelsTab() {
    if (_loadingChannels && !_channelsLoaded) {
      return Center(
        child: AppLottieStateWidget.loading(
          title: 'Loading Channels',
          message: 'Loading device channels...',
          lottieSize: 80,
          titleColor: AppColors.primary,
          messageColor: AppColors.secondary,
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Device Channels',
            style: TextStyle(
              fontSize: AppSizes.fontSizeLarge,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1e293b),
            ),
          ),
          // const SizedBox(height: AppSizes.spacing16),
          if (_deviceChannels == null || _deviceChannels!.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 100.0),
              child: AppLottieStateWidget.noData(
                //  title: 'No Channels Found',
                // message: 'This device has no channels associated with it.',
                //   lottieSize: 100,
                titleColor: AppColors.primary,
                messageColor: AppColors.secondary,
              ),
            )
          else
            ..._deviceChannels!.map(
              (channel) => Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.spacing16),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        channel.channel?.name ?? 'Channel ${channel.channelId}',
                        style: const TextStyle(
                          fontSize: AppSizes.fontSizeSmall,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1e293b),
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacing8),
                      _buildInfoRow('Channel ID', channel.channelId.toString()),
                      _buildInfoRow('Code', channel.channel?.code ?? 'N/A'),
                      _buildInfoRow('Units', channel.channel?.units ?? 'N/A'),
                      _buildInfoRow(
                        'Cumulative',
                        channel.cumulative.toString(),
                      ),
                      _buildInfoRow('Active', channel.active ? 'Yes' : 'No'),
                      if (channel.channel != null) ...[
                        _buildInfoRow(
                          'Flow Direction',
                          channel.channel!.flowDirection,
                        ),
                        _buildInfoRow('Phase', channel.channel!.phase),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricsTab() {
    if (_loadingMetrics && !_metricsLoaded) {
      return const Center(
        child: AppLottieStateWidget.loading(
          title: 'Loading Metrics',
          message: 'Loading device metrics...',
          lottieSize: 80,
          titleColor: AppColors.primary,
          messageColor: AppColors.secondary,
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with filters and view toggle
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    //const SizedBox(width: 16),
                    // Date filters
                    _buildDateFilter(),
                  ],
                ),
              ),
              // View toggle
              Container(
                height: AppSizes.buttonHeightSmall,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  color: const Color(0xFFF1F5F9),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildViewToggleButton(
                      icon: Icons.table_chart,
                      label: 'Table',
                      isActive: _isTableView,
                      onTap: () {
                        print('Switching to TABLE view');
                        setState(() => _isTableView = true);
                      },
                    ),
                    _buildViewToggleButton(
                      icon: Icons.bar_chart,
                      label: 'Graph',
                      isActive: !_isTableView,
                      onTap: () {
                        print('Switching to GRAPH view');
                        setState(() => _isTableView = false);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_deviceMetrics != null &&
              _deviceMetrics!['DeviceMetrics'] != null) ...[
            if (_isTableView)
              _buildMetricsTableWithPagination()
            else
              _buildMetricsGraph(),
          ] else
            AppLottieStateWidget.noData(
              title: 'No Metrics Data',
              message: 'No metrics data available',
            ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildDateFilter() {
    return Row(
      children: [
        CustomDateRangePicker(
          initialStartDate: _metricsStartDate,
          initialEndDate: _metricsEndDate,
          onDateRangeSelected: (startDate, endDate) {
            setState(() {
              _metricsStartDate = startDate;
              _metricsEndDate = endDate;
              _metricsCurrentPage = 1;
            });
            _refreshMetricsData();
          },
          hintText: 'Select date range',
          enabled: true,
        ),
        const SizedBox(width: 12),
        // Refresh button
        Container(
          // height: AppSizes.inputHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF2563eb),
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          ),
          child: IconButton(
            onPressed: _refreshMetricsData,
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
              size: AppSizes.iconSmall,
            ),
            tooltip: 'Refresh Data',
            padding: const EdgeInsets.all(AppSizes.spacing8),
            constraints: const BoxConstraints(
              minWidth: AppSizes.spacing32,
              minHeight: AppSizes.spacing32,
            ),
            //  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ),
      ],
    );
  }

  Widget _buildViewToggleButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        print(
          'Toggle button tapped: $label, isActive: $isActive, switching to: ${!isActive}',
        );
        onTap();
      },
      //  borderRadius: BorderRadius.circular(6),
      child: Container(
        // height: AppSizes.buttonHeightSmall,
        // padding: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(AppSizes.spacing8),
        constraints: const BoxConstraints(
          minWidth: AppSizes.spacing32,
          minHeight: AppSizes.spacing32,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          color: isActive ? const Color(0xFF2563eb) : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AppSizes.iconSmall,
              color: isActive ? Colors.white : const Color(0xFF64748b),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.white : const Color(0xFF64748b),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGraph() {
    final deviceMetrics = _deviceMetrics!['DeviceMetrics'];
    final metrics = deviceMetrics['Metrics'] as List? ?? [];

    print('Building metrics graph with ${metrics.length} metrics');
    print(
      'Sample metric data: ${metrics.isNotEmpty ? metrics.first : "No data"}',
    );

    if (metrics.isEmpty) {
      return AppLottieStateWidget.noData(
        title: 'No Metrics Data',
        message: 'No metrics data available for graphing',
        lottieSize: 200,
        titleColor: AppColors.primary,
        messageColor: AppColors.secondary,
      );
      // const AppCard(
      //   child:

      //   Center(
      //     child: Column(
      //       mainAxisAlignment: MainAxisAlignment.center,
      //       children: [

      //         Icon(
      //           Icons.bar_chart,
      //           size: AppSizes.iconSmall,
      //           color: Color(0xFF64748b),
      //         ),
      //         // SizedBox(height: 16),
      //         Text(
      //           'No metrics data available for graphing',
      //           style: TextStyle(
      //             fontSize: AppSizes.fontSizeSmall,
      //             color: Color(0xFF64748b),
      //           ),
      //         ),
      //         SizedBox(height: 8),
      //         Text(
      //           'Try adjusting the date range or refresh the data',
      //           style: TextStyle(
      //             fontSize: AppSizes.fontSizeSmall,
      //             color: Color(0xFF64748b),
      //           ),
      //         ),
      //       ],
      //     ),
      //   ),
      // );
    }

    // Take only first 20 metrics for better visualization
    final limitedMetrics = metrics.take(20).toList();
    print('Limited metrics for graph: ${limitedMetrics.length}');

    // Process metrics data for the graph
    final chartSpots = <FlSpot>[];
    double minValue = double.infinity;
    double maxValue = double.negativeInfinity;

    for (int i = 0; i < limitedMetrics.length; i++) {
      final metric = limitedMetrics[i];
      final value = (metric['Value'] ?? 0).toDouble();

      if (value.isFinite) {
        chartSpots.add(FlSpot(i.toDouble(), value));
        if (value < minValue) minValue = value;
        if (value > maxValue) maxValue = value;
      }
    }

    print('Chart spots: ${chartSpots.length}, min: $minValue, max: $maxValue');

    if (chartSpots.isEmpty) {
      return const AppCard(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Color(0xFFf59e0b)),
              SizedBox(height: 16),
              Text(
                'Invalid data for graphing',
                style: TextStyle(fontSize: 16, color: Color(0xFFf59e0b)),
              ),
              SizedBox(height: 8),
              Text(
                'Metrics contain no valid numeric values',
                style: TextStyle(fontSize: 14, color: Color(0xFF64748b)),
              ),
            ],
          ),
        ),
      );
    }

    // Ensure we have reasonable bounds
    if (minValue == maxValue) {
      minValue = maxValue - 1;
      maxValue = maxValue + 1;
    }

    final yPadding = (maxValue - minValue) * 0.1;
    final chartMinY = (minValue - yPadding).clamp(0, double.infinity);
    final chartMaxY = maxValue + yPadding;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Metrics Visualization',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1e293b),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563eb).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Showing ${limitedMetrics.length} of ${metrics.length} records',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2563eb),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Debug information
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF10b981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF10b981)),
            ),
            child: Text(
              'Graph Debug: ${chartSpots.length} points, Y-range: ${chartMinY.toStringAsFixed(1)} to ${chartMaxY.toStringAsFixed(1)}',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF10b981),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Line Chart using fl_chart
          SizedBox(
            height: 400,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  drawHorizontalLine: true,
                  horizontalInterval: (chartMaxY - chartMinY) / 5,
                  verticalInterval: limitedMetrics.length > 10 ? 2 : 1,
                  getDrawingHorizontalLine: (value) {
                    return const FlLine(
                      color: Color(0xFFE1E5E9),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return const FlLine(
                      color: Color(0xFFE1E5E9),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: limitedMetrics.length > 10 ? 2 : 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < limitedMetrics.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Color(0xFF64748b),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (chartMaxY - chartMinY) / 5,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          value.toStringAsFixed(0),
                          style: const TextStyle(
                            color: Color(0xFF64748b),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      },
                      reservedSize: 42,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: const Color(0xFFE1E5E9)),
                ),
                minX: 0,
                maxX: (limitedMetrics.length - 1).toDouble(),
                minY: chartMinY.toDouble(),
                maxY: chartMaxY.toDouble(),
                lineBarsData: [
                  LineChartBarData(
                    spots: chartSpots,
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563eb), Color(0xFF3b82f6)],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: const Color(0xFF2563eb),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF2563eb).withOpacity(0.3),
                          const Color(0xFF2563eb).withOpacity(0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Latest ${limitedMetrics.length} readings visualization',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748b)),
              ),
              Text(
                'Range: ${chartMinY.toStringAsFixed(1)} - ${chartMaxY.toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748b)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsTableWithPagination() {
    final deviceMetrics = _deviceMetrics!['DeviceMetrics'];
    final allMetrics = deviceMetrics['Metrics'] as List? ?? [];

    if (allMetrics.isEmpty) {
      return AppLottieStateWidget.noData(
        title: 'No Metrics Data',
        message: 'No metrics data available for this device.',
        // lottieSize: 100,
        titleColor: AppColors.primary,
        messageColor: AppColors.secondary,
      );
      //  AppCard(
      //   child: Center(
      //     child: Text(
      //       'No metrics data available',
      //       style: TextStyle(fontSize: 16, color: Color(0xFF64748b)),
      //     ),
      //   ),
      // );
    }

    // Calculate pagination
    final totalItems = allMetrics.length;
    final totalPages = (totalItems / _metricsItemsPerPage).ceil();

    // Apply sorting first, then pagination
    final sortedMetrics = _sortMetrics(allMetrics.cast<Map<String, dynamic>>());
    final startIndex = (_metricsCurrentPage - 1) * _metricsItemsPerPage;
    final endIndex = (startIndex + _metricsItemsPerPage).clamp(0, totalItems);
    final paginatedMetrics = sortedMetrics.sublist(startIndex, endIndex);

    return Column(
      children: [
        // Summary row
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildMetricSummaryItem(
                  'Total Records',
                  totalItems.toString(),
                  Icons.dataset,
                ),
              ),
              Expanded(
                child: _buildMetricSummaryItem(
                  'Latest Value',
                  allMetrics.isNotEmpty
                      ? '${allMetrics.first['Value']} ${allMetrics.first['Labels']?['Units'] ?? ''}'
                      : 'N/A',
                  Icons.trending_up,
                ),
              ),
              Expanded(
                child: _buildMetricSummaryItem(
                  'Device Status',
                  deviceMetrics['Status'] ?? 'N/A',
                  Icons.device_hub,
                ),
              ),
            ],
          ),
        ),

        // Unified table using BluNestDataTable
        SizedBox(
          height: 500,
          child: BluNestDataTable<Map<String, dynamic>>(
            data: paginatedMetrics,
            columns: MetricsTableColumns.getColumns(
              currentPage: _metricsCurrentPage,
              itemsPerPage: _metricsItemsPerPage,
              metrics: sortedMetrics,
            ),
            sortBy: _metricsSortBy,
            sortAscending: _metricsSortAscending,
            onSort: _handleMetricsSort,
          ),
        ),

        const SizedBox(height: 16),

        // Pagination controls
        _buildMetricsPagination(totalPages, totalItems),
      ],
    );
  }

  Widget _buildMetricsPagination(int totalPages, int totalItems) {
    final startItem = (_metricsCurrentPage - 1) * _metricsItemsPerPage + 1;
    final endItem = (_metricsCurrentPage * _metricsItemsPerPage) > totalItems
        ? totalItems
        : _metricsCurrentPage * _metricsItemsPerPage;

    return ResultsPagination(
      currentPage: _metricsCurrentPage,
      totalPages: totalPages,
      totalItems: totalItems,
      itemsPerPage: _metricsItemsPerPage,
      startItem: startItem,
      endItem: endItem,
      onPageChanged: (page) {
        setState(() {
          _metricsCurrentPage = page;
        });
      },
      onItemsPerPageChanged: (newItemsPerPage) {
        setState(() {
          _metricsItemsPerPage = newItemsPerPage;
          _metricsCurrentPage = 1; // Reset to first page
        });
      },
      itemLabel: 'metrics',
      showItemsPerPageSelector: true,
      itemsPerPageOptions: const [5, 10, 25, 50],
    );
  }

  Widget _buildMetricSummaryItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF2563eb)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748b),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1e293b),
          ),
        ),
      ],
    );
  }

  Widget _buildBillingTab() {
    if (_loadingBilling && !_billingLoaded) {
      return const Center(
        child: AppLottieStateWidget.loading(
          title: 'Loading Billing',
          message: 'Loading device billing information...',
          lottieSize: 80,
          titleColor: AppColors.primary,
          messageColor: AppColors.secondary,
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Device Billing Information',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeLarge,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1e293b),
                ),
              ),
              _buildBillingActions(),
            ],
          ),
          const SizedBox(height: AppSizes.spacing16),

          if (_deviceBilling != null) ...[
            _buildBillingDataTable(),
          ] else
            AppLottieStateWidget.noData(title: 'No Billing Data'),
          //  AppCard(
          //   child: Center(
          //     child: Text(
          //       'No billing data available',
          //       style: TextStyle(
          //         fontSize: AppSizes.fontSizeMedium,
          //         color: Color(0xFF64748b),
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildBillingActions() {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2563eb),
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          ),
          child: IconButton(
            onPressed: _refreshBillingData,
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
              size: AppSizes.iconSmall,
            ),
            tooltip: 'Refresh Data',
            padding: const EdgeInsets.all(AppSizes.spacing8),
            constraints: const BoxConstraints(
              minWidth: AppSizes.spacing32,
              minHeight: AppSizes.spacing32,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBillingDataTable() {
    // Extract billing records from the API response
    List<dynamic> billingRecords = [];

    if (_deviceBilling!['Billing'] != null) {
      billingRecords = _deviceBilling!['Billing'] as List;
    }

    if (billingRecords.isEmpty) {
      return AppLottieStateWidget.noData(
        title: 'No Billing Records',
        message: 'This device has no billing records available.',
        // lottieSize: 100,
        titleColor: AppColors.primary,
        messageColor: AppColors.secondary,
      );
      //  const AppCard(
      //   child: Center(
      //     child: Text(
      //       'No billing records found',
      //       style: TextStyle(
      //         fontSize: AppSizes.fontSizeMedium,
      //         color: Color(0xFF64748b),
      //       ),
      //     ),
      //   ),
      // );
    }

    // Convert to Map<String, dynamic> for compatibility
    final convertedRecords = billingRecords
        .map((record) => record as Map<String, dynamic>)
        .toList();

    // Apply sorting
    if (_billingSortBy != null) {
      convertedRecords.sort((a, b) {
        dynamic aValue = a[_billingSortBy!];
        dynamic bValue = b[_billingSortBy!];

        // Handle DateTime sorting
        if (_billingSortBy == 'StartTime' || _billingSortBy == 'EndTime') {
          aValue =
              DateTime.tryParse(aValue?.toString() ?? '') ?? DateTime.now();
          bValue =
              DateTime.tryParse(bValue?.toString() ?? '') ?? DateTime.now();
        }

        final comparison = aValue.toString().compareTo(bValue.toString());
        return _billingSortAscending ? comparison : -comparison;
      });
    }

    // Calculate pagination
    final totalItems = convertedRecords.length;
    final totalPages = (totalItems / _billingItemsPerPage).ceil();
    final startIndex = (_billingCurrentPage - 1) * _billingItemsPerPage;
    final endIndex = (startIndex + _billingItemsPerPage).clamp(0, totalItems);
    final paginatedRecords = convertedRecords.sublist(startIndex, endIndex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Table using BluNestDataTable
        SizedBox(
          height: 500,
          child: BluNestDataTable<Map<String, dynamic>>(
            data: paginatedRecords,
            columns: BillingTableColumns.getColumns(
              currentPage: _billingCurrentPage,
              itemsPerPage: _billingItemsPerPage,
              billingRecords: convertedRecords,
              onRowTapped: _navigateToBillingReadings,
            ),
            onRowTap: _navigateToBillingReadings, // Enable row click
            sortBy: _billingSortBy,
            sortAscending: _billingSortAscending,
            onSort: _handleBillingSort,
          ),
        ),

        const SizedBox(height: AppSizes.spacing16),

        // Pagination controls
        _buildBillingPagination(totalPages, totalItems),
      ],
    );
  }

  void _handleBillingSort(String key, bool ascending) {
    setState(() {
      _billingSortBy = key;
      _billingSortAscending = ascending;
    });
  }

  void _navigateToBillingReadings(Map<String, dynamic> billingRecord) {
    if (widget.onNavigateToBillingReadings != null) {
      widget.onNavigateToBillingReadings!(widget.device, billingRecord);
    } else {
      // Use Go Router navigation
      AppRouter.goToDeviceBillingReadings(
        context,
        widget.device,
        billingRecord,
      );
    }
  }

  Widget _buildBillingPagination(int totalPages, int totalItems) {
    final startItem = (_billingCurrentPage - 1) * _billingItemsPerPage + 1;
    final endItem = (_billingCurrentPage * _billingItemsPerPage) > totalItems
        ? totalItems
        : _billingCurrentPage * _billingItemsPerPage;

    return ResultsPagination(
      currentPage: _billingCurrentPage,
      totalPages: totalPages,
      totalItems: totalItems,
      itemsPerPage: _billingItemsPerPage,
      startItem: startItem,
      endItem: endItem,
      onPageChanged: (page) {
        setState(() {
          _billingCurrentPage = page;
        });
      },
      onItemsPerPageChanged: (newItemsPerPage) {
        setState(() {
          _billingItemsPerPage = newItemsPerPage;
          _billingCurrentPage = 1; // Reset to first page
        });
      },
      itemLabel: 'billing records',
      showItemsPerPageSelector: true,
    );
  }

  void _refreshBillingData() {
    setState(() {
      _billingLoaded = false;
      _billingCurrentPage = 1;
    });
    _loadBillingData();
  }

  Widget _buildLocationTab() {
    if (_loadingLocation && !_locationLoaded) {
      return const Center(
        child: AppLottieStateWidget.loading(
          title: 'Loading Location',
          message: 'Loading device location...',
          lottieSize: 80,
          titleColor: AppColors.primary,
          messageColor: AppColors.secondary,
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
      child: DeviceLocationViewer(
        address: widget.device.address,
        addressText: widget.device.addressText,
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    IconData? icon,
    bool showStatusChip = false,
    bool showLabel = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null && showLabel) ...[
            Icon(
              icon,
              size: AppSizes.iconMedium,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
          ],
          if (showLabel) ...[
            SizedBox(
              width: icon != null ? 100 : 120,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: AppSizes.fontSizeSmall,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748b),
                ),
              ),
            ),
            const Text(
              ': ',
              style: TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                color: Color(0xFF64748b),
              ),
            ),
          ],
          showStatusChip
              ? _buildStatusDisplay(value)
              : Text(
                  value,
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeSmall,
                    color: Color(0xFF1e293b),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildStatusDisplay(String status) {
    // if (status.isEmpty || status == 'None') {
    //   return Container(
    //     // 'None',
    //     // style: TextStyle(
    //     //   fontSize: 14,
    //     //   color: Color(0xFF9CA3AF),
    //     //   fontStyle: FontStyle.italic,
    //     // ),
    //   );
    // }

    Color statusColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'commissioned':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        break;
      case 'decommissioned':
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
        break;
      case 'multidrive':
      case 'e-power':
        statusColor = AppColors.primary;
        statusIcon = Icons.link;
        break;
      default:
        statusColor = AppColors.warning;
        statusIcon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: AppSizes.iconMedium, color: statusColor),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              fontWeight: FontWeight.w500,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  void _handleMetricsSort(String columnKey, bool ascending) {
    setState(() {
      _metricsSortBy = columnKey;
      _metricsSortAscending = ascending;
    });
  }

  List<Map<String, dynamic>> _sortMetrics(List<Map<String, dynamic>> metrics) {
    if (_metricsSortBy == null) return metrics;

    final sortedMetrics = List<Map<String, dynamic>>.from(metrics);
    sortedMetrics.sort((a, b) {
      dynamic aValue;
      dynamic bValue;

      switch (_metricsSortBy) {
        case 'timestamp':
          aValue = a['Timestamp']?.toString() ?? '';
          bValue = b['Timestamp']?.toString() ?? '';
          break;
        case 'value':
          aValue = a['Value'] ?? 0;
          bValue = b['Value'] ?? 0;
          if (aValue is String) aValue = double.tryParse(aValue) ?? 0;
          if (bValue is String) bValue = double.tryParse(bValue) ?? 0;
          break;
        case 'previous':
          aValue = a['Previous'] ?? a['PreValue'] ?? 0;
          bValue = b['Previous'] ?? b['PreValue'] ?? 0;
          if (aValue is String) aValue = double.tryParse(aValue) ?? 0;
          if (bValue is String) bValue = double.tryParse(bValue) ?? 0;
          break;
        case 'change':
          final aVal = a['Value'] ?? 0;
          final aPrev = a['Previous'] ?? a['PreValue'] ?? 0;
          final bVal = b['Value'] ?? 0;
          final bPrev = b['Previous'] ?? b['PreValue'] ?? 0;

          aValue =
              (aVal is String ? double.tryParse(aVal) ?? 0 : aVal) -
              (aPrev is String ? double.tryParse(aPrev) ?? 0 : aPrev);
          bValue =
              (bVal is String ? double.tryParse(bVal) ?? 0 : bVal) -
              (bPrev is String ? double.tryParse(bPrev) ?? 0 : bPrev);
          break;
        case 'phase':
          aValue =
              a['Labels']?['Phase']?.toString() ?? a['Phase']?.toString() ?? '';
          bValue =
              b['Labels']?['Phase']?.toString() ?? b['Phase']?.toString() ?? '';
          break;
        case 'units':
          aValue =
              a['Labels']?['Units']?.toString() ?? a['Units']?.toString() ?? '';
          bValue = b['Labels']?['Units']?.toString() ?? '';
          break;
        default:
          return 0;
      }

      int comparison;
      if (aValue is num && bValue is num) {
        comparison = aValue.compareTo(bValue);
      } else {
        comparison = aValue.toString().toLowerCase().compareTo(
          bValue.toString().toLowerCase(),
        );
      }

      return _metricsSortAscending ? comparison : -comparison;
    });

    return sortedMetrics;
  }
}
