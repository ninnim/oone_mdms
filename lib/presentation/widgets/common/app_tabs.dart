import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class AppTab {
  final String label;
  final Widget? icon;
  final Widget content;

  const AppTab({
    required this.label,
    this.icon,
    required this.content,
  });
}

class AppTabsWidget extends StatefulWidget {
  final List<AppTab> tabs;
  final int initialIndex;
  final Function(int)? onTabChanged;
  final TabBarIndicatorSize indicatorSize;
  final Color? indicatorColor;
  final Color? selectedTabColor;
  final Color? unselectedTabColor;
  final EdgeInsets? tabPadding;
  final bool isScrollable;

  const AppTabsWidget({
    super.key,
    required this.tabs,
    this.initialIndex = 0,
    this.onTabChanged,
    this.indicatorSize = TabBarIndicatorSize.tab,
    this.indicatorColor,
    this.selectedTabColor,
    this.unselectedTabColor,
    this.tabPadding,
    this.isScrollable = false,
  });

  @override
  State<AppTabsWidget> createState() => _AppTabsWidgetState();
}

class _AppTabsWidgetState extends State<AppTabsWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.tabs.length,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging && widget.onTabChanged != null) {
        widget.onTabChanged!(_tabController.index);
      }
    });
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
        // Custom Tab Bar with improved styling
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(
                color: AppColors.border,
                width: 1.0,
              ),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: widget.isScrollable,
            labelColor: widget.selectedTabColor ?? AppColors.primary,
            unselectedLabelColor: widget.unselectedTabColor ?? AppColors.textSecondary,
            labelStyle: const TextStyle(
              fontSize: AppSizes.fontSizeMedium,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: AppSizes.fontSizeMedium,
              fontWeight: FontWeight.w500,
            ),
            indicatorColor: widget.indicatorColor ?? AppColors.primary,
            indicatorSize: widget.indicatorSize,
            indicatorWeight: 3.0,
            indicator: BoxDecoration(
              color: Colors.transparent,
              border: Border(
                bottom: BorderSide(
                  color: widget.indicatorColor ?? AppColors.primary,
                  width: 3.0,
                ),
              ),
            ),
            labelPadding: widget.tabPadding ?? EdgeInsets.symmetric(
              horizontal: AppSizes.spacing16,
              vertical: AppSizes.spacing12,
            ),
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            splashFactory: NoSplash.splashFactory,
            tabs: widget.tabs.map((tab) {
              return Tab(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSizes.spacing8,
                    vertical: AppSizes.spacing8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (tab.icon != null) ...[
                        tab.icon!,
                        SizedBox(width: AppSizes.spacing8),
                      ],
                      Text(tab.label),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        
        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: widget.tabs.map((tab) => tab.content).toList(),
          ),
        ),
      ],
    );
  }
}

// Alternative Pill-style tabs widget
class AppPillTabs extends StatefulWidget {
  final List<AppTab> tabs;
  final int initialIndex;
  final Function(int)? onTabChanged;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? selectedTextColor;
  final Color? unselectedTextColor;

  const AppPillTabs({
    super.key,
    required this.tabs,
    this.initialIndex = 0,
    this.onTabChanged,
    this.selectedColor,
    this.unselectedColor,
    this.selectedTextColor,
    this.unselectedTextColor,
  });

  @override
  State<AppPillTabs> createState() => _AppPillTabsState();
}

class _AppPillTabsState extends State<AppPillTabs> {
  late int selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Pill Tab Bar
        Container(
          padding: EdgeInsets.all(AppSizes.spacing4),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          ),
          child: Row(
            children: widget.tabs.asMap().entries.map((entry) {
              final index = entry.key;
              final tab = entry.value;
              final isSelected = index == selectedIndex;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedIndex = index;
                    });
                    widget.onTabChanged?.call(index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSizes.spacing16,
                      vertical: AppSizes.spacing12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (widget.selectedColor ?? AppColors.primary)
                          : (widget.unselectedColor ?? Colors.transparent),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (tab.icon != null) ...[
                          tab.icon!,
                          SizedBox(width: AppSizes.spacing8),
                        ],
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: AppSizes.fontSizeMedium,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? (widget.selectedTextColor ?? AppColors.onPrimary)
                                : (widget.unselectedTextColor ?? AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        
        SizedBox(height: AppSizes.spacing16),
        
        // Tab Content
        Expanded(
          child: widget.tabs[selectedIndex].content,
        ),
      ],
    );
  }
}
