import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/special_day.dart';
import '../common/app_button.dart';
import '../common/app_input_field.dart';
import '../common/app_toast.dart';
import '../common/custom_single_date_picker.dart';

// Helper class to manage Special Day Detail form data
class _SpecialDayDetailItem {
  final int id;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  DateTime? startDate;
  DateTime? endDate;

  _SpecialDayDetailItem({
    required this.id,
    String? name,
    String? description,
    this.startDate,
    this.endDate,
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
      active: true, // Always active since we removed the toggle
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
      'Active': true, // Always active since we removed the toggle
    };
  }
}

class SpecialDayFormDialog extends StatefulWidget {
  final SpecialDay? specialDay; // null for create, non-null for edit
  final Function(SpecialDay) onSave;
  final VoidCallback?
  onSuccess; // Callback to refresh data after successful operation

  const SpecialDayFormDialog({
    super.key,
    this.specialDay,
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

  // Special Day Details Management
  List<_SpecialDayDetailItem> _specialDayDetails = [];
  int _nextDetailId = -1; // Negative IDs for new items

  @override
  void initState() {
    super.initState();
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
      _specialDayDetails[index].dispose();
      _specialDayDetails.removeAt(index);
    });
  }

  bool get _isEditMode => widget.specialDay != null;

  String get _dialogTitle {
    return _isEditMode ? 'Edit Special Day' : 'Add Special Day';
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate Special Day Details
    for (int i = 0; i < _specialDayDetails.length; i++) {
      final detail = _specialDayDetails[i];
      if (detail.nameController.text.trim().isEmpty) {
        AppToast.show(
          context,
          title: 'Validation Error',
          message: 'Detail name is required',
          type: ToastType.error,
        );
        return;
      }
      if (detail.startDate == null || detail.endDate == null) {
        AppToast.show(
          context,
          title: 'Validation Error',
          message: 'Start and End dates are required',
          type: ToastType.error,
        );
        return;
      }
      if (detail.endDate!.isBefore(detail.startDate!)) {
        AppToast.show(
          context,
          title: 'Validation Error',
          message: 'End date cannot be before start date',
          type: ToastType.error,
        );
        return;
      }
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
    if (_specialDayDetails.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(AppSizes.spacing24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Icon(Icons.event_note, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: AppSizes.spacing12),
              Text(
                'No Special Day Details Added',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSizes.spacing8),
              Text(
                'Click "Add Detail" to create special day periods',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ];
    }

    return _specialDayDetails.asMap().entries.map((entry) {
      final index = entry.key;
      final detail = entry.value;
      return _buildSpecialDayDetailCard(detail, index);
    }).toList();
  }

  Widget _buildSpecialDayDetailCard(_SpecialDayDetailItem detail, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spacing16),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.end, // Align to bottom to match field heights
        children: [
          // Name field
          Expanded(
            flex: 2,
            child: AppInputField(
              controller: detail.nameController,
              label: 'Detail Name',
              hintText: 'e.g., Khmer New Year',
              required: true,
            ),
          ),
          const SizedBox(width: AppSizes.spacing12),

          // Description field
          Expanded(
            flex: 2,
            child: AppInputField(
              controller: detail.descriptionController,
              label: 'Description',
              hintText: 'Optional description',
            ),
          ),
          const SizedBox(width: AppSizes.spacing12),

          // Start Date field
          Expanded(
            flex: 1,
            child: CustomSingleDatePicker(
              label: 'Start Date',
              hintText: 'Select start date',
              initialDate: detail.startDate,
              onDateSelected: (date) {
                setState(() {
                  detail.startDate = date;
                  // Auto-set end date if it's before start date
                  if (detail.endDate != null &&
                      detail.endDate!.isBefore(date)) {
                    detail.endDate = date;
                  }
                });
              },
              isRequired: true,
            ),
          ),
          const SizedBox(width: AppSizes.spacing12),

          // End Date field
          Expanded(
            flex: 1,
            child: CustomSingleDatePicker(
              label: 'End Date',
              hintText: 'Select end date',
              initialDate: detail.endDate,
              firstDate: detail
                  .startDate, // This will be null for new records, which should be fine
              onDateSelected: (date) {
                setState(() {
                  detail.endDate = date;
                });
              },
              isRequired: true,
            ),
          ),

          // Delete button (only show if multiple details exist)
          if (_specialDayDetails.length > 1) ...[
            const SizedBox(width: AppSizes.spacing12),
            IconButton(
              onPressed: () => _removeSpecialDayDetail(index),
              icon: const Icon(Icons.delete_outline),
              style: IconButton.styleFrom(
                foregroundColor: AppColors.error,
                backgroundColor: AppColors.surfaceVariant,
              ),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.95,
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
                      // Special Day Information Section
                      Text(
                        'Special Day Information',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacing16),

                      // Special Day Information - Single Row Layout (Name + Description)
                      Row(
                        children: [
                          Expanded(
                            child: AppInputField(
                              controller: _nameController,
                              label: 'Special Day Name',
                              hintText: 'Enter special day name',
                              required: true,
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

                      const SizedBox(height: AppSizes.spacing32),

                      // Special Day Details Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Special Day Details',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                          ),
                          AppButton(
                            text: 'Add Detail',
                            type: AppButtonType.outline,
                            onPressed: _addNewSpecialDayDetail,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.spacing16),

                      // Special Day Details List
                      ..._buildSpecialDayDetailsList(),
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
