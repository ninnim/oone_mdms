import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/time_of_use.dart';
import '../../../core/models/time_band.dart';
import '../../../core/services/time_of_use_service.dart';
import '../common/app_button.dart';
import '../common/app_input_field.dart';
import '../common/app_dropdown_field.dart';
import '../common/app_toast.dart';
import '../common/app_lottie_state_widget.dart';
import '../common/blunest_data_table.dart';
import '../common/results_pagination.dart';
import '../time_bands/time_band_smart_chips.dart';
import 'tou_form_validation_grid.dart';

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
  List<TimeBand> _availableTimeBands = [];
  List<Channel> _availableChannels = [];
  int? _selectedFilterChannelId; // Channel filter for validation grid
  Map<String, TextEditingController> _registerCodeControllers = {};
  int _detailIdCounter = 0; // Counter for generating unique IDs for new details
  final Map<TimeOfUseDetail, String> _detailToIdMap =
      {}; // Map to track detail unique IDs

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

      // Initialize mapping for existing details
      for (final detail in _details) {
        if (detail.id == null) {
          // For details without IDs, generate unique IDs
          _detailToIdMap[detail] = 'existing_detail_${_detailIdCounter++}';
        }
      }
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
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _toggleEditMode() {
    setState(() => _isEditMode = !_isEditMode);
  }

  void _cancel() {
    Navigator.of(context).pop();
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

      // Generate unique ID for new detail
      _detailToIdMap[newDetail] = 'new_detail_${_detailIdCounter++}';

      _cleanupControllers();
    });
  }

  void _removeDetail(int index) {
    setState(() {
      final detailToRemove = _details[index];

      // Dispose the controller for the removed item
      final detailId = _getDetailUniqueId(detailToRemove);
      if (_registerCodeControllers.containsKey(detailId)) {
        _registerCodeControllers[detailId]!.dispose();
        _registerCodeControllers.remove(detailId);
      }

      // Remove from mapping if it's a new detail
      _detailToIdMap.remove(detailToRemove);

      _details.removeAt(index);

      // Update priority order for remaining items
      for (int i = 0; i < _details.length; i++) {
        _details[i] = _details[i].copyWith(priorityOrder: i + 1);
      }

      _cleanupControllers();
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

      // If we're creating a new detail object, we need to update the mapping
      if (_detailToIdMap.containsKey(oldDetail)) {
        final uniqueId = _detailToIdMap[oldDetail]!;
        _detailToIdMap.remove(oldDetail);
        _detailToIdMap[newDetail] = uniqueId;
      }

      _details[index] = newDetail;
    });
  }

  void _reorderDetails(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _details.removeAt(oldIndex);
      _details.insert(newIndex, item);

      // Update priority order based on new positions
      for (int i = 0; i < _details.length; i++) {
        _details[i] = _details[i].copyWith(priorityOrder: i + 1);
      }
    });
  }

  String _getDetailUniqueId(TimeOfUseDetail detail) {
    // For existing details, use their ID from the backend
    if (detail.id != null) {
      return detail.id.toString();
    }

    // For new details, use the generated unique ID
    if (_detailToIdMap.containsKey(detail)) {
      return _detailToIdMap[detail]!;
    }

    // Fallback - this shouldn't happen if _addDetail is used properly
    final uniqueId = 'fallback_detail_${_detailIdCounter++}';
    _detailToIdMap[detail] = uniqueId;
    return uniqueId;
  }

  TextEditingController _getRegisterCodeController(
    TimeOfUseDetail detail,
    String initialValue,
  ) {
    final detailId = _getDetailUniqueId(detail);
    if (!_registerCodeControllers.containsKey(detailId)) {
      _registerCodeControllers[detailId] = TextEditingController(
        text: initialValue,
      );
    }
    return _registerCodeControllers[detailId]!;
  }

  void _cleanupControllers() {
    // Remove controllers for items that no longer exist
    final validIds = _details
        .map((detail) => _getDetailUniqueId(detail))
        .toSet();
    _registerCodeControllers.removeWhere((key, controller) {
      if (!validIds.contains(key)) {
        controller.dispose();
        return true;
      }
      return false;
    });
  }

  /// Validates that each channel has 24-hour and 7-day coverage with detailed error messages
  String? _validateChannelCoverage() {
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
        allErrors.add('❌ $channelName: No time bands assigned');
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
        // Handle overnight periods (e.g., 22:00 - 06:00)
        if (endTime <= startTime) {
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
    print('🔄 TOU Dialog: Save method called');
    if (!_formKey.currentState!.validate()) {
      print('❌ TOU Dialog: Form validation failed');
      return;
    }
    if (_details.isEmpty) {
      print('❌ TOU Dialog: No details provided');
      AppToast.showWarning(
        context,
        message: 'Please add at least one time of use detail',
        title: 'Missing Details',
      );
      return;
    }

    // Validate 24-hour and 7-day coverage for each channel
    final coverageError = _validateChannelCoverage();
    if (coverageError != null) {
      print('❌ TOU Dialog: Coverage validation failed');
      AppToast.showWarning(
        context,
        message: coverageError,
        title: 'TOU Coverage Issues',
      );
      return;
    }

    print('✅ TOU Dialog: All validations passed, proceeding with save');

    // Update register codes from controllers before saving
    for (int i = 0; i < _details.length; i++) {
      final detailId = _getDetailUniqueId(_details[i]);
      if (_registerCodeControllers.containsKey(detailId)) {
        _details[i] = _details[i].copyWith(
          registerDisplayCode: _registerCodeControllers[detailId]!.text.trim(),
        );
      }
    }

    // Ensure details are sorted by PriorityOrder before saving
    _details.sort((a, b) => a.priorityOrder.compareTo(b.priorityOrder));

    try {
      setState(() => _isLoading = true);
      print('🔄 TOU Dialog: Starting API call...');

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
          print('✅ TOU Dialog: Save successful, showing success toast');
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
            print('🔄 TOU Dialog: Calling onSaved callback');
            widget.onSaved!();
          }

          print(
            '🚪 TOU Dialog: Closing dialog with result=true to trigger parent refresh',
          );
          // Close dialog and return true to trigger parent data refresh
          Navigator.of(context).pop(true);
        } else {
          print('❌ TOU Dialog: Save failed - ${response.message}');
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
      print('💥 TOU Dialog: Exception during save - $error');
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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      child: SizedBox(
        width:
            MediaQuery.of(context).size.width *
            0.95, // Wider for side-by-side layout
        height:
            MediaQuery.of(context).size.height *
            0.95, // Appropriate height for horizontal layout
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppButton(
            text: 'Cancel',
            type: AppButtonType.outline,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: AppSizes.spacing12),
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
      ),
    );
  }

  Widget _buildHeader() {
    final title = widget.timeOfUse == null
        ? 'Create Time of Use'
        : widget.isReadOnly && !_isEditMode
        ? 'View Time of Use Details'
        : 'Edit Time of Use';

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Icon(
            widget.timeOfUse == null ? Icons.add : Icons.schedule,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: AppSizes.spacing8),
          Text(
            title,
            style: const TextStyle(
              fontSize: AppSizes.fontSizeLarge,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.textSecondary.withOpacity(0.1),
              foregroundColor: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _availableTimeBands.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      child: Form(
        key: _formKey,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: General Information + Time of Use Details
            Expanded(flex: 1, child: _buildGeneralInfoGrid()),
            const SizedBox(width: AppSizes.spacing24),

            // Right Column: TOU Validation Grid
            Expanded(flex: 1, child: _buildValidationGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralInfoGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Basic Information Section
        const Text(
          'Basic Information',
          style: TextStyle(
            fontSize: AppSizes.fontSizeLarge,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.spacing16),

        // Single row for Code, Name, and Description
        Row(
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
            const SizedBox(width: AppSizes.spacing12),

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
            const SizedBox(width: AppSizes.spacing12),

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

        const SizedBox(height: AppSizes.spacing24),

        // Time of Use Details Section
        Row(
          children: [
            const Text(
              'Time of Use Details',
              style: TextStyle(
                fontSize: AppSizes.fontSizeLarge,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
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
        const SizedBox(height: AppSizes.spacing16),

        // Scrollable Time of Use Details List
        Expanded(
          child: _details.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(AppSizes.spacing24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.schedule,
                          color: AppColors.textSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: AppSizes.spacing8),
                        Text(
                          'No Time of Use details added yet',
                          style: TextStyle(
                            color: AppColors.textSecondary,
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
                  buildDefaultDragHandles: false,
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

      children: [
        // Header with title and filter dropdown
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Time of use validate',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeLarge,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            // Channel filter dropdown
            const Spacer(),
            if (_details.isNotEmpty) ...[
              const SizedBox(width: AppSizes.spacing8),
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 200,
                    minWidth: 150,
                  ),
                  child: AppSearchableDropdown<int?>(
                    value: _selectedFilterChannelId,
                    hintText: 'All Selected Channels',
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('All Selected Channels'),
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
                          child: Text(_getFilterChannelDisplayText(channel)),
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
        const SizedBox(height: AppSizes.spacing16),

        // Scrollable Validation Grid Container
        Expanded(
          flex: 1,
          child: _details.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(AppSizes.spacing24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.grid_view,
                          color: AppColors.textSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: AppSizes.spacing8),
                        Text(
                          'No data to validate yet',
                          style: TextStyle(
                            color: AppColors.textSecondary,
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
                  // No height specified - will expand to fill available space
                  showLegend: true,
                ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(int index, TimeOfUseDetail detail) {
    final itemContent = Container(
      padding: const EdgeInsets.all(AppSizes.spacing12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Priority order indicator with drag icon
          Container(
            padding: const EdgeInsets.only(
              top: 28,
            ), // Align with first input field
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Priority number circle
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${detail.priorityOrder}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: AppSizes.fontSizeSmall,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                // Drag icon
                if (_isEditMode) ...[
                  const SizedBox(height: 4),
                  ReorderableDragStartListener(
                    index: index,
                    child: const Icon(
                      Icons.drag_handle,
                      color: AppColors.textSecondary,
                      size: 16,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSizes.spacing12),

          // Form fields in a column
          Expanded(
            child: Column(
              children: [
                // Row with Register Code, Time Band and Channel
                Row(
                  children: [
                    // Register Code field
                    Expanded(
                      flex: 2,
                      child: AppInputField(
                        controller: _getRegisterCodeController(
                          detail,
                          detail.registerDisplayCode,
                        ),
                        label: 'Register Code',
                        enabled: _isEditMode,
                        onChanged: (value) =>
                            _updateDetail(index, registerDisplayCode: value),
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacing8),

                    // Time Band dropdown
                    Expanded(
                      flex: 3,
                      child: _buildEnhancedTimeBandDropdown(detail, index),
                    ),
                    const SizedBox(width: AppSizes.spacing8),

                    // Channel dropdown
                    Expanded(
                      flex: 2,
                      child: _buildEnhancedChannelDropdown(detail, index),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Delete button
          if (_isEditMode) ...[
            const SizedBox(width: AppSizes.spacing12),
            Container(
              padding: const EdgeInsets.only(
                top: 28,
              ), // Align with first input field
              child: IconButton(
                onPressed: () => _removeDetail(index),
                icon: const Icon(Icons.delete_outline),
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.error,
                  backgroundColor: AppColors.surfaceVariant,
                ),
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ),
          ],
        ],
      ),
    );

    // Wrap with drag listener if in edit mode
    if (_isEditMode) {
      return ReorderableDragStartListener(index: index, child: itemContent);
    } else {
      return itemContent;
    }
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
    return channel.name.isNotEmpty ? '$code - ${channel.name}' : code;
  }

  /// Builds enhanced time band dropdown with detailed information
  Widget _buildEnhancedTimeBandDropdown(TimeOfUseDetail detail, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Time Band',
          style: TextStyle(
            fontSize: AppSizes.fontSizeSmall,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
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
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                color: _isEditMode
                    ? Theme.of(context).colorScheme.surface
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
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
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_isEditMode)
                      Icon(
                        Icons.arrow_drop_down,
                        color: AppColors.textSecondary,
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
        const Text(
          'Channel',
          style: TextStyle(
            fontSize: AppSizes.fontSizeSmall,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        AppSearchableDropdown<int>(
          value: value,
          hintText: 'Select Channel',
          items: channels
              .map(
                (channel) => DropdownMenuItem<int>(
                  value: channel.id,
                  child: Text(
                    _getChannelDisplayText(channel),
                    style: const TextStyle(
                      fontSize: AppSizes.fontSizeSmall,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: enabled ? onChanged : null,
          validator: validator,
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
  int? _selectedTimeBandId;
  String? _sortBy;
  bool _sortAscending = true;
  List<String> _hiddenColumns = ['id', 'attributes', 'status'];

  @override
  void initState() {
    super.initState();
    _selectedTimeBandId = widget.selectedTimeBandId;
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
    setState(() {
      _selectedTimeBandId = timeBand.id;
    });
  }

  List<BluNestTableColumn<TimeBand>> _buildTableColumns() {
    return [
      // Selection column
      BluNestTableColumn<TimeBand>(
        key: 'selection',
        title: '',
        flex: 1,
        builder: (timeBand) => Radio<int>(
          value: timeBand.id,
          groupValue: _selectedTimeBandId,
          onChanged: (value) {
            if (value != null) {
              _handleTimeBandSelection(timeBand);
            }
          },
        ),
      ),

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
                fontWeight: _selectedTimeBandId == timeBand.id
                    ? FontWeight.w600
                    : FontWeight.w500,
                fontSize: 14,
                color: _selectedTimeBandId == timeBand.id
                    ? AppColors.primary
                    : AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              'ID: ${timeBand.id}',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          ),
          child: Text(
            '${timeBand.startTime} - ${timeBand.endTime}',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
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
        builder: (timeBand) =>
            TimeBandSmartChips.buildDayOfWeekChips(timeBand.daysOfWeek),
      ),

      // Months column
      BluNestTableColumn<TimeBand>(
        key: 'months',
        title: 'Months',
        sortable: false,
        flex: 2,
        builder: (timeBand) =>
            TimeBandSmartChips.buildMonthOfYearChips(timeBand.monthsOfYear),
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
                ? AppColors.textPrimary
                : AppColors.textSecondary,
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

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.85,
        constraints: const BoxConstraints(maxWidth: 1400, maxHeight: 800),
        child: Column(
          children: [
            // Header with search
            Container(
              padding: const EdgeInsets.all(AppSizes.spacing16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border)),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppSizes.radiusLarge),
                  topRight: Radius.circular(AppSizes.radiusLarge),
                ),
              ),
              child: Column(
                children: [
                  // Title row
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'Select Time Band',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeLarge,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          foregroundColor: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.spacing16),
                  // Search bar
                  Row(
                    children: [
                      Expanded(
                        child: AppInputField(
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
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusSmall,
                          ),
                        ),
                        child: Text(
                          '${_filteredTimeBands.length} items',
                          style: const TextStyle(
                            fontSize: AppSizes.fontSizeSmall,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // BluNestDataTable (same style as Time Bands screen)
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(AppSizes.spacing16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
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
              ),
            ),

            // Pagination and footer
            Container(
              padding: const EdgeInsets.all(AppSizes.spacing16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppSizes.radiusLarge),
                  bottomRight: Radius.circular(AppSizes.radiusLarge),
                ),
              ),
              child: Column(
                children: [
                  // Pagination - Always visible for consistency
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSizes.spacing16),
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

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AppButton(
                        text: 'Cancel',
                        type: AppButtonType.outline,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: AppSizes.spacing12),
                      AppButton(
                        text: 'Select',
                        onPressed: _selectedTimeBandId != null
                            ? () {
                                widget.onTimeBandSelected(_selectedTimeBandId!);
                                Navigator.of(context).pop();
                              }
                            : null,
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
