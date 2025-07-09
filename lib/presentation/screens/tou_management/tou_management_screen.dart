import 'package:flutter/material.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import 'time_bands_screen.dart';
import 'seasons_screen.dart';
import 'special_days_screen.dart';

class TouManagementScreen extends StatefulWidget {
  const TouManagementScreen({super.key});

  @override
  State<TouManagementScreen> createState() => _TouManagementScreenState();
}

class _TouManagementScreenState extends State<TouManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header section
        Container(
          padding: const EdgeInsets.all(AppSizes.spacing24),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Time of Use Management',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacing4),
                    Text(
                      'Manage time bands, seasons, and special days for tariff configuration',
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Quick stats cards
              _buildQuickStats(),
            ],
          ),
        ),

        // Tab navigation
        Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            tabs: const [
              Tab(icon: Icon(Icons.schedule), text: 'Time Bands'),
              Tab(icon: Icon(Icons.wb_sunny), text: 'Seasons'),
              Tab(icon: Icon(Icons.event_note), text: 'Special Days'),
            ],
          ),
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              TimeBandsScreen(),
              SeasonsScreen(),
              SpecialDaysScreen(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        _buildStatCard(
          title: 'Time Bands',
          value: '12',
          icon: Icons.schedule,
          color: AppColors.primary,
          onTap: () => _tabController.animateTo(0),
        ),
        const SizedBox(width: AppSizes.spacing12),
        _buildStatCard(
          title: 'Seasons',
          value: '4',
          icon: Icons.wb_sunny,
          color: AppColors.warning,
          onTap: () => _tabController.animateTo(1),
        ),
        const SizedBox(width: AppSizes.spacing12),
        _buildStatCard(
          title: 'Special Days',
          value: '8',
          icon: Icons.event_note,
          color: AppColors.info,
          onTap: () => _tabController.animateTo(2),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(AppSizes.spacing16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: AppSizes.iconMedium),
            const SizedBox(height: AppSizes.spacing8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: AppSizes.spacing4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
