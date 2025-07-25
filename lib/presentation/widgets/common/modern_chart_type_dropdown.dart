import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/chart_type.dart';

class ModernChartTypeDropdown extends StatefulWidget {
  final ChartType selectedType;
  final ValueChanged<ChartType> onChanged;

  const ModernChartTypeDropdown({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  State<ModernChartTypeDropdown> createState() =>
      _ModernChartTypeDropdownState();
}

class _ModernChartTypeDropdownState extends State<ModernChartTypeDropdown> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isOpen = false;
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showDropdown();
    }
  }

  void _showDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 4,
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            color: Theme.of(context).cardColor,
            child: Container(
              constraints: BoxConstraints(maxHeight: 200, minWidth: size.width),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: ChartType.values.length,
                  itemBuilder: (context, index) {
                    final chartType = ChartType.values[index];
                    final isSelected = chartType == widget.selectedType;

                    return InkWell(
                      onTap: () {
                        widget.onChanged(chartType);
                        _removeOverlay();
                      },
                      child: Container(
                        height: AppSizes.buttonHeightSmall,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.spacing16,
                          vertical: AppSizes.spacing8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.1)
                              : Colors.transparent,
                          border: index < ChartType.values.length - 1
                              ? Border(
                                  bottom: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).dividerColor.withOpacity(0.1),
                                    width: 1,
                                  ),
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              chartType.icon,
                              size: 16,
                              color: isSelected
                                  ? AppColors.primary
                                  : Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                            ),
                            const SizedBox(width: AppSizes.spacing8),
                            Expanded(
                              child: Text(
                                chartType.displayName,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: isSelected
                                          ? AppColors.primary
                                          : Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.color,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check,
                                size: 16,
                                color: AppColors.primary,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: _toggleDropdown,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        child: Container(
          height: AppSizes.buttonHeightSmall,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacing16,
            vertical: AppSizes.spacing8,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: _isOpen
                  ? AppColors.primary
                  : Theme.of(context).dividerColor.withOpacity(0.3),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            color: Theme.of(context).cardColor,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.selectedType.icon,
                size: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              const SizedBox(width: AppSizes.spacing8),
              Text(
                widget.selectedType.displayName,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: AppSizes.spacing8),
              Icon(
                _isOpen ? Icons.expand_less : Icons.expand_more,
                size: 18,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
