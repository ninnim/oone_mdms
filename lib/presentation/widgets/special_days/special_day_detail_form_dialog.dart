import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/special_day.dart';
import '../common/app_button.dart';
import '../common/app_input_field.dart';
import '../common/app_toast.dart';
import '../common/custom_single_date_picker.dart';
import '../common/app_dropdown_field.dart';

class SpecialDayDetailFormDialog extends StatefulWidget {
  final SpecialDayDetail?
  specialDayDetail; // null for create, non-null for edit
  final List<SpecialDay> availableParentSpecialDays;
  final Function(SpecialDayDetail) onSave;
  final int? preferredParentId; // Auto-select this parent if provided
  final VoidCallback?
  onSuccess; // Callback to refresh data after successful operation

  const SpecialDayDetailFormDialog({
    super.key,
    this.specialDayDetail,
    required this.availableParentSpecialDays,
    required this.onSave,
    this.preferredParentId,
    this.onSuccess,
  });

  @override
  State<SpecialDayDetailFormDialog> createState() =>
      _SpecialDayDetailFormDialogState();
}

class _SpecialDayDetailFormDialogState
    extends State<SpecialDayDetailFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _selectedParentId = 0;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    if (widget.specialDayDetail != null) {
      // Edit mode
      final detail = widget.specialDayDetail!;
      _nameController.text = detail.name;
      _descriptionController.text = detail.description;
      _selectedParentId = detail.specialDayId;
      _startDate = detail.startDate;
      _endDate = detail.endDate;
    } else {
      // Create mode - use preferred parent if provided,
      // otherwise auto-select first available parent if there's only one
      if (widget.preferredParentId != null) {
        _selectedParentId = widget.preferredParentId!;
      } else if (widget.availableParentSpecialDays.length == 1) {
        _selectedParentId = widget.availableParentSpecialDays.first.id;
      }
    }

    // Ensure the selected parent ID is valid (exists in available options)
    final validParentIds = widget.availableParentSpecialDays
        .map((s) => s.id)
        .toSet();
    if (_selectedParentId == 0 || !validParentIds.contains(_selectedParentId)) {
      if (widget.availableParentSpecialDays.isNotEmpty) {
        _selectedParentId = widget.availableParentSpecialDays.first.id;
      }
    }
  }

  bool get _isEditMode => widget.specialDayDetail != null;

  String get _dialogTitle {
    return _isEditMode ? 'Edit Special Day Detail' : 'Add Special Day Detail';
  }

  List<DropdownMenuItem<int>> get _parentSpecialDayOptions {
    return widget.availableParentSpecialDays.map((specialDay) {
      return DropdownMenuItem<int>(
        value: specialDay.id,
        child: Text(specialDay.name),
      );
    }).toList();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final detail = SpecialDayDetail(
        id: widget.specialDayDetail?.id ?? 0,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        active: true, // Always set to active
        specialDayId: _selectedParentId,
        startDate: _startDate,
        endDate: _endDate,
      );

      await widget.onSave(detail);

      if (mounted) {
        Navigator.of(context).pop();
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          title: 'Error',
          message: 'Failed to save special day detail: $e',
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    _dialogTitle,
                    style: const TextStyle(
                      fontSize: AppSizes.fontSizeLarge,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _handleCancel,
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.textSecondary,
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
                      // Row 1: Name, Parent Special Day, Description
                      Row(
                        children: [
                          Expanded(
                            child: AppInputField(
                              controller: _nameController,
                              label: 'Detail Name',
                              hintText: 'Enter detail name',
                              required: true,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Detail name is required';
                                }
                                if (value.trim().length < 3) {
                                  return 'Name must be at least 3 characters';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: AppSizes.spacing16),
                          Expanded(
                            child: AppSearchableDropdown<int>(
                              label: 'Parent Special Day',
                              hintText: 'Select Parent Special Day',
                              value: _selectedParentId,
                              items: _parentSpecialDayOptions,
                              onChanged: (value) {
                                setState(() {
                                  _selectedParentId = value ?? 0;
                                });
                              },
                              height: AppSizes.inputHeight,
                              validator: (value) {
                                if (value == null || value == 0) {
                                  return 'Please select a parent special day';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: AppSizes.spacing16),
                          Expanded(
                            child: AppInputField(
                              controller: _descriptionController,
                              label: 'Description',
                              hintText: 'Enter description (optional)',
                              validator: (value) {
                                return null; // No validation required for description
                              },
                            ),
                          ),
                        ],
                      ),

                      // Helper text for pre-selected parent
                      if (widget.preferredParentId != null &&
                          widget.preferredParentId != 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _isEditMode
                                ? 'Editing detail. Current parent special day is pre-selected.'
                                : 'Creating detail under the current special day.',
                            style: const TextStyle(
                              fontSize: AppSizes.fontSizeSmall,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      else if (widget.availableParentSpecialDays.length == 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Creating detail under: ${widget.availableParentSpecialDays.first.name}',
                            style: const TextStyle(
                              fontSize: AppSizes.fontSizeSmall,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),

                      const SizedBox(height: AppSizes.spacing24),

                      // Row 2: Start Date and End Date
                      Row(
                        children: [
                          Expanded(
                            child: CustomSingleDatePicker(
                              label: 'Start Date',
                              initialDate: _startDate,

                              hintText: 'Select start date',
                              onDateSelected: (DateTime date) {
                                setState(() {
                                  _startDate = date;
                                  // Ensure end date is after start date
                                  if (_endDate.isBefore(date)) {
                                    _endDate = date.add(
                                      const Duration(days: 1),
                                    );
                                  }
                                });
                              },
                              lastDate: _endDate.subtract(
                                const Duration(days: 1),
                              ),
                              isRequired: true,
                            ),
                          ),
                          const SizedBox(width: AppSizes.spacing16),
                          Expanded(
                            child: CustomSingleDatePicker(
                              label: 'End Date',
                              initialDate: _endDate,
                              hintText: 'Select end date',
                              onDateSelected: (DateTime date) {
                                setState(() {
                                  _endDate = date;
                                });
                              },
                              firstDate: _startDate.add(
                                const Duration(days: 1),
                              ),
                              isRequired: true,
                            ),
                          ),
                        ],
                      ),
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
                    onPressed: _isSaving ? null : _handleCancel,
                  ),
                  const SizedBox(width: AppSizes.spacing12),
                  AppButton(
                    text: _isEditMode ? 'Update' : 'Create',
                    type: AppButtonType.primary,
                    onPressed: _isSaving ? null : _handleSave,
                    isLoading: _isSaving,
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
