import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/special_day.dart';
import '../../../core/utils/responsive_helper.dart';
import '../common/app_button.dart';
import '../common/app_input_field.dart';
import '../common/app_toast.dart';
import '../common/app_dialog_header.dart';
import '../common/custom_single_date_picker.dart';

enum SpecialDayDialogMode { view, edit, create }

// Helper class to manage Special Day Detail form data
class _SpecialDayDetailItem {
  final int id;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  DateTime? startDate;
  DateTime? endDate;
  bool active; // Track if this detail is active or marked for deletion

  _SpecialDayDetailItem({
    required this.id,
    String? name,
    String? description,
    this.startDate,
    this.endDate,
    this.active = true, // Default to active
  }) : nameController = TextEditingController(text: name ?? ''),
       descriptionController = TextEditingController(text: description ?? '');

  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
  }

  SpecialDayDetail toSpecialDayDetail() {
    return SpecialDayDetail(
      id: id > 0 ? id : 0, // Use 0 for new items
      specialDayId: 0, // Will be set by API
      name: nameController.text.trim(),
      description: descriptionController.text.trim(),
      startDate: startDate ?? DateTime.now(),
      endDate: endDate ?? DateTime.now(),
      active: active, // Use the active field from this item
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id > 0) 'Id': id,
      'Name': nameController.text.trim(),
      'Description': descriptionController.text.trim(),
      'StartDate': (startDate ?? DateTime.now())
          .toIso8601String()
          .split('T')
          .first,
      'EndDate': (endDate ?? DateTime.now()).toIso8601String().split('T').first,
      'Active': active, // Use the active field from this item
    };
  }
}

class SpecialDayFormDialog extends StatefulWidget {
  final SpecialDay? specialDay; // null for create, non-null for edit/view
  final SpecialDayDialogMode mode; // view, edit, or create
  final Function(SpecialDay) onSave;
  final VoidCallback?
  onSuccess; // Callback to refresh data after successful operation

  const SpecialDayFormDialog({
    super.key,
    this.specialDay,
    this.mode = SpecialDayDialogMode.create,
    required this.onSave,
    this.onSuccess,
  });

  @override
  State<SpecialDayFormDialog> createState() => _SpecialDayFormDialogState();
}

