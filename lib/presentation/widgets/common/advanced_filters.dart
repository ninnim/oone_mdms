import 'package:flutter/material.dart';
import 'dart:async';
// import '../../../core/constants/app_colors.dart';
import '../../themes/app_theme.dart';
import '../../../core/constants/app_sizes.dart';
import 'app_button.dart';
import 'app_input_field.dart';
import 'app_dropdown_field.dart';
import 'custom_date_range_picker.dart';

class AdvancedFilters extends StatefulWidget {
  final List<FilterConfig> filterConfigs;
  final Map<String, dynamic> initialValues;
  final Function(Map<String, dynamic>) onFiltersChanged;
  final VoidCallback? onClear;
  final VoidCallback? onSave;
  final bool showSaveOption;
  final String? savedFilterName;
  final bool startExpanded;
  final String title;
  final Widget? leadingIcon;
  final bool showApplyButton;
  final bool autoApply;
  final Duration debounceDelay;

  const AdvancedFilters({
    super.key,
    required this.filterConfigs,
    required this.initialValues,
    required this.onFiltersChanged,
    this.onClear,
    this.onSave,
    this.showSaveOption = false,
    this.savedFilterName,
    this.startExpanded = false,
    this.title = 'Advanced Filters',
    this.leadingIcon,
    this.showApplyButton = true,
    this.autoApply = false,
    this.debounceDelay = const Duration(milliseconds: 500),
  });

  @override
  State<AdvancedFilters> createState() => _AdvancedFiltersState();
}

class _AdvancedFiltersState extends State<AdvancedFilters> {
  late Map<String, dynamic> _filterValues;
  late bool _isExpanded;
  Timer? _debounceTimer;
  final Map<String, TextEditingController> _textControllers = {};

  @override
  void initState() {
    super.initState();
    _filterValues = Map.from(widget.initialValues);
    _isExpanded = widget.startExpanded;
    _initializeControllers();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _disposeControllers();
    super.dispose();
  }

  void _initializeControllers() {
    for (final config in widget.filterConfigs) {
      if (config.type == FilterType.text || config.type == FilterType.number) {
        _textControllers[config.key] = TextEditingController(
          text: _filterValues[config.key]?.toString() ?? '',
        );
      }
    }
  }

