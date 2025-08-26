import 'package:flutter/material.dart';
import 'package:mdms_clone/presentation/widgets/common/app_lottie_state_widget.dart';
import '../../../core/constants/app_sizes.dart';
import '../../themes/app_theme.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../core/models/schedule.dart';
import '../../../core/models/site.dart';
import '../../../core/models/device.dart';
import '../../../core/models/device_group.dart';
import '../../../core/models/time_of_use.dart';
import '../../../core/models/response_models.dart';
import '../../../core/services/schedule_service.dart';
import '../../../core/services/site_service.dart';
import '../../../core/services/device_service.dart';
import '../../../core/services/device_group_service.dart';
import '../../../core/services/time_of_use_service.dart';
import '../../../core/services/service_locator.dart';
import '../common/app_button.dart';
import '../common/app_input_field.dart';
import '../common/app_dropdown_field.dart';
import '../common/app_toast.dart';
import '../common/app_dialog_header.dart';
import '../common/custom_single_date_picker.dart';
import 'package:intl/intl.dart';

class ScheduleFormDialog extends StatefulWidget {
  final Schedule? schedule;
  final VoidCallback? onSuccess;
  final String mode; // 'create', 'edit', 'view'
  final int? preselectedDeviceGroupId; // Pre-select device group
  final String? preselectedTargetType; // Pre-select target type ('DeviceGroup')
  final String? preselectedDeviceId; // Pre-select device ID

  const ScheduleFormDialog({
    super.key,
    this.schedule,
    this.onSuccess,
    this.mode = 'create',
    this.preselectedDeviceGroupId,
    this.preselectedTargetType,
    this.preselectedDeviceId,
  });

  @override
  State<ScheduleFormDialog> createState() => _ScheduleFormDialogState();
}

