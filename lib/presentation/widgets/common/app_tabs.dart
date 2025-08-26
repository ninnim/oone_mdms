import 'package:flutter/material.dart';
// import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../themes/app_theme.dart';

class AppTab {
  final String label;
  final Widget? icon;
  final Widget content;

  const AppTab({required this.label, this.icon, required this.content});
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
      setState(() {});
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
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline,
                width: 1.0,
              ),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: widget.isScrollable,
            labelColor: widget.selectedTabColor ?? context.primaryColor,
            unselectedLabelColor:
                widget.unselectedTabColor ??
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            labelStyle: const TextStyle(
              fontSize: AppSizes.fontSizeMedium,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: AppSizes.fontSizeMedium,
              fontWeight: FontWeight.w500,
            ),
            indicatorColor: widget.indicatorColor ?? context.primaryColor,
            indicatorSize: widget.indicatorSize,
            indicatorWeight: 1.0,
            indicator: BoxDecoration(
              color: Colors.transparent,
              border: Border(
                bottom: BorderSide(
                  color: widget.indicatorColor ?? context.primaryColor,
                  width: 1.0,
                ),
              ),
            ),
            labelPadding:
                widget.tabPadding ??
                EdgeInsets.symmetric(
                  horizontal: AppSizes.spacing16,
                  vertical: AppSizes.spacing12,
                ),
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            splashFactory: NoSplash.splashFactory,
            tabs: widget.tabs.asMap().entries.map((entry) {
              final index = entry.key;
              final tab = entry.value;
              final isSelected = _tabController.index == index;

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
                        IconTheme(
                          data: IconThemeData(
                            color: isSelected
                                ? (widget.selectedTabColor ??
                                      context.primaryColor)
                                : (widget.unselectedTabColor ??
                                      Theme.of(context).colorScheme.onSurface
                                          .withValues(alpha: 0.7)),
                          ),
                          child: tab.icon!,
                        ),
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

class _AppPillTabsState extends State<AppPillTabs>
    with SingleTickerProviderStateMixin {
  late int selectedIndex;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late double _tabWidth;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _tabWidth = 1.0 / widget.tabs.length;

    _slideAnimation =
        Tween<Offset>(
          begin: Offset(selectedIndex.toDouble() * _tabWidth, 0.0),
          end: Offset(selectedIndex.toDouble() * _tabWidth, 0.0),
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOutCubic,
          ),
        );

    _animationController.addListener(() {
      setState(() {});
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _animateToTab(int newIndex) {
    final currentOffset = _slideAnimation.value.dx;
    final targetOffset = newIndex.toDouble() * _tabWidth;

    _slideAnimation =
        Tween<Offset>(
          begin: Offset(currentOffset, 0.0),
          end: Offset(targetOffset, 0.0),
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOutCubic,
          ),
        );

    _animationController
      ..reset()
      ..forward();

    setState(() {
      selectedIndex = newIndex;
    });

    widget.onTabChanged?.call(newIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 45,
          padding: EdgeInsets.all(AppSizes.spacing4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final containerWidth = constraints.maxWidth;
              final tabWidth = containerWidth / widget.tabs.length;

              return Stack(
                children: [
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Positioned(
                        left: _slideAnimation.value.dx * containerWidth,
                        width: tabWidth,
                        child: Container(
                          height: 35,
                          decoration: BoxDecoration(
                            color: widget.selectedColor ?? context.primaryColor,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusLarge,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: AppSizes.radiusLarge,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  Row(
                    children: widget.tabs.asMap().entries.map((entry) {
                      final index = entry.key;
                      final tab = entry.value;
                      final isSelected = index == selectedIndex;

                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _animateToTab(index),
                        child: Container(
                          width: tabWidth,
                          height: 35,
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (tab.icon != null) ...[
                                IconTheme(
                                  data: IconThemeData(
                                    size: AppSizes.iconMedium,
                                    color: isSelected
                                        ? (widget.selectedTextColor ??
                                              Theme.of(
                                                context,
                                              ).colorScheme.onPrimary)
                                        : (widget.unselectedTextColor ??
                                              Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.7)),
                                  ),
                                  child: tab.icon!,
                                ),
                                SizedBox(width: AppSizes.spacing8),
                              ],
                              Text(
                                tab.label,
                                style: TextStyle(
                                  fontSize: AppSizes.fontSizeSmall,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? (widget.selectedTextColor ??
                                            Theme.of(
                                              context,
                                            ).colorScheme.onPrimary)
                                      : (widget.unselectedTextColor ??
                                            Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.7)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
        ),
        Expanded(child: widget.tabs[selectedIndex].content),
      ],
    );
  }
}
