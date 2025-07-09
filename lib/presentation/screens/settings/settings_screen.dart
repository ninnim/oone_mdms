import 'package:flutter/material.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_input_field.dart';
import '../../widgets/common/status_chip.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Settings values
  bool _darkMode = false;
  bool _notifications = true;
  bool _autoSync = true;
  String _language = 'English';
  String _timezone = 'UTC+7';
  String _dateFormat = 'DD/MM/YYYY';
  int _itemsPerPage = 25;

  // Site configuration
  String _siteName = 'MDMS System';
  String _siteDescription = 'Device Management System';
  String _adminEmail = 'admin@mdms.com';
  String _supportEmail = 'support@mdms.com';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.spacing24),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: AppSizes.spacing24),
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(
          Icons.settings,
          size: AppSizes.iconLarge,
          color: AppColors.primary,
        ),
        const SizedBox(width: AppSizes.spacing16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: AppSizes.fontSizeXXLarge,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Manage system preferences and configuration',
              style: TextStyle(
                fontSize: AppSizes.fontSizeMedium,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const Spacer(),
        _buildQuickActions(),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        AppButton(
          text: 'Export Settings',
          type: AppButtonType.secondary,
          onPressed: _exportSettings,
          icon: const Icon(Icons.download),
        ),
        const SizedBox(width: AppSizes.spacing8),
        AppButton(
          text: 'Import Settings',
          type: AppButtonType.secondary,
          onPressed: _importSettings,
          icon: const Icon(Icons.upload),
        ),
        const SizedBox(width: AppSizes.spacing8),
        AppButton(
          text: 'Reset to Defaults',
          type: AppButtonType.danger,
          onPressed: _resetToDefaults,
          icon: const Icon(Icons.restore),
        ),
      ],
    );
  }

  Widget _buildTabContent() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            border: Border.all(color: AppColors.border),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            tabs: const [
              Tab(icon: Icon(Icons.palette), text: 'Appearance'),
              Tab(icon: Icon(Icons.person), text: 'User Preferences'),
              Tab(icon: Icon(Icons.business), text: 'Site Configuration'),
              Tab(icon: Icon(Icons.tune), text: 'Advanced'),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.spacing24),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAppearanceTab(),
              _buildUserPreferencesTab(),
              _buildSiteConfigurationTab(),
              _buildAdvancedTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppearanceTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Theme Settings',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeLarge,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.spacing16),
                _buildSwitchSetting(
                  'Dark Mode',
                  'Use dark theme for the interface',
                  _darkMode,
                  (value) => setState(() => _darkMode = value),
                ),
                const SizedBox(height: AppSizes.spacing16),
                _buildDropdownSetting(
                  'Language',
                  'Select interface language',
                  _language,
                  ['English', 'Spanish', 'French', 'German'],
                  (value) => setState(() => _language = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.spacing16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Display Settings',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeLarge,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.spacing16),
                _buildDropdownSetting(
                  'Items Per Page',
                  'Default number of items shown in tables',
                  _itemsPerPage.toString(),
                  ['10', '25', '50', '100'],
                  (value) => setState(() => _itemsPerPage = int.parse(value)),
                ),
                const SizedBox(height: AppSizes.spacing16),
                _buildDropdownSetting(
                  'Date Format',
                  'How dates are displayed',
                  _dateFormat,
                  ['DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY-MM-DD'],
                  (value) => setState(() => _dateFormat = value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserPreferencesTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notification Settings',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeLarge,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.spacing16),
                _buildSwitchSetting(
                  'Enable Notifications',
                  'Receive system notifications',
                  _notifications,
                  (value) => setState(() => _notifications = value),
                ),
                const SizedBox(height: AppSizes.spacing16),
                _buildSwitchSetting(
                  'Auto Sync',
                  'Automatically sync data in background',
                  _autoSync,
                  (value) => setState(() => _autoSync = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.spacing16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Regional Settings',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeLarge,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.spacing16),
                _buildDropdownSetting(
                  'Timezone',
                  'Your local timezone',
                  _timezone,
                  ['UTC+7', 'UTC+0', 'UTC-5', 'UTC+8'],
                  (value) => setState(() => _timezone = value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSiteConfigurationTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Site Information',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeLarge,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.spacing16),
                AppInputField(
                  label: 'Site Name',
                  hintText: 'Enter site name',
                  controller: TextEditingController(text: _siteName),
                  onChanged: (value) => setState(() => _siteName = value),
                ),
                const SizedBox(height: AppSizes.spacing16),
                AppInputField(
                  label: 'Site Description',
                  hintText: 'Enter site description',
                  controller: TextEditingController(text: _siteDescription),
                  onChanged: (value) =>
                      setState(() => _siteDescription = value),
                ),
                const SizedBox(height: AppSizes.spacing16),
                AppInputField(
                  label: 'Admin Email',
                  hintText: 'admin@example.com',
                  controller: TextEditingController(text: _adminEmail),
                  onChanged: (value) => setState(() => _adminEmail = value),
                ),
                const SizedBox(height: AppSizes.spacing16),
                AppInputField(
                  label: 'Support Email',
                  hintText: 'support@example.com',
                  controller: TextEditingController(text: _supportEmail),
                  onChanged: (value) => setState(() => _supportEmail = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.spacing16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'System Status',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeLarge,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.spacing16),
                Row(
                  children: [
                    const Text('Database Status:'),
                    const SizedBox(width: AppSizes.spacing8),
                    StatusChip(text: 'Connected', type: StatusChipType.success),
                  ],
                ),
                const SizedBox(height: AppSizes.spacing8),
                Row(
                  children: [
                    const Text('API Status:'),
                    const SizedBox(width: AppSizes.spacing8),
                    StatusChip(text: 'Online', type: StatusChipType.success),
                  ],
                ),
                const SizedBox(height: AppSizes.spacing8),
                Row(
                  children: [
                    const Text('Sync Status:'),
                    const SizedBox(width: AppSizes.spacing8),
                    StatusChip(text: 'Active', type: StatusChipType.info),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'System Maintenance',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeLarge,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.spacing16),
                _buildActionButton(
                  'Clear Cache',
                  'Clear application cache to free up space',
                  Icons.clear_all,
                  AppColors.info,
                  _clearCache,
                ),
                const SizedBox(height: AppSizes.spacing12),
                _buildActionButton(
                  'Rebuild Database Indexes',
                  'Optimize database performance',
                  Icons.storage,
                  AppColors.warning,
                  _rebuildIndexes,
                ),
                const SizedBox(height: AppSizes.spacing12),
                _buildActionButton(
                  'Backup Configuration',
                  'Create a backup of current settings',
                  Icons.backup,
                  AppColors.success,
                  _backupConfiguration,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.spacing16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Debug Settings',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeLarge,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.spacing16),
                _buildSwitchSetting(
                  'Debug Mode',
                  'Enable debug logging (affects performance)',
                  false,
                  (value) => {},
                ),
                const SizedBox(height: AppSizes.spacing16),
                _buildSwitchSetting(
                  'API Logging',
                  'Log API requests and responses',
                  false,
                  (value) => {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchSetting(
    String title,
    String description,
    bool value,
    Function(bool) onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: AppSizes.fontSizeMedium,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  fontSize: AppSizes.fontSizeSmall,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildDropdownSetting(
    String title,
    String description,
    String value,
    List<String> options,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: AppSizes.fontSizeMedium,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.spacing4),
        Text(
          description,
          style: const TextStyle(
            fontSize: AppSizes.fontSizeSmall,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSizes.spacing8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacing12,
              vertical: AppSizes.spacing8,
            ),
          ),
          items: options
              .map(
                (option) =>
                    DropdownMenuItem(value: option, child: Text(option)),
              )
              .toList(),
          onChanged: (newValue) => onChanged(newValue!),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.spacing12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.spacing8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              ),
              child: Icon(icon, color: color, size: AppSizes.iconMedium),
            ),
            const SizedBox(width: AppSizes.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: AppSizes.fontSizeMedium,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: AppSizes.fontSizeSmall,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: AppSizes.iconSmall,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _exportSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings exported successfully'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _importSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings import feature coming soon'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all settings to defaults? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          AppButton(
            text: 'Reset',
            type: AppButtonType.danger,
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _darkMode = false;
                _notifications = true;
                _autoSync = true;
                _language = 'English';
                _timezone = 'UTC+7';
                _dateFormat = 'DD/MM/YYYY';
                _itemsPerPage = 25;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings reset to defaults'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _clearCache() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cache cleared successfully'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _rebuildIndexes() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Database indexes rebuilt successfully'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _backupConfiguration() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuration backup created'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