  void _disposeControllers() {
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    _textControllers.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      child: Column(
        children: [_buildHeader(), if (_isExpanded) _buildFiltersContent()],
      ),
    );
  }

  Widget _buildHeader() {
    final activeFiltersCount = _filterValues.values
        .where((value) => value != null && _isValueNotEmpty(value))
        .length;

    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Row(
          children: [
            widget.leadingIcon ??
                Icon(
                  Icons.filter_list,
                  color: activeFiltersCount > 0
                      ? context.primaryColor
                      : context.textSecondaryColor,
                  size: AppSizes.iconMedium,
                ),
            const SizedBox(width: AppSizes.spacing8),
            Text(
              widget.title,
              style: TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                fontWeight: FontWeight.w600,
                color: context.textPrimaryColor,
              ),
            ),
            if (activeFiltersCount > 0) ...[
              const SizedBox(width: AppSizes.spacing8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacing6,
                  vertical: AppSizes.spacing2,
                ),
                decoration: BoxDecoration(
                  color: context.primaryColor,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                ),
                child: Text(
                  '$activeFiltersCount',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: AppSizes.fontSizeSmall,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const Spacer(),
            if (widget.savedFilterName != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacing8,
                  vertical: AppSizes.spacing4,
                ),
                decoration: BoxDecoration(
                  color: context.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  border: Border.all(
                    color: context.successColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  widget.savedFilterName!,
                  style: TextStyle(
                    color: context.successColor,
                    fontSize: AppSizes.fontSizeSmall,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.spacing8),
            ],
            Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: context.textSecondaryColor,
              size: AppSizes.iconSmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersContent() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.borderColor)),
      ),
      child: Row(
        children: [
          _buildFilterFields(),
          if (widget.showApplyButton || widget.onClear != null) ...[
            const Spacer(),
            _buildActionButtons(),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterFields() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.start,
        spacing: AppSizes.spacing16,
        runSpacing: AppSizes.spacing16,
        children: widget.filterConfigs.map((config) {
          return SizedBox(
            width: _getFieldWidth(config),
            child: _buildFilterField(config),
          );
        }).toList(),
      ),
    );
  }

  double _getFieldWidth(FilterConfig config) {
    switch (config.type) {
      case FilterType.text:
      case FilterType.number:
        return config.width ?? 200;
      case FilterType.dropdown:
      case FilterType.searchableDropdown:
        return config.width ?? 180;
      case FilterType.multiSelect:
        return config.width ?? 200;
      case FilterType.dateRange:
        return config.width ?? 250;
      case FilterType.datePicker:
        return config.width ?? 150;
      case FilterType.toggle:
        return config.width ?? 150;
      case FilterType.slider:
        return config.width ?? 200;
    }
  }

  Widget _buildFilterField(FilterConfig config) {
    switch (config.type) {
      case FilterType.text:
        return _buildTextFilter(config);
      case FilterType.number:
        return _buildNumberFilter(config);
      case FilterType.dropdown:
        return _buildDropdownFilter(config);
      case FilterType.searchableDropdown:
        return _buildSearchableDropdownFilter(config);
      case FilterType.multiSelect:
        return _buildMultiSelectFilter(config);
      case FilterType.dateRange:
        return _buildDateRangeFilter(config);
      case FilterType.datePicker:
        return _buildDatePickerFilter(config);
      case FilterType.toggle:
        return _buildToggleFilter(config);
      case FilterType.slider:
        return _buildSliderFilter(config);
    }
  }

  Widget _buildTextFilter(FilterConfig config) {
    final controller = _textControllers[config.key]!;

    return AppInputField(
      label: config.label,
      hintText: config.placeholder ?? 'Enter ${config.label.toLowerCase()}',
      controller: controller,
      prefixIcon: config.icon != null ? Icon(config.icon) : null,
      enabled: config.enabled,
      required: config.required,
      onChanged: (value) =>
          _updateFilter(config.key, value.isEmpty ? null : value, config),
    );
  }

  Widget _buildNumberFilter(FilterConfig config) {
    final controller = _textControllers[config.key]!;

    return AppInputField(
      label: config.label,
      hintText: config.placeholder ?? 'Enter ${config.label.toLowerCase()}',
      controller: controller,
      keyboardType: TextInputType.number,
      prefixIcon: config.icon != null ? Icon(config.icon) : null,
      enabled: config.enabled,
      required: config.required,
      onChanged: (value) {
        final numValue = value.isEmpty ? null : double.tryParse(value);
        _updateFilter(config.key, numValue, config);
      },
    );
  }

  Widget _buildDropdownFilter(FilterConfig config) {
    return AppSearchableDropdown<String>(
      label: config.label,
      hintText: config.placeholder ?? 'Select ${config.label.toLowerCase()}',
      value: _filterValues[config.key],
      items: [
        const DropdownMenuItem(value: null, child: Text('All')),
        ...config.options!.map(
          (option) => DropdownMenuItem(value: option, child: Text(option)),
        ),
      ],
      enabled: config.enabled,
      onChanged: (value) => _updateFilter(config.key, value, config),
    );
  }

  Widget _buildSearchableDropdownFilter(FilterConfig config) {
    return AppSearchableDropdown<String>(
      label: config.label,
      hintText: config.placeholder ?? 'Select ${config.label.toLowerCase()}',
      value: _filterValues[config.key],
      items: [
        const DropdownMenuItem(value: null, child: Text('All')),
        ...config.options!.map(
          (option) => DropdownMenuItem(value: option, child: Text(option)),
        ),
      ],
      enabled: config.enabled,
      onChanged: (value) => _updateFilter(config.key, value, config),
      onSearchChanged: config.onSearchChanged,
    );
  }

  Widget _buildMultiSelectFilter(FilterConfig config) {
    final selectedValues = _filterValues[config.key] as List<String>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: config.label,
            style: TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              fontWeight: FontWeight.w500,
              color: context.textSecondaryColor,
            ),
            children: [
              if (config.required)
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: context.errorColor),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.spacing4),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: context.borderColor),
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
          child: Column(
            children: config.options!.map((option) {
              final isSelected = selectedValues.contains(option);
              return CheckboxListTile(
                dense: true,
                value: isSelected,
                title: Text(
                  option,
                  style: TextStyle(fontSize: AppSizes.fontSizeSmall),
                ),
                enabled: config.enabled,
                onChanged: config.enabled
                    ? (checked) {
                        final newValues = List<String>.from(selectedValues);
                        if (checked == true) {
                          newValues.add(option);
                        } else {
                          newValues.remove(option);
                        }
                        _updateFilter(
                          config.key,
                          newValues.isEmpty ? null : newValues,
                          config,
                        );
                      }
                    : null,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeFilter(FilterConfig config) {
    final dateRange = _filterValues[config.key] as DateTimeRange?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (config.label.isNotEmpty) ...[
          RichText(
            text: TextSpan(
              text: config.label,
              style: TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                fontWeight: FontWeight.w500,
                color: context.textSecondaryColor,
              ),
              children: [
                if (config.required)
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: context.errorColor),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.spacing8),
        ],
        SizedBox(
          height: AppSizes.inputHeight,
          child: CustomDateRangePicker(
            initialStartDate: dateRange?.start,
            initialEndDate: dateRange?.end,
            hintText: config.placeholder ?? 'Select date range',
            enabled: config.enabled,
            onDateRangeSelected: (startDate, endDate) {
              final newDateRange = DateTimeRange(
                start: startDate,
                end: endDate,
              );
              _updateFilter(config.key, newDateRange, config);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerFilter(FilterConfig config) {
    final selectedDate = _filterValues[config.key] as DateTime?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: config.label,
            style: TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              fontWeight: FontWeight.w500,
              color: context.textSecondaryColor,
            ),
            children: [
              if (config.required)
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: context.errorColor),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.spacing4),
        InkWell(
          onTap: config.enabled
              ? () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    _updateFilter(config.key, picked, config);
                  }
                }
              : null,
          child: Container(
            padding: const EdgeInsets.all(AppSizes.spacing12),
            decoration: BoxDecoration(
              border: Border.all(color: context.borderColor),
              borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
              color: config.enabled
                  ? context.surfaceColor
                  : context.surfaceColor.withOpacity(0.5),
            ),
            child: Row(
              children: [
                Icon(
                  config.icon ?? Icons.calendar_today,
                  size: AppSizes.iconSmall,
                  color: config.enabled
                      ? context.textSecondaryColor
                      : context.textSecondaryColor,
                ),
                const SizedBox(width: AppSizes.spacing8),
                Expanded(
                  child: Text(
                    selectedDate != null
                        ? _formatDate(selectedDate)
                        : config.placeholder ?? 'Select date',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeSmall,
                      color: selectedDate != null
                          ? (config.enabled
                                ? context.textPrimaryColor
                                : context.textSecondaryColor)
                          : (config.enabled
                                ? context.textSecondaryColor
                                : context.textSecondaryColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleFilter(FilterConfig config) {
    final isEnabled = _filterValues[config.key] as bool? ?? false;

    return Row(
      children: [
        Switch(
          value: isEnabled,
          onChanged: config.enabled
              ? (value) => _updateFilter(config.key, value, config)
              : null,
          activeColor: context.primaryColor,
        ),
        const SizedBox(width: AppSizes.spacing8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  text: config.label,
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeSmall,
                    fontWeight: FontWeight.w500,
                    color: config.enabled
                        ? context.textPrimaryColor
                        : context.textSecondaryColor,
                  ),
                  children: [
                    if (config.required)
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: context.errorColor),
                      ),
                  ],
                ),
              ),
              if (config.description != null)
                Text(
                  config.description!,
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeSmall - 1,
                    color: config.enabled
                        ? context.textSecondaryColor
                        : context.textSecondaryColor,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSliderFilter(FilterConfig config) {
    final value =
        (_filterValues[config.key] as double?) ?? (config.sliderMin ?? 0.0);
    final min = config.sliderMin ?? 0.0;
    final max = config.sliderMax ?? 100.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: config.label,
            style: TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              fontWeight: FontWeight.w500,
              color: context.textSecondaryColor,
            ),
            children: [
              if (config.required)
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: context.errorColor),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.spacing4),
        Row(
          children: [
            Text(
              min.toStringAsFixed(0),
              style: TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                color: context.textSecondaryColor,
              ),
            ),
            Expanded(
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                divisions: config.sliderDivisions,
                label: value.toStringAsFixed(
                  config.sliderDivisions != null ? 0 : 1,
                ),
                onChanged: config.enabled
                    ? (newValue) => _updateFilter(config.key, newValue, config)
                    : null,
                activeColor: context.primaryColor,
              ),
            ),
            Text(
              max.toStringAsFixed(0),
              style: TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                color: context.textSecondaryColor,
              ),
            ),
          ],
        ),
        Center(
          child: Text(
            'Current: ${value.toStringAsFixed(config.sliderDivisions != null ? 0 : 1)}',
            style: TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              color: context.textPrimaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (widget.onClear != null)
          AppButton(
            text: 'Clear',
            type: AppButtonType.outline,
            size: AppButtonSize.small,
            onPressed: () {
              _clearAllFilters();
              widget.onClear?.call();
            },
          ),
        const SizedBox(width: AppSizes.spacing8),
        if (widget.showApplyButton)
          AppButton(
            text: 'Apply',
            size: AppButtonSize.small,
            onPressed: () => widget.onFiltersChanged(_filterValues),
          ),
        if (widget.showSaveOption) ...[
          const SizedBox(width: AppSizes.spacing8),
          AppButton(
            text: 'Save Filter',
            type: AppButtonType.primary,
            size: AppButtonSize.small,
            onPressed: widget.onSave,
          ),
        ],
      ],
    );
  }

  void _clearAllFilters() {
    setState(() {
      _filterValues.clear();
      // Clear all text controllers
      for (final controller in _textControllers.values) {
        controller.clear();
      }
    });

    if (widget.autoApply) {
      widget.onFiltersChanged(_filterValues);
    }
  }

  void _updateFilter(String key, dynamic value, FilterConfig config) {
    setState(() {
      if (value == null || _isValueEmpty(value)) {
        _filterValues.remove(key);
      } else {
        _filterValues[key] = value;
      }
    });

    // Auto-apply filters if enabled
    if (widget.autoApply) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(widget.debounceDelay, () {
        widget.onFiltersChanged(_filterValues);
      });
    }

    // Call config-specific callback
    config.onChanged?.call(value);
  }

  bool _isValueEmpty(dynamic value) {
    if (value == null) return true;
    if (value is String && value.isEmpty) return true;
    if (value is List && value.isEmpty) return true;
    return false;
  }

  bool _isValueNotEmpty(dynamic value) {
    return !_isValueEmpty(value);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

enum FilterType {
  text,
  number,
  dropdown,
  searchableDropdown,
  multiSelect,
  dateRange,
  datePicker,
  toggle,
  slider,
}

class FilterConfig {
  final String key;
  final String label;
  final FilterType type;
  final String? placeholder;
  final List<String>? options;
  final dynamic defaultValue;
  final bool enabled;
  final bool required;
  final IconData? icon;
  final String? description;
  final double? width;
  final Function(dynamic)? onChanged;
  final Function(String)? onSearchChanged;

  // For slider type
  final double? sliderMin;
  final double? sliderMax;
  final int? sliderDivisions;

  FilterConfig({
    required this.key,
    required this.label,
    required this.type,
    this.placeholder,
    this.options,
    this.defaultValue,
    this.enabled = true,
    this.required = false,
    this.icon,
    this.description,
    this.width,
    this.onChanged,
    this.onSearchChanged,
    this.sliderMin,
    this.sliderMax,
    this.sliderDivisions,
  });

  // Factory constructors for common filter types
  factory FilterConfig.text({
    required String key,
    required String label,
    String? placeholder,
    dynamic defaultValue,
    bool enabled = true,
    bool required = false,
    IconData? icon,
    double? width,
    Function(dynamic)? onChanged,
  }) {
    return FilterConfig(
      key: key,
      label: label,
      type: FilterType.text,
      placeholder: placeholder,
      defaultValue: defaultValue,
      enabled: enabled,
      required: required,
      icon: icon,
      width: width,
      onChanged: onChanged,
    );
  }

  factory FilterConfig.number({
    required String key,
    required String label,
    String? placeholder,
    dynamic defaultValue,
    bool enabled = true,
    bool required = false,
    IconData? icon,
    double? width,
    Function(dynamic)? onChanged,
  }) {
    return FilterConfig(
      key: key,
      label: label,
      type: FilterType.number,
      placeholder: placeholder,
      defaultValue: defaultValue,
      enabled: enabled,
      required: required,
      icon: icon,
      width: width,
      onChanged: onChanged,
    );
  }

  factory FilterConfig.dropdown({
    required String key,
    required String label,
    required List<String> options,
    String? placeholder,
    dynamic defaultValue,
    bool enabled = true,
    bool required = false,
    IconData? icon,
    double? width,
    Function(dynamic)? onChanged,
  }) {
    return FilterConfig(
      key: key,
      label: label,
      type: FilterType.dropdown,
      options: options,
      placeholder: placeholder,
      defaultValue: defaultValue,
      enabled: enabled,
      required: required,
      icon: icon,
      width: width,
      onChanged: onChanged,
    );
  }

  factory FilterConfig.searchableDropdown({
    required String key,
    required String label,
    required List<String> options,
    String? placeholder,
    dynamic defaultValue,
    bool enabled = true,
    bool required = false,
    IconData? icon,
    double? width,
    Function(dynamic)? onChanged,
    Function(String)? onSearchChanged,
  }) {
    return FilterConfig(
      key: key,
      label: label,
      type: FilterType.searchableDropdown,
      options: options,
      placeholder: placeholder,
      defaultValue: defaultValue,
      enabled: enabled,
      required: required,
      icon: icon,
      width: width,
      onChanged: onChanged,
      onSearchChanged: onSearchChanged,
    );
  }

  factory FilterConfig.multiSelect({
    required String key,
    required String label,
    required List<String> options,
    dynamic defaultValue,
    bool enabled = true,
    bool required = false,
    double? width,
    Function(dynamic)? onChanged,
  }) {
    return FilterConfig(
      key: key,
      label: label,
      type: FilterType.multiSelect,
      options: options,
      defaultValue: defaultValue,
      enabled: enabled,
      required: required,
      width: width,
      onChanged: onChanged,
    );
  }

  factory FilterConfig.dateRange({
    required String key,
    required String label,
    String? placeholder,
    dynamic defaultValue,
    bool enabled = true,
    bool required = false,
    IconData? icon,
    double? width,
    Function(dynamic)? onChanged,
  }) {
    return FilterConfig(
      key: key,
      label: label,
      type: FilterType.dateRange,
      placeholder: placeholder,
      defaultValue: defaultValue,
      enabled: enabled,
      required: required,
      icon: icon,
      width: width,
      onChanged: onChanged,
    );
  }

  factory FilterConfig.datePicker({
    required String key,
    required String label,
    String? placeholder,
    dynamic defaultValue,
    bool enabled = true,
    bool required = false,
    IconData? icon,
    double? width,
    Function(dynamic)? onChanged,
  }) {
    return FilterConfig(
      key: key,
      label: label,
      type: FilterType.datePicker,
      placeholder: placeholder,
      defaultValue: defaultValue,
      enabled: enabled,
      required: required,
      icon: icon,
      width: width,
      onChanged: onChanged,
    );
  }

  factory FilterConfig.toggle({
    required String key,
    required String label,
    String? description,
    dynamic defaultValue,
    bool enabled = true,
    bool required = false,
    double? width,
    Function(dynamic)? onChanged,
  }) {
    return FilterConfig(
      key: key,
      label: label,
      type: FilterType.toggle,
      description: description,
      defaultValue: defaultValue,
      enabled: enabled,
      required: required,
      width: width,
      onChanged: onChanged,
    );
  }

  factory FilterConfig.slider({
    required String key,
    required String label,
    required double min,
    required double max,
    dynamic defaultValue,
    int? divisions,
    bool enabled = true,
    bool required = false,
    double? width,
    Function(dynamic)? onChanged,
  }) {
    return FilterConfig(
      key: key,
      label: label,
      type: FilterType.slider,
      defaultValue: defaultValue,
      enabled: enabled,
      required: required,
      width: width,
      onChanged: onChanged,
      sliderMin: min,
      sliderMax: max,
      sliderDivisions: divisions,
    );
  }
}
