import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/device.dart';
import '../../../core/services/device_service.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/status_chip.dart';
import '../../widgets/common/results_pagination.dart';
import '../../widgets/common/blunest_data_table.dart';
import '../../widgets/devices/device_location_map.dart';
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

class _Device360DetailsScreenState extends State<Device360DetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DeviceService _deviceService;

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _deviceService = Provider.of<DeviceService>(context, listen: false);

    // Load initial overview data
    _loadOverviewData();

    // Listen to tab changes to trigger lazy loading
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;

    final int tabIndex = _tabController.index;

    switch (tabIndex) {
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
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
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
        widget.device.id,
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
          widget.device.id,
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
        widget.device.id,
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
        widget.device.id,
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
    final int tabIndex = _tabController.index;
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
          padding: const EdgeInsets.all(24),
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
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1e293b),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Serial: ${widget.device.serialNumber}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF64748b),
                      ),
                    ),
                  ],
                ),
              ),
              _buildActionButtons(),
            ],
          ),
        ),

        // Tabs section
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(
                color: AppColors.border,
                width: 1.0,
              ),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(
              fontSize: AppSizes.fontSizeMedium,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: AppSizes.fontSizeMedium,
              fontWeight: FontWeight.w500,
            ),
            indicatorColor: AppColors.primary,
            indicatorWeight: 3.0,
            indicator: BoxDecoration(
              color: Colors.transparent,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.primary,
                  width: 3.0,
                ),
              ),
            ),
            labelPadding: EdgeInsets.symmetric(
              horizontal: AppSizes.spacing16,
              vertical: AppSizes.spacing12,
            ),
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            splashFactory: NoSplash.splashFactory,
            isScrollable: true,
            tabs: [
              Tab(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSizes.spacing8,
                    vertical: AppSizes.spacing8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.dashboard, size: AppSizes.iconSmall),
                      SizedBox(width: AppSizes.spacing8),
                      Text('Overview'),
                    ],
                  ),
                ),
              ),
              Tab(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSizes.spacing8,
                    vertical: AppSizes.spacing8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.device_hub, size: AppSizes.iconSmall),
                      SizedBox(width: AppSizes.spacing8),
                      Text('Channels'),
                    ],
                  ),
                ),
              ),
              Tab(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSizes.spacing8,
                    vertical: AppSizes.spacing8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.analytics, size: AppSizes.iconSmall),
                      SizedBox(width: AppSizes.spacing8),
                      Text('Metrics'),
                    ],
                  ),
                ),
              ),
              Tab(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSizes.spacing8,
                    vertical: AppSizes.spacing8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt, size: AppSizes.iconSmall),
                      SizedBox(width: AppSizes.spacing8),
                      Text('Billing'),
                    ],
                  ),
                ),
              ),
              Tab(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSizes.spacing8,
                    vertical: AppSizes.spacing8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, size: AppSizes.iconSmall),
                      SizedBox(width: AppSizes.spacing8),
                      Text('Location'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Content section
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
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
                          final int tabIndex = _tabController.index;
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
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildChannelsTab(),
                    _buildMetricsTab(),
                    _buildBillingTab(),
                    _buildLocationTab(),
                  ],
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
      final response = await _deviceService.pingDevice(widget.device.id);

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
          message: 'Ping failed: ${response.message}',
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(
          context,
          title: 'Error',
          message: 'Error pinging device: $e',
        );
      }
    }
  }

  Future<void> _linkToHES() async {
    try {
      final response = await _deviceService.linkDeviceToHES(widget.device.id);

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
          message: 'Failed to link device: ${response.message}',
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(
          context,
          title: 'Error',
          message: 'Error linking device: $e',
        );
      }
    }
  }

  Future<void> _commissionDevice() async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Commission Device',
      message: 'Are you sure you want to commission device ${widget.device.serialNumber}?\n\nThis action will make the device active and ready for operation.',
      confirmText: 'Commission',
      confirmColor: AppColors.warning,
    );

    if (confirmed == true) {
      try {
        final response = await _deviceService.commissionDevice(
          widget.device.id,
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
            message: 'Failed to commission device: ${response.message}',
          );
        }
      } catch (e) {
        if (mounted) {
          AppToast.showError(
            context,
            title: 'Error',
            message: 'Error commissioning device: $e',
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
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Device Status Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Device Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1e293b),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    StatusChip.fromDeviceStatus(widget.device.status),
                    const SizedBox(width: 16),
                    StatusChip(
                      text: 'Link: ${widget.device.linkStatus}',
                      type: StatusChipType.info,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Device Information Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Device Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1e293b),
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow('Serial Number', widget.device.serialNumber),
                _buildInfoRow('Device Type', widget.device.deviceType),
                _buildInfoRow('Model', widget.device.model),
                _buildInfoRow('Manufacturer', widget.device.manufacturer),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Address Information Card
          if (widget.device.address != null)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Address Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1e293b),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    'Street',
                    widget.device.address!.street ?? 'N/A',
                  ),
                  _buildInfoRow('City', widget.device.address!.city ?? 'N/A'),
                  _buildInfoRow('State', widget.device.address!.state ?? 'N/A'),
                  _buildInfoRow(
                    'Postal Code',
                    widget.device.address!.postalCode ?? 'N/A',
                  ),
                  _buildInfoRow(
                    'Country',
                    widget.device.address!.country ?? 'N/A',
                  ),
                ],
              ),
            ),

          // Device Attributes Card
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
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1e293b),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._deviceDetails!.deviceAttributes.map(
                    (attribute) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: _buildInfoRow(
                        attribute.name.replaceAll('_', ' ').toUpperCase(),
                        attribute.value,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChannelsTab() {
    if (_loadingChannels && !_channelsLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Device Channels',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1e293b),
            ),
          ),
          const SizedBox(height: 16),
          if (_deviceChannels == null || _deviceChannels!.isEmpty)
            const AppCard(
              child: Center(
                child: Text(
                  'No channels found for this device',
                  style: TextStyle(fontSize: 16, color: Color(0xFF64748b)),
                ),
              ),
            )
          else
            ..._deviceChannels!.map(
              (channel) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        channel.channel?.name ?? 'Channel ${channel.channelId}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1e293b),
                        ),
                      ),
                      const SizedBox(height: 8),
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
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with filters and view toggle
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Text(
                      'Device Metrics',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1e293b),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Date filters
                    _buildDateFilter(),
                  ],
                ),
              ),
              // View toggle
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
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
            const AppCard(
              child: Center(
                child: Text(
                  'No metrics data available',
                  style: TextStyle(fontSize: 16, color: Color(0xFF64748b)),
                ),
              ),
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
          decoration: BoxDecoration(
            color: const Color(0xFF2563eb),
            borderRadius: BorderRadius.circular(6),
          ),
          child: IconButton(
            onPressed: _refreshMetricsData,
            icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
            tooltip: 'Refresh Data',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: isActive ? const Color(0xFF2563eb) : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.white : const Color(0xFF64748b),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
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
      return const AppCard(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart, size: 64, color: Color(0xFF64748b)),
              SizedBox(height: 16),
              Text(
                'No metrics data available for graphing',
                style: TextStyle(fontSize: 16, color: Color(0xFF64748b)),
              ),
              SizedBox(height: 8),
              Text(
                'Try adjusting the date range or refresh the data',
                style: TextStyle(fontSize: 14, color: Color(0xFF64748b)),
              ),
            ],
          ),
        ),
      );
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
      return const AppCard(
        child: Center(
          child: Text(
            'No metrics data available',
            style: TextStyle(fontSize: 16, color: Color(0xFF64748b)),
          ),
        ),
      );
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
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
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
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1e293b),
                ),
              ),
              _buildBillingActions(),
            ],
          ),
          const SizedBox(height: 16),

          if (_deviceBilling != null) ...[
            _buildBillingDataTable(),
          ] else
            const AppCard(
              child: Center(
                child: Text(
                  'No billing data available',
                  style: TextStyle(fontSize: 16, color: Color(0xFF64748b)),
                ),
              ),
            ),
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
            borderRadius: BorderRadius.circular(6),
          ),
          child: IconButton(
            onPressed: _refreshBillingData,
            icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
            tooltip: 'Refresh Data',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
      return const AppCard(
        child: Center(
          child: Text(
            'No billing records found',
            style: TextStyle(fontSize: 16, color: Color(0xFF64748b)),
          ),
        ),
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

        const SizedBox(height: 16),

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
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Device Location',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1e293b),
            ),
          ),
          const SizedBox(height: 16),
          if (widget.device.address != null) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Address Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1e293b),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    'Street',
                    widget.device.address!.street ?? 'N/A',
                  ),
                  _buildInfoRow('City', widget.device.address!.city ?? 'N/A'),
                  _buildInfoRow('State', widget.device.address!.state ?? 'N/A'),
                  _buildInfoRow(
                    'Postal Code',
                    widget.device.address!.postalCode ?? 'N/A',
                  ),
                  _buildInfoRow(
                    'Country',
                    widget.device.address!.country ?? 'N/A',
                  ),
                  if (widget.device.address!.latitude != null &&
                      widget.device.address!.longitude != null)
                    _buildInfoRow(
                      'Coordinates',
                      '${widget.device.address!.latitude}, ${widget.device.address!.longitude}',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Map View',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1e293b),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DeviceLocationMap(
                    address: widget.device.address,
                    readOnly: true,
                  ),
                ],
              ),
            ),
          ] else
            const AppCard(
              child: Center(
                child: Text(
                  'No address information available for this device',
                  style: TextStyle(fontSize: 16, color: Color(0xFF64748b)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748b),
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748b)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1e293b)),
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
