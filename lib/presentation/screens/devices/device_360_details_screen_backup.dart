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
import '../../../core/models/schedule.dart';
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

  // Enhanced Analytics State
  String _selectedChartType = 'line'; // line, bar, pie, area, scatter
  String? _selectedUnits;
  String? _selectedPhase;
  String? _selectedFlowDirection;
  String? _selectedQuickDate;
  
  // Dynamic filter options extracted from data
  Set<String> _availableUnits = {};
  Set<String> _availablePhases = {};
  Set<String> _availableFlowDirections = {};
  
  // Chart hover state
  int? _hoveredDataIndex;
  Map<String, dynamic>? _hoveredDataPoint;

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
  List<Schedule> _schedules = [];
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
        value: widget.device.deviceGroup?.id ?? 0,
        child: Text(
          widget.device.deviceGroup?.name ?? 'None',
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
              value: schedule.id,
              child: Text(
                schedule.name ?? 'Unnamed Schedule',
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
        'Building overview view mode for device: ${widget.device.deviceGroup?.toJson()}',
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
                  widget.device.deviceGroup?.name ?? 'None',
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
                        setState(() => _isTableView = true);
                      },
                    ),
                    _buildViewToggleButton(
                      icon: Icons.analytics,
                      label: 'Analytics',
                      isActive: !_isTableView,
                      onTap: () {
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
              _buildAdvancedAnalyticsDashboard(),
          ] else
            AppLottieStateWidget.noData(
              title: 'No Metrics Data',
              message: 'No metrics data available',
            ),
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

  Widget _buildAdvancedAnalyticsDashboard() {
    final deviceMetrics = _deviceMetrics!['DeviceMetrics'];
    final metrics = deviceMetrics['Metrics'] as List? ?? [];

    if (metrics.isEmpty) {
      return AppLottieStateWidget.noData(
        title: 'No Analytics Data',
        message: 'No metrics data available for analytics',
        lottieSize: 200,
        titleColor: AppColors.primary,
        messageColor: AppColors.secondary,
      );
    }

    // Extract filter options from data
    _extractFilterOptions(metrics);

    // Apply filters to get filtered metrics
    final filteredMetrics = _getFilteredMetrics(metrics);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Modern Header with Gradient Background
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.1),
                AppColors.primary.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.analytics,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Energy Consumption Analytics',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Real-time device metrics with advanced visualization',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _buildChartTypeSelector(),
                ],
              ),
              const SizedBox(height: 24),
              _buildEnergyConsumptionSummary(filteredMetrics),
            ],
          ),
        ),
        
        const SizedBox(height: 24),

        // Advanced Filters Card with Modern Design
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: _buildValueFiltersCard(),
        ),
        
        const SizedBox(height: 24),

        // Main Chart with Enhanced Design
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: _buildChartsGrid(filteredMetrics),
        ),

        const SizedBox(height: 24),

        // Data Summary Card with Enhanced Design
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: _buildDataSummaryCard(filteredMetrics),
        ),
      ],
    );
  }

  // Energy Consumption Summary Widget
  Widget _buildEnergyConsumptionSummary(List<Map<String, dynamic>> metrics) {
    if (metrics.isEmpty) return const SizedBox.shrink();

    final consumptionData = _calculateEnergyConsumption(metrics);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          _buildConsumptionItem(
            'Total Energy',
            '${(consumptionData['total'] ?? 0.0).toStringAsFixed(2)} kWh',
            Icons.flash_on,
            const Color(0xFF3B82F6),
          ),
          _buildConsumptionItem(
            'Peak Consumption',
            '${(consumptionData['peak'] ?? 0.0).toStringAsFixed(2)} kW',
            Icons.trending_up,
            const Color(0xFF10B981),
          ),
          _buildConsumptionItem(
            'Average Load',
            '${(consumptionData['average'] ?? 0.0).toStringAsFixed(2)} kW',
            Icons.speed,
            const Color(0xFF8B5CF6),
          ),
          _buildConsumptionItem(
            'Efficiency',
            '${(consumptionData['efficiency'] ?? 0.0).toStringAsFixed(1)}%',
            Icons.eco,
            const Color(0xFF06B6D4),
          ),
        ],
      ),
    );
  }

  Widget _buildConsumptionItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Calculate energy consumption metrics
  Map<String, double> _calculateEnergyConsumption(List<Map<String, dynamic>> metrics) {
    if (metrics.isEmpty) {
      return {
        'total': 0.0,
        'peak': 0.0,
        'average': 0.0,
        'efficiency': 0.0,
      };
    }

    final values = metrics.map((m) => (m['Value'] ?? 0).toDouble()).where((v) => v.isFinite).toList();
    
    if (values.isEmpty) {
      return {
        'total': 0.0,
        'peak': 0.0,
        'average': 0.0,
        'efficiency': 0.0,
      };
    }

    final total = values.reduce((a, b) => a + b);
    final peak = values.reduce((a, b) => a > b ? a : b);
    final average = total / values.length;
    final efficiency = peak > 0 ? (average / peak) * 100 : 0.0;

    return {
      'total': total / 1000, // Convert to kWh
      'peak': peak,
      'average': average,
      'efficiency': efficiency,
    };
  }

  // Extract available filter options from metrics data
  void _extractFilterOptions(List metrics) {
    _availableUnits.clear();
    _availablePhases.clear();
    _availableFlowDirections.clear();

    for (final metric in metrics) {
      final labels = metric['Labels'] as Map<String, dynamic>? ?? {};
      
      // Extract units
      final units = labels['Units']?.toString() ?? metric['Units']?.toString();
      if (units != null && units.isNotEmpty) {
        _availableUnits.add(units);
      }

      // Extract phases
      final phase = labels['Phase']?.toString() ?? metric['Phase']?.toString();
      if (phase != null && phase.isNotEmpty) {
        _availablePhases.add(phase);
      }

      // Extract flow directions
      final flowDirection = labels['FlowDirection']?.toString() ?? 
                          metric['FlowDirection']?.toString();
      if (flowDirection != null && flowDirection.isNotEmpty) {
        _availableFlowDirections.add(flowDirection);
      }
    }
  }

  // Apply active filters to metrics data
  List<Map<String, dynamic>> _getFilteredMetrics(List metrics) {
    List<Map<String, dynamic>> filteredMetrics = metrics.cast<Map<String, dynamic>>();

    // Apply Units filter
    if (_selectedUnits != null && _selectedUnits != 'None') {
      filteredMetrics = filteredMetrics.where((metric) {
        final labels = metric['Labels'] as Map<String, dynamic>? ?? {};
        final units = labels['Units']?.toString() ?? metric['Units']?.toString();
        return units == _selectedUnits;
      }).toList();
    }

    // Apply Phase filter
    if (_selectedPhase != null && _selectedPhase != 'None') {
      filteredMetrics = filteredMetrics.where((metric) {
        final labels = metric['Labels'] as Map<String, dynamic>? ?? {};
        final phase = labels['Phase']?.toString() ?? metric['Phase']?.toString();
        return phase == _selectedPhase;
      }).toList();
    }

    // Apply FlowDirection filter
    if (_selectedFlowDirection != null && _selectedFlowDirection != 'None') {
      filteredMetrics = filteredMetrics.where((metric) {
        final labels = metric['Labels'] as Map<String, dynamic>? ?? {};
        final flowDirection = labels['FlowDirection']?.toString() ?? 
                             metric['FlowDirection']?.toString();
        return flowDirection == _selectedFlowDirection;
      }).toList();
    }

    return filteredMetrics;
  }

  Widget _buildValueFiltersCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.filter_list,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Advanced Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _clearMetricsFilters,
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Clear Filters'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Filter dropdowns in a row
          Row(
            children: [
              // Units filter
              Expanded(
                child: _buildFilterDropdown(
                  label: 'Units',
                  value: _selectedUnits,
                  items: ['None', ..._availableUnits.toList()],
                  onChanged: (value) {
                    setState(() {
                      _selectedUnits = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              
              // Phase filter
              Expanded(
                child: _buildFilterDropdown(
                  label: 'Phase',
                  value: _selectedPhase,
                  items: ['None', ..._availablePhases.toList()],
                  onChanged: (value) {
                    setState(() {
                      _selectedPhase = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              
              // FlowDirection filter
              Expanded(
                child: _buildFilterDropdown(
                  label: 'Flow Direction',
                  value: _selectedFlowDirection,
                  items: ['None', ..._availableFlowDirections.toList()],
                  onChanged: (value) {
                    setState(() {
                      _selectedFlowDirection = value;
                    });
                  },
                ),
              ),
            ],
          ),
          
          // Quick date selection
          const SizedBox(height: 16),
          _buildQuickDateSelection(),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: InputBorder.none,
            ),
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            hint: Text(
              'Select $label',
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickDateSelection() {
    final quickDateOptions = [
      {'label': 'Today', 'value': 'today'},
      {'label': 'This Week', 'value': 'this_week'},
      {'label': 'Last Week', 'value': 'last_week'},
      {'label': 'This Month', 'value': 'this_month'},
      {'label': 'Last Month', 'value': 'last_month'},
      {'label': 'This Year', 'value': 'this_year'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Date Selection',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: quickDateOptions.map((option) {
            final isSelected = _selectedQuickDate == option['value'];
            return GestureDetector(
              onTap: () => _applyQuickDateSelection(option['value']!),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
                child: Text(
                  option['label']!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _applyQuickDateSelection(String dateOption) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;

    switch (dateOption) {
      case 'today':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'this_week':
        final weekday = now.weekday;
        startDate = now.subtract(Duration(days: weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case 'last_week':
        final weekday = now.weekday;
        endDate = now.subtract(Duration(days: weekday));
        endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
        startDate = endDate.subtract(const Duration(days: 6));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case 'this_month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'last_month':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        startDate = lastMonth;
        endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
        break;
      case 'this_year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        return;
    }

    setState(() {
      _selectedQuickDate = dateOption;
      _metricsStartDate = startDate;
      _metricsEndDate = endDate;
      _metricsCurrentPage = 1;
    });
    
    _refreshMetricsData();
  }

  void _clearMetricsFilters() {
    setState(() {
      _selectedUnits = null;
      _selectedPhase = null;
      _selectedFlowDirection = null;
      _selectedQuickDate = null;
    });
  }

  Widget _buildChartTypeSelector() {
    final chartTypes = [
      {'icon': Icons.show_chart, 'type': 'line', 'label': 'Line', 'color': const Color(0xFF3B82F6)},
      {'icon': Icons.bar_chart, 'type': 'bar', 'label': 'Bar', 'color': const Color(0xFF10B981)},
      {'icon': Icons.pie_chart, 'type': 'pie', 'label': 'Pie', 'color': const Color(0xFFF59E0B)},
      {'icon': Icons.area_chart, 'type': 'area', 'label': 'Area', 'color': const Color(0xFF8B5CF6)},
      {'icon': Icons.scatter_plot, 'type': 'scatter', 'label': 'Scatter', 'color': const Color(0xFFEF4444)},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: chartTypes.map((chart) {
          final isSelected = _selectedChartType == chart['type'];
          final color = chart['color'] as Color;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedChartType = chart['type'] as String;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    chart['icon'] as IconData,
                    size: 18,
                    color: isSelected ? Colors.white : color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    chart['label'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : color,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // NEW ADVANCED ANALYTICS METHODS START HERE

  Widget _buildChartsGrid(List<Map<String, dynamic>> filteredMetrics) {
    if (filteredMetrics.isEmpty) {
      return AppCard(
        child: Column(
          children: [
            const Icon(
              Icons.analytics,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Data Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Adjust your filters to see analytics',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    switch (_selectedChartType) {
      case 'line':
        return _buildModernLineChart(filteredMetrics);
      case 'bar':
        return _buildModernBarChart(filteredMetrics);
      case 'pie':
        return _buildModernPieChart(filteredMetrics);
      case 'area':
        return _buildModernAreaChart(filteredMetrics);
      case 'scatter':
        return _buildModernScatterChart(filteredMetrics);
      default:
        return _buildModernLineChart(filteredMetrics);
    }
  }

  Widget _buildModernLineChart(List<Map<String, dynamic>> metrics) {
    final chartData = _prepareTimeSeriesChartData(metrics);
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEnhancedGraphHeader('Energy Consumption Over Time', metrics.length),
          const SizedBox(height: 24),
          
          // Phase Legend
          _buildPhaseLegend(chartData['phaseData']),
          const SizedBox(height: 20),
          
          SizedBox(
            height: 450,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  drawHorizontalLine: true,
                  horizontalInterval: (chartData['maxY'] - chartData['minY']) / 6,
                  verticalInterval: chartData['timeSpan'] / 8,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.border.withOpacity(0.3),
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: AppColors.border.withOpacity(0.3),
                    strokeWidth: 1,
                  ),
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
                      reservedSize: 40,
                      interval: chartData['timeSpan'] / 6,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final timestamp = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Transform.rotate(
                            angle: -0.5,
                            child: Text(
                              '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      interval: (chartData['maxY'] - chartData['minY']) / 6,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          '${value.toStringAsFixed(0)} W',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: AppColors.border.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                minX: chartData['minX'],
                maxX: chartData['maxX'],
                minY: chartData['minY'],
                maxY: chartData['maxY'],
                lineBarsData: chartData['phaseData'].entries.map<LineChartBarData>((entry) {
                  final phase = entry.key;
                  final spots = entry.value as List<FlSpot>;
                  final color = _getPhaseColor(phase);
                  
                  return LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: spots.length <= 20,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: color,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.3),
                          color.withOpacity(0.1),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  );
                }).toList(),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                    if (touchResponse != null && touchResponse.lineBarSpots != null) {
                      final spot = touchResponse.lineBarSpots!.first;
                      final timestamp = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                      
                      setState(() {
                        _hoveredDataIndex = spot.x.toInt();
                        _hoveredDataPoint = {
                          'timestamp': timestamp,
                          'value': spot.y,
                          'phase': _getPhaseFromIndex(touchResponse.lineBarSpots!.first.barIndex),
                        };
                      });
                    } else {
                      setState(() {
                        _hoveredDataIndex = null;
                        _hoveredDataPoint = null;
                      });
                    }
                  },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        final timestamp = DateTime.fromMillisecondsSinceEpoch(barSpot.x.toInt());
                        final phase = _getPhaseFromIndex(barSpot.barIndex);
                        
                        return LineTooltipItem(
                          '${barSpot.y.toStringAsFixed(2)} W\n',
                          TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: 'Phase: $phase\n',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextSpan(
                              text: '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          
          if (_hoveredDataPoint != null) ...[
            const SizedBox(height: 20),
            _buildEnhancedHoverDataInfo(),
          ],
        ],
      ),
    );
  }

  // Enhanced chart data preparation with time series and phase separation
  Map<String, dynamic> _prepareTimeSeriesChartData(List<Map<String, dynamic>> metrics) {
    if (metrics.isEmpty) {
      return {
        'phaseData': <String, List<FlSpot>>{},
        'minX': 0.0,
        'maxX': 1.0,
        'minY': 0.0,
        'maxY': 1.0,
        'timeSpan': 1.0,
      };
    }

    // Group metrics by phase
    final Map<String, List<FlSpot>> phaseData = {};
    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final metric in metrics) {
      final labels = metric['Labels'] as Map<String, dynamic>? ?? {};
      final phase = labels['Phase']?.toString() ?? metric['Phase']?.toString() ?? 'Total';
      final value = (metric['Value'] ?? 0).toDouble();
      
      // Parse timestamp
      DateTime timestamp;
      if (metric['Timestamp'] != null) {
        try {
          timestamp = DateTime.parse(metric['Timestamp'].toString());
        } catch (e) {
          timestamp = DateTime.now();
        }
      } else {
        timestamp = DateTime.now();
      }
      
      final x = timestamp.millisecondsSinceEpoch.toDouble();
      
      if (value.isFinite && x.isFinite) {
        if (!phaseData.containsKey(phase)) {
          phaseData[phase] = [];
        }
        
        phaseData[phase]!.add(FlSpot(x, value));
        
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (value < minY) minY = value;
        if (value > maxY) maxY = value;
      }
    }

    // Sort spots by X value for each phase
    phaseData.forEach((phase, spots) {
      spots.sort((a, b) => a.x.compareTo(b.x));
    });

    // Ensure reasonable bounds
    if (minY == maxY) {
      minY = maxY - 10;
      maxY = maxY + 10;
    }

    final yPadding = (maxY - minY) * 0.1;
    final chartMinY = (minY - yPadding).clamp(0, double.infinity);
    final chartMaxY = maxY + yPadding;

    final timeSpan = maxX - minX;

    return {
      'phaseData': phaseData,
      'minX': minX,
      'maxX': maxX,
      'minY': chartMinY,
      'maxY': chartMaxY,
      'timeSpan': timeSpan,
    };
  }

  // Phase color mapping
  Color _getPhaseColor(String phase) {
    switch (phase.toLowerCase()) {
      case 'a':
      case 'phase a':
        return const Color(0xFF3B82F6); // Blue
      case 'b':
      case 'phase b':
        return const Color(0xFF10B981); // Green
      case 'c':
      case 'phase c':
        return const Color(0xFFF59E0B); // Orange
      case 'total':
      case 'sum':
        return const Color(0xFF8B5CF6); // Purple
      default:
        return AppColors.primary;
    }
  }

  String _getPhaseFromIndex(int index) {
    final phases = ['Total', 'Phase A', 'Phase B', 'Phase C'];
    return index < phases.length ? phases[index] : 'Unknown';
  }

  // Enhanced phase legend
  Widget _buildPhaseLegend(Map<String, dynamic> phaseData) {
    final phases = phaseData.keys.toList();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.border.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phase Legend',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: phases.map((phase) {
              final color = _getPhaseColor(phase);
              final spots = phaseData[phase] as List<FlSpot>? ?? [];
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$phase (${spots.length} points)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: color.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Enhanced graph header with modern design
  Widget _buildEnhancedGraphHeader(String title, int dataCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.05),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Real-time data • $dataCount measurements',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Live',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced hover data info with modern design
  Widget _buildEnhancedHoverDataInfo() {
    if (_hoveredDataPoint == null) return const SizedBox.shrink();

    final dataPoint = _hoveredDataPoint!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.insights,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Data Point Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildEnhancedDataInfoItem(
                  'Energy Consumption',
                  '${(dataPoint['value'] ?? 0.0).toStringAsFixed(2)} W',
                  Icons.flash_on,
                  const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildEnhancedDataInfoItem(
                  'Phase',
                  dataPoint['phase']?.toString() ?? 'N/A',
                  Icons.electrical_services,
                  const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildEnhancedDataInfoItem(
                  'Time',
                  dataPoint['timestamp'] != null 
                      ? '${(dataPoint['timestamp'] as DateTime).hour.toString().padLeft(2, '0')}:${(dataPoint['timestamp'] as DateTime).minute.toString().padLeft(2, '0')}'
                      : 'N/A',
                  Icons.schedule,
                  const Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildEnhancedDataInfoItem(
                  'Date',
                  dataPoint['timestamp'] != null 
                      ? '${(dataPoint['timestamp'] as DateTime).day}/${(dataPoint['timestamp'] as DateTime).month}/${(dataPoint['timestamp'] as DateTime).year}'
                      : 'N/A',
                  Icons.calendar_today,
                  const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedDataInfoItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
                maxX: (metrics.length - 1).toDouble(),
                minY: chartData['minY'],
                maxY: chartData['maxY'],
                lineBarsData: [
                  LineChartBarData(
                    spots: chartData['spots'],
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF3b82f6)],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.primary,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.3),
                          AppColors.primary.withOpacity(0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                    if (touchResponse != null && touchResponse.lineBarSpots != null) {
                      final spot = touchResponse.lineBarSpots!.first;
                      setState(() {
                        _hoveredDataIndex = spot.x.toInt();
                        if (_hoveredDataIndex! < metrics.length) {
                          _hoveredDataPoint = metrics[_hoveredDataIndex!];
                        }
                      });
                    } else {
                      setState(() {
                        _hoveredDataIndex = null;
                        _hoveredDataPoint = null;
                      });
                    }
                  },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        final index = barSpot.x.toInt();
                        if (index < metrics.length) {
                          final metric = metrics[index];
                          return LineTooltipItem(
                            'Value: ${barSpot.y.toStringAsFixed(2)}\n',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                text: 'Time: ${metric['Timestamp']?.toString().substring(0, 16) ?? 'N/A'}\n',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              TextSpan(
                                text: 'Units: ${metric['Labels']?['Units'] ?? 'N/A'}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          );
                        }
                        return null;
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          
          if (_hoveredDataPoint != null) ...[
            const SizedBox(height: 16),
            _buildHoverDataInfo(),
          ],
        ],
      ),
    );
  }

  Widget _buildModernBarChart(List<Map<String, dynamic>> metrics) {
    final chartData = _prepareChartData(metrics);
    
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGraphHeader('Bar Chart Analysis', metrics.length),
          const SizedBox(height: 20),
          
          SizedBox(
            height: 400,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: chartData['maxY'],
                minY: chartData['minY'],
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: (chartData['maxY'] - chartData['minY']) / 5,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.border,
                    strokeWidth: 1,
                  ),
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
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < metrics.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
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
                      reservedSize: 40,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          value.toStringAsFixed(0),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: AppColors.border),
                ),
                barGroups: List.generate(
                  metrics.length,
                  (index) {
                    final value = (metrics[index]['Value'] ?? 0).toDouble();
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: value,
                          color: AppColors.primary,
                          width: 16,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchCallback: (FlTouchEvent event, BarTouchResponse? touchResponse) {
                    if (touchResponse != null && touchResponse.spot != null) {
                      final index = touchResponse.spot!.touchedBarGroupIndex;
                      setState(() {
                        _hoveredDataIndex = index;
                        if (index < metrics.length) {
                          _hoveredDataPoint = metrics[index];
                        }
                      });
                    } else {
                      setState(() {
                        _hoveredDataIndex = null;
                        _hoveredDataPoint = null;
                      });
                    }
                  },
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      if (groupIndex < metrics.length) {
                        final metric = metrics[groupIndex];
                        return BarTooltipItem(
                          'Value: ${rod.toY.toStringAsFixed(2)}\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(
                              text: 'Time: ${metric['Timestamp']?.toString().substring(0, 16) ?? 'N/A'}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        );
                      }
                      return null;
                    },
                  ),
                ),
              ),
            ),
          ),
          
          if (_hoveredDataPoint != null) ...[
            const SizedBox(height: 16),
            _buildHoverDataInfo(),
          ],
        ],
      ),
    );
  }

  Widget _buildModernPieChart(List<Map<String, dynamic>> metrics) {
    final pieData = _preparePieChartData(metrics);
    
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGraphHeader('Distribution Analysis', metrics.length),
          const SizedBox(height: 20),
          
          SizedBox(
            height: 400,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 80,
                      sections: pieData,
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, PieTouchResponse? touchResponse) {
                          if (touchResponse != null && touchResponse.touchedSection != null) {
                            final index = touchResponse.touchedSection!.touchedSectionIndex;
                            setState(() {
                              _hoveredDataIndex = index;
                              // Set hover data based on pie section
                              if (index < metrics.length && index >= 0) {
                                _hoveredDataPoint = metrics[index];
                              }
                            });
                          } else {
                            setState(() {
                              _hoveredDataIndex = null;
                              _hoveredDataPoint = null;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: _buildPieChartLegend(pieData, metrics),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAreaChart(List<Map<String, dynamic>> metrics) {
    final chartData = _prepareChartData(metrics);
    
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGraphHeader('Area Chart Analysis', metrics.length),
          const SizedBox(height: 20),
          
          SizedBox(
            height: 400,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  drawHorizontalLine: true,
                  horizontalInterval: (chartData['maxY'] - chartData['minY']) / 5,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.border,
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: AppColors.border,
                    strokeWidth: 1,
                  ),
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
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < metrics.length) {
                          return Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
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
                      reservedSize: 40,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          value.toStringAsFixed(0),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: AppColors.border),
                ),
                minX: 0,
                maxX: (metrics.length - 1).toDouble(),
                minY: chartData['minY'],
                maxY: chartData['maxY'],
                lineBarsData: [
                  LineChartBarData(
                    spots: chartData['spots'],
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.4),
                          AppColors.primary.withOpacity(0.1),
                          Colors.transparent,
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
        ],
      ),
    );
  }

  Widget _buildModernScatterChart(List<Map<String, dynamic>> metrics) {
    final chartData = _prepareChartData(metrics);
    
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGraphHeader('Scatter Plot Analysis', metrics.length),
          const SizedBox(height: 20),
          
          SizedBox(
            height: 400,
            child: ScatterChart(
              ScatterChartData(
                scatterSpots: chartData['spots'].map<ScatterSpot>((spot) {
                  return ScatterSpot(
                    spot.x,
                    spot.y,
                  );
                }).toList(),
                minX: 0,
                maxX: (metrics.length - 1).toDouble(),
                minY: chartData['minY'],
                maxY: chartData['maxY'],
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: (chartData['maxY'] - chartData['minY']) / 5,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.border,
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: AppColors.border,
                    strokeWidth: 1,
                  ),
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
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < metrics.length) {
                          return Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
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
                      reservedSize: 40,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          value.toStringAsFixed(0),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: AppColors.border),
                ),
                scatterTouchData: ScatterTouchData(
                  enabled: true,
                  touchCallback: (FlTouchEvent event, ScatterTouchResponse? touchResponse) {
                    if (touchResponse != null && touchResponse.touchedSpot != null) {
                      final spot = touchResponse.touchedSpot!.spot;
                      final index = spot.x.toInt();
                      setState(() {
                        _hoveredDataIndex = index;
                        if (index < metrics.length) {
                          _hoveredDataPoint = metrics[index];
                        }
                      });
                    } else {
                      setState(() {
                        _hoveredDataIndex = null;
                        _hoveredDataPoint = null;
                      });
                    }
                  },
                  touchTooltipData: ScatterTouchTooltipData(
                    getTooltipItems: (ScatterSpot touchedBarSpot) {
                      final index = touchedBarSpot.x.toInt();
                      if (index < metrics.length) {
                        final metric = metrics[index];
                        return ScatterTooltipItem(
                          'Value: ${touchedBarSpot.y.toStringAsFixed(2)}\n'
                          'Time: ${metric['Timestamp']?.toString().substring(0, 16) ?? 'N/A'}',
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for chart data preparation
  Map<String, dynamic> _prepareChartData(List<Map<String, dynamic>> metrics) {
    final spots = <FlSpot>[];
    double minValue = double.infinity;
    double maxValue = double.negativeInfinity;

    for (int i = 0; i < metrics.length; i++) {
      final value = (metrics[i]['Value'] ?? 0).toDouble();
      if (value.isFinite) {
        spots.add(FlSpot(i.toDouble(), value));
        if (value < minValue) minValue = value;
        if (value > maxValue) maxValue = value;
      }
    }

    // Ensure reasonable bounds
    if (minValue == maxValue) {
      minValue = maxValue - 1;
      maxValue = maxValue + 1;
    }

    final yPadding = (maxValue - minValue) * 0.1;
    final chartMinY = (minValue - yPadding).clamp(0, double.infinity);
    final chartMaxY = maxValue + yPadding;

    return {
      'spots': spots,
      'minY': chartMinY,
      'maxY': chartMaxY,
    };
  }

  List<PieChartSectionData> _preparePieChartData(List<Map<String, dynamic>> metrics) {
    final Map<String, double> groupedData = {};
    
    // Group data by units or phase for pie chart
    for (final metric in metrics) {
      final labels = metric['Labels'] as Map<String, dynamic>? ?? {};
      final key = labels['Units']?.toString() ?? 
                  labels['Phase']?.toString() ?? 
                  'Unknown';
      final value = (metric['Value'] ?? 0).toDouble();
      groupedData[key] = (groupedData[key] ?? 0) + value;
    }

    final total = groupedData.values.fold(0.0, (sum, value) => sum + value);
    final colors = [
      AppColors.primary,
      AppColors.success,
      AppColors.warning,
      AppColors.error,
      AppColors.secondary,
    ];

    return groupedData.entries.map((entry) {
      final index = groupedData.keys.toList().indexOf(entry.key);
      final percentage = (entry.value / total) * 100;
      
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildGraphHeader(String title, int dataCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Showing $dataCount data points',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        if (_selectedUnits != null || _selectedPhase != null || _selectedFlowDirection != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Filtered',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPieChartLegend(List<PieChartSectionData> pieData, List<Map<String, dynamic>> metrics) {
    final Map<String, double> groupedData = {};
    
    for (final metric in metrics) {
      final labels = metric['Labels'] as Map<String, dynamic>? ?? {};
      final key = labels['Units']?.toString() ?? 
                  labels['Phase']?.toString() ?? 
                  'Unknown';
      final value = (metric['Value'] ?? 0).toDouble();
      groupedData[key] = (groupedData[key] ?? 0) + value;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Legend',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...groupedData.entries.map((entry) {
          final index = groupedData.keys.toList().indexOf(entry.key);
          final colors = [
            AppColors.primary,
            AppColors.success,
            AppColors.warning,
            AppColors.error,
            AppColors.secondary,
          ];
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors[index % colors.length],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        entry.value.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildHoverDataInfo() {
    if (_hoveredDataPoint == null) return const SizedBox.shrink();

    final metric = _hoveredDataPoint!;
    final labels = metric['Labels'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Hovered Data Point',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDataInfoItem(
                  'Value',
                  '${metric['Value'] ?? 'N/A'} ${labels['Units'] ?? ''}',
                ),
              ),
              Expanded(
                child: _buildDataInfoItem(
                  'Timestamp',
                  metric['Timestamp']?.toString().substring(0, 16) ?? 'N/A',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDataInfoItem(
                  'Phase',
                  labels['Phase']?.toString() ?? 'N/A',
                ),
              ),
              Expanded(
                child: _buildDataInfoItem(
                  'Flow Direction',
                  labels['FlowDirection']?.toString() ?? 'N/A',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDataSummaryCard(List<Map<String, dynamic>> filteredMetrics) {
    if (filteredMetrics.isEmpty) return const SizedBox.shrink();

    // Calculate summary statistics
    final values = filteredMetrics.map((m) => (m['Value'] ?? 0).toDouble()).where((v) => v.isFinite).toList();
    final average = values.isNotEmpty ? values.reduce((a, b) => a + b) / values.length : 0;
    final maxValue = values.isNotEmpty ? values.reduce((a, b) => a > b ? a : b) : 0;
    final minValue = values.isNotEmpty ? values.reduce((a, b) => a < b ? a : b) : 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.summarize,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Data Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total Records',
                  filteredMetrics.length.toString(),
                  Icons.dataset,
                  AppColors.primary,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Average Value',
                  average.toStringAsFixed(2),
                  Icons.trending_up,
                  AppColors.success,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Max Value',
                  maxValue.toStringAsFixed(2),
                  Icons.arrow_upward,
                  AppColors.error,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Min Value',
                  minValue.toStringAsFixed(2),
                  Icons.arrow_downward,
                  AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
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
