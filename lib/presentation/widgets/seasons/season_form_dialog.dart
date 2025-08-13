import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/season.dart';
import '../common/app_button.dart';
import '../common/app_input_field.dart';
import '../common/app_toast.dart';

class SeasonFormDialog extends StatefulWidget {
  final Season? season; // null for create, populated for edit
  final Function(Season)? onSave;
  final VoidCallback? onSuccess;

  const SeasonFormDialog({super.key, this.season, this.onSave, this.onSuccess});

  @override
  State<SeasonFormDialog> createState() => _SeasonFormDialogState();
}

class _SeasonFormDialogState extends State<SeasonFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<bool> _selectedMonths = List.filled(12, false);
  bool _isLoading = false;

  final List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.season != null) {
      _nameController.text = widget.season!.name;
      _descriptionController.text = widget.season!.description;

      // Set selected months based on the season's month range
      for (int i = 0; i < 12; i++) {
        _selectedMonths[i] = widget.season!.monthRange.contains(i + 1);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Build smart select/clear all button based on current selection state
  Widget _buildSmartSelectButton() {
    final selectedCount = _selectedMonths.where((selected) => selected).length;
    final allSelected = selectedCount == 12;

    if (allSelected) {
      // Show Clear All button when all are selected
      return TextButton.icon(
        onPressed: _clearAllMonths,
        icon: const Icon(Icons.clear_all, size: AppSizes.iconSmall),
        label: const Text('Clear All'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.error,
          textStyle: const TextStyle(
            fontSize: AppSizes.fontSizeSmall,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    } else {
      // Show Select All button when not all are selected
      return TextButton.icon(
        onPressed: _selectAllMonths,
        icon: const Icon(Icons.select_all, size: AppSizes.iconSmall),
        label: const Text('Select All'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontSize: AppSizes.fontSizeSmall,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
  }

  /// Select all months
  void _selectAllMonths() {
    setState(() {
      _selectedMonths = List.filled(12, true);
    });
  }

  /// Clear all month selections
  void _clearAllMonths() {
    setState(() {
      _selectedMonths = List.filled(12, false);
    });
  }

  /// Set months based on a predefined pattern
  void _setMonthPattern(List<int> months) {
    setState(() {
      _selectedMonths = List.filled(12, false);
      for (final month in months) {
        if (month >= 1 && month <= 12) {
          _selectedMonths[month - 1] = true;
        }
      }
    });
  }

  /// Build a quick pattern chip for common season selections
  Widget _buildQuickPatternChip(String label, List<int> months, Color color) {
    final isCurrentPattern = _isCurrentPattern(months);

    return GestureDetector(
      onTap: () => _setMonthPattern(months),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isCurrentPattern
              ? color.withValues(alpha: 0.2)
              : color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCurrentPattern ? color : color.withValues(alpha: 0.3),
            width: isCurrentPattern ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCurrentPattern) ...[
              Icon(Icons.check_circle, color: color, size: 12),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: AppSizes.fontSizeExtraSmall,
                fontWeight: isCurrentPattern
                    ? FontWeight.w600
                    : FontWeight.w500,
                color: isCurrentPattern ? color : color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Check if the current selection matches a pattern
  bool _isCurrentPattern(List<int> months) {
    final selectedMonths = <int>[];
    for (int i = 0; i < 12; i++) {
      if (_selectedMonths[i]) {
        selectedMonths.add(i + 1);
      }
    }

    if (selectedMonths.length != months.length) return false;

    final sortedSelected = List.from(selectedMonths)..sort();
    final sortedPattern = List.from(months)..sort();

    for (int i = 0; i < sortedSelected.length; i++) {
      if (sortedSelected[i] != sortedPattern[i]) return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.season != null;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        constraints: const BoxConstraints(minWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                    isEdit ? 'Edit Season' : 'Create Season',
                    style: const TextStyle(
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
            ),

            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.spacing24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name Field
                      AppInputField(
                        label: 'Name',
                        controller: _nameController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Season name is required';
                          }
                          if (value.trim().length < 2) {
                            return 'Season name must be at least 2 characters';
                          }
                          return null;
                        },
                        hintText: 'Enter season name (e.g., Summer, Winter)',
                      ),

                      const SizedBox(height: AppSizes.spacing20),

                      // Description Field
                      AppInputField(
                        label: 'Description',
                        controller: _descriptionController,
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Description is required';
                          }
                          return null;
                        },
                        hintText: 'Enter season description',
                      ),

                      const SizedBox(height: AppSizes.spacing24),

                      // Month Selection Header with Smart Bulk Action
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Select Months',
                            style: TextStyle(
                              fontSize: AppSizes.fontSizeLarge,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          // Smart Select All/Clear All button
                          _buildSmartSelectButton(),
                        ],
                      ),
                      const SizedBox(height: AppSizes.spacing12),

                      // Quick Season Patterns
                      Container(
                        padding: const EdgeInsets.all(AppSizes.spacing12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMedium,
                          ),
                          border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quick Patterns:',
                              style: TextStyle(
                                fontSize: AppSizes.fontSizeSmall,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSizes.spacing8),
                            Wrap(
                              spacing: AppSizes.spacing8,
                              runSpacing: AppSizes.spacing4,
                              children: [
                                _buildQuickPatternChip('Winter', [
                                  12,
                                  1,
                                  2,
                                ], AppColors.primary),
                                _buildQuickPatternChip('Spring', [
                                  3,
                                  4,
                                  5,
                                ], AppColors.primary),
                                _buildQuickPatternChip('Summer', [
                                  6,
                                  7,
                                  8,
                                ], AppColors.primary),
                                _buildQuickPatternChip('Autumn', [
                                  9,
                                  10,
                                  11,
                                ], AppColors.primary),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacing8),
                      const Text(
                        'Choose the months that belong to this season',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeMedium,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacing16),

                      _buildMonthSelection(),

                      const SizedBox(height: AppSizes.spacing16),

                      // Selected months summary
                      _buildSelectedMonthsSummary(),
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
                    onPressed: () => Navigator.of(context).pop(),
                    type: AppButtonType.outline,
                  ),
                  const SizedBox(width: AppSizes.spacing12),
                  AppButton(
                    text: isEdit ? 'Update Season' : 'Create Season',
                    onPressed: _isLoading ? null : _handleSave,
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

  Widget _buildMonthSelection() {
    // Use only primary color for easier theming
    const primaryColor = AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          childAspectRatio: 2.5,
          crossAxisSpacing: AppSizes.spacing8,
          mainAxisSpacing: AppSizes.spacing8,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          final isSelected = _selectedMonths[index];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedMonths[index] = !_selectedMonths[index];
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor.withValues(alpha: 0.2)
                    : primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                border: Border.all(
                  color: isSelected
                      ? primaryColor
                      : primaryColor.withValues(alpha: 0.3),
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
                        color: primaryColor,
                        size: AppSizes.iconSmall,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: Text(
                        _monthNames[index],
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeSmall,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected
                              ? primaryColor
                              : primaryColor.withValues(alpha: 0.8),
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedMonthsSummary() {
    // Use only primary color for easier theming
    const primaryColor = AppColors.primary;
    final selectedCount = _selectedMonths.where((selected) => selected).length;
    final selectedMonthNames = <String>[];
    final selectedIndices = <int>[];

    for (int i = 0; i < 12; i++) {
      if (_selectedMonths[i]) {
        selectedMonthNames.add(_monthNames[i]);
        selectedIndices.add(i);
      }
    }

    if (selectedCount == 0) {
      return Container(
        padding: const EdgeInsets.all(AppSizes.spacing12),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning,
              color: AppColors.warning,
              size: AppSizes.iconMedium,
            ),
            const SizedBox(width: AppSizes.spacing8),
            const Text(
              'Please select at least one month',
              style: TextStyle(
                color: AppColors.warning,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Special case for all months selected
    if (selectedCount == 12) {
      return Container(
        padding: const EdgeInsets.all(AppSizes.spacing12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month,
              color: AppColors.primary,
              size: AppSizes.iconMedium,
            ),
            const SizedBox(width: AppSizes.spacing8),
            Text(
              'All 12 months selected (Full Year Season)',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: AppSizes.fontSizeSmall,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing12),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: primaryColor,
                size: AppSizes.iconMedium,
              ),
              const SizedBox(width: AppSizes.spacing8),
              Text(
                'Selected $selectedCount month${selectedCount == 1 ? '' : 's'}:',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: AppSizes.fontSizeSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing8),
          Wrap(
            spacing: AppSizes.spacing4,
            runSpacing: AppSizes.spacing4,
            children: selectedIndices.map((index) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  _monthNames[index],
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeExtraSmall,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final selectedCount = _selectedMonths.where((selected) => selected).length;
    if (selectedCount == 0) {
      AppToast.show(
        context,
        title: 'Validation Error',
        message: 'Please select at least one month for the season.',
        type: ToastType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Build month range list (1-based indexing)
      final monthRange = <int>[];
      for (int i = 0; i < 12; i++) {
        if (_selectedMonths[i]) {
          monthRange.add(i + 1);
        }
      }

      // Create or update season
      final season = Season(
        id: widget.season?.id ?? 0,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        monthRange: monthRange,
        active: widget.season?.active ?? true,
      );

      print('🔄 SeasonFormDialog: Saving season: ${season.name}');
      print('📅 SeasonFormDialog: Month range: $monthRange');

      if (widget.onSave != null) {
        await widget.onSave!(season);
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess?.call();

        AppToast.show(
          context,
          title: 'Success',
          message: widget.season != null
              ? 'Season updated successfully'
              : 'Season created successfully',
          type: ToastType.success,
        );
      }
    } catch (e) {
      print('❌ SeasonFormDialog: Error saving season: $e');
      if (mounted) {
        AppToast.show(
          context,
          title: 'Error',
          message: 'Failed to save season. Please try again.',
          type: ToastType.error,
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
}
