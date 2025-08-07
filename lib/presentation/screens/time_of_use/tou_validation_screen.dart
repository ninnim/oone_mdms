import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/time_of_use.dart';
import '../../../core/models/time_band.dart';
import '../../../core/services/time_of_use_service.dart';
import '../../../core/services/time_band_service.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_lottie_state_widget.dart';
import '../../widgets/common/status_chip.dart';
import '../../widgets/time_of_use/tou_validation_grid.dart';

class TOUValidationScreen extends StatefulWidget {
  final int? timeOfUseId;

  const TOUValidationScreen({super.key, this.timeOfUseId});

  @override
  State<TOUValidationScreen> createState() => _TOUValidationScreenState();
}

class _TOUValidationScreenState extends State<TOUValidationScreen>
    with TickerProviderStateMixin {
  late final TimeOfUseService _timeOfUseService;
  late final TimeBandService _timeBandService;
  late final TabController _tabController;

  // Data state
  bool _isLoading = true;
  TimeOfUse? _timeOfUse;
  List<TimeBand> _availableTimeBands = [];
  List<Channel> _availableChannels = [];
  String _errorMessage = '';

  // Validation state
  TOUValidationViewMode _currentViewMode = TOUValidationViewMode.weekly;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timeOfUseService = Provider.of<TimeOfUseService>(context, listen: false);
    _timeBandService = Provider.of<TimeBandService>(context, listen: false);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load time bands and channels
      await Future.wait([_loadTimeBands(), _loadTimeOfUse()]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTimeBands() async {
    try {
      final response = await _timeBandService.getTimeBands(limit: 100);
      if (response.success && response.data != null) {
        setState(() {
          _availableTimeBands = response.data!;
        });
      }
    } catch (e) {
      print('Warning: Failed to load time bands: $e');
    }
  }

  Future<void> _loadTimeOfUse() async {
    if (widget.timeOfUseId == null) return;

    try {
      final response = await _timeOfUseService.getTimeOfUseById(
        widget.timeOfUseId!,
      );
      if (response.success && response.data != null) {
        setState(() {
          _timeOfUse = response.data!;
          _availableChannels = _timeOfUse!.timeOfUseDetails
              .where((detail) => detail.channel != null)
              .map((detail) => detail.channel!)
              .toSet()
              .toList();
        });
      }
    } catch (e) {
      print('Warning: Failed to load time of use: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOU Validation',
            style: TextStyle(
              fontSize: AppSizes.fontSizeLarge,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (_timeOfUse != null)
            Text(
              _timeOfUse!.name,
              style: const TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.normal,
              ),
            ),
        ],
      ),
      actions: [
        if (_timeOfUse != null)
          StatusChip(
            text: _timeOfUse!.active ? 'Active' : 'Inactive',
            type: _timeOfUse!.active
                ? StatusChipType.success
                : StatusChipType.secondary,
          ),
        const SizedBox(width: AppSizes.spacing16),
        AppButton(
          text: 'Refresh',
          type: AppButtonType.text,
          icon: const Icon(Icons.refresh, size: 16),
          onPressed: _loadData,
        ),
        const SizedBox(width: AppSizes.spacing8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const AppLottieStateWidget.loading(
        message: 'Loading TOU validation data...',
      );
    }

    if (_errorMessage.isNotEmpty) {
      return AppLottieStateWidget.error(
        message: _errorMessage,
        onButtonPressed: _loadData,
      );
    }

    if (_timeOfUse == null) {
      return const AppLottieStateWidget.noData(
        message: 'No TOU configuration found',
      );
    }

    return Column(
      children: [
        _buildStatsHeader(),
        _buildTabBar(),
        Expanded(child: _buildTabContent()),
      ],
    );
  }

  Widget _buildStatsHeader() {
    final totalDetails = _timeOfUse?.timeOfUseDetails.length ?? 0;
    final activeDetails =
        _timeOfUse?.timeOfUseDetails.where((detail) => detail.active).length ??
        0;
    final uniqueChannels = _availableChannels.length;
    final uniqueTimeBands =
        _timeOfUse?.timeOfUseDetails
            .map((detail) => detail.timeBandId)
            .toSet()
            .length ??
        0;

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing20),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Details',
              totalDetails.toString(),
              Icons.list_alt_rounded,
              AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSizes.spacing12),
          Expanded(
            child: _buildStatCard(
              'Active Details',
              activeDetails.toString(),
              Icons.check_circle_outline,
              AppColors.success,
            ),
          ),
          const SizedBox(width: AppSizes.spacing12),
          Expanded(
            child: _buildStatCard(
              'Channels',
              uniqueChannels.toString(),
              Icons.account_tree_outlined,
              AppColors.info,
            ),
          ),
          const SizedBox(width: AppSizes.spacing12),
          Expanded(
            child: _buildStatCard(
              'Time Bands',
              uniqueTimeBands.toString(),
              Icons.access_time_rounded,
              AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.spacing8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSizes.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeLarge,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeSmall,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: AppSizes.fontSizeMedium,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: AppSizes.fontSizeMedium,
        ),
        tabs: const [
          Tab(icon: Icon(Icons.grid_view_rounded), text: 'Validation Grid'),
          Tab(icon: Icon(Icons.analytics_outlined), text: 'Analysis'),
          Tab(icon: Icon(Icons.list_alt_rounded), text: 'Details'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildValidationTab(),
        _buildAnalysisTab(),
        _buildDetailsTab(),
      ],
    );
  }

  Widget _buildValidationTab() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing20),
      child: TOUValidationGrid(
        timeOfUseDetails: _timeOfUse?.timeOfUseDetails ?? [],
        availableTimeBands: _availableTimeBands,
        availableChannels: _availableChannels,
        viewMode: _currentViewMode,
        onViewModeChanged: (mode) {
          setState(() {
            _currentViewMode = mode;
          });
        },
        onChannelFilterChanged: (channelIds) {
          // Handle channel filter changes
          print('Channel filter changed: $channelIds');
        },
        onTimeBandFilterChanged: (timeBandIds) {
          // Handle time band filter changes
          print('Time band filter changed: $timeBandIds');
        },
      ),
    );
  }

  Widget _buildAnalysisTab() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing20),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: AppSizes.spacing16),
            Text(
              'Analysis View',
              style: TextStyle(
                fontSize: AppSizes.fontSizeLarge,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppSizes.spacing8),
            Text(
              'Advanced analytics and reporting features coming soon',
              style: TextStyle(
                fontSize: AppSizes.fontSizeMedium,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTab() {
    final details = _timeOfUse?.timeOfUseDetails ?? [];

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing20),
      child: ListView.builder(
        itemCount: details.length,
        itemBuilder: (context, index) {
          final detail = details[index];
          return _buildDetailCard(detail);
        },
      ),
    );
  }

  Widget _buildDetailCard(TimeOfUseDetail detail) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spacing12),
      padding: const EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  detail.channel?.name ?? 'Unknown Channel',
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeMedium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              StatusChip(
                text: detail.active ? 'Active' : 'Inactive',
                compact: true,
                type: detail.active
                    ? StatusChipType.success
                    : StatusChipType.secondary,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing8),
          if (detail.timeBand != null) ...[
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSizes.spacing4),
                Text(
                  detail.timeBand!.name,
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeSmall,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  'Priority: ${detail.priorityOrder}',
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeSmall,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacing4),
            Text(
              detail.timeBand!.timeRangeDisplay,
              style: const TextStyle(
                fontSize: AppSizes.fontSizeSmall,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (detail.registerDisplayCode.isNotEmpty) ...[
            const SizedBox(height: AppSizes.spacing8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacing8,
                vertical: AppSizes.spacing4,
              ),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              ),
              child: Text(
                'Register: ${detail.registerDisplayCode}',
                style: const TextStyle(
                  fontSize: AppSizes.fontSizeSmall,
                  color: AppColors.textSecondary,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