class _SpecialDayFormDialogState extends State<SpecialDayFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSaving = false;
  bool _hasValidationErrors = false; // Track if validation has been attempted
  SpecialDayDialogMode _currentMode =
      SpecialDayDialogMode.create; // Track current mode

  // Special Day Details Management
  List<_SpecialDayDetailItem> _specialDayDetails = [];
  int _nextDetailId = -1; // Negative IDs for new items

  @override
  void initState() {
    super.initState();
    _currentMode = widget.mode;
    _initializeForm();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    // Dispose detail controllers
    for (var detail in _specialDayDetails) {
      detail.dispose();
    }
    super.dispose();
  }

  void _initializeForm() {
    if (widget.specialDay != null) {
      // Edit mode
      final specialDay = widget.specialDay!;
      _nameController.text = specialDay.name;
      _descriptionController.text = specialDay.description;

      // Initialize existing Special Day Details
      _specialDayDetails = specialDay.specialDayDetails.map((detail) {
        return _SpecialDayDetailItem(
          id: detail.id,
          name: detail.name,
          description: detail.description,
          startDate: detail.startDate,
          endDate: detail.endDate,
          active: detail.active, // Include the active field
        );
      }).toList();
    } else {
      // Create mode - add one default detail
      _addNewSpecialDayDetail();
    }
  }

  void _addNewSpecialDayDetail() {
    setState(() {
      // Insert at the beginning (index 0) instead of adding at the end
      _specialDayDetails.insert(
        0,
        _SpecialDayDetailItem(
          id: _nextDetailId--,
          name: '',
          description: '',
          startDate: null, // Start with null to avoid date picker issues
          endDate: null, // Start with null to avoid date picker issues
        ),
      );
    });
  }

  void _removeSpecialDayDetail(int index) {
    setState(() {
      // Instead of removing the item, mark it as inactive
      _specialDayDetails[index].active = false;
    });
  }

  bool get _isEditMode => _currentMode == SpecialDayDialogMode.edit;
  bool get _isViewMode => _currentMode == SpecialDayDialogMode.view;
  bool get _isReadOnlyMode => _isViewMode;

  void _switchToEditMode() {
    setState(() {
      _currentMode = SpecialDayDialogMode.edit;
    });
  }

  Future<void> _handleSave() async {
    // Set validation attempted flag and trigger rebuild
    setState(() {
      _hasValidationErrors = true;
    });

    // First, validate the main form
    if (!_formKey.currentState!.validate()) {
      AppToast.show(
        context,
        title: 'Validation Error',
        message: 'Please fix the errors in the form',
        type: ToastType.error,
      );
      return;
    }

    // Validate Special Day Details and trigger UI error states
    bool hasValidationErrors = false;

    for (int i = 0; i < _specialDayDetails.length; i++) {
      final detail = _specialDayDetails[i];

      // Skip validation for inactive details (marked for deletion)
      if (!detail.active) continue;

      // Validate Detail Name (required)
      if (detail.nameController.text.trim().isEmpty) {
        AppToast.show(
          context,
          title: 'Validation Error',
          message: 'Detail name is required for detail ${i + 1}',
          type: ToastType.error,
        );
        hasValidationErrors = true;
        break;
      }

      // Validate Start Date (required)
      if (detail.startDate == null) {
        AppToast.show(
          context,
          title: 'Validation Error',
          message: 'Start date is required for detail ${i + 1}',
          type: ToastType.error,
        );
        hasValidationErrors = true;
        break;
      }

      // Validate End Date (required)
      if (detail.endDate == null) {
        AppToast.show(
          context,
          title: 'Validation Error',
          message: 'End date is required for detail ${i + 1}',
          type: ToastType.error,
        );
        hasValidationErrors = true;
        break;
      }

      // Validate date range
      if (detail.endDate!.isBefore(detail.startDate!)) {
        AppToast.show(
          context,
          title: 'Validation Error',
          message: 'End date cannot be before start date for detail ${i + 1}',
          type: ToastType.error,
        );
        hasValidationErrors = true;
        break;
      }
    }

    if (hasValidationErrors) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Create SpecialDay object for callback (service will handle the payload format)
      final specialDay = SpecialDay(
        id: widget.specialDay?.id ?? 0,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        active: true, // Always active since we removed the toggle
        specialDayDetails: _specialDayDetails
            .map((detail) => detail.toSpecialDayDetail())
            .toList(),
      );

      // Call onSave with the special day object (the service will handle the payload format)
      await widget.onSave(specialDay);

      if (mounted) {
        Navigator.of(context).pop();

        // Show success toast
        AppToast.show(
          context,
          title: 'Success',
          message: _isEditMode
              ? 'Special day updated successfully'
              : 'Special day created successfully',
          type: ToastType.success,
        );

        if (widget.onSuccess != null) {
          widget.onSuccess!();
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          title: 'Error',
          message: 'Failed to save special day: $e',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _handleCancel() {
    Navigator.of(context).pop();
  }

  List<Widget> _buildSpecialDayDetailsList() {
    // Filter to show only active details in the UI
    final activeDetails = _specialDayDetails
        .asMap()
        .entries
        .where((entry) => entry.value.active)
        .toList();

    if (activeDetails.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(AppSizes.spacing24),
          decoration: BoxDecoration(
            color: context.surfaceColor, //AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            children: [
              Icon(
                Icons.event_note,
                size: 48,
                color: context.textSecondaryColor,
              ),
              const SizedBox(height: AppSizes.spacing12),
              Text(
                'No Special Day Details Added',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: context.textSecondaryColor,
                ),
              ),
              const SizedBox(height: AppSizes.spacing8),
              Text(
                _isViewMode
                    ? 'This special day has no details'
                    : 'Click "Add Detail" to create special day periods',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ];
    }

    return activeDetails.map((entry) {
      final index =
          entry.key; // This is the original index in _specialDayDetails
      final detail = entry.value;
      return _buildSpecialDayDetailCard(detail, index);
    }).toList();
  }

  Widget _buildSpecialDayDetailCard(_SpecialDayDetailItem detail, int index) {
    final isMobile = ResponsiveHelper.shouldUseCompactUI(context);
    final canDelete = _specialDayDetails.where((d) => d.active).length > 1;

    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveHelper.getSpacing(context)),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(color: context.borderColor.withOpacity(0.2)),
      ),
      padding: EdgeInsets.all(ResponsiveHelper.getSpacing(context)),
      child: isMobile
          ? _buildMobileDetailCard(detail, index, canDelete)
          : _buildDesktopDetailCard(detail, index, canDelete),
    );
  }

  Widget _buildMobileDetailCard(
    _SpecialDayDetailItem detail,
    int index,
    bool canDelete,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with delete button
        if (canDelete && !_isReadOnlyMode)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Detail ${index + 1}',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeSmall,
                  fontWeight: FontWeight.w600,
                  color: context.textSecondaryColor,
                ),
              ),
              IconButton(
                onPressed: () => _removeSpecialDayDetail(index),
                icon: const Icon(Icons.delete_outline),
                style: IconButton.styleFrom(
                  foregroundColor: context.errorColor,
                  backgroundColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),

        // Name field
        AppInputField(
          controller: detail.nameController,
          label: 'Detail Name',
          hintText: 'e.g., Khmer New Year',
          required: true,
          readOnly: _isReadOnlyMode,
          showErrorSpace: false,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Detail name is required';
            }
            return null;
          },
        ),
        SizedBox(height: ResponsiveHelper.getSpacing(context)),

        // Description field
        AppInputField(
          controller: detail.descriptionController,
          label: 'Description',
          hintText: 'Optional description',
          readOnly: _isReadOnlyMode,
          showErrorSpace: false,
        ),
        SizedBox(height: ResponsiveHelper.getSpacing(context)),

        // Date fields row
        Row(
          children: [
            Expanded(
              child: CustomSingleDatePicker(
                label: 'Start Date',
                hintText: 'Select start date',
                initialDate: detail.startDate,
                enabled: !_isReadOnlyMode,
                onDateSelected: (date) {
                  setState(() {
                    detail.startDate = date;
                    if (_hasValidationErrors && detail.startDate != null) {
                      // Optional: you can clear validation state here
                    }
                    // Auto-set end date if it's before start date
                    if (detail.endDate != null &&
                        detail.endDate!.isBefore(date)) {
                      detail.endDate = date;
                    }
                  });
                },
                isRequired: true,
                hasError: _hasValidationErrors && detail.startDate == null,
                errorText: _hasValidationErrors && detail.startDate == null
                    ? 'This field is required'
                    : null,
              ),
            ),
            SizedBox(width: ResponsiveHelper.getSpacing(context)),
            Expanded(
              child: CustomSingleDatePicker(
                label: 'End Date',
                hintText: 'Select end date',
                initialDate: detail.endDate,
                enabled: !_isReadOnlyMode,
                firstDate: detail.startDate,
                onDateSelected: (date) {
                  setState(() {
                    detail.endDate = date;
                    if (_hasValidationErrors && detail.endDate != null) {
                      // Optional: you can clear validation state here
                    }
                  });
                },
                isRequired: true,
                hasError: _hasValidationErrors && detail.endDate == null,
                errorText: _hasValidationErrors && detail.endDate == null
                    ? 'This field is required'
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopDetailCard(
    _SpecialDayDetailItem detail,
    int index,
    bool canDelete,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name field
        Expanded(
          child: AppInputField(
            controller: detail.nameController,
            label: 'Detail Name',
            hintText: 'e.g., Khmer New Year',
            required: true,
            readOnly: _isReadOnlyMode,
            showErrorSpace: false,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Detail name is required';
              }
              return null;
            },
          ),
        ),
        SizedBox(width: ResponsiveHelper.getSpacing(context)),

        // Description field
        Expanded(
          child: AppInputField(
            controller: detail.descriptionController,
            label: 'Description',
            hintText: 'Optional description',
            readOnly: _isReadOnlyMode,
            showErrorSpace: false,
          ),
        ),
        SizedBox(width: ResponsiveHelper.getSpacing(context)),

        // Start Date field
        Expanded(
          flex: 1,
          child: CustomSingleDatePicker(
            label: 'Start Date',
            hintText: 'Select start date',
            initialDate: detail.startDate,
            enabled: !_isReadOnlyMode,
            onDateSelected: (date) {
              setState(() {
                detail.startDate = date;
                if (_hasValidationErrors && detail.startDate != null) {
                  // Optional: you can clear validation state here
                }
                // Auto-set end date if it's before start date
                if (detail.endDate != null && detail.endDate!.isBefore(date)) {
                  detail.endDate = date;
                }
              });
            },
            isRequired: true,
            hasError: _hasValidationErrors && detail.startDate == null,
            errorText: _hasValidationErrors && detail.startDate == null
                ? 'This field is required'
                : null,
          ),
        ),
        SizedBox(width: ResponsiveHelper.getSpacing(context)),

        // End Date field
        Expanded(
          flex: 1,
          child: CustomSingleDatePicker(
            label: 'End Date',
            hintText: 'Select end date',
            initialDate: detail.endDate,
            enabled: !_isReadOnlyMode,
            firstDate: detail.startDate,
            onDateSelected: (date) {
              setState(() {
                detail.endDate = date;
                if (_hasValidationErrors && detail.endDate != null) {
                  // Optional: you can clear validation state here
                }
              });
            },
            isRequired: true,
            hasError: _hasValidationErrors && detail.endDate == null,
            errorText: _hasValidationErrors && detail.endDate == null
                ? 'This field is required'
                : null,
          ),
        ),

        // Delete button (only show if multiple active details exist)
        if (canDelete) ...[
          SizedBox(width: ResponsiveHelper.getSpacing(context)),
          if (!_isReadOnlyMode)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: IconButton(
                onPressed: () => _removeSpecialDayDetail(index),
                icon: const Icon(Icons.delete_outline),
                style: IconButton.styleFrom(
                  foregroundColor: context.errorColor,
                  backgroundColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
        ],
      ],
    );
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

    switch (_currentMode) {
      case SpecialDayDialogMode.create:
        dialogType = DialogType.create;
        dialogTitle = 'Create Special Day';
        dialogSubtitle =
            'Define special day periods with dates and descriptions';
        break;
      case SpecialDayDialogMode.view:
        dialogType = DialogType.view;
        dialogTitle = 'View Special Day';
        dialogSubtitle = 'Review special day configuration and details';
        break;
      case SpecialDayDialogMode.edit:
        dialogType = DialogType.edit;
        dialogTitle = 'Edit Special Day';
        dialogSubtitle = 'Update special day periods and settings';
        break;
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
              onClose: _handleCancel,
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
                    color: context.borderColor.withOpacity(0.1),
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
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInformationSection(),
              SizedBox(height: ResponsiveHelper.getSpacing(context) * 2),
              _buildSpecialDayDetailsSection(),
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
            text: _isSaving ? 'Saving...' : (_isEditMode ? 'Update' : 'Create'),
            onPressed: _isSaving ? null : _handleSave,
            isLoading: _isSaving,
          ),
        const SizedBox(height: AppSizes.spacing8),
        AppButton(
          text: _isViewMode ? 'Close' : 'Cancel',
          type: AppButtonType.outline,
          onPressed: _isSaving ? null : _handleCancel,
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
          onPressed: _isSaving ? null : _handleCancel,
        ),
        SizedBox(width: ResponsiveHelper.getSpacing(context)),
        if (_isViewMode)
          AppButton(text: 'Edit', onPressed: _switchToEditMode)
        else
          AppButton(
            text: _isSaving ? 'Saving...' : (_isEditMode ? 'Update' : 'Create'),
            onPressed: _isSaving ? null : _handleSave,
            isLoading: _isSaving,
          ),
      ],
    );
  }

  Widget _buildBasicInformationSection() {
    final isMobile = ResponsiveHelper.shouldUseCompactUI(context);

    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: context.borderColor.withOpacity(0.1)),
      ),
      padding: EdgeInsets.all(ResponsiveHelper.getSpacing(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Special Day Information',
            style: TextStyle(
              fontSize: isMobile
                  ? AppSizes.fontSizeMedium
                  : AppSizes.fontSizeLarge,
              fontWeight: FontWeight.w600,
              color: context.textPrimaryColor,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getSpacing(context)),

          // Name and Description fields (responsive)
          isMobile
              ? Column(
                  children: [
                    AppInputField(
                      controller: _nameController,
                      label: 'Special Day Name',
                      hintText: 'Enter special day name',
                      required: true,
                      readOnly: _isReadOnlyMode,
                      showErrorSpace: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Special day name is required';
                        }
                        if (value.trim().length < 3) {
                          return 'Name must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: ResponsiveHelper.getSpacing(context)),
                    AppInputField(
                      controller: _descriptionController,
                      label: 'Description',
                      hintText: 'Enter description (optional)',
                      readOnly: _isReadOnlyMode,
                      showErrorSpace: true,
                      validator: (value) {
                        return null; // No validation required for description
                      },
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppInputField(
                        controller: _nameController,
                        label: 'Special Day Name',
                        hintText: 'Enter special day name',
                        required: true,
                        readOnly: _isReadOnlyMode,
                        showErrorSpace: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Special day name is required';
                          }
                          if (value.trim().length < 3) {
                            return 'Name must be at least 3 characters';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.getSpacing(context)),
                    Expanded(
                      child: AppInputField(
                        controller: _descriptionController,
                        label: 'Description',
                        hintText: 'Enter description (optional)',
                        readOnly: _isReadOnlyMode,
                        showErrorSpace: true,
                        validator: (value) {
                          return null; // No validation required for description
                        },
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildSpecialDayDetailsSection() {
    final isMobile = ResponsiveHelper.shouldUseCompactUI(context);

    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: context.borderColor.withOpacity(0.1)),
      ),
      padding: EdgeInsets.all(ResponsiveHelper.getSpacing(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Special Day Details',
                style: TextStyle(
                  fontSize: isMobile
                      ? AppSizes.fontSizeMedium
                      : AppSizes.fontSizeLarge,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimaryColor,
                ),
              ),
              if (!_isReadOnlyMode)
                AppButton(
                  text: 'Add Detail',
                  type: AppButtonType.outline,
                  onPressed: _addNewSpecialDayDetail,
                ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getSpacing(context)),

          // Special Day Details List
          ..._buildSpecialDayDetailsList(),
        ],
      ),
    );
  }
}