class _ScheduleFormDialogState extends State<ScheduleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _retryCountController = TextEditingController();

  late final ScheduleService _scheduleService;
  late final SiteService _siteService;
  late final DeviceService _deviceService;
  late final DeviceGroupService _deviceGroupService;
  late final TimeOfUseService _timeOfUseService;

  bool _isLoading = false;
  bool _isLoadingData = true;
  bool _isActive = true;

  // Current mode state (can change from view to edit)
  late String _currentMode;

  // Form field values
  String _targetType = 'Device';
  String _interval = 'Monthly';
  DateTime? _startBillingDate;
  DateTime? _lastExecuteDate; // Added last execute date

  // Dropdown data
  List<Site> _sites = [];
  List<Device> _devices = [];
  List<DeviceGroup> _deviceGroups = [];
  List<TimeOfUse> _timeOfUses = [];

  // Selected values
  int? _selectedSiteId;
  String? _selectedDeviceId;
  int? _selectedDeviceGroupId;
  int? _selectedTimeOfUseId;

  // Computed properties
  bool get _isViewMode => _currentMode == 'view';

  @override
  void initState() {
    super.initState();

    // Initialize current mode from widget
    _currentMode = widget.mode;

    final serviceLocator = ServiceLocator();
    _scheduleService = ScheduleService(serviceLocator.apiService);
    _siteService = SiteService(serviceLocator.apiService);
    _deviceService = DeviceService(serviceLocator.apiService);
    _deviceGroupService = DeviceGroupService(serviceLocator.apiService);
    _timeOfUseService = TimeOfUseService(serviceLocator.apiService);

    _retryCountController.text = '0'; // Default retry count (optional)

    // Handle preselected values for new schedules
    if (widget.schedule == null) {
      if (widget.preselectedTargetType != null) {
        _targetType = widget.preselectedTargetType!;
      }
      if (widget.preselectedDeviceGroupId != null) {
        _selectedDeviceGroupId = widget.preselectedDeviceGroupId!;
      }
      if (widget.preselectedDeviceId != null) {
        _selectedDeviceId = widget.preselectedDeviceId!;
      }
    }

    if (widget.schedule != null) {
      _populateFields(widget.schedule!);
    }

    _loadDropdownData();
  }

  void _switchToEditMode() {
    setState(() {
      _currentMode = 'edit';
    });
  }

  void _populateFields(Schedule schedule) {
    _codeController.text = schedule.code ?? '';
    _nameController.text = schedule.name ?? '';

    // Set active state based on billingDevice status, not schedule.active
    if (schedule.billingDevice?.status != null) {
      _isActive = schedule.billingDevice!.status!.toLowerCase() == 'enabled';
    } else {
      _isActive =
          schedule.active ??
          true; // Fallback to schedule.active if no billingDevice status
    }

    // Handle target type mapping from API
    final apiTargetType = schedule.targetType ?? 'Device';
    if (apiTargetType.toLowerCase() == 'group') {
      _targetType = 'DeviceGroup';
    } else {
      _targetType = 'Device';
    }

    _interval = schedule.billingDevice?.interval ?? 'Monthly';
    _retryCountController.text = (schedule.billingDevice?.retryCount ?? 1)
        .toString();

    _selectedSiteId = schedule.billingDevice?.siteId;
    _selectedDeviceId = schedule.billingDevice?.deviceId;
    _selectedDeviceGroupId = schedule.billingDevice?.deviceGroupId;
    _selectedTimeOfUseId = schedule.billingDevice?.timeOfUseId;

    if (schedule.billingDevice?.nextBillingDate != null) {
      _startBillingDate = schedule.billingDevice!.nextBillingDate;
      _updateNextExecuteDate();
    }

    // Set last execute date if available
    if (schedule.billingDevice?.lastExecutionTime != null) {
      _lastExecuteDate = schedule.billingDevice!.lastExecutionTime;
    }
  }

  Future<void> _loadDropdownData() async {
    try {
      setState(() => _isLoadingData = true);

      final results = await Future.wait([
        _siteService.getSites(),
        _deviceService.getDevices(limit: 1000),
        _deviceGroupService.getDeviceGroups(limit: 1000),
        _timeOfUseService.getTimeOfUse(limit: 1000),
      ]);

      if (mounted) {
        setState(() {
          _sites = (results[0] as ApiResponse<List<Site>>).data ?? [];
          _devices = (results[1] as ApiResponse<List<Device>>).data ?? [];
          _deviceGroups =
              (results[2] as ApiResponse<List<DeviceGroup>>).data ?? [];
          _timeOfUses = (results[3] as ApiResponse<List<TimeOfUse>>).data ?? [];
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
        AppToast.showError(
          context,
          error: 'Failed to load form data: $e',
          title: 'Error',
        );
      }
    }
  }

  void _updateNextExecuteDate() {
    // This method is called to trigger UI rebuild when dates change
    setState(() {});
  }

  String _generateCronExpression(DateTime startDate, String interval) {
    switch (interval) {
      case 'Monthly':
        return '0 0 0 ${startDate.day} * ?';
      case 'Weekly':
        final weekday = startDate.weekday == 7
            ? 1
            : startDate.weekday + 1; // Convert to cron weekday
        return '0 0 0 ? * $weekday';
      case 'Daily':
        return '0 0 0 * * ?';
      default:
        return '0 0 0 ${startDate.day} * ?';
    }
  }

  Future<void> _saveSchedule() async {
    if (_isViewMode) return; // Prevent save in view mode

    if (!_formKey.currentState!.validate()) return;

    if (_startBillingDate == null) {
      AppToast.showError(
        context,
        error: 'Please select a start billing date',
        title: 'Validation Error',
      );
      return;
    }

    if (_selectedSiteId == null) {
      AppToast.showError(
        context,
        error: 'Please select a site',
        title: 'Validation Error',
      );
      return;
    }

    if (_selectedTimeOfUseId == null) {
      AppToast.showError(
        context,
        error: 'Please select a Time of Use',
        title: 'Validation Error',
      );
      return;
    }

    if (_targetType == 'Device' && _selectedDeviceId == null) {
      AppToast.showError(
        context,
        error: 'Please select a device',
        title: 'Validation Error',
      );
      return;
    }

    if (_targetType == 'DeviceGroup' && _selectedDeviceGroupId == null) {
      AppToast.showError(
        context,
        error: 'Please select a device group',
        title: 'Validation Error',
      );
      return;
    }

    // Remove the validation that was preventing past dates
    // since we now automatically adjust to tomorrow if needed

    setState(() => _isLoading = true);

    try {
      final cronExpression = _generateCronExpression(
        _startBillingDate!,
        _interval,
      );
      final retryCount = int.tryParse(_retryCountController.text) ?? 0;

      final billingDevice = BillingDevice(
        id: widget.schedule?.billingDeviceId, // Include existing ID for updates
        jobId: widget.schedule?.jobId, // Include existing JobId for updates
        siteId: _selectedSiteId!,
        deviceId: _targetType == 'Device' ? _selectedDeviceId : null,
        deviceGroupId: _targetType == 'DeviceGroup'
            ? _selectedDeviceGroupId
            : null,
        timeOfUseId: _selectedTimeOfUseId!,
        status: _isActive
            ? 'Enabled'
            : 'Disabled', // Use _isActive to set status
        nextBillingDate: _startBillingDate,
        interval: _interval,
        retryCount: retryCount,
        active: _isActive,
      );

      final schedule = Schedule(
        id: widget.schedule?.id,
        code: _codeController.text.trim(),
        name: _nameController.text.trim(),
        cronExpression: cronExpression,
        targetType: _targetType == 'DeviceGroup'
            ? 'Group'
            : 'Device', // Map back to API value
        active: _isActive,
        billingDevice: billingDevice,
        jobId: widget.schedule?.jobId,
        jobTriggerId: widget.schedule?.jobTriggerId,
        jobStatus: widget.schedule?.jobStatus,
        billingDeviceId: widget.schedule?.billingDeviceId,
        createdDate: widget.schedule?.createdDate ?? DateTime.now(),
        createdBy: widget.schedule?.createdBy,
      );

      final response = widget.schedule == null
          ? await _scheduleService.createSchedule(schedule)
          : await _scheduleService.updateSchedule(
              widget.schedule!.billingDeviceId.toString(),
              schedule,
            );

      if (response.success) {
        if (mounted) {
          Navigator.of(context).pop();
          widget.onSuccess?.call();
        }
      } else {
        if (mounted) {
          AppToast.showError(
            context,
            error: response.message ?? 'Failed to save schedule',
            title: 'Save Failed',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(
          context,
          error: 'Failed to save schedule: $e',
          title: 'Error',
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
    // Use ResponsiveHelper for consistent responsive behavior
    final dialogConstraints = ResponsiveHelper.getDialogConstraints(context);
    final isMobile = ResponsiveHelper.shouldUseCompactUI(context);

    // Dialog configuration based on mode
    DialogType dialogType;
    String dialogTitle;
    String dialogSubtitle;

    if (_currentMode == 'create') {
      dialogType = DialogType.create;
      dialogTitle = 'Create Schedule';
      dialogSubtitle =
          'Set up automated billing schedules for devices and groups';
    } else if (_currentMode == 'view') {
      dialogType = DialogType.view;
      dialogTitle = 'View Schedule';
      dialogSubtitle = 'Review schedule configuration and execution details';
    } else {
      dialogType = DialogType.edit;
      dialogTitle = 'Edit Schedule';
      dialogSubtitle = 'Update schedule configuration and settings';
    }

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
                color: context.surfaceColor,
                border: Border(
                  top: BorderSide(
                    color: context.borderColor.withValues(alpha: 0.1),
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
      color: context.backgroundColor,
      padding: EdgeInsets.all(ResponsiveHelper.getSpacing(context)),
      child: _isLoadingData
          ? Center(child: AppLottieStateWidget.loading(lottieSize: 80))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSchedulingConfigSection(),
                    SizedBox(height: ResponsiveHelper.getSpacing(context) * 2),
                    _buildTargetConfigSection(),
                    SizedBox(height: ResponsiveHelper.getSpacing(context) * 2),
                    _buildScheduleSettingsSection(),
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
        if (_isViewMode)
          AppButton(text: 'Edit', onPressed: _switchToEditMode)
        else
          AppButton(
            text: _isLoading
                ? 'Saving...'
                : (widget.schedule == null
                      ? 'Create Schedule'
                      : 'Update Schedule'),
            onPressed: _isLoading ? null : _saveSchedule,
            isLoading: _isLoading,
          ),
        const SizedBox(height: AppSizes.spacing8),
        AppButton(
          text: _isViewMode ? 'Close' : 'Cancel',
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
          text: _isViewMode ? 'Close' : 'Cancel',
          type: AppButtonType.outline,
          onPressed: () => Navigator.of(context).pop(),
        ),
        SizedBox(width: ResponsiveHelper.getSpacing(context)),
        if (_isViewMode)
          AppButton(text: 'Edit', onPressed: _switchToEditMode)
        else
          AppButton(
            text: _isLoading
                ? 'Saving...'
                : (widget.schedule == null
                      ? 'Create Schedule'
                      : 'Update Schedule'),
            onPressed: _isLoading ? null : _saveSchedule,
            isLoading: _isLoading,
          ),
      ],
    );
  }

  Widget _buildSchedulingConfigSection() {
    final isMobile = ResponsiveHelper.shouldUseCompactUI(context);

    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: context.borderColor.withValues(alpha: 0.1)),
      ),
      padding: EdgeInsets.all(ResponsiveHelper.getSpacing(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Schedule Configuration',
            style: TextStyle(
              fontSize: isMobile
                  ? AppSizes.fontSizeMedium
                  : AppSizes.fontSizeLarge,
              fontWeight: FontWeight.w600,
              color: context.textPrimaryColor,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getSpacing(context)),

          // First row: Code and Name (responsive)
          isMobile
              ? Column(
                  children: [
                    AppInputField(
                      controller: _codeController,
                      label: 'Schedule Code *',
                      hintText: 'Enter unique schedule code',
                      readOnly: _isViewMode,
                      validator: (value) {
                        if (_isViewMode) return null;
                        if (value?.trim().isEmpty ?? true) {
                          return 'Schedule code is required';
                        }
                        if (value!.trim().length < 3) {
                          return 'Code must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: ResponsiveHelper.getSpacing(context)),
                    AppInputField(
                      controller: _nameController,
                      label: 'Schedule Name *',
                      hintText: 'Enter descriptive name',
                      readOnly: _isViewMode,
                      validator: (value) {
                        if (_isViewMode) return null;
                        if (value?.trim().isEmpty ?? true) {
                          return 'Schedule name is required';
                        }
                        // if (value!.trim().length < 5) {
                        //   return 'Name must be at least 5 characters';
                        // }
                        return null;
                      },
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: AppInputField(
                        controller: _codeController,
                        label: 'Schedule Code *',
                        hintText: 'Enter unique schedule code',
                        readOnly: _isViewMode,
                        validator: (value) {
                          if (_isViewMode) return null;
                          if (value?.trim().isEmpty ?? true) {
                            return 'Schedule code is required';
                          }
                          if (value!.trim().length < 3) {
                            return 'Code must be at least 3 characters';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.getSpacing(context)),
                    Expanded(
                      child: AppInputField(
                        controller: _nameController,
                        label: 'Schedule Name *',
                        hintText: 'Enter descriptive name',
                        readOnly: _isViewMode,
                        validator: (value) {
                          if (_isViewMode) return null;
                          if (value?.trim().isEmpty ?? true) {
                            return 'Schedule name is required';
                          }
                          // if (value!.trim().length < 5) {
                          //   return 'Name must be at least 5 characters';
                          // }
                          // return null;
                        },
                      ),
                    ),
                  ],
                ),
          SizedBox(height: ResponsiveHelper.getSpacing(context)),

          // Second row: Billing Interval and Start Billing Date (responsive)
          isMobile
              ? Column(
                  children: [
                    _buildIntervalDropdown(),
                    SizedBox(height: ResponsiveHelper.getSpacing(context)),
                    _buildDatePickerField(),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildIntervalDropdown()),
                    SizedBox(width: ResponsiveHelper.getSpacing(context)),
                    Expanded(child: _buildDatePickerField()),
                  ],
                ),
          SizedBox(height: ResponsiveHelper.getSpacing(context)),

          // Third row: Last Execute Date and Next Execute Date (responsive)
          isMobile
              ? Column(
                  children: [
                    _buildLastExecuteDateDisplay(),
                    SizedBox(height: ResponsiveHelper.getSpacing(context)),
                    _buildNextExecuteDateDisplay(),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildLastExecuteDateDisplay()),
                    SizedBox(width: ResponsiveHelper.getSpacing(context)),
                    Expanded(child: _buildNextExecuteDateDisplay()),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildTargetConfigSection() {
    final isMobile = ResponsiveHelper.shouldUseCompactUI(context);

    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: context.borderColor.withValues(alpha: 0.1)),
      ),
      padding: EdgeInsets.all(ResponsiveHelper.getSpacing(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Target Configuration',
            style: TextStyle(
              fontSize: isMobile
                  ? AppSizes.fontSizeMedium
                  : AppSizes.fontSizeLarge,
              fontWeight: FontWeight.w600,
              color: context.textPrimaryColor,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getSpacing(context)),

          // First row: Target Type and dynamic selection (responsive)
          isMobile
              ? Column(
                  children: [
                    _buildTargetTypeDropdown(),
                    SizedBox(height: ResponsiveHelper.getSpacing(context)),
                    _buildTargetSelectionField(),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildTargetTypeDropdown()),
                    SizedBox(width: ResponsiveHelper.getSpacing(context)),
                    Expanded(child: _buildTargetSelectionField()),
                  ],
                ),
          SizedBox(height: ResponsiveHelper.getSpacing(context)),

          // Second row: Site and Time of Use (responsive)
          isMobile
              ? Column(
                  children: [
                    _buildSiteDropdown(),
                    SizedBox(height: ResponsiveHelper.getSpacing(context)),
                    _buildTimeOfUseDropdown(),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildSiteDropdown()),
                    SizedBox(width: ResponsiveHelper.getSpacing(context)),
                    Expanded(child: _buildTimeOfUseDropdown()),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildScheduleSettingsSection() {
    final isMobile = ResponsiveHelper.shouldUseCompactUI(context);

    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: context.borderColor.withValues(alpha: 0.1)),
      ),
      padding: EdgeInsets.all(ResponsiveHelper.getSpacing(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings,
                size: AppSizes.iconSmall,
                color: context.primaryColor,
              ),
              const SizedBox(width: AppSizes.spacing8),
              Text(
                'Schedule Settings',
                style: TextStyle(
                  fontSize: isMobile
                      ? AppSizes.fontSizeMedium
                      : AppSizes.fontSizeLarge,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing4),
          Text(
            'Configure execution behavior and status',
            style: TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              color: context.textSecondaryColor,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getSpacing(context)),

          // Settings Grid
          isMobile
              ? Column(
                  children: [
                    _buildEnhancedRetryCountField(),
                    SizedBox(height: ResponsiveHelper.getSpacing(context)),
                    _buildEnhancedActiveToggleField(),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildEnhancedRetryCountField()),
                    SizedBox(width: ResponsiveHelper.getSpacing(context) * 2),
                    Expanded(child: _buildEnhancedActiveToggleField()),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildIntervalDropdown() {
    return AppSearchableDropdown<String>(
      value: _interval,
      hintText: 'Select billing interval',
      label: 'Billing Interval',
      height: AppSizes.inputHeight,
      enabled: !_isViewMode,
      items: const [
        DropdownMenuItem(
          value: 'Monthly',
          child: Text(
            'Monthly',
            style: TextStyle(fontSize: AppSizes.fontSizeSmall),
          ),
        ),
        DropdownMenuItem(
          value: 'Weekly',
          child: Text(
            'Weekly',
            style: TextStyle(fontSize: AppSizes.fontSizeSmall),
          ),
        ),
        DropdownMenuItem(
          value: 'Daily',
          child: Text(
            'Daily',
            style: TextStyle(fontSize: AppSizes.fontSizeSmall),
          ),
        ),
      ],
      onChanged: _isViewMode
          ? null
          : (value) {
              if (value != null) {
                setState(() {
                  _interval = value;
                  _updateNextExecuteDate();
                });
              }
            },
    );
  }

  String _calculateNextExecuteDate(DateTime startDate, String interval) {
    final nextDate = _getNextExecuteDate(startDate, interval);
    return DateFormat('yyyy-MM-dd').format(nextDate);
  }

  DateTime _getNextExecuteDate(DateTime startDate, String interval) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime nextDate;

    // Calculate the normal next date based on start date and interval
    switch (interval) {
      case 'Monthly':
        nextDate = DateTime(startDate.year, startDate.month + 1, startDate.day);
        break;
      case 'Weekly':
        nextDate = startDate.add(const Duration(days: 7));
        break;
      case 'Daily':
        nextDate = startDate.add(const Duration(days: 1));
        break;
      default:
        nextDate = DateTime(startDate.year, startDate.month + 1, startDate.day);
    }

    // If the calculated next date is in the past or today, use tomorrow instead
    if (nextDate.isBefore(today) || nextDate.isAtSameMomentAs(today)) {
      nextDate = today.add(const Duration(days: 1)); // Tomorrow
    }

    return nextDate;
  }

  Widget _buildLastExecuteDateDisplay() {
    return AppInputField(
      controller: TextEditingController(
        text: _lastExecuteDate != null
            ? DateFormat('yyyy-MM-dd').format(_lastExecuteDate!)
            : 'Not executed yet',
      ),
      label: 'Last Execute Date',
      hintText: 'Shows when schedule was last executed',
      readOnly: true,
    );
  }

  Widget _buildNextExecuteDateDisplay() {
    final bool hasStartDate = _startBillingDate != null;

    return AppInputField(
      controller: TextEditingController(
        text: hasStartDate
            ? _calculateNextExecuteDate(_startBillingDate!, _interval)
            : '',
      ),
      label: 'Next Execute Date',
      hintText: 'Auto-calculated from start date and interval',
      readOnly: true,
    );
  }

  Widget _buildTargetTypeDropdown() {
    return AppSearchableDropdown<String>(
      value: _targetType,
      hintText: 'Select target type',
      label: 'Target Type',
      height: AppSizes.inputHeight,
      enabled: !_isViewMode,
      items: const [
        DropdownMenuItem(
          value: 'Device',
          child: Text(
            'Single Device',
            style: TextStyle(fontSize: AppSizes.fontSizeSmall),
          ),
        ),
        DropdownMenuItem(
          value: 'DeviceGroup',
          child: Text(
            'Device Group',
            style: TextStyle(fontSize: AppSizes.fontSizeSmall),
          ),
        ),
      ],
      onChanged: _isViewMode
          ? null
          : (value) {
              if (value != null) {
                setState(() {
                  _targetType = value;
                  _selectedDeviceId = null;
                  _selectedDeviceGroupId = null;
                });
              }
            },
    );
  }

  Widget _buildSiteDropdown() {
    return AppSearchableDropdown<int>(
      value: _selectedSiteId,
      hintText: 'Select billing site',
      label: 'Site',
      height: AppSizes.inputHeight,
      enabled: !_isViewMode,
      items: _sites.map((site) {
        final displayName = site.name.isNotEmpty ? site.name : 'Unnamed Site';

        return DropdownMenuItem(
          value: site.id,
          child: Text(
            displayName,
            style: const TextStyle(fontSize: AppSizes.fontSizeSmall),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: _isViewMode
          ? null
          : (value) {
              setState(() => _selectedSiteId = value);
            },
    );
  }

  Widget _buildTimeOfUseDropdown() {
    return AppSearchableDropdown<int>(
      value: _selectedTimeOfUseId,
      hintText: 'Select Time of Use profile',
      label: 'Time of Use (TOU)',
      height: AppSizes.inputHeight,
      enabled: !_isViewMode,
      items: _timeOfUses.map((tou) {
        final displayName = tou.name.isNotEmpty ? tou.name : 'Unnamed TOU';

        return DropdownMenuItem(
          value: tou.id,
          child: Text(
            displayName,
            style: const TextStyle(fontSize: AppSizes.fontSizeSmall),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: _isViewMode
          ? null
          : (value) {
              setState(() => _selectedTimeOfUseId = value);
            },
    );
  }

  Widget _buildDatePickerField() {
    return CustomSingleDatePicker(
      initialDate: _startBillingDate,
      label: 'Start Billing Date',
      hintText: 'Select start billing date',
      isRequired: true,
      enabled: !_isViewMode,

      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      onDateSelected: (selectedDate) {
        if (!_isViewMode) {
          setState(() {
            _startBillingDate = selectedDate;
            _updateNextExecuteDate();
          });
        }
      },
    );
  }

  Widget _buildTargetSelectionField() {
    if (_targetType == 'Device') {
      return _buildDeviceDropdown();
    } else if (_targetType == 'DeviceGroup') {
      return _buildDeviceGroupDropdown();
    } else {
      return AppInputField(
        controller: TextEditingController(),
        label: 'Target Selection',
        hintText: 'Please select a target type first',
        readOnly: true,
      );
    }
  }

  Widget _buildDeviceDropdown() {
    return AppSearchableDropdown<String>(
      value: _selectedDeviceId,
      label: 'Device',
      hintText: 'Select target device',
      height: AppSizes.inputHeight,
      enabled: !_isViewMode,
      items: _devices.map((device) {
        final displayName = device.serialNumber.isNotEmpty
            ? device.serialNumber
            : 'Unknown Device';

        return DropdownMenuItem(
          value: device.id,
          child: Text(
            displayName,
            style: const TextStyle(fontSize: AppSizes.fontSizeSmall),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: _isViewMode
          ? null
          : (value) {
              setState(() => _selectedDeviceId = value);
            },
    );
  }

  Widget _buildDeviceGroupDropdown() {
    return AppSearchableDropdown<int>(
      value: _selectedDeviceGroupId,
      label: 'Device Group',
      hintText: 'Select target device group',
      height: AppSizes.inputHeight,
      enabled: !_isViewMode,
      items: _deviceGroups.map((group) {
        final displayName = group.name?.isNotEmpty == true
            ? group.name!
            : 'Unnamed Group';

        return DropdownMenuItem(
          value: group.id,
          child: Text(
            displayName,
            style: const TextStyle(fontSize: AppSizes.fontSizeSmall),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: _isViewMode
          ? null
          : (value) {
              setState(() => _selectedDeviceGroupId = value);
            },
    );
  }

  Widget _buildEnhancedRetryCountField() {
    final retryCount = int.tryParse(_retryCountController.text) ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.replay,
              size: AppSizes.iconSmall,
              color: context.textSecondaryColor,
            ),
            const SizedBox(width: AppSizes.spacing8),
            Text(
              'Retry Count',
              style: TextStyle(
                fontSize: AppSizes.fontSizeMedium,
                fontWeight: FontWeight.w500,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(width: AppSizes.spacing8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacing6,
                vertical: AppSizes.spacing2,
              ),
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
              ),
              child: Text(
                'Optional',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeSmall - 1,
                  fontWeight: FontWeight.w500,
                  color: context.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spacing8),

        // Compact counter
        Row(
          children: [
            Container(
              height: 36,
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                border: Border.all(color: context.borderColor),
              ),
              child: Row(
                children: [
                  // Decrement button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isViewMode || retryCount <= 0
                          ? null
                          : () {
                              setState(() {
                                _retryCountController.text = (retryCount - 1)
                                    .toString();
                              });
                            },
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppSizes.radiusLarge),
                        bottomLeft: Radius.circular(AppSizes.radiusLarge),
                      ),
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: Icon(
                          Icons.remove,
                          color: _isViewMode || retryCount <= 0
                              ? context.textSecondaryColor
                              : context.textPrimaryColor,
                          size: 16,
                        ),
                      ),
                    ),
                  ),

                  // Value display
                  Container(
                    width: 50,
                    alignment: Alignment.center,
                    child: TextFormField(
                      controller: _retryCountController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      readOnly: _isViewMode,
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeMedium,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimaryColor,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        fillColor: Colors.transparent,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (value) {
                        final count = int.tryParse(value);
                        if (count != null && count >= 0 && count <= 9) {
                          // Valid input, do nothing special
                        } else if (value.isNotEmpty) {
                          // Invalid input, revert to previous valid value
                          setState(() {
                            _retryCountController.text = retryCount.toString();
                            _retryCountController.selection =
                                TextSelection.fromPosition(
                                  TextPosition(
                                    offset: _retryCountController.text.length,
                                  ),
                                );
                          });
                        }
                      },
                      validator: (value) {
                        if (_isViewMode) return null;
                        if (value?.trim().isNotEmpty == true) {
                          final count = int.tryParse(value!);
                          if (count == null || count < 0 || count > 9) {
                            return 'Enter a number (0-9)';
                          }
                        }
                        return null;
                      },
                    ),
                  ),

                  // Increment button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isViewMode || retryCount >= 9
                          ? null
                          : () {
                              setState(() {
                                _retryCountController.text = (retryCount + 1)
                                    .toString();
                              });
                            },
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(AppSizes.radiusLarge),
                        bottomRight: Radius.circular(AppSizes.radiusLarge),
                      ),
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: Icon(
                          Icons.add,
                          color: _isViewMode || retryCount >= 9
                              ? context.textSecondaryColor
                              : context.textPrimaryColor,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // const SizedBox(width: AppSizes.spacing12),
            // Expanded(
            //   child: Text(
            //     retryCount == 0
            //         ? 'Execute once only'
            //         : '$retryCount retr${retryCount == 1 ? 'y' : 'ies'}',
            //     style: TextStyle(
            //       fontSize: AppSizes.fontSizeSmall,
            //       color: context.textSecondaryColor,
            //     ),
            //   ),
            // ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnhancedActiveToggleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _isActive ? Icons.play_circle : Icons.pause_circle,
              size: AppSizes.iconSmall,
              color: _isActive ? Colors.green : context.textSecondaryColor,
            ),
            const SizedBox(width: AppSizes.spacing8),
            Text(
              'Schedule Status',
              style: TextStyle(
                fontSize: AppSizes.fontSizeMedium,
                fontWeight: FontWeight.w500,
                color: context.textPrimaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spacing8),

        // Compact toggle buttons
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _isViewMode
                    ? null
                    : () {
                        setState(() {
                          _isActive = true;
                        });
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 36,
                  decoration: BoxDecoration(
                    color: _isActive
                        ? Colors.green.withValues(alpha: 0.1)
                        : context.surfaceColor,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                    border: Border.all(
                      color: _isActive ? Colors.green : context.borderColor,
                      width: _isActive ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.play_circle,
                        color: _isActive
                            ? Colors.green
                            : context.textSecondaryColor,
                        size: 16,
                      ),
                      const SizedBox(width: AppSizes.spacing4),
                      Text(
                        'Enabled',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeSmall,
                          fontWeight: FontWeight.w500,
                          color: _isActive
                              ? Colors.green
                              : context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: AppSizes.spacing8),

            Expanded(
              child: GestureDetector(
                onTap: _isViewMode
                    ? null
                    : () {
                        setState(() {
                          _isActive = false;
                        });
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 36,
                  decoration: BoxDecoration(
                    color: !_isActive
                        ? context.errorColor.withValues(alpha: 0.1)
                        : context.surfaceColor,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                    border: Border.all(
                      color: !_isActive
                          ? context.errorColor
                          : context.borderColor,
                      width: !_isActive ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.pause_circle,
                        color: !_isActive
                            ? context.errorColor
                            : context.textSecondaryColor,
                        size: 16,
                      ),
                      const SizedBox(width: AppSizes.spacing4),
                      Text(
                        'Disabled',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeSmall,
                          fontWeight: FontWeight.w500,
                          color: !_isActive
                              ? context.errorColor
                              : context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _retryCountController.dispose();
    super.dispose();
  }
}
