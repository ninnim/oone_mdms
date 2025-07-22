import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/device.dart';
import '../../../core/models/device_group.dart';
import '../../../core/services/device_group_service.dart';
import '../../../core/services/device_service.dart';
import '../../../core/services/service_locator.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/breadcrumb_navigation.dart';

class DeviceGroupDetailsScreen extends StatefulWidget {
  final DeviceGroup deviceGroup;

  const DeviceGroupDetailsScreen({
    super.key,
    required this.deviceGroup,
  });

  @override
  State<DeviceGroupDetailsScreen> createState() =>
      _DeviceGroupDetailsScreenState();
}

class _DeviceGroupDetailsScreenState extends State<DeviceGroupDetailsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _deviceGroupService = ServiceLocator().get<DeviceGroupService>();
  final _deviceService = ServiceLocator().get<DeviceService>();

  // State
  List<Device> _allDevices = [];
  List<Device> _selectedDevices = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load all available devices
      final devices = await _deviceService.getDevices();

      // Get devices currently in this group
      final groupDevices = devices
          .where((device) => device.deviceGroupId == widget.deviceGroup.id)
          .toList();

      setState(() {
        _allDevices = devices;
        _selectedDevices = List.from(groupDevices);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    try {
      // Update devices to belong to this group
      final updateFutures = <Future>[];

      // Remove devices that are no longer selected
      final currentGroupDevices = _allDevices
          .where((device) => device.deviceGroupId == widget.deviceGroup.id)
          .toList();

      for (final device in currentGroupDevices) {
        if (!_selectedDevices.any((d) => d.id == device.id)) {
          updateFutures.add(
            _deviceService.updateDevice(
              device.copyWith(deviceGroupId: null),
            ),
          );
        }
      }

      // Add newly selected devices to this group
      for (final device in _selectedDevices) {
        if (device.deviceGroupId != widget.deviceGroup.id) {
          updateFutures.add(
            _deviceService.updateDevice(
              device.copyWith(deviceGroupId: widget.deviceGroup.id),
            ),
          );
        }
      }

      await Future.wait(updateFutures);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device group updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update device group: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with breadcrumbs
          Container(
            padding: const EdgeInsets.all(AppSizes.spacing16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BreadcrumbNavigation(),
                const SizedBox(height: AppSizes.spacing16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.deviceGroup.name ?? 'Device Group',
                            style: const TextStyle(
                              fontSize: AppSizes.fontSizeHeading,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (widget.deviceGroup.description?.isNotEmpty ==
                              true) ...[
                            const SizedBox(height: AppSizes.spacing4),
                            Text(
                              widget.deviceGroup.description!,
                              style: const TextStyle(
                                fontSize: AppSizes.fontSizeMedium,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    AppButton(
                      text: 'Save Changes',
                      onPressed: _isLoading ? null : _saveChanges,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tab bar
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Devices'),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Error: $_error',
                              style: const TextStyle(color: AppColors.error),
                            ),
                            const SizedBox(height: AppSizes.spacing16),
                            AppButton(
                              text: 'Retry',
                              onPressed: _loadData,
                            ),
                          ],
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewTab(),
                          _buildDevicesTab(),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Information Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Basic Information',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeLarge,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.spacing16),
                _buildInfoRow('Name', widget.deviceGroup.name ?? 'Unknown'),
                _buildInfoRow(
                  'Description',
                  widget.deviceGroup.description ?? 'No description',
                ),
                _buildInfoRow(
                  'Status',
                  widget.deviceGroup.active == true ? 'Active' : 'Inactive',
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.spacing16),

          // Statistics Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Statistics',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeLarge,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.spacing16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Devices',
                        _selectedDevices.length.toString(),
                        Icons.devices,
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacing16),
                    Expanded(
                      child: _buildStatCard(
                        'Active Devices',
                        _selectedDevices
                            .where((d) => d.status == 'Commissioned')
                            .length
                            .toString(),
                        Icons.check_circle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevicesTab() {
    final availableDevices = _allDevices
        .where((device) =>
            device.deviceGroupId == null ||
            device.deviceGroupId == widget.deviceGroup.id)
        .toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSizes.spacing16),
          child: Row(
            children: [
              Text(
                'Select devices for this group (${_selectedDevices.length} selected)',
                style: const TextStyle(
                  fontSize: AppSizes.fontSizeLarge,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              AppButton(
                text: _selectedDevices.length == availableDevices.length
                    ? 'Deselect All'
                    : 'Select All',
                type: AppButtonType.outline,
                onPressed: () {
                  setState(() {
                    if (_selectedDevices.length == availableDevices.length) {
                      _selectedDevices.clear();
                    } else {
                      _selectedDevices = List.from(availableDevices);
                    }
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
            itemCount: availableDevices.length,
            itemBuilder: (context, index) {
              final device = availableDevices[index];
              final isSelected =
                  _selectedDevices.any((d) => d.id == device.id);

              return AppCard(
                padding: const EdgeInsets.all(AppSizes.spacing12),
                child: CheckboxListTile(
                  value: isSelected,
                  onChanged: (selected) {
                    setState(() {
                      if (selected == true) {
                        if (!_selectedDevices.any((d) => d.id == device.id)) {
                          _selectedDevices.add(device);
                        }
                      } else {
                        _selectedDevices.removeWhere((d) => d.id == device.id);
                      }
                    });
                  },
                  title: Text(
                    device.serialNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (device.name?.isNotEmpty == true)
                        Text(device.name!),
                      Text('Type: ${device.deviceType ?? 'Unknown'}'),
                      Text('Status: ${device.status ?? 'Unknown'}'),
                    ],
                  ),
                  activeColor: AppColors.primary,
                  checkColor: Colors.white,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spacing12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: AppSizes.fontSizeMedium,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.spacing16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: AppSizes.fontSizeMedium,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: AppSizes.iconLarge,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSizes.spacing8),
          Text(
            value,
            style: const TextStyle(
              fontSize: AppSizes.fontSizeHeading,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSizes.spacing4),
          Text(
            title,
            style: const TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
