import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mdms_clone/core/utils/format_date_helper.dart';
import '../../widgets/common/app_tabs.dart';
import '../../widgets/common/status_chip.dart';
import 'package:provider/provider.dart';
import 'dart:async';
// import '../../../core/constants/app_colors.dart';
import '../../themes/app_theme.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/device.dart';
import '../../../core/models/device_group.dart';
import '../../../core/models/address.dart';
import '../../../core/models/schedule.dart';
import '../../../core/services/device_service.dart';
import '../../../core/services/schedule_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/utils/responsive_helper.dart';
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
import 'create_edit_device_screen.dart';

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

class _Device360DetailsScreenState extends State<Device360DetailsScreen>
    with ResponsiveMixin {
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

  // Responsive UI state for schedules
  bool _scheduleSummaryCardCollapsed = false;
  bool _isScheduleKanbanView = false;
  ScheduleViewMode?
  _previousScheduleViewModeBeforeMobile; // Track previous view mode before mobile switch
  bool?
  _previousScheduleSummaryStateBeforeMobile; // Track previous summary state before mobile switch

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

  @override
  void handleResponsiveStateChange() {
    if (!mounted) return;

    final mediaQuery = MediaQuery.of(context);
    final isMobile = mediaQuery.size.width < 768;
    final isTablet =
        mediaQuery.size.width >= 768 && mediaQuery.size.width < 1024;

    // Handle schedules summary card responsive behavior
    if (isMobile &&
        !_scheduleSummaryCardCollapsed &&
        _previousScheduleSummaryStateBeforeMobile == null) {
      // Save previous summary state before collapsing for mobile
      _previousScheduleSummaryStateBeforeMobile = _scheduleSummaryCardCollapsed;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _scheduleSummaryCardCollapsed =
                true; // Default to collapsed on mobile
          });
          print('📱 Auto-collapsed schedule summary card for mobile');
        }
      });
    }

    // Auto-expand summary card on desktop - restore previous state
    if (!isMobile &&
        !isTablet &&
        _previousScheduleSummaryStateBeforeMobile != null) {
      final shouldExpand = _previousScheduleSummaryStateBeforeMobile == false;
      if (shouldExpand) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _scheduleSummaryCardCollapsed = false;
              _previousScheduleSummaryStateBeforeMobile =
                  null; // Reset tracking
            });
            print('📱 Auto-expanded schedule summary card for desktop');
          }
        });
      }
    }

    // Auto-switch to kanban view on mobile for schedules
    if (isMobile && !_isScheduleKanbanView) {
      // Save previous view mode before switching to mobile kanban
      if (_previousScheduleViewModeBeforeMobile == null) {
        _previousScheduleViewModeBeforeMobile = _scheduleViewMode;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isScheduleKanbanView = true;
            _scheduleViewMode = ScheduleViewMode.kanban;
          });
        }
      });
    }

    // Auto-switch back to previous view mode on desktop
    if (!isMobile &&
        _isScheduleKanbanView &&
        _previousScheduleViewModeBeforeMobile != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isScheduleKanbanView = false;
            _scheduleViewMode = _previousScheduleViewModeBeforeMobile!;
            _previousScheduleViewModeBeforeMobile = null; // Reset tracking
          });
        }
      });
    }

    print(
      '📱 Device360DetailsScreen: Responsive state updated (mobile: $isMobile, kanban: $_isScheduleKanbanView, view: $_scheduleViewMode) - UI ONLY, no API calls',
    );
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
          // _loadAnalyticsData(); // Load analytics data when metrics tab is opened
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
  // Cancel editing overview
  void _cancelEditingOverview() {
    setState(() {
      _isEditingOverview = false;
      _savingOverview = false;
    });
    _clearEditFields();
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
        search: _schedulesSearchQuery.isNotEmpty ? _schedulesSearchQuery : null,
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
              style: TextStyle(fontSize: AppSizes.fontSizeSmall),
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
      DropdownMenuItem<int?>(
        value: null,
        child: Text(
          'None',
          style: TextStyle(
            fontSize: AppSizes.fontSizeSmall,
            color: context.textPrimaryColor,
          ),
        ),
      ),
      ..._schedules.map(
        (schedule) => DropdownMenuItem<int?>(
          value: schedule.id,
          child: Text(
            schedule.name ?? 'Unnamed Schedule',
            style: TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              color: context.textPrimaryColor,
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
          child: Text(type, style: TextStyle(fontSize: AppSizes.fontSizeSmall)),
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
            style: TextStyle(fontSize: AppSizes.fontSizeSmall),
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
            style: TextStyle(fontSize: AppSizes.fontSizeSmall),
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
        context: context,
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

  // Open edit device dialog
  void _openEditDeviceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CreateEditDeviceDialog(
        device: _currentDevice,
        presetDeviceGroupId: _currentDevice.deviceGroupId != 0
            ? _currentDevice.deviceGroupId
            : null,
        onSaved: () {
          // Refresh device data after edit
          _refreshOverviewData();
        },
      ),
    );
  }

  // Refresh overview data after device edit
  Future<void> _refreshOverviewData() async {
    setState(() {
      _overviewLoaded = false;
      _deviceDetails = null;
      _isLoading = true;
      _error = null;
    });

    try {
      // Reload the device from API to get fresh data
      final deviceResponse = await _deviceService.getDeviceById(
        widget.device.id ?? '',
      );

      if (deviceResponse.success && deviceResponse.data != null) {
        // Update the device details
        _deviceDetails = deviceResponse.data;

        // Update the widget's device object with fresh data
        // Note: Since widget.device is final, we update _deviceDetails and use it for display
        setState(() {
          _overviewLoaded = true;
          _isLoading = false;
        });

        print('Device data refreshed successfully');
      } else {
        setState(() {
          _error = 'Failed to refresh device data: ${deviceResponse.message}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error refreshing device data: $e';
        _isLoading = false;
      });
      print('Error refreshing device data: $e');
    }
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
      final startDateStr = formatStartOfDay(_metricsStartDate);
      final endDateStr = formatEndOfDay(_metricsEndDate);
      print('Loading metrics data for device: ${widget.device.id}');
      print(
        'Date rangenew: ${startDateStr} to ${endDateStr}',
      );

      final metricsResponse = await _deviceService.getDeviceMetrics(
        widget.device.id ?? '',
        startDate: startDateStr,
        endDate: endDateStr,
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
        final startDateStr = formatStartOfDay(_metricsStartDate);
    final endDateStr = formatEndOfDay(_metricsEndDate);
      print(
        'Loading metrics data for graphs (PageSize=0) for device: ${widget.device.id}',
      );
      print(
        'Date rangeGraphs: ${startDateStr} to ${endDateStr}',
      );

      final metricsResponse = await _deviceService.getDeviceMetrics(
        widget.device.id ?? '',
        startDate: startDateStr,
        endDate: endDateStr,
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
  // Future<void> _loadAnalyticsData() async {
  //   if (_isLoadingAnalytics) return;

  //   setState(() {
  //     _isLoadingAnalytics = true;
  //     _analyticsError = null;
  //   });

  //   try {
  //     final startDate =
  //         _selectedDateRange?.start ??
  //         DateTime.now().subtract(const Duration(days: 7));
  //     final endDate = _selectedDateRange?.end ?? DateTime.now();

  //     final response = await _deviceService.getDeviceLoadProfile(
  //       deviceId: widget.device.id ?? '',
  //       startDate: startDate,
  //       endDate: endDate,
  //       phases: _selectedPhases,
  //       metricTypes: _selectedMetricTypes,
  //       limit: 1000,
  //     );

  //     if (response.success && response.data != null) {
  //       setState(() {
  //         _analyticsMetrics = response.data!;
  //         _isLoadingAnalytics = false;
  //       });
  //     } else {
  //       setState(() {
  //         _analyticsError = response.message ?? 'Failed to load analytics data';
  //         _isLoadingAnalytics = false;
  //       });
  //     }
  //   } catch (e) {
  //     setState(() {
  //       _analyticsError = 'Error loading analytics data: $e';
  //       _isLoadingAnalytics = false;
  //     });
  //   }
  // }

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
          decoration: BoxDecoration(
            color: context.surfaceColor,
            border: Border(
              bottom: BorderSide(color: context.borderColor, width: 1),
            ),
          ),
          child: Row(
            children: [
              // if (widget.onBack != null) ...[
              //   IconButton(
              //     icon: const Icon(Icons.arrow_back),
              //     onPressed: widget.onBack,
              //     tooltip: 'Back',
              //   ),
              //   const SizedBox(width: 16),
              // ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: widget.onBack,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // if (widget.onBack != null) ...[
                            //   Icon(
                            //     Icons.arrow_back,
                            //     size: AppSizes.iconMedium,
                            //     color: const Color(0xFF1e293b),
                            //   ),
                            //   const SizedBox(width: AppSizes.spacing8),
                            // ស],
                            Text(
                              'Device 360°',
                              style: TextStyle(
                                fontSize: AppSizes.fontSizeXLarge,
                                fontWeight: FontWeight.w600,
                                color: context.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // const SizedBox(height: 4),
                    // Text(
                    //   'Serial: ${widget.device.serialNumber}',
                    //   style: TextStyle(
                    //     fontSize: 16,
                    //     color: Color(0xFF64748b),
                    //   ),
                    // ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      // crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StatusChip(
                          text: widget.device.status,
                          type: widget.device.status == 'Commissioned'
                              ? StatusChipType.success
                              : widget.device.status == 'Discommissioned'
                              ? StatusChipType.construction
                              : widget.device.status == 'None'
                              ? StatusChipType.none
                              : StatusChipType.none,
                          compact: true,
                        ),
                        const SizedBox(width: AppSizes.spacing4),
                        StatusChip(
                          text: widget.device.linkStatus,
                          compact: true,
                          type: widget.device.linkStatus == 'MULTIDRIVE'
                              ? StatusChipType.commissioned
                              : widget.device.linkStatus == 'E-POWER'
                              ? StatusChipType.warning
                              : widget.device.linkStatus == 'None'
                              ? StatusChipType.none
                              : StatusChipType.none,
                        ),
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
              ? Center(
                  child: AppLottieStateWidget.loading(
                    title: 'Loading Device Details',
                    message: 'Please wait while we fetch device details.',
                    lottieSize: 80,
                    titleColor: context.primaryColor,
                    messageColor: context.secondaryColor,
                  ),
                )
              : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: context.errorColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(
                          fontSize: 16,
                          color: context.errorColor,
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
                        child: Text('Retry'),
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
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    // Get current device status (refreshed or original)
    final currentStatus = _currentDevice.status;

    // Determine commission button based on status
    bool showCommission = currentStatus != 'Commissioned';
    bool showDecommission = currentStatus == 'Commissioned';

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
            backgroundColor: context.successColor.withOpacity(0.1),
            foregroundColor: context.successColor,
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
            backgroundColor: context.primaryColor.withOpacity(0.1),
            foregroundColor: context.primaryColor,
          ),
        ),
        const SizedBox(width: 8),

        // Commission/Decommission Device - Dynamic based on status
        if (showCommission)
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
              backgroundColor: context.warningColor.withOpacity(0.1),
              foregroundColor: context.warningColor,
            ),
          ),
        if (showDecommission)
          IconButton(
            padding: const EdgeInsets.all(AppSizes.spacing8),
            constraints: const BoxConstraints(
              minWidth: AppSizes.spacing32,
              minHeight: AppSizes.spacing32,
            ),
            iconSize: AppSizes.iconSmall,
            onPressed: () => _performDeviceAction('decommission'),
            icon: const Icon(Icons.cancel),
            tooltip: 'Decommission Device',
            style: IconButton.styleFrom(
              backgroundColor: context.errorColor.withOpacity(0.1),
              foregroundColor: context.errorColor,
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
      case 'decommission':
        await _decommissionDevice();
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
      confirmColor: context.warningColor,
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
            error: 'Error commissioning device: $e',
          );
        }
      }
    }
  }

  Future<void> _decommissionDevice() async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Decommission Device',
      message:
          'Are you sure you want to decommission device ${widget.device.serialNumber}?\n\nThis action will make the device inactive and not ready for operation.',
      confirmText: 'Decommission',
      confirmColor: context.errorColor,
    );

    if (confirmed == true) {
      try {
        final response = await _deviceService.decommissionDevice(
          widget.device.id ?? '',
        );

        if (response.success && mounted) {
          AppToast.showSuccess(
            context,
            title: 'Decommission Success',
            message: 'Device decommissioned successfully',
          );
          // Refresh device data
          await _refreshCurrentTabData();
        } else if (mounted) {
          AppToast.showError(
            context,
            title: 'Decommission Failed',
            error: 'Failed to decommission device: ${response.message}',
          );
        }
      } catch (e) {
        if (mounted) {
          AppToast.showError(
            context,
            title: 'Error',
            error: 'Error decommissioning device: $e',
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
      return Center(
        child: AppLottieStateWidget.loading(
          title: 'Loading Overview',
          message: 'Loading device overview...',
          lottieSize: 80,
          titleColor: context.primaryColor,
          messageColor: context.secondaryColor,
        ),
      );
    }

    return Column(
      children: [
        // Sticky header
        Container(
          padding: const EdgeInsets.all(AppSizes.spacing16),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            border: Border(
              bottom: BorderSide(color: context.borderColor, width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Device Overview',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeLarge,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimaryColor,
                ),
              ),
              if (!_isEditingOverview)
                AppButton(
                  text: 'Edit Device',
                  type: AppButtonType.outline,
                  size: AppButtonSize.small,
                  onPressed: _openEditDeviceDialog,
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

  // Helper method to get current device data (refreshed or original)
  Device get _currentDevice => _deviceDetails ?? widget.device;

  Widget _buildOverviewViewMode() {
    if (kDebugMode) {
      print(
        'Building overview view mode for device: ${_currentDevice.deviceGroup?.toJson()}',
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
                      color: context.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'General Information',
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeMedium,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.spacing16),
                _buildInfoRow(
                  'Serial Number',
                  _currentDevice.serialNumber,
                  icon: Icons.qr_code,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Device Type',
                  _currentDevice.deviceType.isEmpty
                      ? 'Not specified'
                      : _currentDevice.deviceType,
                  icon: Icons.category,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Model',
                  _currentDevice.model.isEmpty
                      ? 'Not specified'
                      : _currentDevice.model,
                  icon: Icons.memory,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Manufacturer',
                  _currentDevice.manufacturer.isEmpty
                      ? 'Not specified'
                      : _currentDevice.manufacturer,
                  icon: Icons.business,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Device Group',
                  _currentDevice.deviceGroup?.name ?? 'None',
                  // _currentDevice.deviceGroupId.toString() == '0'
                  //     ? 'None'
                  //     : _getDeviceGroupName(),
                  icon: Icons.group_work,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.spacing16),

          // Location Information Card with Map View
          if (_currentDevice.address != null ||
              _currentDevice.addressText.isNotEmpty)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: AppSizes.iconSmall,
                        color: context.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Location Information',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeMedium,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.spacing16),

                  // Map View Section
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        AppSizes.radiusMedium,
                      ),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppSizes.radiusMedium,
                      ),

                      child: DeviceLocationViewer(
                        address: _currentDevice.address,
                        addressText: _currentDevice.addressText,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSizes.spacing16),

                  // Location Details
                  if (_currentDevice.addressText.isNotEmpty)
                    _buildInfoRow(
                      'Address',
                      _currentDevice.addressText,
                      icon: Icons.home,
                    ),
                  if (_currentDevice.address != null) ...[
                    if (_currentDevice.addressText.isNotEmpty)
                      const SizedBox(height: 12),
                    _buildInfoRow(
                      'Street',
                      _currentDevice.address!.street ?? 'Not specified',
                      icon: Icons.place,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoRow(
                            'City',
                            _currentDevice.address!.city ?? 'Not specified',
                            icon: Icons.location_city,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoRow(
                            'State',
                            _currentDevice.address!.state ?? 'Not specified',
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
                            _currentDevice.address!.postalCode ??
                                'Not specified',
                            icon: Icons.local_post_office,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoRow(
                            'Country',
                            _currentDevice.address!.country ?? 'Not specified',
                            icon: Icons.flag,
                          ),
                        ),
                      ],
                    ),
                    if (_currentDevice.address!.latitude != null &&
                        _currentDevice.address!.longitude != null) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Coordinates',
                        '${_currentDevice.address!.latitude?.toStringAsFixed(6)}, ${_currentDevice.address!.longitude?.toStringAsFixed(6)}',
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
                        color: context.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Device Attributes',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeMedium,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimaryColor,
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
                            color: context.surfaceVariantColor,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusMedium,
                            ),
                            border: Border.all(color: context.borderColor),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.label,
                                size: AppSizes.iconMedium,
                                color: context.textSecondaryColor,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  attribute.name
                                      .replaceAll('_', ' ')
                                      .toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: context.textSecondaryColor,
                                    fontSize: AppSizes.fontSizeSmall,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  attribute.value,

                                  style: TextStyle(
                                    color: context.textSecondaryColor,
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
              Text(
                'Edit Device Information',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeLarge,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: AppSizes.spacing16),

              // General Information Card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'General Information',
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeMedium,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimaryColor,
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
                    Text(
                      'Integration Information',
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeMedium,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimaryColor,
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
                    Text(
                      'Location Information',
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeMedium,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimaryColor,
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
                        icon: Icon(Icons.map, color: context.primaryColor),
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
                          color: context.surfaceVariantColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: context.borderColor),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.pin_drop,
                              color: context.textSecondaryColor,
                              size: AppSizes.iconMedium,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Coordinates: ${_selectedAddressEdit!.latitude!.toStringAsFixed(6)}, ${_selectedAddressEdit!.longitude!.toStringAsFixed(6)}',
                              style: TextStyle(
                                fontSize: AppSizes.fontSizeSmall,
                                color: context.textSecondaryColor,
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
                      Text(
                        'Device Attributes',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeMedium,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacing16),
                      Text(
                        'Note: Device attributes are managed through the system configuration.',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeMedium,
                          color: context.textSecondaryColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacing12),
                      ..._deviceDetails!.deviceAttributes.map(
                        (attribute) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(AppSizes.spacing8),
                          decoration: BoxDecoration(
                            color: context.surfaceVariantColor,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusMedium,
                            ),
                            border: Border.all(color: context.borderColor),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  attribute.name
                                      .replaceAll('_', ' ')
                                      .toUpperCase(),
                                  style: TextStyle(
                                    fontSize: AppSizes.fontSizeSmall,
                                    fontWeight: FontWeight.w500,
                                    color: context.textSecondaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSizes.spacing16),
                              Expanded(
                                child: Text(
                                  attribute.value,
                                  style: TextStyle(
                                    fontSize: AppSizes.fontSizeSmall,
                                    color: context.textSecondaryColor,
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
        decoration: BoxDecoration(
          color: context.surfaceColor,
          border: Border(top: BorderSide(color: context.borderColor, width: 1)),
          boxShadow: [
            BoxShadow(
              color: context.shadowColor,
              blurRadius: 8,
              offset: const Offset(0, -2),
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

  Widget _buildChannelsTab() {
    if (_loadingChannels && !_channelsLoaded) {
      return Center(
        child: AppLottieStateWidget.loading(
          title: 'Loading Channels',
          message: 'Loading device channels...',
          lottieSize: 80,
          titleColor: context.primaryColor,
          messageColor: context.secondaryColor,
        ),
      );
    }

    return Column(
      children: [
        // Sticky header
        Container(
          padding: const EdgeInsets.all(AppSizes.spacing16),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            border: Border(
              bottom: BorderSide(color: context.borderColor, width: 1),
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
                        color: context.textPrimaryColor,
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
                    color: context.warningColor.withOpacity(0.1),
                    border: Border.all(
                      color: context.warningColor.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: context.warningColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Note: After updating channel values, ApplyMetric will be set to true automatically, and cumulative values may change based on system calculations.',
                          style: TextStyle(
                            fontSize: 14,
                            color: context.warningColor,
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
          channels: _deviceChannels!,
          context: context,
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
      return Center(
        child: AppLottieStateWidget.loading(
          title: 'Loading Metrics',
          message: 'Loading device metrics...',
          lottieSize: 80,
          titleColor: context.primaryColor,
          messageColor: context.secondaryColor,
        ),
      );
    }

    return Column(
      children: [
        // Fixed header section with padding - SIMPLIFIED HEADER
        Container(
          padding: const EdgeInsets.all(AppSizes.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with only view toggle (removed date filter)
              Row(
                children: [
                  const Spacer(), // Push toggle to the right
                  // View toggle
                  Container(
                    height: AppSizes.buttonHeightSmall,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        AppSizes.radiusMedium,
                      ),
                      color: context.surfaceVariantColor,
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
            color: context.primaryColor,
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          ),
          child: IconButton(
            onPressed: _refreshMetricsData,
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).colorScheme.onPrimary,
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
          color: isActive ? context.primaryColor : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AppSizes.iconSmall,
              color: isActive
                  ? Theme.of(context).colorScheme.onPrimary
                  : context.textSecondaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                fontWeight: FontWeight.w500,
                color: isActive
                    ? Theme.of(context).colorScheme.onPrimary
                    : context.textSecondaryColor,
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
      // CRITICAL FIX: Add Time Period and Date Range callbacks
      onTimePeriodChanged: _handleTimePeriodChanged,
      onDateRangeChanged: _handleDateRangeChanged,
      // NEW: Pass current date range for custom date picker initialization
      currentStartDate: _metricsStartDate,
      currentEndDate: _metricsEndDate,
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

  // CRITICAL FIX: Handle Time Period changes from ModernMetricsChart
  void _handleTimePeriodChanged(
    TimePeriod timePeriod,
    DateTime fromDate,
    DateTime toDate,
  ) async {
    // Update the date range for API calls
    setState(() {
      _metricsStartDate = fromDate;
      _metricsEndDate = toDate;
      _metricsCurrentPage = 1; // Reset to first page
    });

    // Load metrics data with new date range and PageSize=0 for graphs
    await _loadMetricsDataForGraphs();
  }

  // CRITICAL FIX: Handle custom Date Range changes from ModernMetricsChart
  void _handleDateRangeChanged(DateTime? startDate, DateTime? endDate) async {
    // Only process if both dates are provided (for custom date range)
    // Time Period buttons will also trigger this with calculated dates
    if (startDate != null && endDate != null) {
      setState(() {
        _metricsStartDate = startDate;
        _metricsEndDate = endDate;
        _metricsCurrentPage = 1; // Reset to first page
      });

      // Load metrics data with new date range and PageSize=0 for graphs
      await _loadMetricsDataForGraphs();
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
        Text(
          'Metrics Summary',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.textPrimaryColor,
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
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppSizes.spacing12),
            _buildStatRow('Min', stats['min']!, context.infoColor),
            const SizedBox(height: AppSizes.spacing8),
            _buildStatRow('Max', stats['max']!, context.errorColor),
            const SizedBox(height: AppSizes.spacing8),
            _buildStatRow('Avg', stats['avg']!, context.successColor),
            const SizedBox(height: AppSizes.spacing8),
            _buildStatRow('Count', stats['count']!, context.textSecondaryColor),
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
          style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
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

  Widget _buildMetricsTableWithPagination() {
    if (_dynamicMetrics.isEmpty) {
      return AppLottieStateWidget.noData(
        title: 'No Metrics Data',
        message: 'No metrics data available for this device.',
        titleColor: context.primaryColor,
        messageColor: context.secondaryColor,
      );
    }

    // Calculate pagination
    final totalItems = _totalMetricsCount;
    final totalPages = (totalItems / _metricsItemsPerPage).ceil();

    return Column(
      children: [
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
                    context: context,
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
      // itemsPerPageOptions: const [5, 10, 25, 50],
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
          decoration: BoxDecoration(
            color: context.surfaceColor,
            border: Border(
              bottom: BorderSide(color: context.borderColor, width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Device Billing Information',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeLarge,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimaryColor,
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
            color: context.primaryColor,
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          ),
          child: IconButton(
            onPressed: _refreshBillingData,
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).colorScheme.onPrimary,
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
        lottieSize: 80,
        titleColor: context.primaryColor,
        messageColor: context.secondaryColor,
      );
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isMobile = screenWidth < 768;

        return Column(
          children: [
            // Summary Card
            if (isMobile)
              _buildCollapsibleScheduleSummaryCard()
            else
              _buildDesktopScheduleSummaryCard(),

            // Filters and Actions
            if (isMobile)
              _buildMobileScheduleHeader()
            else
              _buildDesktopScheduleHeader(),

            // Content
            Expanded(child: _buildScheduleContent()),
          ],
        );
      },
    );
  }

  Widget _buildDesktopScheduleSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacing16,
        vertical: AppSizes.spacing8,
      ),
      child: ScheduleSummaryCard(schedules: _filteredSchedules),
    );
  }

  Widget _buildCollapsibleScheduleSummaryCard() {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final isTablet =
        MediaQuery.of(context).size.width >= 768 &&
        MediaQuery.of(context).size.width < 1024;

    // Responsive sizing
    final headerFontSize = isMobile ? 14.0 : (isTablet ? 15.0 : 16.0);
    final collapsedHeight = isMobile ? 60.0 : (isTablet ? 60.0 : 70.0);
    final expandedHeight = isMobile ? 180.0 : (isTablet ? 160.0 : 180.0);
    final headerHeight = isMobile ? 50.0 : (isTablet ? 45.0 : 50.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(
        left: AppSizes.spacing16,
        right: AppSizes.spacing16,
        top: AppSizes.spacing8,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: _scheduleSummaryCardCollapsed
            ? collapsedHeight
            : expandedHeight,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            boxShadow: [AppSizes.shadowSmall],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with toggle button
              SizedBox(
                height: headerHeight,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile
                        ? AppSizes.paddingSmall
                        : AppSizes.paddingMedium,
                    vertical: AppSizes.paddingSmall,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        color: context.primaryColor,
                        size: AppSizes.iconSmall,
                      ),
                      SizedBox(
                        width: isMobile ? AppSizes.spacing4 : AppSizes.spacing8,
                      ),
                      Expanded(
                        child: Text(
                          'Schedule Summary',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: context.textPrimaryColor,
                                fontSize: headerFontSize,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _scheduleSummaryCardCollapsed =
                                !_scheduleSummaryCardCollapsed;
                            // Reset mobile tracking when user manually toggles
                            _previousScheduleSummaryStateBeforeMobile = null;
                          });
                        },
                        icon: Icon(
                          _scheduleSummaryCardCollapsed
                              ? Icons.expand_more
                              : Icons.expand_less,
                          color: context.textSecondaryColor,
                          size: AppSizes.iconSmall,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(
                          minWidth: isMobile ? 28 : 32,
                          minHeight: isMobile ? 28 : 32,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Expanded summary content
              if (!_scheduleSummaryCardCollapsed)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? AppSizes.paddingSmall : AppSizes.paddingMedium,
                      0,
                      isMobile ? AppSizes.paddingSmall : AppSizes.paddingMedium,
                      AppSizes.paddingSmall,
                    ),
                    child: ScheduleSummaryCard(schedules: _filteredSchedules),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopScheduleHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
      child: Column(
        children: [
          const SizedBox(height: AppSizes.spacing8),
          ScheduleFiltersAndActionsV2(
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
          const SizedBox(height: AppSizes.spacing8),
        ],
      ),
    );
  }

  Widget _buildMobileScheduleHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacing16,
        vertical: AppSizes.spacing8,
      ),
      child: Container(
        height: AppSizes.cardMobile,
        alignment: Alignment.centerLeft,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacing16,
          vertical: AppSizes.spacing8,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.spacing8),
          color: context.surfaceColor,
          boxShadow: [AppSizes.shadowSmall],
        ),
        child: Row(
          children: [
            Expanded(child: _buildMobileScheduleSearchBar()),
            const SizedBox(width: AppSizes.spacing8),
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: _buildMobileScheduleActionsButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileScheduleSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing8),
      child: TextField(
        onChanged: _onScheduleSearchChanged,
        decoration: const InputDecoration(
          hintText: 'Search schedules...',
          prefixIcon: Icon(Icons.search, size: AppSizes.iconSmall),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _buildMobileScheduleActionsButton() {
    return Container(
      height: 36,
      width: 36,
      decoration: BoxDecoration(
        color: context.primaryColor,
        borderRadius: BorderRadius.circular(AppSizes.spacing8),
      ),
      child: PopupMenuButton<String>(
        icon: Icon(
          Icons.more_vert,
          color: Theme.of(context).colorScheme.onPrimary,
          size: 20,
        ),
        onSelected: (value) {
          switch (value) {
            case 'add':
              _showCreateScheduleDialog();
              break;
            case 'refresh':
              _refreshSchedules();
              break;
            case 'kanban':
              _onScheduleViewModeChanged(ScheduleViewMode.kanban);
              break;
            case 'table':
              _onScheduleViewModeChanged(ScheduleViewMode.table);
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'add',
            child: Row(
              children: [
                Icon(Icons.add, size: 18),
                SizedBox(width: 8),
                Text('Add Schedule'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'refresh',
            child: Row(
              children: [
                Icon(Icons.refresh, size: 18),
                SizedBox(width: 8),
                Text('Refresh'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'table',
            child: Row(
              children: [
                Icon(
                  Icons.table_chart,
                  size: 18,
                  color: _scheduleViewMode == ScheduleViewMode.table
                      ? context.primaryColor
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  'Table View',
                  style: TextStyle(
                    color: _scheduleViewMode == ScheduleViewMode.table
                        ? context.primaryColor
                        : null,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'kanban',
            child: Row(
              children: [
                Icon(
                  Icons.view_kanban,
                  size: 18,
                  color: _scheduleViewMode == ScheduleViewMode.kanban
                      ? context.primaryColor
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  'Kanban View',
                  style: TextStyle(
                    color: _scheduleViewMode == ScheduleViewMode.kanban
                        ? context.primaryColor
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
      // Update kanban view state based on the new mode
      _isScheduleKanbanView = (mode == ScheduleViewMode.kanban);

      // If user manually changes view mode, reset mobile tracking
      if (MediaQuery.of(context).size.width >= 768) {
        _previousScheduleViewModeBeforeMobile = null;
      }
    });
    print(
      '🔄 Device360DetailsScreen: Schedule view mode changed to $mode (kanban: $_isScheduleKanbanView)',
    );
  }

  Widget _buildScheduleContent() {
    // Show no data state if no schedules (loading is handled at tab level)
    if (_allSchedules.isEmpty) {
      return AppLottieStateWidget.noData(
        title: 'No Schedules Found',
        message: 'This device has no scheduled tasks configured.',
        buttonText: 'Create Schedule',
        titleColor: context.primaryColor,
        messageColor: context.secondaryColor,
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
        context: context,
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
              color: context.textSecondaryColor,
            ),
            const SizedBox(width: 8),
          ],
          if (showLabel) ...[
            SizedBox(
              width: icon != null ? 100 : 120,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: AppSizes.fontSizeSmall,
                  fontWeight: FontWeight.w500,
                  color: context.textSecondaryColor,
                ),
              ),
            ),
            Text(
              ': ',
              style: TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                color: context.textSecondaryColor,
              ),
            ),
          ],
          showStatusChip
              ? _buildStatusDisplay(value)
              : Text(
                  value,
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeSmall,
                    color: context.textPrimaryColor,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildStatusDisplay(String status) {
    Color statusColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'commissioned':
        statusColor = context.successColor;
        statusIcon = Icons.check_circle;
        break;
      case 'decommissioned':
        statusColor = context.errorColor;
        statusIcon = Icons.cancel;
        break;
      case 'multidrive':
      case 'e-power':
        statusColor = context.primaryColor;
        statusIcon = Icons.link;
        break;
      default:
        statusColor = context.warningColor;
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
