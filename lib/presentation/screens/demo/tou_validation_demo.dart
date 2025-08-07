import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

/// Demo screen to showcase TOU validation functionality
class TOUValidationDemo extends StatefulWidget {
  const TOUValidationDemo({super.key});

  @override
  State<TOUValidationDemo> createState() => _TOUValidationDemoState();
}

class _TOUValidationDemoState extends State<TOUValidationDemo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        ),
        title: const Text(
          'TOU Validation Demo',
          style: TextStyle(
            fontSize: AppSizes.fontSizeLarge,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(AppSizes.spacing20),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.grid_view_rounded, size: 64, color: AppColors.primary),
              SizedBox(height: AppSizes.spacing16),
              Text(
                'TOU Validation Grid',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeLarge,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: AppSizes.spacing8),
              Text(
                'Advanced time band validation with 24/7 grid visualization',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeMedium,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSizes.spacing24),
              Text(
                'Features:',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeMedium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: AppSizes.spacing12),
              Text(
                '• 24-hour x 7-day grid visualization\n'
                '• Dynamic time band coloring\n'
                '• Conflict and gap detection\n'
                '• Channel filtering\n'
                '• Multiple view modes (Weekly/Monthly/Yearly)\n'
                '• Export capabilities',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeMedium,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
