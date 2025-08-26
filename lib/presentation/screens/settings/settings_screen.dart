import 'package:flutter/material.dart';
import '../../widgets/common/theme_switch.dart';
import '../../widgets/common/app_card.dart';
import '../../../core/constants/app_sizes.dart';
import '../../themes/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: AppTextStyles.title(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Appearance', style: AppTextStyles.subtitle(context)),
            const SizedBox(height: AppSizes.spacing16),
            const ThemeSwitch(showLabel: true),
            const SizedBox(height: AppSizes.spacing32),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('About', style: AppTextStyles.subtitle(context)),
                  const SizedBox(height: AppSizes.spacing16),
                  Text('MDMS Application', style: AppTextStyles.body(context)),
                  const SizedBox(height: AppSizes.spacing8),
                  Text(
                    'Version 1.0.0',
                    style: AppTextStyles.bodySecondary(context),
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
