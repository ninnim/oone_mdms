import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../core/models/time_of_use.dart';
import '../../../core/models/time_band.dart';
import '../../../core/services/time_of_use_service.dart';
import '../common/app_button.dart';
import '../common/app_input_field.dart';
import '../common/app_dropdown_field.dart';
import '../common/app_toast.dart';
import '../common/app_dialog_header.dart';
import '../common/app_lottie_state_widget.dart';
import '../common/blunest_data_table.dart';
import '../common/results_pagination.dart';
import '../time_bands/time_band_smart_chips.dart';
import 'tou_form_validation_grid.dart';
import '../../themes/app_theme.dart';

class TimeOfUseFormDialog extends StatefulWidget {
  final TimeOfUse? timeOfUse;
  final bool isReadOnly;
  final VoidCallback? onSaved; // Callback for when save is successful

  const TimeOfUseFormDialog({
    super.key,
    this.timeOfUse,
    this.isReadOnly = false,
    this.onSaved, // Add callback parameter
  });

  @override
  State<TimeOfUseFormDialog> createState() => _TimeOfUseFormDialogState();
}

class _TimeOfUseFormDialogState extends State<TimeOfUseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  late TimeOfUseService _timeOfUseService;

  bool _isLoading = false;
  bool _isEditMode = false;
  List<TimeOfUseDetail> _details = [];

  // Add getter for view mode
  bool get _isViewMode => !_isEditMode;
  List<TimeBand> _availableTimeBands = [];
  List<Channel> _availableChannels = [];
  int? _selectedFilterChannelId; // Channel filter for validation grid
  Map<int, TextEditingController> _registerCodeControllers =
      {}; // Use index as key for proper state management

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timeOfUseService = Provider.of<TimeOfUseService>(context, listen: false);
  }

  @override
  void initState() {
    super.initState();
    _isEditMode = !widget.isReadOnly;
    _initializeForm();
    // Load data after didChangeDependencies is called
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAvailableData();
    });
  }

  void _initializeForm() {
    if (widget.timeOfUse != null) {
      final tou = widget.timeOfUse!;
      _codeController.text = tou.code;
      _nameController.text = tou.name;
      _descriptionController.text = tou.description;

      // Sort details by PriorityOrder (lowest number first, as it calculates first)
      _details = List.from(tou.timeOfUseDetails)
        ..sort((a, b) => a.priorityOrder.compareTo(b.priorityOrder));

      // Initialize controllers for existing details
      _initializeControllers();
    }
  }

  void _initializeControllers() {
    // Clear existing controllers
    for (final controller in _registerCodeControllers.values) {
      controller.dispose();
    }
    _registerCodeControllers.clear();

    // Create controllers for each detail using index as key
    for (int i = 0; i < _details.length; i++) {
      _registerCodeControllers[i] = TextEditingController(
        text: _details[i].registerDisplayCode,
      );
    }
  }

  Future<void> _loadAvailableData() async {
    setState(() => _isLoading = true);

    try {
      final [timeBandsResponse, channelsResponse] = await Future.wait([
        _timeOfUseService.getAvailableTimeBands(),
        _timeOfUseService.getAvailableChannels(),
      ]);

      if (mounted) {
        setState(() {
          _availableTimeBands =
              (timeBandsResponse.data as List<dynamic>?)?.cast<TimeBand>() ??
              [];
          _availableChannels =
              (channelsResponse.data as List<dynamic>?)?.cast<Channel>() ?? [];
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $error'),
            backgroundColor: context.errorColor,
          ),
        );
      }
    }
  }

  void _toggleEditMode() {
    setState(() => _isEditMode = !_isEditMode);
  }

  void _addDetail() {
    setState(() {
      final newDetail = TimeOfUseDetail(
        timeBandId: _availableTimeBands.isNotEmpty
            ? _availableTimeBands.first.id
            : 1,
        channelId: _availableChannels.isNotEmpty
            ? _availableChannels.first.id
            : 1,
        registerDisplayCode: '',
        priorityOrder: _details.length + 1,
        active: true,
      );
      _details.add(newDetail);

      // Reinitialize all controllers to ensure proper indexing
      _initializeControllers();
    });
  }

  void _removeDetail(int index) {
    setState(() {
      _details.removeAt(index);

      // Update priority order for remaining items
      for (int i = 0; i < _details.length; i++) {
        _details[i] = _details[i].copyWith(priorityOrder: i + 1);
      }

      // Reinitialize all controllers to ensure proper indexing
      _initializeControllers();
    });
  }

  void _updateDetail(
    int index, {
    int? timeBandId,
    int? channelId,
    String? registerDisplayCode,
  }) {
    setState(() {
      final oldDetail = _details[index];
      final newDetail = oldDetail.copyWith(
        timeBandId: timeBandId,
        channelId: channelId,
        registerDisplayCode: registerDisplayCode,
      );

      _details[index] = newDetail;

      // Note: Do not update controller text here as it causes auto-selection
      // The controller is already updated by user input via onChanged
    });
  }

  void _reorderDetails(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }

      // Store the register code values before reordering
      final Map<int, String> registerCodeValues = {};
      for (int i = 0; i < _details.length; i++) {
        if (_registerCodeControllers.containsKey(i)) {
          registerCodeValues[i] = _registerCodeControllers[i]!.text;
        }
      }

      // Reorder the details
      final item = _details.removeAt(oldIndex);
      _details.insert(newIndex, item);

      // Update priority order based on new positions
      for (int i = 0; i < _details.length; i++) {
        _details[i] = _details[i].copyWith(priorityOrder: i + 1);
      }

      // Create new mapping for reordered register codes
      final Map<int, String> reorderedValues = {};
      List<int> oldOrder = List.generate(_details.length, (index) => index);
      int movedValue = oldOrder.removeAt(oldIndex);
      oldOrder.insert(newIndex, movedValue);

      for (int newPos = 0; newPos < oldOrder.length; newPos++) {
        int oldPos = oldOrder[newPos];
        if (registerCodeValues.containsKey(oldPos)) {
          reorderedValues[newPos] = registerCodeValues[oldPos]!;
        }
      }

      // Update the details with the reordered register codes
      for (int i = 0; i < _details.length; i++) {
        if (reorderedValues.containsKey(i)) {
          _details[i] = _details[i].copyWith(
            registerDisplayCode: reorderedValues[i]!,
          );
        }
      }

      // Reinitialize controllers with the new data
      _initializeControllers();
    });
  }

  TextEditingController _getRegisterCodeController(int index) {
    // Ensure controller exists for this index
    if (!_registerCodeControllers.containsKey(index)) {
      _registerCodeControllers[index] = TextEditingController(
        text: index < _details.length
            ? _details[index].registerDisplayCode
            : '',
      );
    }
    return _registerCodeControllers[index]!;
  }

  /// Validates individual time bands for basic validity (duration, format, etc.)
  String? _validateTimeBands() {
    final List<String> timeBandErrors = [];

    // Get all unique time band IDs used in details
    final timeBandIds = _details.map((d) => d.timeBandId).toSet();

    for (final timeBandId in timeBandIds) {
      final timeBand = _availableTimeBands.firstWhere(
        (tb) => tb.id == timeBandId,
        orElse: () => TimeBand(
          id: timeBandId,
          name: 'Unknown TimeBand $timeBandId',
          startTime: '00:00:00',
          endTime: '00:00:00',
          description: '',
          active: false,
        ),
      );

      // Validate time band duration
      final startTime = _parseTimeToHours(timeBand.startTime);
      final endTime = _parseTimeToHours(timeBand.endTime);

      if (startTime != null && endTime != null) {
        // Check for zero-duration time bands
        if (startTime == endTime) {
          timeBandErrors.add(
            '❌ Time Band "${timeBand.name}" has zero duration (${timeBand.startTime} - ${timeBand.endTime})\n'
            '   This time band provides no coverage and cannot be used in Time of Use.',
          );
        }

        // Check for invalid time ranges (over 24 hours for same-day periods)
        if (endTime > startTime && (endTime - startTime) > 24.0) {
          timeBandErrors.add(
            '❌ Time Band "${timeBand.name}" has invalid duration > 24 hours (${timeBand.startTime} - ${timeBand.endTime})\n'
            '   Single-day time bands cannot exceed 24 hours.',
          );
        }
      } else {
        timeBandErrors.add(
          '❌ Time Band "${timeBand.name}" has invalid time format (${timeBand.startTime} - ${timeBand.endTime})',
        );
      }
    }

    if (timeBandErrors.isNotEmpty) {
      return '🚨 INVALID TIME BANDS DETECTED\n\n${timeBandErrors.join('\n\n')}\n\n'
          'Please select valid time bands with proper duration before saving.';
    }

    return null;
  }

  /// Validates that each channel has 24-hour and 7-day coverage with detailed error messages
  String? _validateChannelCoverage() {
    // First, validate all time bands for basic validity
    final timeBandValidationError = _validateTimeBands();
    if (timeBandValidationError != null) {
      return timeBandValidationError;
    }

    // Group details by channel
    final channelGroups = <int, List<TimeOfUseDetail>>{};
    for (final detail in _details) {
      if (!channelGroups.containsKey(detail.channelId)) {
        channelGroups[detail.channelId] = [];
      }
      channelGroups[detail.channelId]!.add(detail);
    }

    // Collect detailed errors for comprehensive display
    final List<String> allErrors = [];

    // Validate each channel
    for (final channelEntry in channelGroups.entries) {
      final channelId = channelEntry.key;
      final channelDetails = channelEntry.value;

      // Get channel information
      final channel = _availableChannels.firstWhere(
        (c) => c.id == channelId,
        orElse: () => Channel.simple(id: channelId, name: 'Channel $channelId'),
      );

      // Create channel display name
      final channelName = _getChannelDisplayName(channel);

      // Get all time bands for this channel
      final timeBandIds = channelDetails.map((d) => d.timeBandId).toSet();
      final timeBands = _availableTimeBands
          .where((tb) => timeBandIds.contains(tb.id))
          .toList();

      // Debug logging for full time band
      for (final timeBand in timeBands) {
        if (timeBand.name.toLowerCase().contains('full')) {
          print('🔍 Debug: Full TimeBand ${timeBand.id} (${timeBand.name})');
          print('  StartTime: ${timeBand.startTime}');
          print('  EndTime: ${timeBand.endTime}');
          print('  DaysOfWeek: ${timeBand.daysOfWeek}');
          print('  TimeBandAttributes: ${timeBand.timeBandAttributes.length}');
          for (final attr in timeBand.timeBandAttributes) {
            print(
              '    ${attr.attributeType}: ${attr.attributeValue} (${attr.valueList})',
            );
          }
        }
      }

      if (timeBands.isEmpty) {
        allErrors.add(
          '❌ $channelName: No time bands assigned - Cannot save without time band coverage',
        );
        continue;
      }

      // Check 7-day coverage
      final dayCoverage = _calculateDayCoverage(timeBands);
      if (dayCoverage < 7) {
        final missingDays = _getMissingDays(timeBands);
        if (missingDays.length == 7) {
          allErrors.add('❌ $channelName\nMISSING: No day coverage');
        } else {
          allErrors.add('❌ $channelName\nMISSING: ${missingDays.join(', ')}');
        }
      }

      // Check 24-hour coverage
      final hourCoverage = _calculateHourCoverage(timeBands);
      if (hourCoverage < 24.0) {
        final deficit = 24.0 - hourCoverage;
        allErrors.add(
          '❌ $channelName\nMISSING: ${deficit.toStringAsFixed(1)} hours',
        );
      }
    }

    // Return comprehensive error message if any issues found
    if (allErrors.isNotEmpty) {
      final errorCount = allErrors.length;
      final totalChannels = channelGroups.length;

      return '🚨 VALIDATION FAILED ($errorCount of $totalChannels channels)\n\n'
          '${allErrors.join('\n\n')}';
    }

    return null; // All validations passed
  }

  /// Gets user-friendly display name for a channel
  String _getChannelDisplayName(Channel channel) {
    final code = channel.code.isEmpty ? 'CH${channel.id}' : channel.code;
    final name = channel.name.isNotEmpty
        ? channel.name
        : 'Channel ${channel.id}';

    // If code and name are different, show both; otherwise show just one
    if (channel.code.isNotEmpty &&
        channel.name.isNotEmpty &&
        channel.code != channel.name) {
      return '$code - $name';
    } else {
      return name;
    }
  }

  /// Gets list of missing day names
  List<String> _getMissingDays(List<TimeBand> timeBands) {
    final Set<int> coveredDays = {};
    // API day numbering: 0=Sunday, 1=Monday, 2=Tuesday, 3=Wednesday, 4=Thursday, 5=Friday, 6=Saturday
    final dayNames = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];

    for (final timeBand in timeBands) {
      final apiDaysOfWeek = timeBand.daysOfWeek;
      if (apiDaysOfWeek.isNotEmpty) {
        for (final apiDay in apiDaysOfWeek) {
          if (apiDay >= 0 && apiDay <= 6) {
            coveredDays.add(apiDay);
          }
        }
      }
    }

    final missingDays = <String>[];
    for (int day = 0; day <= 6; day++) {
      if (!coveredDays.contains(day)) {
        missingDays.add(dayNames[day]);
      }
    }

    return missingDays;
  }

  /// Calculates total hour coverage from time bands
  double _calculateHourCoverage(List<TimeBand> timeBands) {
    if (timeBands.isEmpty) return 0.0;

    final List<({double start, double end})> timeRanges = [];

    for (final timeBand in timeBands) {
      // Special handling for "full" time band
      if (timeBand.name.toLowerCase() == 'full') {
        // Full time band covers full 24 hours
        return 24.0;
      }

      final startTime = _parseTimeToHours(timeBand.startTime);
      final endTime = _parseTimeToHours(timeBand.endTime);

      if (startTime != null && endTime != null) {
        // Check for zero-duration time bands (same start and end time)
        if (startTime == endTime) {
          print(
            '⚠️ Zero-duration time band detected: ${timeBand.name} (${timeBand.startTime} - ${timeBand.endTime})',
          );
          // Zero-duration time bands contribute 0 hours
          continue;
        }

        // Handle overnight periods (e.g., 22:00 - 06:00)
        if (endTime < startTime) {
          // Split into two ranges: start to 24:00 and 00:00 to end
          timeRanges.add((start: startTime, end: 24.0));
          if (endTime > 0) {
            timeRanges.add((start: 0.0, end: endTime));
          }
        } else {
          timeRanges.add((start: startTime, end: endTime));
        }
      }
    }

    // Merge overlapping ranges and calculate total coverage
    if (timeRanges.isEmpty) return 0.0;

    // Sort ranges by start time
    timeRanges.sort((a, b) => a.start.compareTo(b.start));

    double totalHours = 0;
    double currentStart = timeRanges.first.start;
    double currentEnd = timeRanges.first.end;

    for (int i = 1; i < timeRanges.length; i++) {
      final range = timeRanges[i];
      // Use a small epsilon for comparison to handle floating point precision
      const epsilon = 0.001; // About 3.6 seconds
      if (range.start <= currentEnd + epsilon) {
        // Overlapping or adjacent ranges - merge them
        if (range.end > currentEnd) {
          currentEnd = range.end;
        }
      } else {
        // Non-overlapping range - add previous range to total and start new one
        final rangeHours = currentEnd - currentStart;
        totalHours += rangeHours;
        currentStart = range.start;
        currentEnd = range.end;
      }
    }

    // Add the last range
    final lastRangeHours = currentEnd - currentStart;
    totalHours += lastRangeHours;

    // For validation purposes, full day coverage should be 24.0 hours
    // If we have coverage >= 24.0, we consider it complete
    return totalHours;
  }

  /// Calculates total day coverage from time bands
  int _calculateDayCoverage(List<TimeBand> timeBands) {
    if (timeBands.isEmpty) return 0;

    final Set<int> coveredDays = {};

    for (final timeBand in timeBands) {
      // Special handling for "full" time band
      if (timeBand.name.toLowerCase() == 'full') {
        // Full time band should cover all 7 days
        for (int day = 0; day <= 6; day++) {
          coveredDays.add(day);
        }
        continue;
      }

      // Get days of week from time band attributes (API: 0=Sunday, 6=Saturday)
      final apiDaysOfWeek = timeBand.daysOfWeek;

      if (apiDaysOfWeek.isNotEmpty) {
        // Convert API days (0-6) to standard days (0-6) and add to coverage
        for (final apiDay in apiDaysOfWeek) {
          if (apiDay >= 0 && apiDay <= 6) {
            coveredDays.add(apiDay);
          }
        }
      }
    }

    // Return the count of unique days covered (can be 0-7)
    // For validation, we need all 7 days (0,1,2,3,4,5,6)
    return coveredDays.length;
  }

  /// Parses time string (HH:mm or HH:mm:ss) to hours as double
  double? _parseTimeToHours(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hours = int.parse(parts[0]);
        final minutes = int.parse(parts[1]);
        double result = hours + (minutes / 60.0);

        // Handle special case for end-of-day times
        if (parts.length >= 3) {
          final seconds = int.parse(parts[2]);
          result += (seconds / 3600.0);

          // If this is 23:59:59, treat it as 24:00:00 for coverage calculation
          if (hours == 23 && minutes == 59 && seconds == 59) {
            result = 24.0;
          }
        }

        return result;
      }
    } catch (e) {
      // Invalid time format
      return null;
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_details.isEmpty) {
      AppToast.showWarning(
        context,
        message: 'Please add at least one time of use detail',
        title: 'Missing Details',
      );
      return;
    }

    // Additional validation: Check for any details with missing or invalid channels/time bands
    final invalidDetails = <String>[];
    for (int i = 0; i < _details.length; i++) {
      final detail = _details[i];
      if (detail.channelId <= 0) {
        invalidDetails.add('Row ${i + 1}: Channel is required');
      }
      if (detail.timeBandId <= 0) {
        invalidDetails.add('Row ${i + 1}: Time Band is required');
      }
    }

    if (invalidDetails.isNotEmpty) {
      AppToast.showWarning(
        context,
        message:
            'Please fix the following issues:\n${invalidDetails.join('\n')}',
        title: 'Invalid Details',
      );
      return;
    }

    // Validate 24-hour and 7-day coverage for each channel
    final coverageError = _validateChannelCoverage();
    if (coverageError != null) {
      AppToast.showWarning(
        context,
        message: coverageError,
        title: 'TOU Coverage Issues',
      );
      return;
    }

    // Update register codes from controllers before saving
    for (int i = 0; i < _details.length; i++) {
      String newRegisterCode = '';

      // First priority: get value from controller if it exists
      if (_registerCodeControllers.containsKey(i)) {
        newRegisterCode = _registerCodeControllers[i]!.text.trim();
      } else {
        // Fallback: use current detail value
        newRegisterCode = _details[i].registerDisplayCode.trim();
      }

      // Update the detail with the final register code value
      _details[i] = _details[i].copyWith(registerDisplayCode: newRegisterCode);
    }

    // Ensure details are sorted by PriorityOrder before saving
    _details.sort((a, b) => a.priorityOrder.compareTo(b.priorityOrder));

    try {
      setState(() => _isLoading = true);

      final response = widget.timeOfUse == null
          ? await _timeOfUseService.createTimeOfUse(
              code: _codeController.text.trim(),
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              timeOfUseDetails: _details,
            )
          : await _timeOfUseService.updateTimeOfUse(
              timeOfUse: widget.timeOfUse!.copyWith(
                code: _codeController.text.trim(),
                name: _nameController.text.trim(),
                description: _descriptionController.text.trim(),
              ),
              timeOfUseDetails: _details,
            );

      print(
        '📥 TOU Dialog: API response received - Success: ${response.success}',
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (response.success) {
          // Show success toast message
          AppToast.showSuccess(
            context,
            message: widget.timeOfUse == null
                ? 'Time of Use "${_nameController.text.trim()}" has been created successfully'
                : 'Time of Use "${_nameController.text.trim()}" has been updated successfully',
            title: widget.timeOfUse == null
                ? 'Created Successfully'
                : 'Updated Successfully',
          );

          // Call the callback if provided
          if (widget.onSaved != null) {
            widget.onSaved!();
          }

          // Close dialog and return true to trigger parent data refresh
          Navigator.of(context).pop(true);
        } else {
          // Show error toast message
          AppToast.showError(
            context,
            error: response.message ?? 'An unknown error occurred',
            title: widget.timeOfUse == null
                ? 'Creation Failed'
                : 'Update Failed',
          );
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);

        // Show error toast message for exceptions
        AppToast.showError(
          context,
          error: 'An unexpected error occurred: ${error.toString()}',
          title: 'Error',
        );
      }
    }
  }

  String get _actionButtonText {
    if (widget.isReadOnly && !_isEditMode) return '';
    return widget.timeOfUse == null ? 'Create' : 'Update';
  }

  @override
  Widget build(BuildContext context) {
    // Use ResponsiveHelper for consistent responsive behavior
    final dialogConstraints = ResponsiveHelper.getDialogConstraints(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      child: ConstrainedBox(
        constraints: dialogConstraints,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: _buildBody(),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: ResponsiveHelper.getPadding(context),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.borderColor)),
        color: context.surfaceColor,
      ),
      child: ResponsiveHelper.shouldUseCompactUI(context)
          ? _buildMobileFooter()
          : _buildDesktopFooter(),
    );
  }

  // Mobile footer - vertical button layout
  Widget _buildMobileFooter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.isReadOnly && !_isEditMode)
          // Show "Edit" button in view mode
          AppButton(text: 'Edit', onPressed: _toggleEditMode)
        else if (_isEditMode || widget.timeOfUse == null)
          // Show "Update" or "Create" button in edit mode
          AppButton(
            text: _actionButtonText,

            onPressed: _save,
            isLoading: _isLoading,
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
        if (widget.isReadOnly && !_isEditMode)
          // Show "Edit" button in view mode
          AppButton(text: 'Edit', onPressed: _toggleEditMode)
        else if (_isEditMode || widget.timeOfUse == null)
          // Show "Update" or "Create" button in edit mode
          AppButton(
            text: _actionButtonText,
            onPressed: _save,
            isLoading: _isLoading,
          ),
      ],
    );
  }

  Widget _buildHeader() {
    // Determine dialog type and content based on state
    final DialogType dialogType;
    final String title;
    final String subtitle;

    if (widget.timeOfUse == null) {
      dialogType = DialogType.create;
      title = 'Create Time of Use';
      subtitle = 'Set up new time-based usage configuration';
    } else if (widget.isReadOnly && !_isEditMode) {
      dialogType = DialogType.view;
      title = 'View Time of Use Details';
      subtitle = 'Review time-based usage configuration';
    } else {
      dialogType = DialogType.edit;
      title = 'Edit Time of Use';
      subtitle = 'Modify time-based usage configuration';
    }

    return AppDialogHeader(
      type: dialogType,
      title: title,
      subtitle: subtitle,
      onClose: () => Navigator.of(context).pop(),
      showCloseButton: true,
    );
  }

  Widget _buildBody() {
    if (_isLoading && _availableTimeBands.isEmpty) {
      return Container(
        color: context.backgroundColor,
        constraints: BoxConstraints(
          minHeight: ResponsiveHelper.shouldUseCompactUI(context) ? 300 : 400,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: ResponsiveHelper.getSpacing(context) * 10),
              AppLottieStateWidget.loading(
                lottieSize: ResponsiveHelper.shouldUseCompactUI(context)
                    ? 60
                    : 80,
              ),
              // SizedBox(height: ResponsiveHelper.getSpacing(context)),
            ],
          ),
        ),
      );
    }

    return Container(
      color: context.backgroundColor,
      padding: ResponsiveHelper.getPadding(context),
      constraints: BoxConstraints(minHeight: context.isMobile ? 300 : 400),
      child: Form(
        key: _formKey,
        child: context.isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mobile: Stack vertically with intrinsic sizing
                  _buildGeneralInfoGrid(),
                  SizedBox(height: ResponsiveHelper.getSpacing(context)),
                  _buildValidationGrid(),
                ],
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Desktop/Tablet: Side by side layout
                      Expanded(
                        flex: 1,
                        child: Container(
                          constraints: BoxConstraints(
                            maxHeight: constraints.maxHeight > 0
                                ? constraints.maxHeight
                                : 600,
                          ),
                          child: _buildGeneralInfoGrid(),
                        ),
                      ),
                      SizedBox(width: ResponsiveHelper.getSpacing(context) * 2),
                      Expanded(
                        flex: 1,
                        child: Container(
                          constraints: BoxConstraints(
                            maxHeight: constraints.maxHeight > 0
                                ? constraints.maxHeight
                                : 600,
                          ),
                          child: _buildValidationGrid(),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildGeneralInfoGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Basic Information Section
        Text(
          'Basic Information',
          style: TextStyle(
            fontSize: context.isMobile
                ? AppSizes.fontSizeMedium
                : AppSizes.fontSizeLarge,
            fontWeight: FontWeight.w600,
            color: context.textPrimaryColor,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getSpacing(context)),

        // Responsive layout for form fields
        context.isMobile
            ? Column(
                children: [
                  AppInputField(
                    controller: _codeController,
                    label: 'Code',
                    enabled: _isEditMode,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Code is required';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: ResponsiveHelper.getSpacing(context)),
                  AppInputField(
                    controller: _nameController,
                    label: 'Name',
                    enabled: _isEditMode,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: ResponsiveHelper.getSpacing(context)),
                  AppInputField(
                    controller: _descriptionController,
                    label: 'Description',
                    enabled: _isEditMode,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Description is required';
                      }
                      return null;
                    },
                  ),
                ],
              )
            : Row(
                children: [
                  // Code field
                  Expanded(
                    flex: 2,
                    child: AppInputField(
                      controller: _codeController,
                      label: 'Code',
                      enabled: _isEditMode,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Code is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getSpacing(context)),

                  // Name field
                  Expanded(
                    flex: 3,
                    child: AppInputField(
                      controller: _nameController,
                      label: 'Name',
                      enabled: _isEditMode,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getSpacing(context)),

                  // Description field
                  Expanded(
                    flex: 4,
                    child: AppInputField(
                      controller: _descriptionController,
                      label: 'Description',
                      enabled: _isEditMode,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Description is required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

        SizedBox(height: ResponsiveHelper.getSpacing(context) * 2),

        // Time of Use Details Section
        Row(
          children: [
            Text(
              'Time of Use Details',
              style: TextStyle(
                fontSize: context.isMobile
                    ? AppSizes.fontSizeMedium
                    : AppSizes.fontSizeLarge,
                fontWeight: FontWeight.w600,
                color: context.textPrimaryColor,
              ),
            ),
            const Spacer(),
            if (_isEditMode)
              AppButton(
                text: 'Add',
                type: AppButtonType.outline,
                onPressed: _addDetail,
              ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getSpacing(context)),

        // Scrollable Time of Use Details List with fixed height
        Container(
          height: context.isMobile ? 200 : 300,
          decoration: BoxDecoration(
            color: context.surfaceColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            border: Border.all(color: context.borderColor.withOpacity(0.5)),
          ),
          child: _details.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(AppSizes.spacing24),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.schedule,
                          color: context.textSecondaryColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: AppSizes.spacing8),
                        Text(
                          'No Time of Use details added yet',
                          style: TextStyle(
                            color: context.textSecondaryColor,
                            fontSize: AppSizes.fontSizeSmall,
                          ),
                        ),
                        if (_isEditMode) ...[
                          const SizedBox(height: AppSizes.spacing12),
                          AppButton(
                            text: 'Add First',
                            type: AppButtonType.outline,
                            onPressed: _addDetail,
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.all(AppSizes.spacing8),
                  buildDefaultDragHandles: false,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _details.length,
                  onReorder: _isEditMode
                      ? _reorderDetails
                      : (oldIndex, newIndex) {},
                  itemBuilder: (context, index) => Container(
                    key: ValueKey('detail_$index'),
                    margin: const EdgeInsets.only(bottom: AppSizes.spacing12),
                    child: _buildDetailItem(index, _details[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildValidationGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with title and filter dropdown
        Container(
          width: double.infinity,
          child: context.isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Time of use validate',
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeMedium,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    if (_details.isNotEmpty) ...[
                      SizedBox(height: ResponsiveHelper.getSpacing(context)),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 250),
                        child: AppSearchableDropdown<int?>(
                          value: _selectedFilterChannelId,
                          hintText: 'All Channels',
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text(
                                'All Selected Channels',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            ..._details.map((d) => d.channelId).toSet().map((
                              channelId,
                            ) {
                              final channel = _availableChannels.firstWhere(
                                (c) => c.id == channelId,
                                orElse: () => Channel.simple(
                                  id: channelId,
                                  name: 'Channel $channelId',
                                ),
                              );
                              return DropdownMenuItem<int?>(
                                value: channelId,
                                child: Text(
                                  _getFilterChannelDisplayText(channel),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedFilterChannelId = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Time of use validate',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeLarge,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimaryColor,
                        ),
                      ),
                    ),
                    // Channel filter dropdown
                    if (_details.isNotEmpty) ...[
                      SizedBox(width: ResponsiveHelper.getSpacing(context)),
                      Expanded(
                        flex: 1,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 250,
                            minWidth: 120,
                          ),
                          child: AppSearchableDropdown<int?>(
                            value: _selectedFilterChannelId,
                            hintText: 'All Channels',
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text(
                                  'All Selected Channels',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              ..._details.map((d) => d.channelId).toSet().map((
                                channelId,
                              ) {
                                final channel = _availableChannels.firstWhere(
                                  (c) => c.id == channelId,
                                  orElse: () => Channel.simple(
                                    id: channelId,
                                    name: 'Channel $channelId',
                                  ),
                                );
                                return DropdownMenuItem<int?>(
                                  value: channelId,
                                  child: Text(
                                    _getFilterChannelDisplayText(channel),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedFilterChannelId = value;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
        SizedBox(height: ResponsiveHelper.getSpacing(context)),

        // Validation Grid Container with responsive height
        Container(
          height: context.isMobile ? 250 : 550,
          decoration: BoxDecoration(
            color: context.surfaceColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            border: Border.all(color: context.borderColor.withOpacity(0.5)),
          ),
          child: _details.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(AppSizes.spacing24),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.grid_view,
                          color: context.textSecondaryColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: AppSizes.spacing8),
                        Text(
                          'No data to validate yet',
                          style: TextStyle(
                            color: context.textSecondaryColor,
                            fontSize: AppSizes.fontSizeSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : TOUFormValidationGrid(
                  timeOfUseDetails: _details,
                  availableTimeBands: _availableTimeBands,
                  availableChannels: _availableChannels,
                  selectedChannelIds: _details
                      .map((d) => d.channelId)
                      .toSet()
                      .toList(),
                  selectedFilterChannelId: _selectedFilterChannelId,
                  showLegend: true,
                ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(int index, TimeOfUseDetail detail) {
    final itemContent = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Priority Order indicator
        Container(
          width: 28,
          height: 28,
          margin: const EdgeInsets.only(top: 24), // Align with input fields
          decoration: BoxDecoration(
            color: context.primaryColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              '${detail.priorityOrder}',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSizes.spacing12),

        // Form fields - Time Band and Channel only
        Expanded(
          child: Column(
            children: [
              // Row with Time Band and Channel
              Row(
                children: [
                  // Time Band dropdown
                  Expanded(
                    flex: 3,
                    child: _buildEnhancedTimeBandDropdown(detail, index),
                  ),
                  const SizedBox(width: AppSizes.spacing8),

                  // Channel dropdown
                  Expanded(
                    flex: 3,
                    child: _buildEnhancedChannelDropdown(detail, index),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSizes.spacing12),

        // Register Code field with tooltip - moved to right side
        SizedBox(
          width: 120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Register Code',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeSmall,
                  fontWeight: FontWeight.w500,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: AppSizes.spacing8),
              SizedBox(
                height: AppSizes.inputHeight,
                child: TextFormField(
                  controller: _getRegisterCodeController(index),
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeSmall,
                    color: context.textPrimaryColor,
                  ),
                  readOnly: _isViewMode,
                  onChanged: (value) {
                    // The register code value is captured in the controller
                    // and will be synced to the detail object during save
                  },
                  enableInteractiveSelection: true,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'Enter code',
                    filled: true,
                    fillColor: context.surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                      borderSide: BorderSide(color: context.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                      borderSide: BorderSide(color: context.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.spacing16,
                      vertical: AppSizes.spacing12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Action buttons (Drag handle and Delete) - aligned with center of text input
        if (_isEditMode) ...[
          const SizedBox(width: AppSizes.spacing8),
          Container(
            margin: const EdgeInsets.only(
              top: 24,
            ), // Align with input field center
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle with tooltip
                Tooltip(
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  message: 'First order will be calculated first',
                  child: ReorderableDragStartListener(
                    index: index,
                    child: Icon(
                      Icons.drag_handle,
                      color: context.textSecondaryColor,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Delete button
                IconButton(
                  onPressed: () => _removeDetail(index),
                  icon: const Icon(Icons.delete_outline),
                  style: IconButton.styleFrom(
                    foregroundColor: context.errorColor,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(32, 32),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );

    // No need to wrap with drag listener since we have specific drag handle
    return itemContent;
  }

  /// Builds enhanced channel dropdown with code and name display
  Widget _buildEnhancedChannelDropdown(TimeOfUseDetail detail, int index) {
    return _CustomChannelDropdown(
      value: detail.channelId,
      channels: _availableChannels,
      enabled: _isEditMode,
      onChanged: _isEditMode
          ? (value) => _updateDetail(index, channelId: value)
          : null,
      validator: (value) {
        if (value == null) {
          return 'Channel is required';
        }
        return null;
      },
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();

    // Dispose all register code controllers
    for (final controller in _registerCodeControllers.values) {
      controller.dispose();
    }
    _registerCodeControllers.clear();

    super.dispose();
  }

  /// Gets display text for filter channel dropdown
  String _getFilterChannelDisplayText(Channel channel) {
    final code = channel.code.isEmpty ? 'CH${channel.id}' : channel.code;
    if (channel.name.isNotEmpty) {
      // Use a more compact format for dropdown
      return '${code} - ${channel.name}';
    }
    return code;
  }

  /// Builds enhanced time band dropdown with detailed information
  Widget _buildEnhancedTimeBandDropdown(TimeOfUseDetail detail, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time Band',
          style: TextStyle(
            fontSize: AppSizes.fontSizeSmall,
            fontWeight: FontWeight.w500,
            color: context.textPrimaryColor,
          ),
        ),
        const SizedBox(height: AppSizes.spacing8),

        // TextField that opens dialog when clicked
        SizedBox(
          height: AppSizes.inputHeight,
          child: GestureDetector(
            onTap: _isEditMode
                ? () => _showTimeBandTableDialog(detail, index)
                : null,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: context.borderColor),
                borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                color: _isEditMode
                    ? context.surfaceColor
                    : context.surfaceVariantColor,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacing16,
                  //vertical: AppSizes.spacing12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        _getSelectedTimeBandDisplayText(detail.timeBandId),
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeSmall,
                          color: detail.timeBandId > 0
                              ? context.textPrimaryColor
                              : context.textSecondaryColor,
                          fontWeight: FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_isEditMode)
                      Icon(
                        Icons.arrow_drop_down,
                        color: context.textSecondaryColor,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Gets display text for selected time band (only name)
  String _getSelectedTimeBandDisplayText(int timeBandId) {
    if (timeBandId <= 0) {
      return 'Select Time Band';
    }

    final selectedTimeBand = _availableTimeBands.firstWhere(
      (tb) => tb.id == timeBandId,
      orElse: () => TimeBand(
        id: timeBandId,
        name: 'TimeBand $timeBandId', // Show ID if name not found
        startTime: '',
        endTime: '',
        description: '',
        active: true,
      ),
    );

    // Return the name, or show ID if name is empty
    return selectedTimeBand.name.isNotEmpty
        ? selectedTimeBand.name
        : 'TimeBand $timeBandId';
  }

  /// Shows time band selection dialog with search and pagination (like Time Bands screen)
  void _showTimeBandTableDialog(TimeOfUseDetail detail, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _TimeBandSelectionDialog(
          availableTimeBands: _availableTimeBands,
          selectedTimeBandId: detail.timeBandId,
          onTimeBandSelected: (timeBandId) {
            _updateDetail(index, timeBandId: timeBandId);
          },
        );
      },
    );
  }
}

/// Custom channel dropdown that shows code in selected field and code+name in dropdown items
class _CustomChannelDropdown extends StatelessWidget {
  final int? value;
  final List<Channel> channels;
  final bool enabled;
  final ValueChanged<int?>? onChanged;
  final String? Function(int?)? validator;

  const _CustomChannelDropdown({
    this.value,
    required this.channels,
    this.enabled = true,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Channel',
              style: TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                fontWeight: FontWeight.w500,
                color: context.textPrimaryColor,
              ),
            ),
            // if (!enabled) ...[
            //   const SizedBox(width: 8),
            //   Tooltip(
            //     message: 'Channel dropdown is disabled in view mode',
            //     child: Icon(
            //       Icons.info_outline,
            //       size: 16,
            //       color: AppColors.textSecondary,
            //     ),
            //   ),
            // ],
          ],
        ),
        const SizedBox(height: 8),
        IgnorePointer(
          ignoring: !enabled, // Completely disable interaction when not enabled
          child: Opacity(
            opacity: enabled ? 1.0 : 0.6, // Visual feedback for disabled state
            child: AppSearchableDropdown<int>(
              value: value,
              hintText: enabled ? 'Select Channel' : 'Channel (View Only)',
              items: channels
                  .map(
                    (channel) => DropdownMenuItem<int>(
                      value: channel.id,
                      child: Text(
                        _getChannelDisplayText(channel),
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeSmall,
                          color: enabled
                              ? context.textPrimaryColor
                              : context.textSecondaryColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: enabled ? onChanged : null,
              validator: enabled
                  ? validator
                  : null, // Skip validation in view mode
            ),
          ),
        ),
      ],
    );
  }

  /// Gets display text for channel - code first, then name
  String _getChannelDisplayText(Channel channel) {
    final code = channel.code.isEmpty ? 'CH${channel.id}' : channel.code;
    return channel.name.isNotEmpty ? '$code - ${channel.name}' : code;
  }
}

/// Time Band Selection Dialog with BluNestDataTable (same style as Time Bands screen)
class _TimeBandSelectionDialog extends StatefulWidget {
  final List<TimeBand> availableTimeBands;
  final int? selectedTimeBandId;
  final Function(int) onTimeBandSelected;

  const _TimeBandSelectionDialog({
    required this.availableTimeBands,
    required this.selectedTimeBandId,
    required this.onTimeBandSelected,
  });

  @override
  State<_TimeBandSelectionDialog> createState() =>
      _TimeBandSelectionDialogState();
}

class _TimeBandSelectionDialogState extends State<_TimeBandSelectionDialog> {
  List<TimeBand> _filteredTimeBands = [];
  String _searchQuery = '';
  int _currentPage = 1;
  int _itemsPerPage = 10;
  int _totalPages = 1;
  String? _sortBy;
  bool _sortAscending = true;
  List<String> _hiddenColumns = ['id', 'attributes', 'status'];

  @override
  void initState() {
    super.initState();
    _filterTimeBands();
  }

  void _filterTimeBands() {
    _filteredTimeBands = widget.availableTimeBands.where((timeBand) {
      if (_searchQuery.isEmpty) return true;
      return timeBand.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          timeBand.description.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          '${timeBand.startTime} - ${timeBand.endTime}'.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
    }).toList();

    _totalPages = (_filteredTimeBands.length / _itemsPerPage).ceil();
    if (_totalPages == 0) _totalPages = 1;

    // Reset to first page if current page is out of bounds
    if (_currentPage > _totalPages) {
      _currentPage = 1;
    }
  }

  List<TimeBand> _getPaginatedTimeBands() {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(
      0,
      _filteredTimeBands.length,
    );

    if (startIndex >= _filteredTimeBands.length) return [];
    return _filteredTimeBands.sublist(startIndex, endIndex);
  }

  void _handleSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 1;
      _filterTimeBands();
    });
  }

  void _handlePageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _handlePageSizeChanged(int pageSize) {
    setState(() {
      _itemsPerPage = pageSize;
      _currentPage = 1;
      _filterTimeBands();
    });
  }

  void _handleSort(String sortBy, bool ascending) {
    setState(() {
      _sortBy = sortBy;
      _sortAscending = ascending;
    });
    // Apply sorting to filtered data
    _filteredTimeBands.sort((a, b) {
      dynamic aValue, bValue;
      switch (sortBy) {
        case 'name':
          aValue = a.name;
          bValue = b.name;
          break;
        case 'timeRange':
          aValue = a.startTime;
          bValue = b.startTime;
          break;
        case 'description':
          aValue = a.description;
          bValue = b.description;
          break;
        default:
          return 0;
      }
      final comparison = aValue.toString().compareTo(bValue.toString());
      return ascending ? comparison : -comparison;
    });
  }

  void _handleTimeBandSelection(TimeBand timeBand) {
    // Directly select and close dialog
    widget.onTimeBandSelected(timeBand.id);
    Navigator.of(context).pop();
  }

  List<BluNestTableColumn<TimeBand>> _buildTableColumns() {
    return [
      // Name column (with ID)
      BluNestTableColumn<TimeBand>(
        key: 'name',
        title: 'Name',
        sortable: true,
        flex: 2,
        builder: (timeBand) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              timeBand.name,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: context.textPrimaryColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              'ID: ${timeBand.id}',
              style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
            ),
          ],
        ),
      ),

      // Time Range column
      BluNestTableColumn<TimeBand>(
        key: 'timeRange',
        title: 'Time Range',
        sortable: true,
        flex: 2,
        builder: (timeBand) => Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacing8,
            vertical: AppSizes.spacing4,
          ),
          decoration: BoxDecoration(
            color: context.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
          child: Text(
            '${timeBand.startTime} - ${timeBand.endTime}',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      ),

      // Days of Week column
      BluNestTableColumn<TimeBand>(
        key: 'daysOfWeek',
        title: 'Days of Week',
        sortable: false,
        flex: 2,
        builder: (timeBand) => TimeBandSmartChips.buildDayOfWeekChips(
          timeBand.daysOfWeek,
          context,
        ),
      ),

      // Months column
      BluNestTableColumn<TimeBand>(
        key: 'months',
        title: 'Months',
        sortable: false,
        flex: 2,
        builder: (timeBand) => TimeBandSmartChips.buildMonthOfYearChips(
          timeBand.monthsOfYear,
          context,
        ),
      ),

      // Description column
      BluNestTableColumn<TimeBand>(
        key: 'description',
        title: 'Description',
        sortable: true,
        flex: 3,
        builder: (timeBand) => Text(
          timeBand.description.isNotEmpty
              ? timeBand.description
              : 'No description',
          style: TextStyle(
            fontSize: 13,
            color: timeBand.description.isNotEmpty
                ? context.textPrimaryColor
                : context.textSecondaryColor,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final paginatedTimeBands = _getPaginatedTimeBands();
    final dialogConstraints = ResponsiveHelper.getCustomDialogConstraints(
      context,
      mobileWidthRatio: 0.95,
      tabletWidthRatio: 0.9,
      desktopWidthRatio: 0.8,
      maxDesktopWidth: 1200,
      heightRatio: 0.85,
    );

    return Dialog(
      backgroundColor: context.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      child: ConstrainedBox(
        constraints: dialogConstraints,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Enhanced Header with AppDialogHeader
            AppDialogHeader(
              type: DialogType.view,
              title: 'Select Time Band',
              subtitle: 'Choose a time band for your configuration',
              onClose: () => Navigator.of(context).pop(),
              showCloseButton: true,
            ),

            // Search and Filter Section
            Container(
              padding: EdgeInsets.all(ResponsiveHelper.getSpacing(context)),
              decoration: BoxDecoration(
                color: context.backgroundColor,
                border: Border(bottom: BorderSide(color: context.borderColor)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search bar with item count
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: AppInputField.search(
                          hintText: 'Search time bands...',
                          prefixIcon: const Icon(Icons.search),
                          onChanged: _handleSearchChanged,
                        ),
                      ),
                      const SizedBox(width: AppSizes.spacing12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.spacing12,
                          vertical: AppSizes.spacing8,
                        ),
                        decoration: BoxDecoration(
                          color: context.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMedium,
                          ),
                        ),
                        child: Text(
                          '${_filteredTimeBands.length} items',
                          style: TextStyle(
                            fontSize: AppSizes.fontSizeSmall,
                            fontWeight: FontWeight.w500,
                            color: context.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.spacing8),
                  // Instruction text
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.spacing12,
                      vertical: AppSizes.spacing8,
                    ),
                    decoration: BoxDecoration(
                      color: context.infoColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        AppSizes.radiusMedium,
                      ),
                      border: Border.all(
                        color: context.infoColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: AppSizes.iconSmall,
                          color: context.infoColor,
                        ),
                        const SizedBox(width: AppSizes.spacing8),
                        Expanded(
                          child: Text(
                            'Click on any row to select the time band',
                            style: TextStyle(
                              fontSize: AppSizes.fontSizeSmall,
                              color: context.infoColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // BluNestDataTable (same style as Time Bands screen) - Scrollable
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(AppSizes.spacing16),
                decoration: BoxDecoration(
                  color: context.backgroundColor,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                  boxShadow: [AppSizes.shadowSmall],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SizedBox(
                        height: constraints.maxHeight,
                        child: BluNestDataTable<TimeBand>(
                          data: paginatedTimeBands,
                          columns: _buildTableColumns(),
                          onRowTap: _handleTimeBandSelection,
                          onSort: _handleSort,
                          sortBy: _sortBy,
                          sortAscending: _sortAscending,
                          enableMultiSelect: false,
                          hiddenColumns: _hiddenColumns,
                          emptyState: Center(
                            child: AppLottieStateWidget.noData(
                              title: _searchQuery.isNotEmpty
                                  ? 'No matches found'
                                  : 'No time bands available',
                              message: _searchQuery.isNotEmpty
                                  ? 'No time bands found matching "$_searchQuery"'
                                  : 'No time bands available',
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Pagination and footer
            Container(
              padding: const EdgeInsets.all(AppSizes.spacing16),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                border: Border(top: BorderSide(color: context.borderColor)),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppSizes.radiusLarge),
                  bottomRight: Radius.circular(AppSizes.radiusLarge),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pagination - Always visible for consistency
                  Container(
                    color: context.surfaceColor,
                    margin: EdgeInsets.only(
                      bottom: ResponsiveHelper.getSpacing(context),
                    ),
                    child: ResultsPagination(
                      currentPage: _currentPage,
                      totalPages: _totalPages,
                      totalItems: _filteredTimeBands.length,
                      itemsPerPage: _itemsPerPage,
                      itemsPerPageOptions: const [5, 10, 20, 50],
                      startItem: (_currentPage - 1) * _itemsPerPage + 1,
                      endItem:
                          (_currentPage * _itemsPerPage >
                              _filteredTimeBands.length)
                          ? _filteredTimeBands.length
                          : _currentPage * _itemsPerPage,
                      onPageChanged: _handlePageChanged,
                      onItemsPerPageChanged: _handlePageSizeChanged,
                    ),
                  ),

                  // Action buttons - Only Cancel button needed
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AppButton(
                        text: 'Cancel',
                        type: AppButtonType.outline,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
