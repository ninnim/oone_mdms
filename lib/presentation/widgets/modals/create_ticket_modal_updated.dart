import 'package:flutter/material.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_input_field.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_colors.dart';

class CreateTicketModal extends StatefulWidget {
  const CreateTicketModal({super.key});

  @override
  State<CreateTicketModal> createState() => _CreateTicketModalState();
}

class _CreateTicketModalState extends State<CreateTicketModal> {
  late final GlobalKey<FormState> _formKey;
  final _deviceController = TextEditingController();
  final _unitDetailsController = TextEditingController();
  final _contactController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedDevice = 'Azure House';
  String _selectedStatus = 'High';
  String _selectedTicketType = 'For service Technician';
  final List<String> _selectedAvailability = ['Sun', 'Thu', 'Fri'];

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
  }

  @override
  void dispose() {
    _deviceController.dispose();
    _unitDetailsController.dispose();
    _contactController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSizes.spacing16),
      child: Container(
        width: 800,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(colorScheme),
            Expanded(child: _buildForm(colorScheme)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppSizes.radiusMedium),
          topRight: Radius.circular(AppSizes.radiusMedium),
        ),
        border: Border(bottom: BorderSide(color: colorScheme.outline)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.spacing8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
            child: Icon(
              Icons.add_task,
              color: colorScheme.primary,
              size: AppSizes.iconMedium,
            ),
          ),
          const SizedBox(width: AppSizes.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Support Ticket',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeXLarge,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Submit a detailed support request for assistance',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeSmall,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(
                0.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(ColorScheme colorScheme) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Device Information', colorScheme),
            const SizedBox(height: AppSizes.spacing16),
            _buildDeviceDropdown(colorScheme),
            const SizedBox(height: AppSizes.spacing16),
            AppInputField(
              controller: _unitDetailsController,
              label: 'Unit Details',
              hintText: 'Enter unit details...',
              maxLines: 2,
            ),
            const SizedBox(height: AppSizes.spacing24),
            _buildSectionTitle('Priority Level', colorScheme),
            const SizedBox(height: AppSizes.spacing16),
            _buildPrioritySelector(colorScheme),
            const SizedBox(height: AppSizes.spacing24),
            _buildSectionTitle('Ticket Type', colorScheme),
            const SizedBox(height: AppSizes.spacing16),
            _buildTicketTypeSelector(colorScheme),
            const SizedBox(height: AppSizes.spacing24),
            _buildSectionTitle('Contact Information', colorScheme),
            const SizedBox(height: AppSizes.spacing16),
            AppInputField(
              controller: _contactController,
              label: 'Contact Details',
              hintText: 'Phone number or email...',
            ),
            const SizedBox(height: AppSizes.spacing24),
            _buildSectionTitle('Description', colorScheme),
            const SizedBox(height: AppSizes.spacing16),
            AppInputField(
              controller: _descriptionController,
              label: 'Issue Description',
              hintText: 'Provide detailed description of the issue...',
              maxLines: 4,
            ),
            const SizedBox(height: AppSizes.spacing24),
            _buildSectionTitle('Availability', colorScheme),
            const SizedBox(height: AppSizes.spacing16),
            _buildAvailabilitySelector(colorScheme),
            const SizedBox(height: AppSizes.spacing32),
            _buildActions(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme colorScheme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: AppSizes.fontSizeMedium,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
    );
  }

  Widget _buildDeviceDropdown(ColorScheme colorScheme) {
    final devices = ['Azure House', 'Blue Manor', 'Green Villa', 'Red Tower'];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacing12,
        vertical: AppSizes.spacing4,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedDevice,
          isExpanded: true,
          onChanged: (value) {
            setState(() {
              _selectedDevice = value!;
            });
          },
          items: devices.map((device) {
            return DropdownMenuItem<String>(
              value: device,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSizes.spacing8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          device,
                          style: TextStyle(
                            fontSize: AppSizes.fontSizeSmall,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Property Location',
                          style: TextStyle(
                            fontSize: AppSizes.fontSizeExtraSmall,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildPrioritySelector(ColorScheme colorScheme) {
    final priorities = [
      ('High', colorScheme.error),
      ('Medium', AppColors.warning),
      ('Low', colorScheme.outline),
    ];

    return Row(
      children: priorities.map((priority) {
        final isSelected = _selectedStatus == priority.$1;
        final color = priority.$2;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: AppSizes.spacing8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedStatus = priority.$1;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(AppSizes.spacing12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.1)
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? color : colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacing8),
                    Text(
                      priority.$1,
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeSmall,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? color : colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTicketTypeSelector(ColorScheme colorScheme) {
    final types = [
      'For service Technician',
      'For Property Manager',
      'General Inquiry',
    ];

    return Column(
      children: types.map((type) {
        final isSelected = _selectedTicketType == type;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.spacing8),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedTicketType = type;
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.spacing12),
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? colorScheme.primary : colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              ),
              child: Text(
                type,
                style: TextStyle(
                  fontSize: AppSizes.fontSizeSmall,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAvailabilitySelector(ColorScheme colorScheme) {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Wrap(
      spacing: AppSizes.spacing8,
      runSpacing: AppSizes.spacing8,
      children: days.map((day) {
        final isSelected = _selectedAvailability.contains(day);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedAvailability.remove(day);
              } else {
                _selectedAvailability.add(day);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacing16,
              vertical: AppSizes.spacing8,
            ),
            decoration: BoxDecoration(
              color: isSelected ? colorScheme.primary : Colors.transparent,
              border: Border.all(
                color: isSelected ? colorScheme.primary : colorScheme.outline,
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
            child: Text(
              day,
              style: TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActions(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            text: 'Cancel',
            type: AppButtonType.secondary,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        const SizedBox(width: AppSizes.spacing12),
        Expanded(
          child: AppButton(text: 'Create Ticket', onPressed: _submitForm),
        ),
      ],
    );
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      // Process form submission
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Support ticket created successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
