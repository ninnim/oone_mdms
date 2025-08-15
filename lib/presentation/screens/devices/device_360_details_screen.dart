import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mdms_clone/presentation/widgets/common/app_tabs.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/device.dart';
import '../../../core/models/device_group.dart';
import '../../../core/models/address.dart';
import '../../../core/models/schedule.dart';
import '../../../core/models/load_profile_metric.dart';
import '../../../core/models/chart_type.dart';
import '../../../core/services/device_service.dart';
import '../../../core/services/schedule_service.dart';
import '../../../core/services/service_locator.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_input_field.dart';
import '../../widgets/common/app_dropdown_field.dart';
import '../../widgets/common/app_confirm_dialog.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/common/results_pagination.dart';
import '../../widgets/common/blunest_data_table.dart';
import '../../widgets/common/app_lottie_state_widget.dart';
import '../../widgets/devices/device_location_viewer.dart';
import '../../widgets/devices/interactive_map_dialog.dart';
import '../../widgets/devices/dynamic_metrics_table_columns.dart';
import '../../widgets/devices/billing_table_columns.dart';
import '../../widgets/devices/modern_metrics_chart.dart';
import '../../widgets/schedules/schedule_form_dialog.dart';
import '../../widgets/schedules/schedule_table_columns.dart';
import '../../widgets/schedules/schedule_filters_and_actions_v2.dart';
import '../../widgets/schedules/schedule_summary_card.dart';
import '../../widgets/schedules/schedule_kanban_view.dart';
import 'widgets/device_channel_table_columns.dart';
import '../../widgets/common/custom_date_range_picker.dart';
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

  // Channels tab state
  bool _isEditingChannels = false;
  bool _savingChannels = false;
  final Map<String, double> _editedCumulativeValues = {};
  final Map<String, double> _originalCumulativeValues =
      {}; // Store original values for comparison
  Set<String> _selectedChannelIds = {};
  final Map<String, TextEditingController> _channelControllers = {};
  bool _showApplyMetricWarning = false;

  // Channels table state
  List<String> _hiddenChannelColumns = [];
  String? _channelSortBy;
  bool _channelSortAscending = true;

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

  // Dynamic metrics state
  List<Map<String, dynamic>> _dynamicMetrics = [];
  Set<String> _selectedChartFields = {};
  int _totalMetricsCount = 0;
  bool _isLoadingMetrics = false;

  // Metrics table state for UI consistency
  Set<Map<String, dynamic>> _selectedMetrics = {};
  List<String> _hiddenMetricsColumns = [];

  // Metrics table scroll controller for drag-to-scroll
  final ScrollController _metricsTableScrollController = ScrollController();

  // Advanced analytics data
  List<LoadProfileMetric> _analyticsMetrics = [];
  bool _isLoadingAnalytics = false;
  String? _analyticsError;
  DateTimeRange? _selectedDateRange;
  final List<String> _selectedPhases = ['L1', 'L2', 'L3'];
  final List<String> _selectedMetricTypes = ['Voltage', 'Current', 'Power'];
  ChartType _selectedChartType = ChartType.line;
  bool _showHover = true;
  final Map<String, bool> _phaseVisibility = {
    'L1': true,
    'L2': true,
    'L3': true,
  };

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
  bool _hasMoreSchedules = true;
  int? _selectedScheduleIdEdit;

  // Schedules tab data
  List<Schedule> _deviceSchedules = [];
  List<Schedule> _deviceGroupSchedules = [];
  List<Schedule> _allSchedules = [];
  List<Schedule> _filteredSchedules = [];
  Set<Schedule> _selectedSchedules = {};
  bool _schedulesLoaded = false;
  String? _schedulesError;

  // Schedule table state
  List<String> _schedulesHiddenColumns = [];
  int _schedulesCurrentPage = 1;
  int _schedulesTotalPages = 1;
  int _schedulesTotalItems = 0;
  int _schedulesItemsPerPage = 10;
  Timer? _schedulesDebounceTimer;

  // Schedule filters
  String? _selectedScheduleStatus;
  String? _selectedScheduleTargetType;
  String _schedulesSearchQuery = '';

  // Schedule tab state (matching device group details style)
  bool _isSchedulesLoading = false;
  ScheduleViewMode _scheduleViewMode = ScheduleViewMode.table;

  // Schedule sorting
  String? _schedulesSortBy;
  bool _schedulesSortAscending = true;

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
    // Initialize form fields with device data
    _serialNumberEditController.text = widget.device.serialNumber;
    _modelEditController.text = widget.device.model;

    // Initialize dropdown selections
    _selectedDeviceTypeEdit = widget.device.deviceType.isNotEmpty
        ? widget.device.deviceType
        : 'None';
    _selectedStatusEdit = widget.device.status.isNotEmpty
        ? widget.device.status
        : 'None';
    _selectedLinkStatusEdit = widget.device.linkStatus.isNotEmpty
        ? widget.device.linkStatus
        : 'None';

    // Initialize device group selection if available
    _selectedDeviceGroupIdEdit = widget.device.deviceGroupId;

    // Initialize schedule selection if available
    // Note: Device model doesn't have scheduleId field yet, add this when model is updated
    // if (widget.device!.scheduleId != null) {
    //   _selectedScheduleIdEdit = widget.device!.scheduleId;
    // }
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentTabIndex = index;
    });

    switch (index) {
      case 0: // Overview
        if (!_overviewLoaded) _loadOverviewData();
        break;
      case 1: // Schedules
        if (!_schedulesLoaded) _loadSchedulesData();
        break;
      case 2: // Channels
        if (!_channelsLoaded) _loadChannelsData();
        break;
      case 3: // Metrics
        if (!_metricsLoaded) {
          _loadMetricsData();
          _loadAnalyticsData(); // Load analytics data when metrics tab is opened
        }
        break;
      case 4: // Billing
        if (!_billingLoaded) _loadBillingData();
        break;
      case 5: // Location
        if (!_locationLoaded) _loadLocationData();
        break;
    }
  }

  @override
  void dispose() {
    _serialNumberEditController.dispose();
    _modelEditController.dispose();
    _addressEditController.dispose();
    _metricsTableScrollController.dispose();
    // Dispose channel controllers
    for (final controller in _channelControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // Helper method to get device group name
  // Start editing overview
  void _startEditingOverview() {
    setState(() {
      _isEditingOverview = true;
    });
    _loadDropdownDataForEdit();
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
      _schedulesSearchQuery = '';

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
  Future<void> _loadDeviceGroups({
    bool reset = false,
    bool loadMore = false,
    String? searchQuery,
  }) async {
    if (_isLoadingDeviceGroups) return;

    // If loading more, but no more data available, return
    if (loadMore && !_hasMoreDeviceGroups) return;

    setState(() {
      _isLoadingDeviceGroups = true;

      // Reset for new search or first load
      if (reset || !loadMore) {
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
          'Loading device groups: reset=$reset, loadMore=$loadMore, searchQuery=$searchQuery',
        );
        print('Current selected device group ID: $_selectedDeviceGroupIdEdit');
      }

      final deviceGroupsResponse = await _deviceService.getDeviceGroups(
        limit: 20,
        offset: loadMore ? _deviceGroups.length : 0,
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
          if (_selectedDeviceGroupIdEdit != null) {
            final hasSelected = newGroups.any(
              (g) => g.id == _selectedDeviceGroupIdEdit,
            );
            print(
              'Selected device group $_selectedDeviceGroupIdEdit found in loaded groups: $hasSelected',
            );
          }
        }

        setState(() {
          if (loadMore) {
            _deviceGroups.addAll(newGroups);
          } else {
            _deviceGroups = newGroups;
          }

          _hasMoreDeviceGroups = newGroups.length >= 20;

          // Validate selected device group still exists
          if (_selectedDeviceGroupIdEdit != null) {
            final uniqueGroups = _getUniqueDeviceGroups();
            final groupExists = uniqueGroups.any(
              (group) => group.id == _selectedDeviceGroupIdEdit,
            );
            if (!groupExists) {
              if (kDebugMode) {
                print(
                  'Selected device group $_selectedDeviceGroupIdEdit not found in loaded groups, keeping for now',
                );
              }
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

  // Handle device group search
  void _onDeviceGroupSearchChanged(String query) {
    _loadDeviceGroups(reset: true, searchQuery: query);
  }

  // Handle load more device groups
  void _onLoadMoreDeviceGroups() {
    if (!_isLoadingDeviceGroups && _hasMoreDeviceGroups) {
      _loadDeviceGroups(loadMore: true);
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
        search: _schedulesSearchQuery.isNotEmpty ? _schedulesSearchQuery : '',
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

  // Build device group dropdown for edit mode
  Widget _buildDeviceGroupEditDropdown() {
    return AppSearchableDropdown<int?>(
      label: 'Device Group',
      hintText: 'None',
      value: _getSafeDeviceGroupValue(),
      height: AppSizes.inputHeight,
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text(
            'None',
            style: TextStyle(fontSize: AppSizes.fontSizeSmall),
          ),
        ),
        ..._getUniqueDeviceGroups().map((group) {
          return DropdownMenuItem<int?>(
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
      onChanged: (int? value) {
        setState(() {
          _selectedDeviceGroupIdEdit = value;
        });
      },
      onTap: () {
        // Load device groups when dropdown is tapped
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
      ..._schedules.map(
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
      ),
    ];

    return AppSearchableDropdown<int?>(
      label: 'Schedule',
      hintText: 'Select Schedule',
      value: _selectedScheduleIdEdit,
      height: AppSizes.inputHeight,
      items: items,
      isLoading: _isLoadingSchedules,
      hasMore: _hasMoreSchedules,
      searchQuery: _schedulesSearchQuery,
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
  Future<void> _loadChannelsData({bool forceRefresh = false}) async {
    if (_channelsLoaded || _loadingChannels) {
      // Skip loading if already loaded, unless force refresh is requested
      if (!forceRefresh) return;
    }

    setState(() {
      _loadingChannels = true;
    });

    try {
      print('Loading channels data for device: ${widget.device.id}');

      // Always fetch fresh device details when force refresh or no cached data
      if (_deviceDetails == null || forceRefresh) {
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
        pageSize: _metricsItemsPerPage,
        currentPage: _metricsCurrentPage,
      );

      print('Metrics response: ${metricsResponse.success}');

      if (metricsResponse.success) {
        final responseData = metricsResponse.data;

        // Parse the new API structure
        if (responseData != null && responseData['Result'] != null) {
          final List<dynamic> resultList =
              responseData['Result'] as List<dynamic>;
          _dynamicMetrics = resultList.cast<Map<String, dynamic>>();

          // Get pagination info
          final queryParam = responseData['QueryParam'];
          if (queryParam != null) {
            _totalMetricsCount = queryParam['RowCount'] ?? 0;
          } else {
            _totalMetricsCount = _dynamicMetrics.length;
          }

          print('Dynamic metrics loaded: ${_dynamicMetrics.length} items');
          print('Total metrics count: $_totalMetricsCount');
        } else {
          _dynamicMetrics = [];
          _totalMetricsCount = 0;
        }

        // Keep the old structure for compatibility with existing graph code
        _deviceMetrics = {
          'DeviceMetrics': {'Metrics': _dynamicMetrics, 'Status': 'Success'},
        };
      } else {
        print('Metrics error: ${metricsResponse.message}');
        _dynamicMetrics = [];
        _totalMetricsCount = 0;
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
        _dynamicMetrics = [];
        _totalMetricsCount = 0;
        _deviceMetrics = {
          'DeviceMetrics': {'Metrics': [], 'Status': 'Error: $e'},
        };
      });
    }
  }

  // Load metrics data specifically for graphs with PageSize=0 to get all data
  Future<void> _loadMetricsDataForGraphs() async {
    if (_loadingMetrics) return;

    setState(() {
      _loadingMetrics = true;
    });

    try {
      print(
        'Loading metrics data for graphs (PageSize=0) for device: ${widget.device.id}',
      );
      print(
        'Date range: ${_metricsStartDate.toIso8601String()} to ${_metricsEndDate.toIso8601String()}',
      );

      final metricsResponse = await _deviceService.getDeviceMetrics(
        widget.device.id ?? '',
        startDate: _metricsStartDate.toIso8601String(),
        endDate: _metricsEndDate.toIso8601String(),
        pageSize: 0, // PageSize=0 to get all data for graphs
        currentPage: 1,
      );

      print('Metrics response for graphs: ${metricsResponse.success}');

      if (metricsResponse.success) {
        final responseData = metricsResponse.data;

        // Parse the new API structure
        if (responseData != null && responseData['Result'] != null) {
          final List<dynamic> resultList =
              responseData['Result'] as List<dynamic>;
          _dynamicMetrics = resultList.cast<Map<String, dynamic>>();

          // Get pagination info
          final queryParam = responseData['QueryParam'];
          if (queryParam != null) {
            _totalMetricsCount = queryParam['RowCount'] ?? 0;
          } else {
            _totalMetricsCount = _dynamicMetrics.length;
          }

          print(
            'Dynamic metrics loaded for graphs: ${_dynamicMetrics.length} items',
          );
          print('Total metrics count: $_totalMetricsCount');
        } else {
          _dynamicMetrics = [];
          _totalMetricsCount = 0;
        }

        // Keep the old structure for compatibility with existing graph code
        _deviceMetrics = {
          'DeviceMetrics': {'Metrics': _dynamicMetrics, 'Status': 'Success'},
        };
      } else {
        print('Metrics error for graphs: ${metricsResponse.message}');
        _dynamicMetrics = [];
        _totalMetricsCount = 0;
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
      print('Error loading metrics data for graphs: $e');
      setState(() {
        _loadingMetrics = false;
        _dynamicMetrics = [];
        _totalMetricsCount = 0;
        _deviceMetrics = {
          'DeviceMetrics': {'Metrics': [], 'Status': 'Error: $e'},
        };
      });
    }
  }

  // Load analytics data for advanced charts
  Future<void> _loadAnalyticsData() async {
    if (_isLoadingAnalytics) return;

    setState(() {
      _isLoadingAnalytics = true;
      _analyticsError = null;
    });

    try {
      final startDate =
          _selectedDateRange?.start ??
          DateTime.now().subtract(const Duration(days: 7));
      final endDate = _selectedDateRange?.end ?? DateTime.now();

      final response = await _deviceService.getDeviceLoadProfile(
        deviceId: widget.device.id ?? '',
        startDate: startDate,
        endDate: endDate,
        phases: _selectedPhases,
        metricTypes: _selectedMetricTypes,
        limit: 1000,
      );

      if (response.success && response.data != null) {
        setState(() {
          _analyticsMetrics = response.data!;
          _isLoadingAnalytics = false;
        });
      } else {
        setState(() {
          _analyticsError = response.message ?? 'Failed to load analytics data';
          _isLoadingAnalytics = false;
        });
      }
    } catch (e) {
      setState(() {
        _analyticsError = 'Error loading analytics data: $e';
        _isLoadingAnalytics = false;
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

  Future<void> _loadSchedulesData() async {
    setState(() {
      _isSchedulesLoading = true;
      _schedulesError = null;
    });

    try {
      // Load device schedules only (API by device ID, no pagination)
      final deviceSchedulesResponse = await _scheduleService
          .getSchedulesByDeviceId(widget.device.id!);

      List<Schedule> deviceSchedules = [];
      if (deviceSchedulesResponse.success &&
          deviceSchedulesResponse.data != null) {
        deviceSchedules = deviceSchedulesResponse.data!;
      }

      setState(() {
        _deviceSchedules = deviceSchedules;
        _deviceGroupSchedules = []; // No group schedules needed
        _allSchedules = deviceSchedules; // Only device schedules
        _filteredSchedules = _applyScheduleFilters(_allSchedules);
        _schedulesLoaded = true;
        _isSchedulesLoading = false;
      });

      print('Loaded ${deviceSchedules.length} device schedules only');
    } catch (e) {
      print('Error loading schedules data: $e');
      setState(() {
        _schedulesError = e.toString();
        _isSchedulesLoading = false;
      });
    }
  }

  List<Schedule> _applyScheduleFilters(List<Schedule> schedules) {
    var filtered = schedules;

    // Apply search filter
    if (_schedulesSearchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (schedule) =>
                schedule.displayName.toLowerCase().contains(
                  _schedulesSearchQuery.toLowerCase(),
                ) ||
                schedule.displayCode.toLowerCase().contains(
                  _schedulesSearchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    // Apply status filter
    if (_selectedScheduleStatus != null) {
      filtered = filtered
          .where(
            (schedule) => schedule.displayStatus == _selectedScheduleStatus,
          )
          .toList();
    }

    // Apply target type filter
    if (_selectedScheduleTargetType != null) {
      filtered = filtered
          .where(
            (schedule) =>
                schedule.displayTargetType == _selectedScheduleTargetType,
          )
          .toList();
    }

    return filtered;
  }

  void _updateSchedulePaginationTotals() {
    _schedulesTotalItems = _filteredSchedules.length;
    _schedulesTotalPages = _schedulesTotalItems > 0
        ? ((_schedulesTotalItems - 1) ~/ _schedulesItemsPerPage) + 1
        : 1;

    // Ensure current page is valid
    if (_schedulesCurrentPage > _schedulesTotalPages) {
      _schedulesCurrentPage = _schedulesTotalPages;
    }
    if (_schedulesCurrentPage < 1) {
      _schedulesCurrentPage = 1;
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

    // Use appropriate loader based on current view
    if (_isTableView) {
      _loadMetricsData(); // Table view - uses pagination
    } else {
      _loadMetricsDataForGraphs(); // Graph view - always PageSize=0
    }
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
      case 1: // Schedules
        setState(() {
          _schedulesLoaded = false;
          _deviceSchedules.clear();
          _deviceGroupSchedules.clear();
          _allSchedules.clear();
          _filteredSchedules.clear();
          _schedulesError = null;
        });
        await _loadSchedulesData();
        break;
      case 2: // Channels
        setState(() {
          _channelsLoaded = false;
          _deviceChannels = null;
        });
        await _loadChannelsData();
        break;
      case 3: // Metrics
        setState(() {
          _metricsLoaded = false;
          _deviceMetrics = null;
          _metricsCurrentPage = 1;
        });
        await _loadMetricsData();
        break;
      case 4: // Billing
        setState(() {
          _billingLoaded = false;
          _deviceBilling = null;
        });
        await _loadBillingData();
        break;
      case 5: // Location
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
                            case 0: // Overview
                              setState(() {
                                _overviewLoaded = false;
                                _error = null;
                              });
                              _loadOverviewData();
                              break;
                            case 1: // Schedules
                              setState(() {
                                _schedulesLoaded = false;
                                _error = null;
                              });
                              _loadSchedulesData();
                              break;
                            case 2: // Channels
                              setState(() {
                                _channelsLoaded = false;
                                _error = null;
                              });
                              _loadChannelsData();
                              break;
                            case 3: // Metrics
                              setState(() {
                                _metricsLoaded = false;
                                _error = null;
                              });
                              _loadMetricsData();
                              break;
                            case 4: // Billing
                              setState(() {
                                _billingLoaded = false;
                                _error = null;
                              });
                              _loadBillingData();
                              break;
                            case 5: // Location
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
                      label: 'Schedules',
                      icon: Icon(Icons.schedule, size: AppSizes.iconSmall),
                      content: _buildSchedulesTab(),
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

    return Column(
      children: [
        // Sticky header
        Container(
          padding: const EdgeInsets.all(AppSizes.spacing16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFE1E5E9), width: 1),
            ),
          ),
          child: Row(
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
              if (!_isEditingOverview)
                AppButton(
                  text: 'Edit Device',
                  type: AppButtonType.outline,
                  size: AppButtonSize.small,
                  onPressed: _startEditingOverview,
                  icon: const Icon(Icons.edit, size: AppSizes.iconSmall),
                ),
            ],
          ),
        ),
        // Scrollable content
        Expanded(
          child: _isEditingOverview
              ? _buildOverviewEditMode()
              : _buildOverviewViewMode(),
        ),
      ],
    );
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

    return Column(
      children: [
        // Sticky header
        Container(
          padding: const EdgeInsets.all(AppSizes.spacing16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFE1E5E9), width: 1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with actions
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Device Channels',
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeLarge,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1e293b),
                      ),
                    ),
                  ),
                  if (_deviceChannels != null &&
                      _deviceChannels!.isNotEmpty) ...[
                    if (!_isEditingChannels) ...[
                      AppButton(
                        size: AppButtonSize.small,
                        text: 'Edit Channels',
                        type: AppButtonType.outline,
                        icon: Icon(Icons.edit, size: AppSizes.iconSmall),
                        onPressed: _startEditingChannels,
                      ),
                    ] else ...[
                      AppButton(
                        text: 'Cancel',
                        type: AppButtonType.outline,
                        onPressed: _cancelEditingChannels,
                      ),
                      const SizedBox(width: 12),
                      AppButton(
                        text: _savingChannels ? 'Saving...' : 'Save Changes',
                        type: AppButtonType.primary,
                        icon: _savingChannels
                            ? null
                            : Icon(Icons.save, size: AppSizes.iconSmall),
                        onPressed: _savingChannels ? null : _saveChannelChanges,
                        isLoading: _savingChannels,
                      ),
                    ],
                  ],
                ],
              ),

              // Warning message when ApplyMetric will be updated
              if (_showApplyMetricWarning) ...[
                const SizedBox(height: AppSizes.spacing16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    border: Border.all(
                      color: AppColors.warning.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: AppColors.warning),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Note: After updating channel values, ApplyMetric will be set to true automatically, and cumulative values may change based on system calculations.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.warning,
                            fontWeight: FontWeight.w500,
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
        // Scrollable content
        Expanded(
          child: _deviceChannels != null && _deviceChannels!.isNotEmpty
              ? _buildChannelsTable()
              : Center(
                  child: AppLottieStateWidget.noData(
                    title: 'No Channels Available',
                    message:
                        'This device does not have any channels configured.',
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildChannelsTable() {
    if (_deviceChannels == null || _deviceChannels!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      child: BluNestDataTable<DeviceChannel>(
        columns: DeviceChannelTableColumns.getColumns(
          isEditMode: _isEditingChannels,
          selectedChannelIds: _selectedChannelIds,
          onChannelSelect: (channel, value) {
            _toggleChannelSelection(channel.id, value ?? false);
          },
          onCumulativeChanged: (channel, value) {
            final numValue = double.tryParse(value);
            if (numValue != null) {
              setState(() {
                _editedCumulativeValues[channel.id] = numValue;

                // Auto-select/deselect row based on whether value changed from original
                final originalValue = _originalCumulativeValues[channel.id];
                if (originalValue != null) {
                  if (numValue != originalValue) {
                    // Value changed from original - select the row
                    _selectedChannelIds.add(channel.id);
                  } else {
                    // Value matches original - deselect the row
                    _selectedChannelIds.remove(channel.id);
                  }
                }
              });
            }
          },
          channelControllers: _channelControllers,
          onView: null, // No view action for channels
          onEdit: null, // No individual edit action
          onDelete: null, // No individual delete action
        ),
        data: _deviceChannels!,
        enableMultiSelect: _isEditingChannels,
        selectedItems: _isEditingChannels
            ? _deviceChannels!
                  .where((c) => _selectedChannelIds.contains(c.id))
                  .toSet()
            : <DeviceChannel>{},
        onSelectionChanged: (selectedItems) {
          setState(() {
            _selectedChannelIds = selectedItems.map((c) => c.id).toSet();
          });
        },
        hiddenColumns: _hiddenChannelColumns,
        onColumnVisibilityChanged: (hiddenColumns) {
          setState(() {
            _hiddenChannelColumns = hiddenColumns;
          });
        },
        sortBy: _channelSortBy,
        sortAscending: _channelSortAscending,
        onSort: (sortBy, ascending) {
          setState(() {
            _channelSortBy = sortBy;
            _channelSortAscending = ascending;
            _sortChannelsData();
          });
        },
        isLoading: _loadingChannels,
      ),
    );
  }

  void _startEditingChannels() {
    setState(() {
      _isEditingChannels = true;
      _editedCumulativeValues.clear();
      _originalCumulativeValues.clear();
      _selectedChannelIds.clear();
      _showApplyMetricWarning = true;
    });

    // Initialize controllers with current values and store original values
    for (final channel in _deviceChannels!) {
      if (!_channelControllers.containsKey(channel.id)) {
        _channelControllers[channel.id] = TextEditingController(
          text: channel.cumulative.toStringAsFixed(2),
        );
      }
      // Store original value for comparison
      _originalCumulativeValues[channel.id] = channel.cumulative;
    }
  }

  void _cancelEditingChannels() {
    setState(() {
      _isEditingChannels = false;
      _savingChannels = false;
      _editedCumulativeValues.clear();
      _originalCumulativeValues.clear();
      _selectedChannelIds.clear();
      _showApplyMetricWarning = false;
    });

    // Reset controllers to original values
    for (final channel in _deviceChannels!) {
      if (_channelControllers.containsKey(channel.id)) {
        _channelControllers[channel.id]!.text = channel.cumulative
            .toStringAsFixed(2);
      }
    }
  }

  void _toggleChannelSelection(String channelId, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedChannelIds.add(channelId);
      } else {
        _selectedChannelIds.remove(channelId);
      }
    });
  }

  Future<void> _saveChannelChanges() async {
    if (_selectedChannelIds.isEmpty) {
      AppToast.showWarning(
        context,
        title: 'No Channels Selected',
        message: 'Please select channels to update.',
      );
      return;
    }

    setState(() {
      _savingChannels = true;
    });

    try {
      // Prepare channel updates for selected channels
      final List<Map<String, dynamic>> channelUpdates = [];

      for (final channelId in _selectedChannelIds) {
        final channel = _deviceChannels!.firstWhere((c) => c.id == channelId);
        final controller = _channelControllers[channelId];

        if (controller != null) {
          final newValue = double.tryParse(controller.text);
          if (newValue != null && newValue != channel.cumulative) {
            // Create channel update with only the required fields as per API spec
            channelUpdates.add({
              "Id": channel.id,
              "ApplyMetric": false, // Set to false as per the payload example
              "Cumulative": newValue,
            });
          }
        }
      }

      if (channelUpdates.isEmpty) {
        AppToast.showWarning(
          context,
          title: 'No Changes',
          message: 'No cumulative values were changed.',
        );
        setState(() {
          _savingChannels = false;
        });
        return;
      }

      // Update device with channels via API using existing service method
      final response = await _deviceService.updateDeviceWithChannels(
        widget.device,
        channelUpdates,
      );

      if (response.success && mounted) {
        AppToast.showSuccess(
          context,
          title: 'Channels Updated',
          message: '${channelUpdates.length} channel(s) updated successfully',
        );

        // Exit edit mode and refresh channels data
        setState(() {
          _isEditingChannels = false;
          _savingChannels = false;
          _editedCumulativeValues.clear();
          _originalCumulativeValues.clear();
          _selectedChannelIds.clear();
          _showApplyMetricWarning = false;
          _channelsLoaded = false;
          // Clear device details cache to force fresh API call
          _deviceDetails = null;
          // Also clear overview cache to refresh main device data
          _overviewLoaded = false;
          // Clear metrics cache as cumulative changes might affect metrics
          _metricsLoaded = false;
          // Clear billing cache as cumulative changes might affect billing data
          _billingLoaded = false;
        });

        // Refresh channels data with fresh API call
        await _loadChannelsData(forceRefresh: true);

        // Optional: Add small delay to ensure backend processing is complete
        await Future.delayed(const Duration(milliseconds: 500));

        // Trigger any parent widget callbacks if needed for real-time updates
        // (Could add onDeviceUpdated callback in future if parent needs notification)
      } else if (mounted) {
        AppToast.showError(
          context,
          title: 'Update Failed',
          error: response.message ?? 'Failed to update channels',
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(
          context,
          title: 'Update Failed',
          error: 'Error updating channels: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _savingChannels = false;
        });
      }
    }
  }

  // Sort channels data based on current sort configuration
  void _sortChannelsData() {
    if (_deviceChannels == null || _channelSortBy == null) return;

    _deviceChannels!.sort((a, b) {
      dynamic aValue;
      dynamic bValue;

      switch (_channelSortBy) {
        case 'channel':
          aValue = a.channel?.name ?? '';
          bValue = b.channel?.name ?? '';
          break;
        case 'code':
          aValue = a.channel?.code ?? '';
          bValue = b.channel?.code ?? '';
          break;
        case 'units':
          aValue = a.channel?.units ?? '';
          bValue = b.channel?.units ?? '';
          break;
        case 'cumulative':
          aValue = a.cumulative;
          bValue = b.cumulative;
          break;
        case 'apply_metric':
          aValue = a.applyMetric;
          bValue = b.applyMetric;
          break;
        default:
          return 0;
      }

      int comparison;
      if (aValue is num && bValue is num) {
        comparison = aValue.compareTo(bValue);
      } else if (aValue is bool && bValue is bool) {
        comparison = aValue.toString().compareTo(bValue.toString());
      } else {
        comparison = aValue.toString().toLowerCase().compareTo(
          bValue.toString().toLowerCase(),
        );
      }

      return _channelSortAscending ? comparison : -comparison;
    });
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

    return Column(
      children: [
        // Fixed header section with padding
        Container(
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
                      borderRadius: BorderRadius.circular(
                        AppSizes.radiusMedium,
                      ),
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
                            // Trigger metrics API loading with PageSize=0 when switching to graph view
                            _loadMetricsDataForGraphs();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Expandable content area with scrolling
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
            child:
                _deviceMetrics != null &&
                    _deviceMetrics!['DeviceMetrics'] != null
                ? (_isTableView
                      ? _buildMetricsTableWithPagination()
                      : SingleChildScrollView(child: _buildMetricsGraph()))
                : const AppLottieStateWidget.noData(
                    title: 'No Metrics Data',
                    message: 'No metrics data available',
                  ),
          ),
        ),
      ],
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
    return Column(
      children: [
        // Dynamic Metrics Chart Dashboard
        _buildDynamicMetricsChart(),
        const SizedBox(height: AppSizes.spacing24),
        // Metrics Summary Cards
        _buildMetricsSummaryCards(),
      ],
    );
  }

  Widget _buildDynamicMetricsChart() {
    return ModernMetricsChart(
      data: _dynamicMetrics,
      isLoading: _isLoadingMetrics,
      onRefresh:
          _loadMetricsDataForGraphs, // Use graph-specific loader with PageSize=0
      onExport: _exportMetricsChart,
      onPageSizeChanged: _handlePageSizeChanged,
    );
  }

  void _handlePageSizeChanged(int pageSize) async {
    print('PageSize changed to: $pageSize');

    // Update the page size for the API call
    if (pageSize == 0) {
      // Load all data (PageSize = 0)
      await _loadMetricsDataForGraphs();
    } else {
      // Load with specific page size - we need to create a new method for this
      await _loadMetricsDataWithPageSize(pageSize);
    }
  }

  Future<void> _loadMetricsDataWithPageSize(int pageSize) async {
    if (_loadingMetrics) return;

    setState(() {
      _loadingMetrics = true;
    });

    try {
      print(
        'Loading metrics data with PageSize=$pageSize for device: ${widget.device.id}',
      );

      final metricsResponse = await _deviceService.getDeviceMetrics(
        widget.device.id ?? '',
        startDate: _metricsStartDate.toIso8601String(),
        endDate: _metricsEndDate.toIso8601String(),
        pageSize: pageSize,
        currentPage: 1,
      );

      print(
        'Metrics response with PageSize=$pageSize: ${metricsResponse.success}',
      );

      if (metricsResponse.success) {
        final responseData = metricsResponse.data;

        // Parse the new API structure
        if (responseData != null && responseData['Result'] != null) {
          final List<dynamic> resultList =
              responseData['Result'] as List<dynamic>;
          _dynamicMetrics = resultList.cast<Map<String, dynamic>>();

          // Get pagination info
          final queryParam = responseData['QueryParam'];
          if (queryParam != null) {
            _totalMetricsCount = queryParam['RowCount'] ?? 0;
          } else {
            _totalMetricsCount = _dynamicMetrics.length;
          }

          print(
            'Dynamic metrics loaded with PageSize=$pageSize: ${_dynamicMetrics.length} items',
          );
          print('Total metrics count: $_totalMetricsCount');
        } else {
          _dynamicMetrics = [];
          _totalMetricsCount = 0;
        }

        setState(() {
          _loadingMetrics = false;
        });
      } else {
        setState(() {
          _loadingMetrics = false;
        });
        print(
          'Failed to load metrics with PageSize=$pageSize: ${metricsResponse.message}',
        );
      }
    } catch (e, stackTrace) {
      setState(() {
        _loadingMetrics = false;
      });
      print('Error loading metrics with PageSize=$pageSize: $e');
      print('Stack trace: $stackTrace');
    }
  }

  void _exportMetricsChart() {
    // TODO: Implement chart export functionality
    AppToast.showSuccess(context, message: 'Chart export feature coming soon');
  }

  String _formatFieldName(String fieldName) {
    // Convert camelCase or PascalCase to readable format
    return fieldName
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .trim()
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : '',
        )
        .join(' ');
  }

  Widget _buildMetricsSummaryCards() {
    if (_dynamicMetrics.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate summary statistics for selected chart fields
    Map<String, Map<String, double>> summaries = {};

    for (String field in _selectedChartFields) {
      List<double> values = [];
      for (var record in _dynamicMetrics) {
        if (record[field] != null && record[field] is num) {
          values.add(record[field].toDouble());
        }
      }

      if (values.isNotEmpty) {
        values.sort();
        summaries[field] = {
          'min': values.first,
          'max': values.last,
          'avg': values.reduce((a, b) => a + b) / values.length,
          'count': values.length.toDouble(),
        };
      }
    }

    if (summaries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Metrics Summary',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.spacing16),
        Wrap(
          spacing: AppSizes.spacing16,
          runSpacing: AppSizes.spacing16,
          children: summaries.entries.map((entry) {
            return _buildSummaryCard(entry.key, entry.value);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String fieldName, Map<String, double> stats) {
    return AppCard(
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatFieldName(fieldName),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.spacing12),
            _buildStatRow('Min', stats['min']!, AppColors.info),
            const SizedBox(height: AppSizes.spacing8),
            _buildStatRow('Max', stats['max']!, AppColors.error),
            const SizedBox(height: AppSizes.spacing8),
            _buildStatRow('Avg', stats['avg']!, AppColors.success),
            const SizedBox(height: AppSizes.spacing8),
            _buildStatRow('Count', stats['count']!, AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, double value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        Text(
          _formatMetricValue(value),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatMetricValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(2)}K';
    } else {
      return value.toStringAsFixed(2);
    }
  }

  Widget _buildEnergySummaryCards() {
    if (_analyticsMetrics.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate energy summary from metrics
    final powerMetrics = _analyticsMetrics
        .where((m) => m.metricType == 'Power')
        .toList();
    final totalConsumption = powerMetrics.fold<double>(
      0,
      (sum, metric) => sum + metric.value,
    );
    final avgConsumption = powerMetrics.isNotEmpty
        ? totalConsumption / powerMetrics.length
        : 0;
    final peakConsumption = powerMetrics.isNotEmpty
        ? powerMetrics.map((m) => m.value).reduce((a, b) => a > b ? a : b)
        : 0;

    return Row(
      children: [
        Expanded(
          child: _buildEnergySummaryCard(
            'Total Consumption',
            '${totalConsumption.toStringAsFixed(2)} kWh',
            Icons.bolt,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSizes.spacing16),
        Expanded(
          child: _buildEnergySummaryCard(
            'Average Power',
            '${avgConsumption.toStringAsFixed(2)} kW',
            Icons.trending_up,
            AppColors.success,
          ),
        ),
        const SizedBox(width: AppSizes.spacing16),
        Expanded(
          child: _buildEnergySummaryCard(
            'Peak Demand',
            '${peakConsumption.toStringAsFixed(2)} kW',
            Icons.flash_on,
            AppColors.warning,
          ),
        ),
        const SizedBox(width: AppSizes.spacing16),
        Expanded(
          child: _buildEnergySummaryCard(
            'Data Points',
            '${_analyticsMetrics.length}',
            Icons.data_usage,
            AppColors.info,
          ),
        ),
      ],
    );
  }

  Widget _buildEnergySummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppSizes.spacing8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainAnalyticsChart() {
    if (_isLoadingAnalytics) {
      return const SizedBox(
        height: 400,
        child: Center(
          child: AppLottieStateWidget.loading(
            title: 'Loading Analytics',
            message: 'Fetching real-time data...',
          ),
        ),
      );
    }

    if (_analyticsError != null) {
      return SizedBox(
        height: 400,
        child: Center(
          child: AppLottieStateWidget.error(
            title: 'Analytics Error',
            message: _analyticsError!,
          ),
        ),
      );
    }

    if (_analyticsMetrics.isEmpty) {
      return const SizedBox(
        height: 400,
        child: Center(
          child: AppLottieStateWidget.noData(
            title: 'No Analytics Data',
            message: 'No data available for the selected period',
          ),
        ),
      );
    }

    // Display charts as card grid for easier viewing
    return _buildChartsCardGrid();
  }

  Widget _buildChartsCardGrid() {
    if (_analyticsMetrics.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grid Header with Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Analytics Charts Grid',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Row(
              children: [
                // Date-Time Display
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacing12,
                    vertical: AppSizes.spacing6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSizes.spacing4),
                      Text(
                        _getDateTimeRangeDisplay(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.spacing8),
                // Hover Toggle
                Row(
                  children: [
                    Checkbox(
                      value: _showHover,
                      onChanged: (value) {
                        setState(() {
                          _showHover = value ?? true;
                        });
                      },
                    ),
                    const Text('Hover', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spacing16),

        // Grid of Charts
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSizes.spacing16,
            mainAxisSpacing: AppSizes.spacing16,
            childAspectRatio: 1.3, // Adjusted for better chart visibility
          ),
          itemCount: _selectedMetricTypes.length,
          itemBuilder: (context, index) {
            final metricType = _selectedMetricTypes[index];
            return _buildAnalyticsGridCard(metricType);
          },
        ),
      ],
    );
  }

  String _getDateTimeRangeDisplay() {
    if (_selectedDateRange == null) {
      return 'No date range selected';
    }

    final start = _selectedDateRange!.start;
    final end = _selectedDateRange!.end;

    // Format: "Jul 25, 10:30 - Jul 25, 14:30"
    final startFormatted =
        '${_getMonthAbbr(start.month)} ${start.day}, ${start.hour}:${start.minute.toString().padLeft(2, '0')}';
    final endFormatted =
        '${_getMonthAbbr(end.month)} ${end.day}, ${end.hour}:${end.minute.toString().padLeft(2, '0')}';

    return '$startFormatted - $endFormatted';
  }

  String _getMonthAbbr(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month];
  }

  Widget _buildAnalyticsGrid() {
    if (_analyticsMetrics.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grid Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Advanced Analytics Grid',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Row(
              children: [
                // Hover Toggle
                Row(
                  children: [
                    Checkbox(
                      value: _showHover,
                      onChanged: (value) {
                        setState(() {
                          _showHover = value ?? true;
                        });
                      },
                    ),
                    const Text('Show Hover', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spacing16),

        // Grid of Charts
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSizes.spacing16,
            mainAxisSpacing: AppSizes.spacing16,
            childAspectRatio: 1.2,
          ),
          itemCount: _selectedMetricTypes.length,
          itemBuilder: (context, index) {
            final metricType = _selectedMetricTypes[index];
            return _buildAnalyticsGridCard(metricType);
          },
        ),
      ],
    );
  }

  Widget _buildAnalyticsGridCard(String metricType) {
    // Filter metrics by type
    final metricsForType =
        _analyticsMetrics.where((m) => m.metricType == metricType).toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (metricsForType.isEmpty) {
      return AppCard(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 48,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: AppSizes.spacing8),
              Text(
                'No $metricType Data',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Group by phase
    final phaseData = <String, List<FlSpot>>{};
    final phaseColors = {
      'L1': AppColors.primary,
      'L2': AppColors.success,
      'L3': AppColors.warning,
    };

    // Get unique timestamps
    final uniqueTimestamps =
        metricsForType.map((m) => m.timestamp).toSet().toList()..sort();

    for (int i = 0; i < uniqueTimestamps.length; i++) {
      final timestamp = uniqueTimestamps[i];

      for (final phase in _selectedPhases) {
        if (!phaseData.containsKey(phase)) {
          phaseData[phase] = [];
        }

        final metric = metricsForType
            .where((m) => m.timestamp == timestamp && m.phase == phase)
            .firstOrNull;

        if (metric != null && _phaseVisibility[phase] == true) {
          phaseData[phase]!.add(FlSpot(i.toDouble(), metric.value));
        }
      }
    }

    // Calculate stats
    final allValues = metricsForType.map((m) => m.value).toList();
    final avgValue = allValues.isNotEmpty
        ? allValues.reduce((a, b) => a + b) / allValues.length
        : 0;
    final maxValue = allValues.isNotEmpty
        ? allValues.reduce((a, b) => a > b ? a : b)
        : 0;
    final minValue = allValues.isNotEmpty
        ? allValues.reduce((a, b) => a < b ? a : b)
        : 0;

    // Get unit
    final unit = metricsForType.isNotEmpty ? metricsForType.first.unit : '';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                metricType,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing8),

          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                'Avg',
                avgValue.toStringAsFixed(1),
                AppColors.info,
              ),
              _buildStatItem(
                'Max',
                maxValue.toStringAsFixed(1),
                AppColors.success,
              ),
              _buildStatItem(
                'Min',
                minValue.toStringAsFixed(1),
                AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing12),

          // Chart
          Expanded(
            child: _selectedChartType == ChartType.line
                ? _buildGridLineChart(phaseData, phaseColors)
                : _selectedChartType == ChartType.bar
                ? _buildGridBarChart(phaseData, phaseColors)
                : _buildGridAreaChart(phaseData, phaseColors),
          ),

          // Phase Legend
          const SizedBox(height: AppSizes.spacing8),
          _buildPhaseLegend(phaseColors),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildGridLineChart(
    Map<String, List<FlSpot>> phaseData,
    Map<String, Color> phaseColors,
  ) {
    // Get time labels for X-axis
    final metricsForCurrentType =
        _analyticsMetrics
            .where((m) => phaseData.keys.any((phase) => m.phase == phase))
            .toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final uniqueTimestamps =
        metricsForCurrentType.map((m) => m.timestamp).toSet().toList()..sort();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          drawHorizontalLine: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.border.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: AppColors.border.withOpacity(0.2),
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
              reservedSize: 32,
              interval: (uniqueTimestamps.length / 3).ceil().toDouble(),
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index >= 0 && index < uniqueTimestamps.length) {
                  final timestamp = uniqueTimestamps[index];
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
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
                    fontSize: 9,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: AppColors.border.withOpacity(0.3),
            width: 1,
          ),
        ),
        lineBarsData: phaseData.entries.map((entry) {
          final phase = entry.key;
          final spots = entry.value;
          final color = phaseColors[phase] ?? AppColors.primary;

          return LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: _showHover,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 2,
                  color: color,
                  strokeWidth: 0,
                );
              },
            ),
          );
        }).toList(),
        lineTouchData: LineTouchData(
          enabled: _showHover,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final index = barSpot.x.toInt();
                final timestamp = index < uniqueTimestamps.length
                    ? uniqueTimestamps[index]
                    : DateTime.now();
                return LineTooltipItem(
                  '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}\n${barSpot.y.toStringAsFixed(2)}',
                  const TextStyle(color: Colors.white, fontSize: 10),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGridBarChart(
    Map<String, List<FlSpot>> phaseData,
    Map<String, Color> phaseColors,
  ) {
    // Get time labels for X-axis
    final metricsForCurrentType =
        _analyticsMetrics
            .where((m) => phaseData.keys.any((phase) => m.phase == phase))
            .toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final uniqueTimestamps =
        metricsForCurrentType.map((m) => m.timestamp).toSet().toList()..sort();

    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          drawHorizontalLine: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.border.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: AppColors.border.withOpacity(0.2),
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
              reservedSize: 32,
              interval: (uniqueTimestamps.length / 3).ceil().toDouble(),
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index >= 0 && index < uniqueTimestamps.length) {
                  final timestamp = uniqueTimestamps[index];
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
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
                    fontSize: 9,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: AppColors.border.withOpacity(0.3),
            width: 1,
          ),
        ),
        barGroups: _buildBarGroups(phaseData, phaseColors),
        barTouchData: BarTouchData(
          enabled: _showHover,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final timestamp = groupIndex < uniqueTimestamps.length
                  ? uniqueTimestamps[groupIndex]
                  : DateTime.now();
              return BarTooltipItem(
                '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}\n${rod.toY.toStringAsFixed(2)}',
                const TextStyle(color: Colors.white, fontSize: 10),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGridAreaChart(
    Map<String, List<FlSpot>> phaseData,
    Map<String, Color> phaseColors,
  ) {
    // Get time labels for X-axis
    final metricsForCurrentType =
        _analyticsMetrics
            .where((m) => phaseData.keys.any((phase) => m.phase == phase))
            .toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final uniqueTimestamps =
        metricsForCurrentType.map((m) => m.timestamp).toSet().toList()..sort();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          drawHorizontalLine: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.border.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: AppColors.border.withOpacity(0.2),
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
              reservedSize: 32,
              interval: (uniqueTimestamps.length / 3).ceil().toDouble(),
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index >= 0 && index < uniqueTimestamps.length) {
                  final timestamp = uniqueTimestamps[index];
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
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
                    fontSize: 9,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: AppColors.border.withOpacity(0.3),
            width: 1,
          ),
        ),
        lineBarsData: phaseData.entries.map((entry) {
          final phase = entry.key;
          final spots = entry.value;
          final color = phaseColors[phase] ?? AppColors.primary;

          return LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 1,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [color.withOpacity(0.4), color.withOpacity(0.1)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          );
        }).toList(),
        lineTouchData: LineTouchData(
          enabled: _showHover,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final index = barSpot.x.toInt();
                final timestamp = index < uniqueTimestamps.length
                    ? uniqueTimestamps[index]
                    : DateTime.now();
                return LineTooltipItem(
                  '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}\n${barSpot.y.toStringAsFixed(2)}',
                  const TextStyle(color: Colors.white, fontSize: 10),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(
    Map<String, List<FlSpot>> phaseData,
    Map<String, Color> phaseColors,
  ) {
    final groups = <BarChartGroupData>[];
    final maxDataPoints = phaseData.values.isNotEmpty
        ? phaseData.values
              .map((spots) => spots.length)
              .reduce((a, b) => a > b ? a : b)
        : 0;

    for (int i = 0; i < maxDataPoints; i++) {
      final rods = <BarChartRodData>[];

      for (final entry in phaseData.entries) {
        final phase = entry.key;
        final spots = entry.value;
        final color = phaseColors[phase] ?? AppColors.primary;

        if (i < spots.length) {
          rods.add(
            BarChartRodData(
              toY: spots[i].y,
              color: color,
              width: 8,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(2),
                topRight: Radius.circular(2),
              ),
            ),
          );
        }
      }

      if (rods.isNotEmpty) {
        groups.add(BarChartGroupData(x: i, barRods: rods, barsSpace: 2));
      }
    }

    return groups;
  }

  Widget _buildPhaseLegend(Map<String, Color> phaseColors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: phaseColors.entries
          .where(
            (entry) =>
                _selectedPhases.contains(entry.key) &&
                _phaseVisibility[entry.key] == true,
          )
          .map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: entry.value,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          })
          .toList(),
    );
  }

  Widget _buildMetricsTableWithPagination() {
    if (_dynamicMetrics.isEmpty) {
      return AppLottieStateWidget.noData(
        title: 'No Metrics Data',
        message: 'No metrics data available for this device.',
        titleColor: AppColors.primary,
        messageColor: AppColors.secondary,
      );
    }

    // Calculate pagination
    final totalItems = _totalMetricsCount;
    final totalPages = (totalItems / _metricsItemsPerPage).ceil();

    return Column(
      children: [
        // Metrics controls and summary
        // Container(
        //   padding: const EdgeInsets.all(16),
        //   margin: const EdgeInsets.only(bottom: 16),
        //   decoration: BoxDecoration(
        //     color: Colors.white,
        //     borderRadius: BorderRadius.circular(12),
        //     boxShadow: [
        //       BoxShadow(
        //         color: Colors.black.withOpacity(0.04),
        //         blurRadius: 8,
        //         offset: const Offset(0, 2),
        //       ),
        //     ],
        //   ),

        // ),

        // Dynamic table with standard styling (consistent with other tables)
        Expanded(
          child: GestureDetector(
            onPanUpdate: (details) {
              // Enable drag-to-scroll horizontally
              _metricsTableScrollController.position.moveTo(
                _metricsTableScrollController.offset - details.delta.dx,
              );
            },
            child: SingleChildScrollView(
              controller: _metricsTableScrollController,
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width,
                  maxWidth: MediaQuery.of(context).size.width * 2.0,
                ),
                child: BluNestDataTable<Map<String, dynamic>>(
                  data: _dynamicMetrics,
                  columns: DynamicMetricsTableColumns.generateColumns(
                    metrics: _dynamicMetrics,
                    currentPage: _metricsCurrentPage,
                    itemsPerPage: _metricsItemsPerPage,
                    hiddenColumns: _hiddenMetricsColumns,
                  ),
                  selectedItems: _selectedMetrics,
                  onSelectionChanged: (selected) {
                    setState(() {
                      _selectedMetrics = selected;
                    });
                  },
                  sortBy: _metricsSortBy,
                  sortAscending: _metricsSortAscending,
                  onSort: _handleMetricsSort,
                  enableMultiSelect:
                      true, // Enable multi-select like other tables
                  hiddenColumns: _hiddenMetricsColumns,
                  onColumnVisibilityChanged: (hiddenColumns) {
                    setState(() {
                      _hiddenMetricsColumns = hiddenColumns;
                    });
                  },
                ), // BluNestDataTable
              ), // ConstrainedBox
            ), // SingleChildScrollView
          ), // GestureDetector
        ), // Expanded
        // Pagination controls
        Container(
          padding: const EdgeInsets.only(top: 16),
          child: _buildMetricsPagination(totalPages, totalItems),
        ),
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
        _loadMetricsData(); // Reload data for new page
      },
      onItemsPerPageChanged: (newItemsPerPage) {
        setState(() {
          _metricsItemsPerPage = newItemsPerPage;
          _metricsCurrentPage = 1; // Reset to first page
        });
        _loadMetricsData(); // Reload data with new page size
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
      return const Center(child: AppLottieStateWidget.loading(lottieSize: 80));
    }

    return Column(
      children: [
        // Sticky header
        Container(
          padding: const EdgeInsets.all(AppSizes.spacing16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFE1E5E9), width: 1),
            ),
          ),
          child: Row(
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
        ),
        // Scrollable content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.spacing16),
            child: _deviceBilling != null
                ? _buildBillingDataTable()
                : AppLottieStateWidget.noData(title: 'No Billing Data'),
          ),
        ),
      ],
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
        // Table using BluNestDataTable with sticky headers
        Expanded(
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

        // Pagination controls
        Container(
          padding: const EdgeInsets.only(top: AppSizes.spacing16),
          child: _buildBillingPagination(totalPages, totalItems),
        ),
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
          lottieSize: 80,
          titleColor: AppColors.primary,
        ),
      );
    }

    return Column(
      children: [
        // Sticky header
        Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.all(AppSizes.spacing16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFE1E5E9), width: 1),
            ),
          ),
          child: const Text(
            'Device Location',
            style: TextStyle(
              fontSize: AppSizes.fontSizeLarge,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1e293b),
            ),
          ),
        ),
        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
            child: DeviceLocationViewer(
              address: widget.device.address,
              addressText: widget.device.addressText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSchedulesTab() {
    // Show loading state for schedules tab
    if (_isSchedulesLoading) {
      return AppLottieStateWidget.loading(lottieSize: 80);
    }

    // Show error state for schedules tab
    if (_schedulesError != null) {
      return AppLottieStateWidget.error(
        title: 'Failed to Load Schedules',
        message: _schedulesError!,
        buttonText: 'Retry',
        onButtonPressed: _refreshSchedules,
      );
    }

    return Column(
      children: [
        // Summary card with padding (same style as device group details)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
          child: ScheduleSummaryCard(schedules: _filteredSchedules),
        ),

        const SizedBox(height: AppSizes.spacing8),

        // Filters and actions with padding (same style as device group details)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
          child: ScheduleFiltersAndActionsV2(
            onSearchChanged: _onScheduleSearchChanged,
            onStatusFilterChanged: _onScheduleStatusFilterChanged,
            onTargetTypeFilterChanged: _onScheduleTargetTypeFilterChanged,
            onViewModeChanged: _onScheduleViewModeChanged,
            onAddSchedule: _showCreateScheduleDialog,
            onRefresh: _refreshSchedules,
            onExport: _exportSchedules,
            onImport: _importSchedules,
            currentViewMode: _scheduleViewMode,
            selectedStatus: _selectedScheduleStatus,
            selectedTargetType: _selectedScheduleTargetType,
          ),
        ),

        const SizedBox(height: AppSizes.spacing8),

        // Content based on view mode
        Expanded(child: _buildScheduleContent()),
      ],
    );
  }

  void _onScheduleSearchChanged(String value) {
    // Cancel the previous timer
    _schedulesDebounceTimer?.cancel();

    // Set a new timer
    _schedulesDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _schedulesSearchQuery = value;
        _filteredSchedules = _applyScheduleFilters(_allSchedules);
        _schedulesCurrentPage = 1;
        _updateSchedulePaginationTotals();
      });
    });
  }

  void _onScheduleStatusFilterChanged(String? status) {
    setState(() {
      _selectedScheduleStatus = status;
      _filteredSchedules = _applyScheduleFilters(_allSchedules);
      _schedulesCurrentPage = 1;
      _updateSchedulePaginationTotals();
    });
  }

  void _onScheduleTargetTypeFilterChanged(String? targetType) {
    setState(() {
      _selectedScheduleTargetType = targetType;
      _filteredSchedules = _applyScheduleFilters(_allSchedules);
      _schedulesCurrentPage = 1;
      _updateSchedulePaginationTotals();
    });
  }

  void _onScheduleViewModeChanged(ScheduleViewMode mode) {
    setState(() {
      _scheduleViewMode = mode;
    });
  }

  Widget _buildScheduleContent() {
    // Show no data state if no schedules (loading is handled at tab level)
    if (_allSchedules.isEmpty) {
      return AppLottieStateWidget.noData(
        title: 'No Schedules Found',
        message: 'This device has no scheduled tasks configured.',
        buttonText: 'Create Schedule',
        titleColor: AppColors.primary,
        messageColor: AppColors.secondary,
        onButtonPressed: _showCreateScheduleDialog,
      );
    }

    // Show filtered empty state if filtered schedules are empty but original schedules exist
    if (_filteredSchedules.isEmpty && _allSchedules.isNotEmpty) {
      return AppLottieStateWidget.noData(
        title: 'No Matching Schedules',
        message:
            'No schedules match your current filters. Try adjusting your search criteria.',
        buttonText: 'Clear Filters',
        onButtonPressed: _clearScheduleFilters,
      );
    }

    // Build content based on view mode
    return switch (_scheduleViewMode) {
      ScheduleViewMode.table => _buildScheduleTableView(),
      ScheduleViewMode.kanban => _buildScheduleKanbanView(),
    };
  }

  Widget _buildScheduleTableView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
      child: _buildScheduleTable(),
    );
  }

  Widget _buildScheduleKanbanView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
      child: ScheduleKanbanView(
        schedules: _filteredSchedules,
        onScheduleSelected: _showViewScheduleDialog,
        onScheduleView: _showViewScheduleDialog,
        onScheduleEdit: (schedule) => _canEditSchedule(schedule)
            ? _showEditScheduleDialog(schedule)
            : null,
        onScheduleDelete: (schedule) => _canEditSchedule(schedule)
            ? _showDeleteScheduleDialog(schedule)
            : null,
        isLoading: false,
        enablePagination: false,
        itemsPerPage: _filteredSchedules.length,
      ),
    );
  }

  Widget _buildScheduleTable() {
    return BluNestDataTable<Schedule>(
      columns: ScheduleTableColumns.getBluNestColumns(
        onView: (schedule) => _showViewScheduleDialog(schedule),
        onEdit: (schedule) => _canEditSchedule(schedule)
            ? _showEditScheduleDialog(schedule)
            : null,
        onDelete: (schedule) => _canEditSchedule(schedule)
            ? _showDeleteScheduleDialog(schedule)
            : null,
        currentPage: 1,
        itemsPerPage: _filteredSchedules.length,
        schedules: _filteredSchedules,
      ),
      data: _filteredSchedules,
      onRowTap: (schedule) => _showViewScheduleDialog(schedule),
      onEdit: (schedule) =>
          _canEditSchedule(schedule) ? _showEditScheduleDialog(schedule) : null,
      onDelete: (schedule) => _canEditSchedule(schedule)
          ? _showDeleteScheduleDialog(schedule)
          : null,
      onView: (schedule) => _showViewScheduleDialog(schedule),
      enableMultiSelect: true,
      selectedItems: _selectedSchedules,
      onSelectionChanged: (selectedItems) {
        setState(() {
          _selectedSchedules = selectedItems;
        });
      },
      hiddenColumns: _schedulesHiddenColumns,
      onColumnVisibilityChanged: (hiddenColumns) {
        setState(() {
          _schedulesHiddenColumns = hiddenColumns;
        });
      },
      sortBy: _schedulesSortBy,
      sortAscending: _schedulesSortAscending,
      onSort: _handleScheduleSort,
      isLoading: false,
      totalItemsCount: _filteredSchedules.length,
      onSelectAllItems: () async => _filteredSchedules,
    );
  }

  // Helper method to determine if a schedule can be edited (only device schedules, not group schedules)
  bool _canEditSchedule(Schedule schedule) {
    // If Target Type is 'Group', it's view-only
    return schedule.displayTargetType != 'Group';
  }

  void _clearScheduleFilters() {
    setState(() {
      _selectedScheduleStatus = null;
      _selectedScheduleTargetType = null;
      _schedulesSearchQuery = '';
      _filteredSchedules = List.from(_allSchedules);
    });
  }

  void _handleScheduleSort(String columnKey, bool ascending) {
    setState(() {
      _schedulesSortBy = columnKey;
      _schedulesSortAscending = ascending;
      _sortSchedules();
    });
  }

  void _sortSchedules() {
    if (_schedulesSortBy == null) return;

    _filteredSchedules.sort((a, b) {
      dynamic aValue;
      dynamic bValue;

      switch (_schedulesSortBy) {
        case 'code':
          aValue = a.displayCode.toLowerCase();
          bValue = b.displayCode.toLowerCase();
          break;
        case 'name':
          aValue = a.displayName.toLowerCase();
          bValue = b.displayName.toLowerCase();
          break;
        case 'targetType':
          aValue = a.displayTargetType.toLowerCase();
          bValue = b.displayTargetType.toLowerCase();
          break;
        case 'status':
          aValue = a.displayStatus.toLowerCase();
          bValue = b.displayStatus.toLowerCase();
          break;
        case 'interval':
          aValue = a.displayInterval.toLowerCase();
          bValue = b.displayInterval.toLowerCase();
          break;
        default:
          return 0;
      }

      int comparison = aValue.toString().compareTo(bValue.toString());
      return _schedulesSortAscending ? comparison : -comparison;
    });
  }

  Future<void> _refreshSchedules() async {
    setState(() {
      _schedulesLoaded = false;
      _deviceSchedules.clear();
      _deviceGroupSchedules.clear();
      _allSchedules.clear();
      _filteredSchedules.clear();
      _schedulesError = null;
    });
    await _loadSchedulesData();
  }

  void _showCreateScheduleDialog() {
    showDialog(
      context: context,
      builder: (context) => ScheduleFormDialog(
        preselectedTargetType: 'Device',
        preselectedDeviceId: widget.device.id,
        onSuccess: () {
          _refreshSchedules();
          AppToast.showSuccess(
            context,
            message: 'Schedule created successfully',
          );
        },
      ),
    );
  }

  void _exportSchedules() {
    AppToast.showInfo(
      context,
      title: 'Export',
      message: 'Export functionality coming soon',
    );
  }

  void _importSchedules() {
    AppToast.showInfo(
      context,
      title: 'Import',
      message: 'Import functionality coming soon',
    );
  }

  void _showViewScheduleDialog(Schedule schedule) {
    showDialog(
      context: context,
      builder: (context) => ScheduleFormDialog(
        schedule: schedule,
        mode: 'view',
        onSuccess: () {
          _refreshSchedules();
          AppToast.showSuccess(
            context,
            message: 'Schedule updated successfully',
          );
        },
      ),
    );
  }

  void _showEditScheduleDialog(Schedule schedule) {
    showDialog(
      context: context,
      builder: (context) => ScheduleFormDialog(
        schedule: schedule,
        onSuccess: () {
          _refreshSchedules();
          AppToast.showSuccess(
            context,
            message: 'Schedule updated successfully',
          );
        },
      ),
    );
  }

  Future<void> _showDeleteScheduleDialog(Schedule schedule) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Delete Schedule',
      message:
          'Are you sure you want to delete schedule "${schedule.displayName}"? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      confirmType: AppButtonType.danger,
      icon: Icons.delete_outline,
    );

    if (confirmed == true && mounted) {
      await _deleteSchedule(schedule);
    }
  }

  Future<void> _deleteSchedule(Schedule schedule) async {
    try {
      await _scheduleService.deleteSchedule(
        schedule.billingDevice!.id!.toLowerCase(),
      );

      if (mounted) {
        AppToast.showSuccess(
          context,
          title: 'Schedule Deleted',
          message:
              'Schedule "${schedule.displayName}" has been successfully deleted.',
        );

        await _refreshSchedules();
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(
          context,
          error: e,
          title: 'Delete Failed',
          errorContext: 'schedule_delete',
        );
      }
    }
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
      // For dynamic metrics, we might need to reload data with sorting
      // Or implement client-side sorting if all data is loaded
    });
  }

  // Helper methods for filter tooltips
  Map<String, double> _getPhaseCurrentValue(String phase) {
    final phaseMetrics = _analyticsMetrics
        .where((m) => m.phase == phase)
        .toList();

    if (phaseMetrics.isEmpty) {
      return {'voltage': 0.0, 'current': 0.0, 'power': 0.0};
    }

    // Get latest values for each metric type
    final voltageMetrics = phaseMetrics
        .where((m) => m.metricType == 'Voltage')
        .toList();
    final currentMetrics = phaseMetrics
        .where((m) => m.metricType == 'Current')
        .toList();
    final powerMetrics = phaseMetrics
        .where((m) => m.metricType == 'Power')
        .toList();

    voltageMetrics.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    currentMetrics.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    powerMetrics.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return {
      'voltage': voltageMetrics.isNotEmpty ? voltageMetrics.first.value : 0.0,
      'current': currentMetrics.isNotEmpty ? currentMetrics.first.value : 0.0,
      'power': powerMetrics.isNotEmpty ? powerMetrics.first.value : 0.0,
    };
  }

  Map<String, double> _getMetricCurrentValue(String metricType) {
    final typeMetrics = _analyticsMetrics
        .where((m) => m.metricType == metricType)
        .toList();

    if (typeMetrics.isEmpty) {
      return {'L1': 0.0, 'L2': 0.0, 'L3': 0.0};
    }

    // Get latest values for each phase
    final l1Metrics = typeMetrics.where((m) => m.phase == 'L1').toList();
    final l2Metrics = typeMetrics.where((m) => m.phase == 'L2').toList();
    final l3Metrics = typeMetrics.where((m) => m.phase == 'L3').toList();

    l1Metrics.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    l2Metrics.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    l3Metrics.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return {
      'L1': l1Metrics.isNotEmpty ? l1Metrics.first.value : 0.0,
      'L2': l2Metrics.isNotEmpty ? l2Metrics.first.value : 0.0,
      'L3': l3Metrics.isNotEmpty ? l3Metrics.first.value : 0.0,
    };
  }

  String _buildPhaseTooltipMessage(String phase, Map<String, double> values) {
    return '$phase Phase Current Values:\n'
        'Voltage: ${values['voltage']?.toStringAsFixed(2) ?? 'N/A'} V\n'
        'Current: ${values['current']?.toStringAsFixed(2) ?? 'N/A'} A\n'
        'Power: ${values['power']?.toStringAsFixed(2) ?? 'N/A'} W';
  }

  String _buildMetricTooltipMessage(
    String metricType,
    Map<String, double> values,
  ) {
    final unit = _getMetricUnit(metricType);
    return '$metricType Current Values:\n'
        'L1: ${values['L1']?.toStringAsFixed(2) ?? 'N/A'} $unit\n'
        'L2: ${values['L2']?.toStringAsFixed(2) ?? 'N/A'} $unit\n'
        'L3: ${values['L3']?.toStringAsFixed(2) ?? 'N/A'} $unit';
  }

  String _getMetricUnit(String metricType) {
    switch (metricType.toLowerCase()) {
      case 'voltage':
        return 'V';
      case 'current':
        return 'A';
      case 'power':
        return 'W';
      default:
        return '';
    }
  }

  // Get unique device groups to prevent dropdown duplicates
  List<DeviceGroup> _getUniqueDeviceGroups() {
    final seen = <int>{};
    return _deviceGroups.where((group) {
      if (seen.contains(group.id)) {
        if (kDebugMode) {
          print(
            'Duplicate device group found with ID: ${group.id}, Name: ${group.name}',
          );
        }
        return false;
      }
      seen.add(group.id ?? 0);
      return true;
    }).toList();
  }

  // Validate and get a safe device group value for the dropdown
  int? _getSafeDeviceGroupValue() {
    if (_selectedDeviceGroupIdEdit == null) return null;

    final uniqueGroups = _getUniqueDeviceGroups();

    // If groups are still loading, keep the selected value
    if (uniqueGroups.isEmpty && _isLoadingDeviceGroups) {
      return _selectedDeviceGroupIdEdit;
    }

    final groupExists = uniqueGroups.any(
      (group) => group.id == _selectedDeviceGroupIdEdit,
    );

    if (!groupExists) {
      if (kDebugMode) {
        print(
          'Selected device group ID $_selectedDeviceGroupIdEdit not found in dropdown (groups loaded: ${uniqueGroups.length})',
        );
      }
      // Only reset if we're sure the groups have been loaded
      if (!_isLoadingDeviceGroups && uniqueGroups.isNotEmpty) {
        _selectedDeviceGroupIdEdit = null;
        return null;
      }
      // Otherwise, keep the value while loading
      return _selectedDeviceGroupIdEdit;
    }

    return _selectedDeviceGroupIdEdit;
  }
}
