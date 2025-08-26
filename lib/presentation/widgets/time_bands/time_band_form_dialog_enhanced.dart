import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../themes/app_theme.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../core/models/time_band.dart';
import '../../../core/services/time_band_service.dart';
import '../../../core/services/service_locator.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_input_field.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/common/app_dialog_header.dart';

class TimeBandFormDialogEnhanced extends StatefulWidget {
  final TimeBand? timeBand;
  final VoidCallback? onSaved;
  final bool isViewMode;

  const TimeBandFormDialogEnhanced({
    super.key,
    this.timeBand,
    this.onSaved,
    this.isViewMode = false,
  });

  @override
  State<TimeBandFormDialogEnhanced> createState() =>
      _TimeBandFormDialogEnhancedState();
}

class _TimeBandFormDialogEnhancedState
    extends State<TimeBandFormDialogEnhanced> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();

  bool _isLoading = false;
  bool _isEditMode = false;
  List<int> _selectedDaysOfWeek = [];
  List<int> _selectedMonthsOfYear = [];
  List<int> _selectedSeasonIds = [];
  List<int> _selectedSpecialDayIds = [];

  // Quick select functionality
  String? _selectedQuickTime;
  bool _isQuickTimeSelected = false;

  // Quick time periods with their corresponding start and end times
  final Map<String, Map<String, String>> _quickTimePeriods = {
    'Day': {'start': '07:00:00', 'end': '19:00:00'},
    'Night': {'start': '19:00:00', 'end': '07:00:00'},
    'Full Day': {'start': '00:00:00', 'end': '23:59:59'},
  };

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

  // Custom time input formatter for HH:mm:ss format
  static final _timeInputFormatter = TextInputFormatter.withFunction((
    oldValue,
    newValue,
  ) {
    // Handle deletion - if user is deleting, allow it
    if (newValue.text.length < oldValue.text.length) {
      // User is deleting, allow it but clean up format
      String text = newValue.text.replaceAll(RegExp(r'[^0-9:]'), '');

      // Remove trailing colons if they exist after deletion
      while (text.endsWith(':') && text.length > 0) {
        text = text.substring(0, text.length - 1);
      }

      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }

    // Handle normal typing/pasting
    final text = newValue.text.replaceAll(RegExp(r'[^0-9:]'), '');

    // Limit to 8 characters (HH:mm:ss)
    if (text.length > 8) {
      return oldValue;
    }

    // If user typed a colon manually, keep it as is (unless invalid position)
    if (newValue.text.contains(':') && newValue.text != oldValue.text) {
      // Check if manual colon is in valid position
      if (text.length <= 8) {
        return TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      }
    }

    String formattedText = '';
    int digitCount = 0;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];

      if (char == ':') {
        // Keep existing colons if they're in valid positions
        if (formattedText.length == 2 || formattedText.length == 5) {
          formattedText += char;
        }
      } else if (char.contains(RegExp(r'[0-9]'))) {
        // Add digit
        if (digitCount < 6) {
          // Allow max 6 digits (2 for hours, 2 for minutes, 2 for seconds)
          formattedText += char;
          digitCount++;

          // Auto-add colons after 2nd and 4th digits (only if not already there)
          if (digitCount == 2 &&
              i + 1 < text.length &&
              text[i + 1] != ':' &&
              !formattedText.endsWith(':')) {
            formattedText += ':';
          } else if (digitCount == 4 &&
              i + 1 < text.length &&
              text[i + 1] != ':' &&
              !formattedText.endsWith(':')) {
            formattedText += ':';
          }
        }
      }
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  });

  // Validate time format and values
  String? _validateTimeFormat(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Handle required validation separately
    }

    // Allow partial input during typing (don't validate incomplete times)
    if (value.length < 8) {
      // Check if what's typed so far is valid format
      final partialRegex = RegExp(
        r'^([0-2]?[0-9]?:?[0-5]?[0-9]?:?[0-5]?[0-9]?)$',
      );
      if (!partialRegex.hasMatch(value)) {
        return 'Please enter time in HH:mm:ss format';
      }
      return null; // Don't validate incomplete times
    }

    // Check complete format HH:mm:ss
    final timeRegex = RegExp(
      r'^([0-1]?[0-9]|2[0-3]):([0-5]?[0-9]):([0-5]?[0-9])$',
    );
    if (!timeRegex.hasMatch(value)) {
      return 'Please enter time in HH:mm:ss format';
    }

    // Additional validation for hours, minutes, seconds
    final parts = value.split(':');
    if (parts.length != 3) {
      return 'Please enter time in HH:mm:ss format';
    }

    final hours = int.tryParse(parts[0]);
    final minutes = int.tryParse(parts[1]);
    final seconds = int.tryParse(parts[2]);

    if (hours == null || hours < 0 || hours > 23) {
      return 'Hours must be between 00-23';
    }

    if (minutes == null || minutes < 0 || minutes > 59) {
      return 'Minutes must be between 00-59';
    }

    if (seconds == null || seconds < 0 || seconds > 59) {
      return 'Seconds must be between 00-59';
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    _isEditMode = !widget.isViewMode;
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.timeBand != null) {
      final timeBand = widget.timeBand!;
      _nameController.text = timeBand.name;
      _startTimeController.text = _formatTimeForDisplay(timeBand.startTime);
      _endTimeController.text = _formatTimeForDisplay(timeBand.endTime);
      _selectedDaysOfWeek = List.from(timeBand.daysOfWeek);
      _selectedMonthsOfYear = List.from(timeBand.monthsOfYear);
      _selectedSeasonIds = List.from(timeBand.seasonIds);
      _selectedSpecialDayIds = List.from(timeBand.specialDayIds);

      // Check if current time settings match any quick select option
      _detectQuickTimeSelection();
    } else {
      // For new time bands, default to select all days and months
      _selectedDaysOfWeek = _daysOfWeekOptions
          .map((o) => o['value'] as int)
          .toList();
      _selectedMonthsOfYear = _monthsOfYearOptions
          .map((o) => o['value'] as int)
          .toList();
    }

    // Add listeners to regenerate description when values change
    _nameController.addListener(_generateDescription);
    _startTimeController.addListener(_generateDescription);
    _endTimeController.addListener(_generateDescription);

    // Add listeners for real-time validation feedback
    _nameController.addListener(_validateName);
    _startTimeController.addListener(_validateStartTime);
    _endTimeController.addListener(_validateEndTime);

    // Generate initial description
    _generateDescription();
  }

  void _validateName() {
    // Trigger form validation to update error states
    if (mounted) {
      _formKey.currentState?.validate();
    }
  }

  void _validateStartTime() {
    // Trigger form validation to update error states
    if (mounted) {
      _formKey.currentState?.validate();
    }
  }

  void _validateEndTime() {
    // Trigger form validation to update error states
    if (mounted) {
      _formKey.currentState?.validate();
    }
  }

  void _detectQuickTimeSelection() {
    final startTime = _startTimeController.text.trim();
    final endTime = _endTimeController.text.trim();

    // First check if there's a quick select indicator in description
    final description = widget.timeBand?.description ?? '';
    if (description.startsWith('QUICK_SELECT:')) {
      final parts = description.split(':');
      if (parts.length >= 2) {
        final quickSelectType = parts[1].split(',')[0].trim();
        if (_quickTimePeriods.containsKey(quickSelectType)) {
          setState(() {
            _selectedQuickTime = quickSelectType;
            _isQuickTimeSelected = true;
          });
          return;
        }
      }
    }

    // Otherwise, try to detect from time values
    for (final entry in _quickTimePeriods.entries) {
      final period = entry.key;
      final times = entry.value;

      if (_formatTimeForDisplay(times['start']!) == startTime &&
          _formatTimeForDisplay(times['end']!) == endTime) {
        setState(() {
          _selectedQuickTime = period;
          _isQuickTimeSelected = true;
        });
        break;
      }
    }
  }

  String _formatTimeForDisplay(String timeString) {
    if (timeString.isEmpty) return '';

    try {
      // Handle different time formats from API
      if (timeString.contains('T')) {
        // DateTime format: "2024-01-01T06:00:00"
        final parts = timeString.split('T');
        if (parts.length > 1) {
          final timePart = parts[1];
          if (timePart.length >= 8) {
            return timePart.substring(0, 8); // HH:mm:ss
          }
        }
      } else if (timeString.length >= 8) {
        // Already in HH:mm:ss format
        return timeString.substring(0, 8);
      } else if (timeString.length == 5) {
        // HH:mm format, add seconds
        return '$timeString:00';
      }

      return timeString;
    } catch (e) {
      print('Error formatting time: $e');
      return timeString;
    }
  }

  Future<void> _selectTime(TextEditingController controller) async {
    // Prevent manual time selection if quick time is selected
    if (_isQuickTimeSelected) {
      AppToast.showWarning(
        context,
        title: 'Quick Time Selected',
        message:
            'Please unselect the quick time period first to manually edit times.',
      );
      return;
    }

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

  void _selectQuickTime(String quickTime) {
    setState(() {
      _selectedQuickTime = quickTime;
      _isQuickTimeSelected = true;

      final times = _quickTimePeriods[quickTime]!;
      _startTimeController.text = _formatTimeForDisplay(times['start']!);
      _endTimeController.text = _formatTimeForDisplay(times['end']!);

      // Auto-generate description
      _generateDescription();
    });

    // Trigger validation to clear any existing error messages since fields are now populated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _formKey.currentState?.validate();
      }
    });
  }

  void _clearQuickTimeSelection() {
    setState(() {
      _selectedQuickTime = null;
      _isQuickTimeSelected = false;

      // Clear the start and end time values when quick selection is cleared
      _startTimeController.clear();
      _endTimeController.clear();

      // Regenerate description when quick time is cleared
      _generateDescription();
    });

    // Trigger validation to clear any existing error messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _formKey.currentState?.validate();
      }
    });
  }

  IconData _getQuickTimeIcon(String period) {
    switch (period) {
      case 'Day':
        return Icons.wb_sunny;
      case 'Night':
        return Icons.nightlight_round;
      case 'Full Day':
        return Icons.schedule;
      default:
        return Icons.access_time;
    }
  }

  String _getDisplayDescription() {
    final fullDescription = _descriptionController.text;
    if (fullDescription.startsWith('QUICK_SELECT:')) {
      // Remove the QUICK_SELECT prefix for display
      final commaIndex = fullDescription.indexOf(', ');
      if (commaIndex != -1) {
        return fullDescription.substring(commaIndex + 2);
      }
      return '';
    }
    return fullDescription;
  }

  void _generateDescription() {
    List<String> descriptionParts = [];

    // Add quick select state indicator if selected (hidden from user but preserved in data)
    String finalDescription = '';
    if (_selectedQuickTime != null) {
      finalDescription = 'QUICK_SELECT:$_selectedQuickTime, ';
    }

    // Add time band name if available
    if (_nameController.text.trim().isNotEmpty) {
      descriptionParts.add('Time Band: ${_nameController.text.trim()}');
    }

    // Add time period information
    if (_selectedQuickTime != null) {
      final times = _quickTimePeriods[_selectedQuickTime]!;
      descriptionParts.add(
        'Quick Period: $_selectedQuickTime (${_formatTimeForDisplay(times['start']!)} - ${_formatTimeForDisplay(times['end']!)})',
      );
    } else if (_startTimeController.text.isNotEmpty ||
        _endTimeController.text.isNotEmpty) {
      descriptionParts.add(
        'Custom Time: ${_startTimeController.text} - ${_endTimeController.text}',
      );
    }

    // Add days of week information
    if (_selectedDaysOfWeek.isNotEmpty) {
      final selectedDayLabels = _daysOfWeekOptions
          .where(
            (option) => _selectedDaysOfWeek.contains(option['value'] as int),
          )
          .map((option) => option['label'] as String)
          .toList();

      if (selectedDayLabels.length == _daysOfWeekOptions.length) {
        descriptionParts.add('Days: All days of week');
      } else {
        // Show ALL selected days without truncation
        descriptionParts.add('Days: ${selectedDayLabels.join(', ')}');
      }
    }

    // Add months of year information
    if (_selectedMonthsOfYear.isNotEmpty) {
      final selectedMonthLabels = _monthsOfYearOptions
          .where(
            (option) => _selectedMonthsOfYear.contains(option['value'] as int),
          )
          .map((option) => option['label'] as String)
          .toList();

      if (selectedMonthLabels.length == _monthsOfYearOptions.length) {
        descriptionParts.add('Months: All months of year');
      } else {
        // Show ALL selected months without truncation
        descriptionParts.add('Months: ${selectedMonthLabels.join(', ')}');
      }
    }

    // Join all parts with commas and set the generated description
    finalDescription += descriptionParts.join(', ');
    _descriptionController.text = finalDescription;
  }

  Widget _buildQuickTimeSelector() {
    final isReadOnly = widget.isViewMode && !_isEditMode;

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing12),
      margin: const EdgeInsets.only(bottom: AppSizes.spacing16),
      decoration: BoxDecoration(
        color: context.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(color: context.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flash_on,
                size: AppSizes.iconSmall,
                color: context.primaryColor,
              ),
              const SizedBox(width: AppSizes.spacing8),
              Text(
                'Quick Time Selection',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeSmall,
                  fontWeight: FontWeight.w600,
                  color: context.primaryColor,
                ),
              ),
              const Spacer(),
              if (_isQuickTimeSelected && !isReadOnly)
                TextButton.icon(
                  onPressed: _clearQuickTimeSelection,
                  icon: const Icon(Icons.clear_all, size: AppSizes.iconSmall),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(
                    foregroundColor: context.errorColor,
                    textStyle: const TextStyle(
                      fontSize: AppSizes.fontSizeSmall,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing8),
          Text(
            isReadOnly
                ? _isQuickTimeSelected
                      ? 'Quick time period: $_selectedQuickTime was used for this time band.'
                      : 'Custom time period was used for this time band.'
                : _isQuickTimeSelected
                ? 'Quick time selected: $_selectedQuickTime. Clear selection to manually edit times.'
                : 'Choose a preset time period for quick setup',
            style: TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              color: _isQuickTimeSelected
                  ? context.warningColor
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: AppSizes.spacing12),
          Wrap(
            spacing: AppSizes.spacing8,
            runSpacing: AppSizes.spacing8,
            children: _quickTimePeriods.keys.map((period) {
              final isSelected = _selectedQuickTime == period;
              final times = _quickTimePeriods[period]!;

              return GestureDetector(
                onTap: isReadOnly ? null : () => _selectQuickTime(period),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacing12,
                    vertical: AppSizes.spacing8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? context.primaryColor : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                    border: Border.all(
                      color: isSelected ? context.primaryColor : Theme.of(context).colorScheme.outline,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: context.primaryColor.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getQuickTimeIcon(period),
                        size: AppSizes.iconMedium,
                        color: isSelected
                            ? Theme.of(context).colorScheme.surface
                            : context.primaryColor,
                      ),
                      const SizedBox(height: AppSizes.spacing4),
                      Text(
                        period,
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeSmall,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Theme.of(context).colorScheme.surface
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacing4),
                      Text(
                        '${_formatTimeForDisplay(times['start']!)} - ${_formatTimeForDisplay(times['end']!)}',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeSmall,
                          color: isSelected
                              ? Theme.of(context).colorScheme.surface.withOpacity(0.9)
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use ResponsiveHelper for consistent responsive behavior
    final dialogConstraints = ResponsiveHelper.getDialogConstraints(context);
    final isMobile = ResponsiveHelper.shouldUseCompactUI(context);

    final bool isReadOnly = widget.isViewMode && !_isEditMode;

    // Dialog configuration based on mode
    DialogType dialogType;
    String dialogTitle;
    String dialogSubtitle;

    if (widget.timeBand == null) {
      dialogType = DialogType.create;
      dialogTitle = 'Create Time Band';
      dialogSubtitle =
          'Define time periods with quick select options or custom time ranges';
    } else if (isReadOnly) {
      dialogType = DialogType.view;
      dialogTitle = 'View Time Band';
      dialogSubtitle = 'Review time band configuration and applied attributes';
    } else {
      dialogType = DialogType.edit;
      dialogTitle = 'Edit Time Band';
      dialogSubtitle = 'Update time band settings and time configurations';
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
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
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
    final bool isReadOnly = widget.isViewMode && !_isEditMode;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: EdgeInsets.all(ResponsiveHelper.getSpacing(context)),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInformationSection(isReadOnly),
              SizedBox(height: ResponsiveHelper.getSpacing(context) * 2),
              _buildTimeConfigurationSection(isReadOnly),
              SizedBox(height: ResponsiveHelper.getSpacing(context) * 2),
              _buildAttributesSection(isReadOnly),
              SizedBox(height: ResponsiveHelper.getSpacing(context) * 2),
              _buildDescriptionSection(),
            ],
          ),
        ),
      ),
    );
  }

  // Mobile footer - vertical button layout
  Widget _buildMobileFooter() {
    final bool isReadOnly = widget.isViewMode && !_isEditMode;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isReadOnly && !_isEditMode)
          AppButton(
            text: 'Edit',
            onPressed: () {
              setState(() {
                _isEditMode = true;
              });
            },
          )
        else
          AppButton(
            text: _isLoading
                ? 'Saving...'
                : (widget.timeBand != null ? 'Update' : 'Create'),
            onPressed: _isLoading ? null : _save,
            isLoading: _isLoading,
          ),
        const SizedBox(height: AppSizes.spacing8),
        AppButton(
          text: isReadOnly ? 'Close' : 'Cancel',
          type: AppButtonType.outline,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  // Desktop footer - horizontal button layout
  Widget _buildDesktopFooter() {
    final bool isReadOnly = widget.isViewMode && !_isEditMode;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AppButton(
          text: isReadOnly ? 'Close' : 'Cancel',
          type: AppButtonType.outline,
          onPressed: () => Navigator.of(context).pop(),
        ),
        SizedBox(width: ResponsiveHelper.getSpacing(context)),
        if (isReadOnly && !_isEditMode)
          AppButton(
            text: 'Edit',
            onPressed: () {
              setState(() {
                _isEditMode = true;
              });
            },
          )
        else
          AppButton(
            text: _isLoading
                ? 'Saving...'
                : (widget.timeBand != null ? 'Update' : 'Create'),
            onPressed: _isLoading ? null : _save,
            isLoading: _isLoading,
          ),
      ],
    );
  }

  Widget _buildBasicInformationSection(bool isReadOnly) {
    final isMobile = ResponsiveHelper.shouldUseCompactUI(context);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
      ),
      padding: EdgeInsets.all(ResponsiveHelper.getSpacing(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: TextStyle(
              fontSize: isMobile
                  ? AppSizes.fontSizeMedium
                  : AppSizes.fontSizeLarge,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getSpacing(context)),
          AppInputField(
            label: 'Name',
            controller: _nameController,
            enabled: !isReadOnly,
            required: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Name is required';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeConfigurationSection(bool isReadOnly) {
    final isMobile = ResponsiveHelper.shouldUseCompactUI(context);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
      ),
      padding: EdgeInsets.all(ResponsiveHelper.getSpacing(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Time Configuration',
            style: TextStyle(
              fontSize: isMobile
                  ? AppSizes.fontSizeMedium
                  : AppSizes.fontSizeLarge,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getSpacing(context)),

          // Quick Time Selection
          _buildQuickTimeSelector(),

          // Time range fields (responsive)
          isMobile
              ? Column(
                  children: [
                    AppInputField(
                      label: 'Start Time',
                      controller: _startTimeController,
                      enabled: !isReadOnly && !_isQuickTimeSelected,
                      required: true,
                      hintText: 'HH:mm:ss (24-hour)',
                      keyboardType: TextInputType.number,
                      inputFormatters: [_timeInputFormatter],
                      suffixIcon: isReadOnly
                          ?  Icon(
                              Icons.access_time,
                              color: context.textSecondaryColor,
                              size: AppSizes.iconSmall,
                            )
                          : _isQuickTimeSelected
                          ? Icon(
                              Icons.lock,
                              color: context.warningColor,
                              size: AppSizes.iconSmall,
                            )
                          : IconButton(
                              icon: const Icon(Icons.access_time),
                              iconSize: AppSizes.iconSmall,
                              onPressed: () =>
                                  _selectTime(_startTimeController),
                            ),
                      validator: (value) {
                        // Skip validation if quick time is selected (fields are auto-populated)
                        if (_isQuickTimeSelected) {
                          return null;
                        }
                        if (value == null || value.trim().isEmpty) {
                          return 'Start time is required';
                        }
                        // Validate time format
                        return _validateTimeFormat(value);
                      },
                    ),
                    SizedBox(height: ResponsiveHelper.getSpacing(context)),
                    AppInputField(
                      label: 'End Time',
                      controller: _endTimeController,
                      enabled: !isReadOnly && !_isQuickTimeSelected,
                      required: true,
                      hintText: 'HH:mm:ss (24-hour)',
                      keyboardType: TextInputType.number,
                      inputFormatters: [_timeInputFormatter],
                      suffixIcon: isReadOnly
                          ?  Icon(
                              size: AppSizes.iconSmall,
                              Icons.access_time,
                              color: context.textSecondaryColor,
                            )
                          : _isQuickTimeSelected
                          ? Icon(
                              Icons.lock,
                              color: context.warningColor,
                              size: AppSizes.iconSmall,
                            )
                          : IconButton(
                              icon: const Icon(Icons.access_time),
                              iconSize: AppSizes.iconSmall,
                              onPressed: () => _selectTime(_endTimeController),
                            ),
                      validator: (value) {
                        // Skip validation if quick time is selected (fields are auto-populated)
                        if (_isQuickTimeSelected) {
                          return null;
                        }
                        if (value == null || value.trim().isEmpty) {
                          return 'End time is required';
                        }
                        // Validate time format
                        return _validateTimeFormat(value);
                      },
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: AppInputField(
                        label: 'Start Time',
                        controller: _startTimeController,
                        enabled: !isReadOnly && !_isQuickTimeSelected,
                        required: true,
                        hintText: 'HH:mm:ss (24-hour)',
                        keyboardType: TextInputType.number,
                        inputFormatters: [_timeInputFormatter],
                        suffixIcon: isReadOnly
                            ? Icon(
                                Icons.access_time,
                                color: context.textSecondaryColor,
                                size: AppSizes.iconSmall,
                              )
                            : _isQuickTimeSelected
                            ? Icon(
                                Icons.lock,
                                color: context.warningColor,
                                size: AppSizes.iconSmall,
                              )
                            : IconButton(
                                icon: const Icon(Icons.access_time),
                                iconSize: AppSizes.iconSmall,
                                onPressed: () =>
                                    _selectTime(_startTimeController),
                              ),
                        validator: (value) {
                          // Skip validation if quick time is selected (fields are auto-populated)
                          if (_isQuickTimeSelected) {
                            return null;
                          }
                          if (value == null || value.trim().isEmpty) {
                            return 'Start time is required';
                          }
                          // Validate time format
                          return _validateTimeFormat(value);
                        },
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.getSpacing(context)),
                    Expanded(
                      child: AppInputField(
                        label: 'End Time',
                        controller: _endTimeController,
                        enabled: !isReadOnly && !_isQuickTimeSelected,
                        required: true,
                        hintText: 'HH:mm:ss (24-hour)',
                        keyboardType: TextInputType.number,
                        inputFormatters: [_timeInputFormatter],
                        suffixIcon: isReadOnly
                            ?  Icon(
                                size: AppSizes.iconSmall,
                                Icons.access_time,
                                color: context.textSecondaryColor,
                              )
                            : _isQuickTimeSelected
                            ? Icon(
                                Icons.lock,
                                color: context.warningColor,
                                size: AppSizes.iconSmall,
                              )
                            : IconButton(
                                icon: const Icon(Icons.access_time),
                                iconSize: AppSizes.iconSmall,
                                onPressed: () =>
                                    _selectTime(_endTimeController),
                              ),
                        validator: (value) {
                          // Skip validation if quick time is selected (fields are auto-populated)
                          if (_isQuickTimeSelected) {
                            return null;
                          }
                          if (value == null || value.trim().isEmpty) {
                            return 'End time is required';
                          }
                          // Validate time format
                          return _validateTimeFormat(value);
                        },
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildAttributesSection(bool isReadOnly) {
    final isMobile = ResponsiveHelper.shouldUseCompactUI(context);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
      ),
      padding: EdgeInsets.all(ResponsiveHelper.getSpacing(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Time Band Attributes',
            style: TextStyle(
              fontSize: isMobile
                  ? AppSizes.fontSizeMedium
                  : AppSizes.fontSizeLarge,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getSpacing(context)),

          // Days of Week
          _buildMultiSelectChips(
            'Days of Week',
            _daysOfWeekOptions,
            _selectedDaysOfWeek,
            (selectedValues) {
              setState(() {
                _selectedDaysOfWeek = selectedValues;
              });
              _generateDescription(); // Regenerate description
            },
            enabled: !isReadOnly,
          ),
          SizedBox(height: ResponsiveHelper.getSpacing(context)),

          // Months of Year
          _buildMultiSelectChips(
            'Months of Year',
            _monthsOfYearOptions,
            _selectedMonthsOfYear,
            (selectedValues) {
              setState(() {
                _selectedMonthsOfYear = selectedValues;
              });
              _generateDescription(); // Regenerate description
            },
            enabled: !isReadOnly,
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
      ),
      padding: EdgeInsets.all(ResponsiveHelper.getSpacing(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: TextStyle(
              fontSize: ResponsiveHelper.shouldUseCompactUI(context)
                  ? AppSizes.fontSizeMedium
                  : AppSizes.fontSizeLarge,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getSpacing(context)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(ResponsiveHelper.getSpacing(context)),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Description (Auto-generated)',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeSmall,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: AppSizes.spacing8),
                Text(
                  _getDisplayDescription().isEmpty
                      ? 'Description will be auto-generated based on your selections...'
                      : _getDisplayDescription(),
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeMedium,
                    color: _getDisplayDescription().isEmpty
                        ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
                        : Theme.of(context).colorScheme.onSurface,
                    fontStyle: _getDisplayDescription().isEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
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
                // Smart Select All / Clear All button
                if (selectedValues.length == options.length)
                  TextButton.icon(
                    onPressed: enabled ? () => onChanged([]) : null,
                    icon: const Icon(Icons.clear_all, size: AppSizes.iconSmall),
                    label: const Text('Clear All'),
                    style: TextButton.styleFrom(
                      foregroundColor: enabled
                          ? context.errorColor//AppColors.error
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      textStyle: const TextStyle(
                        fontSize: AppSizes.fontSizeSmall,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  TextButton.icon(
                    onPressed: enabled
                        ? () {
                            final allValues = options
                                .map((o) => o['value'] as int)
                                .toList();
                            onChanged(allValues);
                          }
                        : null,
                    icon: const Icon(
                      Icons.select_all,
                      size: AppSizes.iconSmall,
                    ),
                    label: const Text('Select All'),
                    style: TextButton.styleFrom(
                      foregroundColor: enabled
                          ? context.primaryColor //AppColors.primary
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
              color: context.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              border: Border.all(color: context.primaryColor.withOpacity(0.3)),
            ),
            child: Text(
              '${selectedValues.length} selected: ${_getSelectedLabels(options, selectedValues)}',
              style: TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                color: context.primaryColor,
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
              chipColor = context.primaryColor;
            } else {
              // Use primary color for easier theming
              chipColor = context.primaryColor;
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

    // Show ALL selected labels without truncation
    return selectedLabels.join(', ');
  }

  String _getCleanDescriptionForAPI() {
    final fullDescription = _descriptionController.text;
    if (fullDescription.startsWith('QUICK_SELECT:')) {
      // Remove the QUICK_SELECT prefix for API
      final commaIndex = fullDescription.indexOf(', ');
      if (commaIndex != -1) {
        return fullDescription.substring(commaIndex + 2);
      }
      return '';
    }
    return fullDescription;
  }

  Future<void> _save() async {
    // Validate form and show specific error message if validation fails
    if (!_formKey.currentState!.validate()) {
      AppToast.showError(
        context,
        error: 'Please fill in all required fields correctly.',
        title: 'Validation Error',
      );
      return;
    }

    // Additional validation for empty name after trimming
    if (_nameController.text.trim().isEmpty) {
      AppToast.showError(
        context,
        error: 'Name is required and cannot be empty.',
        title: 'Validation Error',
      );
      return;
    }

    // Additional validation for time fields (skip if quick time is selected)
    if (!_isQuickTimeSelected) {
      if (_startTimeController.text.trim().isEmpty) {
        AppToast.showError(
          context,
          error: 'Start time is required.',
          title: 'Validation Error',
        );
        return;
      }

      if (_endTimeController.text.trim().isEmpty) {
        AppToast.showError(
          context,
          error: 'End time is required.',
          title: 'Validation Error',
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Call API
      final serviceLocator = Provider.of<ServiceLocator>(
        context,
        listen: false,
      );
      final timeBandService = TimeBandService(serviceLocator.apiService);

      if (widget.timeBand != null) {
        // Update existing time band
        final cleanDescription = _getCleanDescriptionForAPI();
        final updatedTimeBand = TimeBand(
          id: widget.timeBand!.id,
          name: _nameController.text.trim(),
          startTime: _startTimeController.text.trim(),
          endTime: _endTimeController.text.trim(),
          description: cleanDescription,
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
          AppToast.showSuccess(
            context,
            title: 'Time Band Updated',
            message:
                'Time band "${updatedTimeBand.name}" has been updated successfully.',
          );
        } else {
          AppToast.showError(context, error: response.message);
          return;
        }
      } else {
        // Create new time band
        final cleanDescription = _getCleanDescriptionForAPI();
        final response = await timeBandService.createTimeBand(
          name: _nameController.text.trim(),
          startTime: _startTimeController.text.trim(),
          endTime: _endTimeController.text.trim(),
          description: cleanDescription,
          daysOfWeek: _selectedDaysOfWeek,
          monthsOfYear: _selectedMonthsOfYear,
          seasonIds: _selectedSeasonIds,
          specialDayIds: _selectedSpecialDayIds,
        );

        if (response.success) {
          AppToast.showSuccess(
            context,
            title: 'Time Band Created',
            message:
                'Time band "${_nameController.text.trim()}" has been created successfully.',
          );
        } else {
          AppToast.showError(context, error: response.message);
          return;
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved?.call();
      }
    } catch (e) {
      AppToast.showError(
        context,
        error: e,
        title: 'Save Failed',
        errorContext: 'time_band_save',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Remove all listeners before disposing
    _nameController.removeListener(_generateDescription);
    _startTimeController.removeListener(_generateDescription);
    _endTimeController.removeListener(_generateDescription);
    _nameController.removeListener(_validateName);
    _startTimeController.removeListener(_validateStartTime);
    _endTimeController.removeListener(_validateEndTime);

    _nameController.dispose();
    _descriptionController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }
}




