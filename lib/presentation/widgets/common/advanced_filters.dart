import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import 'app_button.dart';
import 'app_input_field.dart';

class AdvancedFilters extends StatefulWidget {
  final List<FilterConfig> filterConfigs;
  final Map<String, dynamic> initialValues;
  final Function(Map<String, dynamic>) onFiltersChanged;
  final VoidCallback? onClear;
  final VoidCallback? onSave;
  final bool showSaveOption;
  final String? savedFilterName;

  const AdvancedFilters({
    super.key,
    required this.filterConfigs,
    required this.initialValues,
    required this.onFiltersChanged,
    this.onClear,
    this.onSave,
    this.showSaveOption = false,
    this.savedFilterName,
  });

  @override
  State<AdvancedFilters> createState() => _AdvancedFiltersState();
}

class _AdvancedFiltersState extends State<AdvancedFilters> {
  late Map<String, dynamic> _filterValues;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _filterValues = Map.from(widget.initialValues);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      child: Column(
        children: [_buildHeader(), if (_isExpanded) _buildFiltersContent()],
      ),
    );
  }

  Widget _buildHeader() {
    final activeFiltersCount = _filterValues.values
        .where((value) => value != null && value.toString().isNotEmpty)
        .length;

    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Row(
          children: [
            Icon(
              Icons.filter_list,
              color: activeFiltersCount > 0
                  ? AppColors.primary
                  : AppColors.textSecondary,
              size: AppSizes.iconMedium,
            ),
            const SizedBox(width: AppSizes.spacing8),
            Text(
              'Advanced Filters',
              style: TextStyle(
                fontSize: AppSizes.fontSizeMedium,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
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
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
                child: Text(
                  '$activeFiltersCount',
                  style: const TextStyle(
                    color: AppColors.textInverse,
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
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Text(
                  widget.savedFilterName!,
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: AppSizes.fontSizeSmall,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.spacing8),
            ],
            Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersContent() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          _buildFilterFields(),
          const SizedBox(height: AppSizes.spacing16),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildFilterFields() {
    return Wrap(
      spacing: AppSizes.spacing16,
      runSpacing: AppSizes.spacing16,
      children: widget.filterConfigs.map((config) {
        return SizedBox(
          width: _getFieldWidth(config),
          child: _buildFilterField(config),
        );
      }).toList(),
    );
  }

  double _getFieldWidth(FilterConfig config) {
    switch (config.type) {
      case FilterType.text:
      case FilterType.number:
        return 200;
      case FilterType.dropdown:
      case FilterType.multiSelect:
        return 180;
      case FilterType.dateRange:
        return 250;
      case FilterType.toggle:
        return 120;
      default:
        return 200;
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
      case FilterType.multiSelect:
        return _buildMultiSelectFilter(config);
      case FilterType.dateRange:
        return _buildDateRangeFilter(config);
      case FilterType.toggle:
        return _buildToggleFilter(config);
      default:
        return const SizedBox();
    }
  }

  Widget _buildTextFilter(FilterConfig config) {
    return AppInputField(
      label: config.label,
      hintText: config.placeholder,
      controller: TextEditingController(
        text: _filterValues[config.key]?.toString() ?? '',
      ),
      onChanged: (value) =>
          _updateFilter(config.key, value.isEmpty ? null : value),
    );
  }

  Widget _buildNumberFilter(FilterConfig config) {
    return AppInputField(
      label: config.label,
      hintText: config.placeholder,
      keyboardType: TextInputType.number,
      controller: TextEditingController(
        text: _filterValues[config.key]?.toString() ?? '',
      ),
      onChanged: (value) {
        final numValue = value.isEmpty ? null : double.tryParse(value);
        _updateFilter(config.key, numValue);
      },
    );
  }

  Widget _buildDropdownFilter(FilterConfig config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          config.label,
          style: const TextStyle(
            fontSize: AppSizes.fontSizeSmall,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSizes.spacing4),
        DropdownButtonFormField<String>(
          value: _filterValues[config.key],
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacing12,
              vertical: AppSizes.spacing8,
            ),
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('All')),
            ...config.options!.map(
              (option) => DropdownMenuItem(value: option, child: Text(option)),
            ),
          ],
          onChanged: (value) => _updateFilter(config.key, value),
        ),
      ],
    );
  }

  Widget _buildMultiSelectFilter(FilterConfig config) {
    final selectedValues = _filterValues[config.key] as List<String>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          config.label,
          style: const TextStyle(
            fontSize: AppSizes.fontSizeSmall,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSizes.spacing4),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          ),
          child: Column(
            children: config.options!.map((option) {
              final isSelected = selectedValues.contains(option);
              return CheckboxListTile(
                dense: true,
                value: isSelected,
                title: Text(
                  option,
                  style: const TextStyle(fontSize: AppSizes.fontSizeSmall),
                ),
                onChanged: (checked) {
                  final newValues = List<String>.from(selectedValues);
                  if (checked == true) {
                    newValues.add(option);
                  } else {
                    newValues.remove(option);
                  }
                  _updateFilter(
                    config.key,
                    newValues.isEmpty ? null : newValues,
                  );
                },
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
        Text(
          config.label,
          style: const TextStyle(
            fontSize: AppSizes.fontSizeSmall,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSizes.spacing4),
        InkWell(
          onTap: () async {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              initialDateRange: dateRange,
            );
            if (picked != null) {
              _updateFilter(config.key, picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(AppSizes.spacing12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.date_range,
                  size: AppSizes.iconSmall,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSizes.spacing8),
                Expanded(
                  child: Text(
                    dateRange != null
                        ? '${_formatDate(dateRange.start)} - ${_formatDate(dateRange.end)}'
                        : 'Select date range',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeSmall,
                      color: dateRange != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
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
          onChanged: (value) => _updateFilter(config.key, value),
          activeColor: AppColors.primary,
        ),
        const SizedBox(width: AppSizes.spacing8),
        Text(
          config.label,
          style: const TextStyle(
            fontSize: AppSizes.fontSizeSmall,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (widget.onClear != null)
          AppButton(
            text: 'Clear All',
            type: AppButtonType.secondary,
            onPressed: () {
              setState(() {
                _filterValues.clear();
              });
              widget.onClear?.call();
              widget.onFiltersChanged(_filterValues);
            },
          ),
        const SizedBox(width: AppSizes.spacing8),
        AppButton(
          text: 'Apply Filters',
          onPressed: () => widget.onFiltersChanged(_filterValues),
        ),
        if (widget.showSaveOption) ...[
          const SizedBox(width: AppSizes.spacing8),
          AppButton(
            text: 'Save Filter',
            type: AppButtonType.secondary,
            onPressed: widget.onSave,
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _updateFilter(String key, dynamic value) {
    setState(() {
      if (value == null ||
          (value is String && value.isEmpty) ||
          (value is List && value.isEmpty)) {
        _filterValues.remove(key);
      } else {
        _filterValues[key] = value;
      }
    });
  }
}

enum FilterType { text, number, dropdown, multiSelect, dateRange, toggle }

class FilterConfig {
  final String key;
  final String label;
  final FilterType type;
  final String? placeholder;
  final List<String>? options;
  final dynamic defaultValue;

  FilterConfig({
    required this.key,
    required this.label,
    required this.type,
    this.placeholder,
    this.options,
    this.defaultValue,
  });
}
