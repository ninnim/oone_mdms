import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/device_group.dart';
import '../../../core/services/device_group_service.dart';
import '../../../core/services/service_locator.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_input_field.dart';
import '../../widgets/common/app_toast.dart';

class CreateEditDeviceGroupDialog extends StatefulWidget {
  final DeviceGroup? deviceGroup;
  final VoidCallback? onSaved;

  const CreateEditDeviceGroupDialog({
    super.key,
    this.deviceGroup,
    this.onSaved,
  });

  @override
  State<CreateEditDeviceGroupDialog> createState() =>
      _CreateEditDeviceGroupDialogState();
}

class _CreateEditDeviceGroupDialogState
    extends State<CreateEditDeviceGroupDialog> {
  final _formKey = GlobalKey<FormState>();
  late DeviceGroupService _deviceGroupService;

  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isActive = true;

  // Loading state
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    // Initialize services using ServiceLocator
    final serviceLocator = ServiceLocator();
    final apiService = serviceLocator.apiService;
    _deviceGroupService = DeviceGroupService(apiService);

    // Pre-fill form if editing
    if (widget.deviceGroup != null) {
      _nameController.text = widget.deviceGroup!.name ?? '';
      _descriptionController.text = widget.deviceGroup!.description ?? '';
      _isActive = widget.deviceGroup!.active ?? true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveDeviceGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final deviceGroup = DeviceGroup(
        id: widget.deviceGroup?.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        active: _isActive,
        devices: widget.deviceGroup?.devices ?? [],
      );

      final response = widget.deviceGroup == null
          ? await _deviceGroupService.createDeviceGroup(deviceGroup)
          : await _deviceGroupService.updateDeviceGroup(deviceGroup);

      if (response.success) {
        if (mounted) {
          AppToast.showSuccess(
            context,
            message: widget.deviceGroup == null
                ? 'Device group created successfully'
                : 'Device group updated successfully',
            title: 'Success',
          );
          Navigator.of(context).pop();
          widget.onSaved?.call();
        }
      } else {
        if (mounted) {
          AppToast.showError(
            context,
            error: response.message ?? 'Failed to save device group',
            title: 'Error',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(
          context,
          error: 'An error occurred: $e',
          title: 'Error',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(AppSizes.spacing24),
                child: Row(
                  children: [
                    Icon(
                      widget.deviceGroup == null ? Icons.add : Icons.edit,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: AppSizes.spacing12),
                    Expanded(
                      child: Text(
                        widget.deviceGroup == null
                            ? 'Create Device Group'
                            : 'Edit Device Group',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Form
              Padding(
                padding: const EdgeInsets.all(AppSizes.spacing24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name field
                      AppInputField(
                        label: 'Device Group Name',
                        controller: _nameController,
                        hintText: 'Enter device group name',
                        required: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Device group name is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppSizes.spacing16),

                      // Description field
                      AppInputField(
                        label: 'Description',
                        controller: _descriptionController,
                        hintText: 'Enter description (optional)',
                        maxLines: 3,
                      ),

                      const SizedBox(height: AppSizes.spacing16),

                      // Active status
                      Row(
                        children: [
                          Text(
                            'Status:',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          const SizedBox(width: AppSizes.spacing12),
                          Switch(
                            value: _isActive,
                            onChanged: (value) =>
                                setState(() => _isActive = value),
                            activeColor: AppColors.success,
                          ),
                          const SizedBox(width: AppSizes.spacing8),
                          Text(
                            _isActive ? 'Active' : 'Inactive',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: _isActive
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 1),

              // Actions
              Padding(
                padding: const EdgeInsets.all(AppSizes.spacing24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton(
                      text: 'Cancel',
                      type: AppButtonType.secondary,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: AppSizes.spacing12),
                    AppButton(
                      text: widget.deviceGroup == null ? 'Create' : 'Update',
                      type: AppButtonType.primary,
                      onPressed: _isSaving ? null : _saveDeviceGroup,
                      isLoading: _isSaving,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
