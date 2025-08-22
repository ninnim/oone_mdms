import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/season.dart';
import '../../../core/utils/responsive_helper.dart';
import '../common/app_button.dart';
import '../common/app_input_field.dart';
import '../common/app_toast.dart';
import '../common/app_dialog_header.dart';

class SeasonFormDialog extends StatefulWidget {
  final Season? season; // null for create, populated for edit/view
  final Function(Season)? onSave;
  final VoidCallback? onSuccess;
  final bool isReadOnly; // New parameter for view-only mode

  const SeasonFormDialog({
    super.key,
    this.season,
    this.onSave,
    this.onSuccess,
    this.isReadOnly = false,
  });

  @override
  State<SeasonFormDialog> createState() => _SeasonFormDialogState();
}

class _SeasonFormDialogState extends State<SeasonFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<bool> _selectedMonths = List.filled(12, false);
  bool _isLoading = false;
  bool _isInEditMode = false; // Track if we're in edit mode

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
    _isInEditMode = !widget.isReadOnly; // Start in edit mode if not read-only
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
  Widget _buildQuickPatternChip(
    String label,
    List<int> months,
    Color color, {
    bool isReadOnly = false,
  }) {
    final isCurrentPattern = _isCurrentPattern(months);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return GestureDetector(
      onTap: isReadOnly ? null : () => _setMonthPattern(months),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 8 : 12,
          vertical: isMobile ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: isCurrentPattern
              ? color.withValues(alpha: 0.2)
              : color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
          border: Border.all(
            color: isCurrentPattern ? color : color.withValues(alpha: 0.3),
            width: isCurrentPattern ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCurrentPattern) ...[
              Icon(Icons.check_circle, color: color, size: isMobile ? 10 : 12),
              SizedBox(width: isMobile ? 2 : 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: isMobile
                    ? AppSizes.fontSizeExtraSmall - 1
                    : AppSizes.fontSizeExtraSmall,
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
    final isCreate = widget.season == null;
    final isViewMode = widget.isReadOnly && !_isInEditMode;

    // Use ResponsiveHelper for consistent responsive behavior
    final isMobile = context.isMobile;

    // Get dialog constraints from ResponsiveHelper
    final dialogConstraints = ResponsiveHelper.getDialogConstraints(context);

    // Dialog configuration based on mode
    DialogType dialogType;
    String dialogTitle;
    String dialogSubtitle;

    if (isCreate) {
      dialogType = DialogType.create;
      dialogTitle = 'Create Season';
      dialogSubtitle = 'Define a new seasonal period with month ranges';
    } else if (isViewMode) {
      dialogType = DialogType.view;
      dialogTitle = 'Season Details';
      dialogSubtitle = 'View seasonal information and month ranges';
    } else {
      dialogType = DialogType.edit;
      dialogTitle = 'Edit Season';
      dialogSubtitle = 'Modify seasonal period and month ranges';
    }

    return PopScope(
      canPop: false, // Prevent dismissal with back button
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getCardBorderRadius(context),
          ),
        ),
        child: Container(
          constraints: dialogConstraints,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Enhanced Header using reusable widget
              AppDialogHeader(
                type: dialogType,
                title: dialogTitle,
                subtitle: dialogSubtitle,
                onClose: () => Navigator.of(context).pop(),
                showCloseButton: true,
              ),

              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: ResponsiveHelper.getPadding(context),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Name Field
                        AppInputField(
                          label: 'Name',
                          controller: _nameController,
                          readOnly: isViewMode,
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

                        SizedBox(
                          height: isMobile
                              ? AppSizes.spacing16
                              : AppSizes.spacing20,
                        ),

                        // Description Field
                        AppInputField(
                          label: 'Description',
                          controller: _descriptionController,
                          readOnly: isViewMode,
                          maxLines: isMobile ? 2 : 3,
                          hintText: 'Enter season description',
                        ),

                        SizedBox(
                          height: isMobile
                              ? AppSizes.spacing16
                              : AppSizes.spacing24,
                        ),

                        // Month Selection Header with Smart Bulk Action
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Select Months',
                                style: TextStyle(
                                  fontSize: isMobile
                                      ? AppSizes.fontSizeMedium
                                      : AppSizes.fontSizeLarge,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Smart Select All/Clear All button (only in edit mode)
                            if (!isViewMode) _buildSmartSelectButton(),
                          ],
                        ),
                        SizedBox(
                          height: isMobile
                              ? AppSizes.spacing8
                              : AppSizes.spacing12,
                        ),

                        // Quick Season Patterns (only in edit mode)
                        Container(
                          padding: EdgeInsets.all(
                            isMobile ? AppSizes.spacing8 : AppSizes.spacing12,
                          ),
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
                              Text(
                                'Quick Patterns:',
                                style: TextStyle(
                                  fontSize: isMobile
                                      ? AppSizes.fontSizeExtraSmall
                                      : AppSizes.fontSizeSmall,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              SizedBox(
                                height: isMobile
                                    ? AppSizes.spacing4
                                    : AppSizes.spacing8,
                              ),
                              Wrap(
                                spacing: isMobile
                                    ? AppSizes.spacing4
                                    : AppSizes.spacing8,
                                runSpacing: AppSizes.spacing4,
                                children: [
                                  _buildQuickPatternChip(
                                    'Winter',
                                    [12, 1, 2],
                                    AppColors.primary,
                                    isReadOnly: isViewMode,
                                  ),
                                  _buildQuickPatternChip(
                                    'Spring',
                                    [3, 4, 5],
                                    AppColors.primary,
                                    isReadOnly: isViewMode,
                                  ),
                                  _buildQuickPatternChip('Summer', [
                                    6,
                                    7,
                                    8,
                                  ], AppColors.primary),
                                  _buildQuickPatternChip(
                                    'Autumn',
                                    [9, 10, 11],
                                    AppColors.primary,
                                    isReadOnly: isViewMode,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: isMobile
                              ? AppSizes.spacing6
                              : AppSizes.spacing8,
                        ),

                        Text(
                          'Choose the months that belong to this season',
                          style: TextStyle(
                            fontSize: isMobile
                                ? AppSizes.fontSizeSmall
                                : AppSizes.fontSizeMedium,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(
                          height: isMobile
                              ? AppSizes.spacing12
                              : AppSizes.spacing16,
                        ),

                        _buildMonthSelection(isReadOnly: isViewMode),

                        SizedBox(
                          height: isMobile
                              ? AppSizes.spacing12
                              : AppSizes.spacing16,
                        ),

                        // Selected months summary
                        _buildSelectedMonthsSummary(),
                      ],
                    ),
                  ),
                ),
              ),

              // Footer
              Container(
                padding: ResponsiveHelper.getPadding(context),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: ResponsiveHelper.shouldUseCompactUI(context)
                    ? _buildMobileFooter(isCreate, isViewMode)
                    : _buildDesktopFooter(isCreate, isViewMode),
              ),
            ],
          ),
        ), // Container closing
      ), // Dialog closing
    ); // PopScope closing
  }

  // Mobile footer - vertical button layout
  Widget _buildMobileFooter(bool isCreate, bool isViewMode) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButton(
          text: (isViewMode && !isCreate)
              ? 'Edit'
              : (isCreate ? 'Create Season' : 'Update Season'),
          onPressed: (isViewMode && !isCreate)
              ? () {
                  setState(() {
                    _isInEditMode = true;
                  });
                }
              : (_isLoading ? null : _handleSave),
          isLoading: (isViewMode && !isCreate) ? false : _isLoading,
        ),
        const SizedBox(height: AppSizes.spacing8),
        AppButton(
          text: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
          type: AppButtonType.outline,
        ),
      ],
    );
  }

  // Desktop footer - horizontal button layout
  Widget _buildDesktopFooter(bool isCreate, bool isViewMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AppButton(
          text: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
          type: AppButtonType.outline,
        ),
        const SizedBox(width: AppSizes.spacing12),
        AppButton(
          text: (isViewMode && !isCreate)
              ? 'Edit'
              : (isCreate ? 'Create Season' : 'Update Season'),
          onPressed: (isViewMode && !isCreate)
              ? () {
                  setState(() {
                    _isInEditMode = true;
                  });
                }
              : (_isLoading ? null : _handleSave),
          isLoading: (isViewMode && !isCreate) ? false : _isLoading,
        ),
      ],
    );
  }

  Widget _buildMonthSelection({bool isReadOnly = false}) {
    // Use only primary color for easier theming
    const primaryColor = AppColors.primary;

    // Adjust for month selection grid - optimize for 12 items
    int monthGridColumns;
    double childAspectRatio;

    if (context.isMobile) {
      // Mobile: 3 columns, 4 rows
      monthGridColumns = 3;
      childAspectRatio = 2.2;
    } else if (context.isTablet) {
      // Tablet: 4 columns, 3 rows
      monthGridColumns = 4;
      childAspectRatio = 2.4;
    } else {
      // Desktop: 6 columns, 2 rows
      monthGridColumns = 6;
      childAspectRatio = 2.5;
    }

    return Container(
      padding: ResponsiveHelper.getPadding(context),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getCardBorderRadius(context),
        ),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: monthGridColumns,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: ResponsiveHelper.shouldUseCompactUI(context)
              ? AppSizes.spacing6
              : AppSizes.spacing8,
          mainAxisSpacing: ResponsiveHelper.shouldUseCompactUI(context)
              ? AppSizes.spacing6
              : AppSizes.spacing8,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          final isSelected = _selectedMonths[index];

          return GestureDetector(
            onTap: isReadOnly
                ? null
                : () {
                    setState(() {
                      _selectedMonths[index] = !_selectedMonths[index];
                    });
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: EdgeInsets.symmetric(
                horizontal: context.isMobile ? 6 : 12,
                vertical: context.isMobile ? 6 : 8,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor.withValues(alpha: isReadOnly ? 0.1 : 0.2)
                    : primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(
                  context.isMobile
                      ? AppSizes.radiusSmall
                      : AppSizes.radiusMedium,
                ),
                border: Border.all(
                  color: isSelected
                      ? primaryColor
                      : primaryColor.withValues(alpha: 0.3),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: ResponsiveHelper.shouldUseCompactUI(context)
                    ? _buildMobileMonthContent(index, isSelected, primaryColor)
                    : _buildDesktopMonthContent(
                        index,
                        isSelected,
                        primaryColor,
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Mobile-optimized month content (compact layout)
  Widget _buildMobileMonthContent(
    int index,
    bool isSelected,
    Color primaryColor,
  ) {
    // Use 3-letter abbreviations for mobile
    final monthAbbrev = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isSelected) ...[
          Icon(Icons.check_circle, color: primaryColor, size: 14),
          const SizedBox(height: 2),
        ],
        Flexible(
          child: Text(
            monthAbbrev[index],
            style: TextStyle(
              fontSize: AppSizes.fontSizeExtraSmall,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected
                  ? primaryColor
                  : primaryColor.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Desktop month content (original horizontal layout)
  Widget _buildDesktopMonthContent(
    int index,
    bool isSelected,
    Color primaryColor,
  ) {
    return Row(
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
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? primaryColor
                  : primaryColor.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedMonthsSummary() {
    // Use only primary color for easier theming
    const primaryColor = AppColors.primary;
    final selectedCount = _selectedMonths.where((selected) => selected).length;
    final selectedMonthNames = <String>[];
    final selectedIndices = <int>[];
    final shouldUseCompactUI = ResponsiveHelper.shouldUseCompactUI(context);

    for (int i = 0; i < 12; i++) {
      if (_selectedMonths[i]) {
        selectedMonthNames.add(_monthNames[i]);
        selectedIndices.add(i);
      }
    }

    if (selectedCount == 0) {
      return Container(
        padding: EdgeInsets.all(
          shouldUseCompactUI ? AppSizes.spacing8 : AppSizes.spacing12,
        ),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getCardBorderRadius(context),
          ),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning,
              color: AppColors.warning,
              size: shouldUseCompactUI
                  ? AppSizes.iconSmall
                  : AppSizes.iconMedium,
            ),
            SizedBox(
              width: shouldUseCompactUI ? AppSizes.spacing4 : AppSizes.spacing8,
            ),
            Expanded(
              child: Text(
                'Please select at least one month',
                style: TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w500,
                  fontSize: shouldUseCompactUI ? AppSizes.fontSizeSmall : null,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Special case for all months selected
    if (selectedCount == 12) {
      return Container(
        padding: EdgeInsets.all(
          shouldUseCompactUI ? AppSizes.spacing8 : AppSizes.spacing12,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getCardBorderRadius(context),
          ),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month,
              color: AppColors.primary,
              size: shouldUseCompactUI
                  ? AppSizes.iconSmall
                  : AppSizes.iconMedium,
            ),
            SizedBox(
              width: shouldUseCompactUI ? AppSizes.spacing4 : AppSizes.spacing8,
            ),
            Expanded(
              child: Text(
                'All 12 months selected (Full Year Season)',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: shouldUseCompactUI
                      ? AppSizes.fontSizeExtraSmall
                      : AppSizes.fontSizeSmall,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(
        shouldUseCompactUI ? AppSizes.spacing8 : AppSizes.spacing12,
      ),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getCardBorderRadius(context),
        ),
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
                size: shouldUseCompactUI
                    ? AppSizes.iconSmall
                    : AppSizes.iconMedium,
              ),
              SizedBox(
                width: shouldUseCompactUI
                    ? AppSizes.spacing4
                    : AppSizes.spacing8,
              ),
              Expanded(
                child: Text(
                  'Selected $selectedCount month${selectedCount == 1 ? '' : 's'}:',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: shouldUseCompactUI
                        ? AppSizes.fontSizeExtraSmall
                        : AppSizes.fontSizeSmall,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: shouldUseCompactUI ? AppSizes.spacing4 : AppSizes.spacing8,
          ),
          Wrap(
            spacing: shouldUseCompactUI ? AppSizes.spacing2 : AppSizes.spacing4,
            runSpacing: AppSizes.spacing4,
            children: selectedIndices.map((index) {
              // Use abbreviated names on mobile for better space usage
              final monthName = shouldUseCompactUI
                  ? [
                      'Jan',
                      'Feb',
                      'Mar',
                      'Apr',
                      'May',
                      'Jun',
                      'Jul',
                      'Aug',
                      'Sep',
                      'Oct',
                      'Nov',
                      'Dec',
                    ][index]
                  : _monthNames[index];

              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: shouldUseCompactUI ? 6 : 8,
                  vertical: shouldUseCompactUI ? 2 : 4,
                ),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(
                    shouldUseCompactUI ? 8 : 12,
                  ),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  monthName,
                  style: TextStyle(
                    fontSize: shouldUseCompactUI
                        ? AppSizes.fontSizeExtraSmall - 1
                        : AppSizes.fontSizeExtraSmall,
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
              ? 'Season "${_nameController.text.trim()}" updated successfully'
              : 'Season "${_nameController.text.trim()}" created successfully',
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
