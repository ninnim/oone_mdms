import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/time_band.dart';
import '../../../core/models/season.dart';
import '../../../core/models/special_day.dart';
import '../../../core/services/time_band_service.dart';
import '../../../core/services/season_service.dart';
import '../../../core/services/special_day_service.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_input_field.dart';
import '../../widgets/common/app_dropdown_field.dart';
import '../../widgets/common/app_toast.dart';

class TimeBandFormDialog extends StatefulWidget {
  final TimeBand? timeBand;
  final VoidCallback? onSaved;
  final bool isViewMode;

  const TimeBandFormDialog({
    super.key,
    this.timeBand,
    this.onSaved,
    this.isViewMode = false,
  });

  @override
  State<TimeBandFormDialog> createState() => _TimeBandFormDialogState();
}

class _TimeBandFormDialogState extends State<TimeBandFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();

  bool _isLoading = false;
  bool _isEditMode =
      false; // Track if we're in edit mode when started as view mode
  List<int> _selectedDaysOfWeek = [];
  List<int> _selectedMonthsOfYear = [];
  List<int> _selectedSeasonIds = [];
  List<int> _selectedSpecialDayIds = [];

  // Options for dropdowns (API uses 0=Sunday, 1=Monday, ..., 6=Saturday)
  final List<Map<String, dynamic>> _daysOfWeekOptions = [
    {'value': 1, 'label': 'Monday'},
    {'value': 2, 'label': 'Tuesday'},
    {'value': 3, 'label': 'Wednesday'},
    {'value': 4, 'label': 'Thursday'},
    {'value': 5, 'label': 'Friday'},
    {'value': 6, 'label': 'Saturday'},
    {'value': 0, 'label': 'Sunday'},
  ];

  final List<Map<String, dynamic>> _monthsOfYearOptions = [
    {'value': 1, 'label': 'January'},
    {'value': 2, 'label': 'February'},
    {'value': 3, 'label': 'March'},
    {'value': 4, 'label': 'April'},
    {'value': 5, 'label': 'May'},
    {'value': 6, 'label': 'June'},
    {'value': 7, 'label': 'July'},
    {'value': 8, 'label': 'August'},
    {'value': 9, 'label': 'September'},
    {'value': 10, 'label': 'October'},
    {'value': 11, 'label': 'November'},
    {'value': 12, 'label': 'December'},
  ];

  List<Season> _availableSeasons = [];
  List<SpecialDay> _availableSpecialDays = [];

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadDropdownData();
  }

  void _initializeForm() {
    if (widget.timeBand != null) {
      final timeBand = widget.timeBand!;
      _nameController.text = timeBand.name;
      _descriptionController.text = timeBand.description;
      _startTimeController.text = _formatTimeForDisplay(timeBand.startTime);
      _endTimeController.text = _formatTimeForDisplay(timeBand.endTime);
      _selectedDaysOfWeek = List.from(timeBand.daysOfWeek);
      _selectedMonthsOfYear = List.from(timeBand.monthsOfYear);
      _selectedSeasonIds = List.from(timeBand.seasonIds);
      _selectedSpecialDayIds = List.from(timeBand.specialDayIds);
    } else {
      // ✨ Enhanced: Initialize with default values for new time band
      // Default to all days of week (0=Sunday to 6=Saturday)
      _selectedDaysOfWeek = [
        0,
        1,
        2,
        3,
        4,
        5,
        6,
      ]; // All days selected by default

      // Default to all months of year (1=January to 12=December)
      _selectedMonthsOfYear = [
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
      ]; // All months selected by default

      // Seasons and Special Days remain empty as they are optional
      _selectedSeasonIds = [];
      _selectedSpecialDayIds = [];
    }
  }

  // Format time for display in form (convert HH:mm:ss to HH:mm:ss for API compatibility)
  String _formatTimeForDisplay(String time) {
    // If time is in HH:mm format, add seconds
    if (time.contains(':') && time.split(':').length == 2) {
      return '$time:00';
    }
    // If already in HH:mm:ss format, keep as is
    return time;
  }

  Future<void> _loadDropdownData() async {
    try {
      final seasonService = Provider.of<SeasonService>(context, listen: false);
      final specialDayService = Provider.of<SpecialDayService>(
        context,
        listen: false,
      );

      // Load seasons from service
      final seasonResponse = await seasonService.getSeasons(limit: 100);
      if (seasonResponse.success) {
        _availableSeasons = seasonResponse.data ?? [];
      }

      // Load special days from service
      final specialDayResponse = await specialDayService.getSpecialDays(
        limit: 100,
      );
      if (specialDayResponse.success) {
        _availableSpecialDays = specialDayResponse.data ?? [];
      }

      // Validate selected values after loading dropdown data
      _validateAndCleanSelections();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(
          context,
          error: 'Failed to load dropdown data: ${e.toString()}',
        );
      }
    }
  }

  // Validate and clean selections to ensure they match available options
  void _validateAndCleanSelections() {
    // Clean season selections
    if (_selectedSeasonIds.isNotEmpty) {
      final validSeasonIds = _availableSeasons.map((s) => s.id).toSet();
      _selectedSeasonIds = _selectedSeasonIds
          .where((id) => validSeasonIds.contains(id))
          .toList();
    }

    // Clean special day selections
    if (_selectedSpecialDayIds.isNotEmpty) {
      final validSpecialDayIds = _availableSpecialDays.map((s) => s.id).toSet();
      _selectedSpecialDayIds = _selectedSpecialDayIds
          .where((id) => validSpecialDayIds.contains(id))
          .toList();
    }
  }

  // Helper methods to create unique dropdown items
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      print('🔍 Form validation failed');
      return;
    }

    // Validate time format and range
    if (!_validateTimes()) {
      print('🔍 Time validation failed');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final timeBandService = Provider.of<TimeBandService>(
        context,
        listen: false,
      );

      // Format time to HH:mm:ss for API
      final formattedStartTime = _startTimeController.text.trim().length == 5
          ? '${_startTimeController.text.trim()}:00'
          : _startTimeController.text.trim();
      final formattedEndTime = _endTimeController.text.trim().length == 5
          ? '${_endTimeController.text.trim()}:00'
          : _endTimeController.text.trim();

      print('🔍 Form data:');
      print('  Name: ${_nameController.text.trim()}');
      print('  Start: $formattedStartTime');
      print('  End: $formattedEndTime');
      print('  Description: ${_descriptionController.text.trim()}');
      print('  Days: $_selectedDaysOfWeek');
      print('  Months: $_selectedMonthsOfYear');
      print('  Seasons: $_selectedSeasonIds');
      print('  Special Days: $_selectedSpecialDayIds');

      if (widget.timeBand != null) {
        // Update existing time band
        final updatedTimeBand = TimeBand(
          id: widget.timeBand!.id,
          name: _nameController.text.trim(),
          startTime: formattedStartTime,
          endTime: formattedEndTime,
          description: _descriptionController.text.trim(),
          active: widget.timeBand!.active,
          timeBandAttributes: widget.timeBand!.timeBandAttributes,
        );

        final response = await timeBandService.updateTimeBand(
          timeBand: updatedTimeBand,
          daysOfWeek: _selectedDaysOfWeek,
          monthsOfYear: _selectedMonthsOfYear,
          seasonIds: _selectedSeasonIds,
          specialDayIds: _selectedSpecialDayIds,
        );

        if (response.success) {
          print('✅ Update successful');
          if (mounted) {
            AppToast.showSuccess(
              context,
              message: 'Time band updated successfully',
            );
            // Use maybePop to safely close dialog
            Navigator.of(context).maybePop();
            widget.onSaved?.call();
          }
        } else {
          print('❌ Update failed: ${response.message}');
          if (mounted) {
            AppToast.showError(context, error: response.message);
          }
        }
      } else {
        // Create new time band
        final response = await timeBandService.createTimeBand(
          name: _nameController.text.trim(),
          startTime: formattedStartTime,
          endTime: formattedEndTime,
          description: _descriptionController.text.trim(),
          daysOfWeek: _selectedDaysOfWeek,
          monthsOfYear: _selectedMonthsOfYear,
          seasonIds: _selectedSeasonIds,
          specialDayIds: _selectedSpecialDayIds,
        );

        if (response.success) {
          print('✅ Create successful');
          if (mounted) {
            AppToast.showSuccess(
              context,
              message: 'Time band created successfully',
            );
            // Use maybePop to safely close dialog
            Navigator.of(context).maybePop();
            widget.onSaved?.call();
          }
        } else {
          print('❌ Create failed: ${response.message}');
          if (mounted) {
            AppToast.showError(context, error: response.message);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(
          context,
          error: 'Error saving time band: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _validateTimes() {
    final timeBandService = Provider.of<TimeBandService>(
      context,
      listen: false,
    );

    final startTime = _startTimeController.text.trim();
    final endTime = _endTimeController.text.trim();

    if (!timeBandService.validateTimeFormat(startTime)) {
      AppToast.showError(
        context,
        error: 'Invalid start time format. Use HH:mm (24-hour)',
      );
      return false;
    }

    if (!timeBandService.validateTimeFormat(endTime)) {
      AppToast.showError(
        context,
        error: 'Invalid end time format. Use HH:mm (24-hour)',
      );
      return false;
    }

    if (!timeBandService.validateTimeRange(startTime, endTime)) {
      AppToast.showError(
        context,
        error: 'Invalid time format. Please check start and end times.',
      );
      return false;
    }

    return true;
  }

  Future<void> _selectTime(TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00';
      controller.text = formattedTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isReadOnly = widget.isViewMode && !_isEditMode;
    final String dialogTitle = widget.isViewMode && !_isEditMode
        ? 'View Time Band Details'
        : widget.timeBand != null
        ? 'Edit Time Band'
        : 'Create Time Band';

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      child: SizedBox(
        // width: 600,
        // constraints: const BoxConstraints(maxHeight: 700),
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppSizes.spacing16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Text(
                    dialogTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusSmall,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.spacing16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Information
                      Text(
                        'Basic Information',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: AppSizes.spacing12),

                      // Name field
                      AppInputField(
                        label: 'Name*',
                        controller: _nameController,
                        enabled: !isReadOnly,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSizes.spacing16),

                      // Description field
                      AppInputField(
                        label: 'Description',
                        controller: _descriptionController,
                        enabled: !isReadOnly,
                        maxLines: 3,
                      ),
                      const SizedBox(height: AppSizes.spacing16),

                      // Time Configuration
                      Text(
                        'Time Configuration',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: AppSizes.spacing12),

                      // Time range fields
                      Row(
                        children: [
                          Expanded(
                            child: AppInputField(
                              label: 'Start Time*',
                              controller: _startTimeController,
                              enabled: !isReadOnly,
                              hintText: 'HH:mm (24-hour)',
                              suffixIcon: isReadOnly
                                  ? const Icon(
                                      Icons.access_time,
                                      color: Colors.grey,
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.access_time),
                                      onPressed: () =>
                                          _selectTime(_startTimeController),
                                    ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Start time is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: AppSizes.spacing16),
                          Expanded(
                            child: AppInputField(
                              label: 'End Time*',
                              controller: _endTimeController,
                              enabled: !isReadOnly,
                              hintText: 'HH:mm (24-hour)',
                              suffixIcon: isReadOnly
                                  ? const Icon(
                                      Icons.access_time,
                                      color: Colors.grey,
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.access_time),
                                      onPressed: () =>
                                          _selectTime(_endTimeController),
                                    ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'End time is required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.spacing24),

                      // Attribute Configuration
                      Text(
                        'Time Band Attributes',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: AppSizes.spacing12),

                      // Days of Week
                      _buildMultiSelectChips(
                        'Days of Week',
                        _daysOfWeekOptions,
                        _selectedDaysOfWeek,
                        (selectedValues) {
                          setState(() {
                            _selectedDaysOfWeek = selectedValues;
                          });
                        },
                        enabled: !isReadOnly,
                      ),
                      const SizedBox(height: AppSizes.spacing16),

                      // Months of Year
                      _buildMultiSelectChips(
                        'Months of Year',
                        _monthsOfYearOptions,
                        _selectedMonthsOfYear,
                        (selectedValues) {
                          setState(() {
                            _selectedMonthsOfYear = selectedValues;
                          });
                        },
                        enabled: !isReadOnly,
                      ),
                      const SizedBox(height: AppSizes.spacing16),

                      // Seasons dropdown (when available)
                      if (_availableSeasons.isNotEmpty) ...[
                        const SizedBox(height: AppSizes.spacing16),
                        AppSearchableDropdown<int>(
                          label: 'Seasons',
                          hintText: 'Select a season',
                          enabled: !isReadOnly,
                          value: _selectedSeasonIds.isNotEmpty
                              ? _selectedSeasonIds.first
                              : null,
                          items: _availableSeasons
                              .map(
                                (season) => DropdownMenuItem<int>(
                                  value: season.id,
                                  child: Text(season.name),
                                ),
                              )
                              .toList(),
                          onChanged: isReadOnly
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedSeasonIds = value != null
                                        ? [value]
                                        : [];
                                  });
                                },
                        ),
                      ],

                      // Special Days dropdown (when available)
                      if (_availableSpecialDays.isNotEmpty) ...[
                        const SizedBox(height: AppSizes.spacing16),
                        AppSearchableDropdown<int>(
                          label: 'Special Days',
                          hintText: 'Select a special day',
                          enabled: !isReadOnly,
                          value: _selectedSpecialDayIds.isNotEmpty
                              ? _selectedSpecialDayIds.first
                              : null,
                          items: _availableSpecialDays
                              .map(
                                (specialDay) => DropdownMenuItem<int>(
                                  value: specialDay.id,
                                  child: Text(specialDay.name),
                                ),
                              )
                              .toList(),
                          onChanged: isReadOnly
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedSpecialDayIds = value != null
                                        ? [value]
                                        : [];
                                  });
                                },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
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
                  if (isReadOnly && !_isEditMode)
                    // Show "Edit" button in view mode
                    AppButton(
                      text: 'Edit',
                      onPressed: () {
                        setState(() {
                          _isEditMode = true;
                        });
                      },
                    )
                  else
                    // Show "Update" or "Create" button in edit mode
                    AppButton(
                      text: widget.timeBand != null ? 'Update' : 'Create',
                      onPressed: _save,
                      isLoading: _isLoading,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiSelectChips(
    String title,
    List<Map<String, dynamic>> options,
    List<int> selectedValues,
    Function(List<int>) onChanged, {
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Row(
              children: [
                TextButton.icon(
                  onPressed: enabled
                      ? () {
                          final allValues = options
                              .map((o) => o['value'] as int)
                              .toList();
                          onChanged(allValues);
                        }
                      : null,
                  icon: const Icon(Icons.select_all, size: AppSizes.iconSmall),
                  label: const Text('Select All'),
                  style: TextButton.styleFrom(
                    foregroundColor: enabled
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    textStyle: const TextStyle(
                      fontSize: AppSizes.fontSizeSmall,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.spacing8),
                TextButton.icon(
                  onPressed: enabled ? () => onChanged([]) : null,
                  icon: const Icon(Icons.clear_all, size: AppSizes.iconSmall),
                  label: const Text('Clear All'),
                  style: TextButton.styleFrom(
                    foregroundColor: enabled
                        ? AppColors.error
                        : AppColors.textSecondary,
                    textStyle: const TextStyle(
                      fontSize: AppSizes.fontSizeSmall,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spacing8),

        // Display selected count summary
        if (selectedValues.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Text(
              '${selectedValues.length} selected: ${_getSelectedLabels(options, selectedValues)}',
              style: TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 120, // Fixed width for each item
            mainAxisExtent: 40, // Fixed height for each item
            crossAxisSpacing: AppSizes.spacing8,
            mainAxisSpacing: AppSizes.spacing8,
          ),
          itemCount: options.length,
          itemBuilder: (context, index) {
            final option = options[index];
            final value = option['value'] as int;
            final label = option['label'] as String;
            final isSelected = selectedValues.contains(value);

            // Color scheme
            Color chipColor;
            if (title.contains('Days')) {
              // Days of week - use green spectrum
              chipColor = AppColors.success;
            } else {
              // Months - use seasonal colors
              const monthColors = [
                Color(0xFF3B82F6), // Jan - Blue (Winter)
                Color(0xFF3B82F6), // Feb - Blue (Winter)
                Color(0xFF10B981), // Mar - Green (Spring)
                Color(0xFF10B981), // Apr - Green (Spring)
                Color(0xFF10B981), // May - Green (Spring)
                Color(0xFFF59E0B), // Jun - Orange (Summer)
                Color(0xFFF59E0B), // Jul - Orange (Summer)
                Color(0xFFF59E0B), // Aug - Orange (Summer)
                Color(0xFFEF4444), // Sep - Red (Autumn)
                Color(0xFFEF4444), // Oct - Red (Autumn)
                Color(0xFFEF4444), // Nov - Red (Autumn)
                Color(0xFF3B82F6), // Dec - Blue (Winter)
              ];
              chipColor = monthColors[index % monthColors.length];
            }

            return GestureDetector(
              onTap: enabled
                  ? () {
                      final newSelectedValues = List<int>.from(selectedValues);
                      if (isSelected) {
                        newSelectedValues.remove(value);
                      } else {
                        newSelectedValues.add(value);
                      }
                      onChanged(newSelectedValues);
                    }
                  : null,
              child: SizedBox(
                width: 120,
                height: 80,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? chipColor.withOpacity(enabled ? 0.2 : 0.1)
                        : chipColor.withOpacity(enabled ? 0.05 : 0.02),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    border: Border.all(
                      color: isSelected
                          ? chipColor.withOpacity(enabled ? 1.0 : 0.5)
                          : chipColor.withOpacity(enabled ? 0.3 : 0.15),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isSelected) ...[
                          Icon(
                            Icons.check_circle,
                            color: chipColor,
                            size: AppSizes.iconSmall,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: AppSizes.fontSizeSmall,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? chipColor
                                  : chipColor.withOpacity(0.8),
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String _getSelectedLabels(
    List<Map<String, dynamic>> options,
    List<int> selectedValues,
  ) {
    final selectedLabels = options
        .where((option) => selectedValues.contains(option['value'] as int))
        .map((option) => option['label'] as String)
        .toList();

    if (selectedLabels.length <= 3) {
      return selectedLabels.join(', ');
    } else {
      return '${selectedLabels.take(3).join(', ')}, +${selectedLabels.length - 3} more';
    }
  }
}
