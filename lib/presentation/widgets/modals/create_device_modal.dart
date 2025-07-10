import 'package:flutter/material.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_input_field.dart';
import '../../widgets/devices/flutter_map_location_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/device.dart';
import '../../../core/models/address.dart';

class CreateDeviceModal extends StatefulWidget {
  final Device? device;
  final VoidCallback? onSave;

  const CreateDeviceModal({super.key, this.device, this.onSave});

  @override
  State<CreateDeviceModal> createState() => _CreateDeviceModalState();
}

class _CreateDeviceModalState extends State<CreateDeviceModal> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 3;

  // Form controllers
  final TextEditingController _serialNumberController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _manufacturerController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _deviceGroupController = TextEditingController();

  String _selectedDeviceType = 'Smart Meter';
  String _selectedStatus = 'None';
  bool _isActive = true;
  Address? _selectedAddress;

  final List<String> _deviceTypes = [
    'Smart Meter',
    'Gas Meter',
    'Water Meter',
    'Power Monitor',
    'Industrial Meter',
  ];

  final List<String> _statusOptions = [
    'None',
    'Commissioned',
    'Renovation',
    'Construction',
    'Maintenance',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.device != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final device = widget.device!;
    _serialNumberController.text = device.serialNumber;
    _nameController.text = device.name;
    _modelController.text = device.model;
    _manufacturerController.text = device.manufacturer;
    _addressController.text = device.addressText;
    _deviceGroupController.text = device.deviceGroupId.toString();
    _selectedDeviceType = device.deviceType;
    _selectedStatus = device.status;
    _isActive = device.active;
  }

  @override
  void dispose() {
    _serialNumberController.dispose();
    _nameController.dispose();
    _modelController.dispose();
    _manufacturerController.dispose();
    _addressController.dispose();
    _deviceGroupController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _saveDevice() {
    if (_formKey.currentState!.validate()) {
      // Create device object and save
      widget.onSave?.call();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      child: Container(
        width: 900,
        height: 700,
        padding: const EdgeInsets.all(AppSizes.spacing24),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: AppSizes.spacing24),
            _buildProgressIndicator(),
            const SizedBox(height: AppSizes.spacing24),
            Expanded(
              child: Form(
                key: _formKey,
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildBasicInfoStep(),
                    _buildLocationStep(),
                    _buildConfigurationStep(),
                  ],
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          widget.device == null ? 'Add New Device' : 'Edit Device',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surfaceVariant,
            foregroundColor: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(_totalSteps, (index) {
        final isActive = index <= _currentStep;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (index < _totalSteps - 1) const SizedBox(width: 8),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Basic Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.spacing24),

          AppInputField(
            controller: _serialNumberController,
            label: 'Serial Number',
            hintText: 'Enter device serial number',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Serial number is required';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSizes.spacing16),

          AppInputField(
            controller: _nameController,
            label: 'Device Name',
            hintText: 'Enter device name (optional)',
          ),
          const SizedBox(height: AppSizes.spacing16),

          Row(
            children: [
              Expanded(
                child: AppInputField(
                  controller: _modelController,
                  label: 'Model',
                  hintText: 'Enter device model',
                ),
              ),
              const SizedBox(width: AppSizes.spacing16),
              Expanded(
                child: AppInputField(
                  controller: _manufacturerController,
                  label: 'Manufacturer',
                  hintText: 'Enter manufacturer',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing16),

          _buildDropdownField(
            label: 'Device Type',
            value: _selectedDeviceType,
            items: _deviceTypes,
            onChanged: (value) {
              setState(() {
                _selectedDeviceType = value!;
              });
            },
          ),
          const SizedBox(height: AppSizes.spacing16),

          _buildDropdownField(
            label: 'Status',
            value: _selectedStatus,
            items: _statusOptions,
            onChanged: (value) {
              setState(() {
                _selectedStatus = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Location & Address',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.spacing24),

          // Address display or input
          if (_selectedAddress != null)
            Container(
              padding: const EdgeInsets.all(AppSizes.spacing16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: AppSizes.spacing8),
                      const Text(
                        'Selected Address:',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeMedium,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.spacing8),
                  Text(
                    _selectedAddress!.getFormattedAddress(),
                    style: const TextStyle(
                      fontSize: AppSizes.fontSizeMedium,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (_selectedAddress!.latitude != null &&
                      _selectedAddress!.longitude != null) ...[
                    const SizedBox(height: AppSizes.spacing4),
                    Text(
                      'Coordinates: ${_selectedAddress!.latitude!.toStringAsFixed(6)}, ${_selectedAddress!.longitude!.toStringAsFixed(6)}',
                      style: const TextStyle(
                        fontSize: AppSizes.fontSizeSmall,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            )
          else
            AppInputField(
              controller: _addressController,
              label: 'Address',
              hintText: 'Enter device address or select from map',
              maxLines: 3,
            ),

          const SizedBox(height: AppSizes.spacing24),

          // Location picker button
          AppButton(
            text: _selectedAddress != null
                ? 'Change Location'
                : 'Select Location from Map',
            onPressed: _showLocationPicker,
            fullWidth: true,
            type: AppButtonType.secondary,
          ),
        ],
      ),
    );
  }

  void _showLocationPicker() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Select Location',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FlutterMapLocationPicker(
                  initialAddress: _selectedAddress,
                  onLocationChanged: (lat, lng, address) {
                    final newAddress = Address(
                      latitude: lat,
                      longitude: lng,
                      longText: address,
                      shortText: address,
                    );
                    setState(() {
                      _selectedAddress = newAddress;
                      _addressController.text = newAddress
                          .getFormattedAddress();
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfigurationStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configuration',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.spacing24),

          AppInputField(
            controller: _deviceGroupController,
            label: 'Device Group ID',
            hintText: 'Enter device group ID',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSizes.spacing24),

          // Active toggle
          Row(
            children: [
              const Text(
                'Device Status:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: AppSizes.spacing16),
              Switch(
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
                activeColor: AppColors.primary,
              ),
              const SizedBox(width: AppSizes.spacing8),
              Text(
                _isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  color: _isActive
                      ? AppColors.success
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing24),

          // Device channels placeholder
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Device Channels',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.spacing16),
                Container(
                  padding: const EdgeInsets.all(AppSizes.spacing16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.settings_input_component,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: AppSizes.spacing8),
                      Text(
                        'Device channels will be configured after creation',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.spacing8),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            filled: true,
            fillColor: AppColors.surface,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        if (_currentStep > 0)
          AppButton(
            text: 'Previous',
            type: AppButtonType.secondary,
            onPressed: _previousStep,
          ),
        const Spacer(),
        if (_currentStep < _totalSteps - 1)
          AppButton(
            text: 'Next',
            type: AppButtonType.primary,
            onPressed: _nextStep,
          )
        else
          AppButton(
            text: widget.device == null ? 'Create Device' : 'Update Device',
            type: AppButtonType.primary,
            onPressed: _saveDevice,
          ),
      ],
    );
  }
}
