import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTimeRange = '7 days';

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
    return Padding(
      padding: const EdgeInsets.all(AppSizes.spacing24),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: AppSizes.spacing24),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(
          Icons.analytics,
          size: AppSizes.iconLarge,
          color: AppColors.primary,
        ),
        const SizedBox(width: AppSizes.spacing16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analytics Dashboard',
              style: TextStyle(
                fontSize: AppSizes.fontSizeXXLarge,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'System performance and device metrics',
              style: TextStyle(
                fontSize: AppSizes.fontSizeMedium,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const Spacer(),
        _buildTimeRangeSelector(),
        const SizedBox(width: AppSizes.spacing16),
        AppButton(
          text: 'Export Report',
          type: AppButtonType.secondary,
          onPressed: _exportReport,
          icon: const Icon(Icons.download),
        ),
      ],
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTimeRange,
          items: ['24 hours', '7 days', '30 days', '90 days', '1 year']
              .map(
                (range) => DropdownMenuItem(value: range, child: Text(range)),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedTimeRange = value!),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildKPICards(),
        const SizedBox(height: AppSizes.spacing24),
        Expanded(child: _buildTabContent()),
      ],
    );
  }

  Widget _buildKPICards() {
    return Row(
      children: [
        Expanded(
          child: _buildKPICard(
            'Total Devices',
            '1,247',
            Icons.devices,
            AppColors.primary,
            '+12%',
          ),
        ),
        const SizedBox(width: AppSizes.spacing16),
        Expanded(
          child: _buildKPICard(
            'Active Devices',
            '1,156',
            Icons.check_circle,
            AppColors.success,
            '+8%',
          ),
        ),
        const SizedBox(width: AppSizes.spacing16),
        Expanded(
          child: _buildKPICard(
            'Offline Devices',
            '91',
            Icons.error,
            AppColors.error,
            '-5%',
          ),
        ),
        const SizedBox(width: AppSizes.spacing16),
        Expanded(
          child: _buildKPICard(
            'Data Points',
            '487K',
            Icons.analytics,
            AppColors.info,
            '+23%',
          ),
        ),
      ],
    );
  }

  Widget _buildKPICard(
    String title,
    String value,
    IconData icon,
    Color color,
    String change,
  ) {
    final isPositive = change.startsWith('+');
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.spacing8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
                child: Icon(icon, color: color, size: AppSizes.iconMedium),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacing6,
                  vertical: AppSizes.spacing2,
                ),
                decoration: BoxDecoration(
                  color: (isPositive ? AppColors.success : AppColors.error)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    color: isPositive ? AppColors.success : AppColors.error,
                    fontSize: AppSizes.fontSizeSmall,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing12),
          Text(
            value,
            style: const TextStyle(
              fontSize: AppSizes.fontSizeXLarge,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
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
              Tab(icon: Icon(Icons.timeline), text: 'Device Status'),
              Tab(icon: Icon(Icons.bar_chart), text: 'Performance'),
              Tab(icon: Icon(Icons.location_on), text: 'Geographic'),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.spacing24),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildDeviceStatusTab(),
              _buildPerformanceTab(),
              _buildGeographicTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceStatusTab() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Device Status Over Time',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeLarge,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.spacing24),
                Expanded(child: _buildDeviceStatusChart()),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSizes.spacing16),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status Distribution',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeLarge,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacing16),
                      Expanded(child: _buildStatusPieChart()),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.spacing16),
              Expanded(
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Device Types',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeLarge,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacing16),
                      _buildDeviceTypesList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceTab() {
    return Row(
      children: [
        Expanded(
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Data Throughput',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeLarge,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.spacing24),
                Expanded(child: _buildThroughputChart()),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSizes.spacing16),
        Expanded(
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Response Times',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeLarge,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.spacing24),
                Expanded(child: _buildResponseTimeChart()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGeographicTab() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Geographic Distribution',
            style: TextStyle(
              fontSize: AppSizes.fontSizeLarge,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.spacing16),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 64, color: AppColors.textTertiary),
                  const SizedBox(height: AppSizes.spacing16),
                  const Text(
                    'Geographic Map View',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeLarge,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacing8),
                  const Text(
                    'Interactive map showing device distribution across regions',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeMedium,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.spacing24),
                  AppButton(text: 'View Full Map', onPressed: () {}),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceStatusChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 30),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: [
              const FlSpot(0, 1000),
              const FlSpot(1, 1050),
              const FlSpot(2, 1100),
              const FlSpot(3, 1080),
              const FlSpot(4, 1150),
              const FlSpot(5, 1200),
              const FlSpot(6, 1247),
            ],
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            dotData: FlDotData(show: true),
          ),
          LineChartBarData(
            spots: [
              const FlSpot(0, 950),
              const FlSpot(1, 980),
              const FlSpot(2, 1020),
              const FlSpot(3, 1000),
              const FlSpot(4, 1080),
              const FlSpot(5, 1120),
              const FlSpot(6, 1156),
            ],
            isCurved: true,
            color: AppColors.success,
            barWidth: 3,
            dotData: FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPieChart() {
    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            value: 92.7,
            color: AppColors.success,
            title: '92.7%',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              fontWeight: FontWeight.bold,
              color: AppColors.textInverse,
            ),
          ),
          PieChartSectionData(
            value: 7.3,
            color: AppColors.error,
            title: '7.3%',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: AppSizes.fontSizeSmall,
              fontWeight: FontWeight.bold,
              color: AppColors.textInverse,
            ),
          ),
        ],
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }

  Widget _buildDeviceTypesList() {
    final deviceTypes = [
      {'name': 'Smart Meters', 'count': 856, 'color': AppColors.primary},
      {'name': 'ToI Devices', 'count': 234, 'color': AppColors.info},
      {'name': 'Sensors', 'count': 157, 'color': AppColors.warning},
    ];

    return Expanded(
      child: ListView.builder(
        itemCount: deviceTypes.length,
        itemBuilder: (context, index) {
          final type = deviceTypes[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.spacing8),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: type['color'] as Color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSizes.spacing8),
                Expanded(
                  child: Text(
                    type['name'] as String,
                    style: const TextStyle(
                      fontSize: AppSizes.fontSizeSmall,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${type['count']}',
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeSmall,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildThroughputChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [BarChartRodData(toY: 8, color: AppColors.primary)],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [BarChartRodData(toY: 10, color: AppColors.primary)],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [BarChartRodData(toY: 14, color: AppColors.primary)],
          ),
          BarChartGroupData(
            x: 3,
            barRods: [BarChartRodData(toY: 15, color: AppColors.primary)],
          ),
          BarChartGroupData(
            x: 4,
            barRods: [BarChartRodData(toY: 13, color: AppColors.primary)],
          ),
          BarChartGroupData(
            x: 5,
            barRods: [BarChartRodData(toY: 17, color: AppColors.primary)],
          ),
          BarChartGroupData(
            x: 6,
            barRods: [BarChartRodData(toY: 20, color: AppColors.primary)],
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 30),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
      ),
    );
  }

  Widget _buildResponseTimeChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 30),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: [
              const FlSpot(0, 120),
              const FlSpot(1, 110),
              const FlSpot(2, 95),
              const FlSpot(3, 85),
              const FlSpot(4, 100),
              const FlSpot(5, 90),
              const FlSpot(6, 80),
            ],
            isCurved: true,
            color: AppColors.warning,
            barWidth: 3,
            dotData: FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Analytics report exported successfully'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
