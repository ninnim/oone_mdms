import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/site.dart';
import '../common/app_button.dart';
import '../common/app_input_field.dart';
import '../common/app_toast.dart';
import '../common/app_dropdown_field.dart';

class SiteFormDialog extends StatefulWidget {
  final Site? site; // null for create, non-null for edit
  final List<Site> availableParentSites;
  final Function(Site) onSave;
  final int? preferredParentId; // Auto-select this parent if provided
  final VoidCallback?
  onSuccess; // Callback to refresh data after successful operation

  const SiteFormDialog({
    super.key,
    this.site,
    required this.availableParentSites,
    required this.onSave,
    this.preferredParentId,
    this.onSuccess,
  });

  @override
  State<SiteFormDialog> createState() => _SiteFormDialogState();
}

class _SiteFormDialogState extends State<SiteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _selectedParentId = 0; // 0 means main site
  bool _isActive = true;
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
    if (widget.site != null) {
      // Edit mode
      final site = widget.site!;
      _nameController.text = site.name;
      _descriptionController.text = site.description;
      _isActive = site.active;

      // For editing subsites: prefer the preferredParentId if provided,
      // otherwise use the site's current parentId
      if (widget.preferredParentId != null) {
        _selectedParentId = widget.preferredParentId!;
      } else {
        _selectedParentId = site.parentId;
      }
    } else {
      // Create mode - use preferred parent if provided,
      // otherwise auto-select first available parent site if there's only one
      if (widget.preferredParentId != null) {
        _selectedParentId = widget.preferredParentId!;
      } else if (widget.availableParentSites.length == 1) {
        _selectedParentId = widget.availableParentSites.first.id!;
      }
    }

    // Ensure the selected parent ID is valid (exists in available options)
    final validParentIds = {
      0,
      ...widget.availableParentSites.map((s) => s.id!).toSet(),
    };
    if (!validParentIds.contains(_selectedParentId)) {
      _selectedParentId = 0; // Default to "Main Site (No Parent)"
    }
  }

  bool get _isEditMode => widget.site != null;

  String get _dialogTitle {
    if (_isEditMode) {
      return widget.site!.isMainSite ? 'Edit Site' : 'Edit Sub Site';
    } else {
      // Check if we're creating a subsite (only one parent site available)
      return widget.availableParentSites.length == 1
          ? 'Add Sub Site'
          : 'Add Site';
    }
  }

  List<DropdownMenuItem<int>> get _parentSiteOptions {
    final items = <DropdownMenuItem<int>>[
      const DropdownMenuItem(value: 0, child: Text('Main Site (No Parent)')),
    ];

    // Add available parent sites (should be main sites only)
    for (final site in widget.availableParentSites) {
      // Don't add the site itself as an option (prevent circular reference)
      if (site.id != widget.site?.id) {
        items.add(
          DropdownMenuItem(
            value: site.id!,
            child: Text('${site.name}${site.isMainSite ? ' (Main Site)' : ''}'),
          ),
        );
      }
    }

    return items;
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
            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.spacing16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Site Information - Single Row Layout
                      Row(
                        children: [
                          Expanded(
                            child: AppInputField(
                              controller: _nameController,
                              label: 'Site Name',
                              hintText: 'Enter site name',
                              required: true,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Site name is required';
                                }
                                if (value.trim().length < 3) {
                                  return 'Site name must be at least 3 characters';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: AppSizes.spacing16),
                          Expanded(
                            child: AppSearchableDropdown<int>(
                              label: 'Parent Site',
                              hintText: 'Select Parent Site',
                              value: _selectedParentId,
                              items: _parentSiteOptions,
                              onChanged: (value) {
                                setState(() {
                                  _selectedParentId = value ?? 0;
                                });
                              },
                              height: AppSizes.inputHeight,
                              validator: (value) {
                                return null; // No validation required for parent site
                              },
                            ),
                          ),
                        ],
                      ),

                      // Helper text for subsite creation/editing
                      if (widget.preferredParentId != null &&
                          widget.preferredParentId != 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _isEditMode
                                ? 'Editing subsite. Current main site is pre-selected.'
                                : 'Creating subsite under the current main site.',
                            style: const TextStyle(
                              fontSize: AppSizes.fontSizeSmall,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      else if (widget.availableParentSites.length == 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Creating subsite under: ${widget.availableParentSites.first.name}',
                            style: const TextStyle(
                              fontSize: AppSizes.fontSizeSmall,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),

                      const SizedBox(height: AppSizes.spacing16),

                      // Description Field
                      AppInputField(
                        controller: _descriptionController,
                        label: 'Description',
                        hintText: 'Enter site description (optional)',
                        maxLines: 3,
                      ),
                      const SizedBox(height: AppSizes.spacing16),

                      // Status Toggle
                      Row(
                        children: [
                          Switch(
                            value: _isActive,
                            onChanged: (value) {
                              setState(() {
                                _isActive = value;
                              });
                            },
                            activeColor: AppColors.success,
                          ),
                          const SizedBox(width: AppSizes.spacing8),
                          Text(
                            'Active Site',
                            style: TextStyle(
                              fontSize: AppSizes.fontSizeMedium,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
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
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                    type: AppButtonType.outline,
                  ),
                  const SizedBox(width: AppSizes.spacing12),
                  AppButton(
                    text: _isEditMode ? 'Update Site' : 'Create Site',
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

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final site = Site(
        id: widget.site?.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        parentId: _selectedParentId,
        active: _isActive,
      );

      await widget.onSave(site);

      if (mounted) {
        Navigator.of(context).pop();

        // Show success toast
        AppToast.show(
          context,
          title: 'Success',
          message: _isEditMode
              ? 'Site updated successfully'
              : 'Site created successfully',
          type: ToastType.success,
        );

        // Trigger API refresh callback if provided
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          title: 'Error',
          message: 'Failed to ${_isEditMode ? 'update' : 'create'} site: $e',
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
}
