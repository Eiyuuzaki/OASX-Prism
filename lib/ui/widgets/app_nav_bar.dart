import 'package:flutter/material.dart';

import 'package:oasx/ui/impl/fluent/fluent_tokens.dart';
import 'package:oasx/ui/style.dart';

/// 一个导航项。
class AppNavDestination {
  const AppNavDestination({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}

/// 导航栏宽度。
///
/// WinUI 的 NavigationView 展开态约 200px（图标在左、文字在右，横排）；
/// Material 的 NavigationRail 是 80px（图标在上、文字在下，竖排）。
/// 布局计算需要提前知道宽度，所以在这里集中暴露。
double appNavBarWidth() => resolveAppUiStyle() == AppUiStyle.fluent ? 200 : 80;

/// 跨平台语义导航栏。
///
/// | | Material NavigationRail | WinUI NavigationView |
/// |---|---|---|
/// | 宽度 | 80 | **200** |
/// | 图标/文字 | 竖排（图标在上） | **横排（图标在左）** |
/// | 选中表现 | 胶囊高亮包住图标 | **左侧 3×16 圆角竖条 + 浅色填充** |
/// | 项圆角 | 16 | **4** |
/// | 项高 | ~56 | **36** |
///
/// 选中指示器是最容易辨认的差异：WinUI 用一根贴着左边缘的短竖条，
/// 而不是把整个图标包起来。
class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<AppNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return resolveAppUiStyle() == AppUiStyle.fluent
        ? _buildFluent(context)
        : _buildMaterial();
  }

  Widget _buildMaterial() {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      labelType: NavigationRailLabelType.all,
      destinations: [
        for (final d in destinations)
          NavigationRailDestination(
            icon: Icon(d.icon),
            label: Text(d.label),
          ),
      ],
    );
  }

  Widget _buildFluent(BuildContext context) {
    final p = FluentPalette.of(context);
    return Container(
      width: appNavBarWidth(),
      color: p.layerAlt,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < destinations.length; i++)
            _FluentNavItem(
              destination: destinations[i],
              selected: i == selectedIndex,
              onTap: () => onSelected(i),
            ),
        ],
      ),
    );
  }
}

/// WinUI NavigationView 的单个导航项。
class _FluentNavItem extends StatefulWidget {
  const _FluentNavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final AppNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_FluentNavItem> createState() => _FluentNavItemState();
}

class _FluentNavItemState extends State<_FluentNavItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = FluentPalette.of(context);

    // 选中用浅填充，未选中悬停用同样系列的更浅填充
    final Color fill;
    if (widget.selected) {
      fill = p.rowHover;
    } else if (_hovering) {
      fill = p.rowPressed;
    } else {
      fill = Colors.transparent;
    }

    return Padding(
      // Win11 的导航项左右各留 4px，让它不贴边
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: FluentMotion.hoverIn,
            curve: FluentMotion.decelerate,
            height: 36,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(FluentRadius.control),
            ),
            child: Row(
              children: [
                // 选中指示器：贴着左边缘的 3×16 圆角竖条
                SizedBox(
                  width: 3,
                  child: Center(
                    child: AnimatedContainer(
                      duration: FluentMotion.hoverIn,
                      curve: FluentMotion.decelerate,
                      width: 3,
                      height: widget.selected ? 16 : 0,
                      decoration: BoxDecoration(
                        color: p.accent,
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Icon(
                  widget.destination.icon,
                  size: 16,
                  color: p.textPrimary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: p.textPrimary,
                      fontWeight: widget.selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
