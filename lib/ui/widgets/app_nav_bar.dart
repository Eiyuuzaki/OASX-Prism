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
/// WinUI 的 NavigationView **紧凑模式**：图标在上、文字在下，约 88px。
/// 对齐 Lenovo Legion Toolkit / Win11 设置应用的侧栏比例。
double appNavBarWidth() => resolveAppUiStyle() == AppUiStyle.fluent ? 88 : 80;

/// 跨平台语义导航栏。
///
/// Windows 上渲染为 WinUI NavigationView 的**紧凑模式**（对齐
/// Lenovo Legion Toolkit 的观感）：
///
/// ```
/// ┌────┐
/// │▌   │  ← 选中：左侧贴边 4×20 圆角竖条 + 圆角高亮块
/// │ 🏠 │
/// │主页│  ← 图标 24 + 文字 11，纵向排列
/// ├────┤
/// │ 📊 │
/// │统计│
/// ├────┤
/// │    │  ← 弹性空白
/// │ ⚙  │
/// │设置│  ← 次级项固定底部（bottomDestinations）
/// └────┘
/// ```
///
/// ## 用色
///
/// 侧栏浮在材质上（无白底卡片托着），文字跟随应用主题：
/// 选中项用主色（accent），未选中用次级文字色。
class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    this.bottomDestinations = const [],
  });

  /// 主分组（顶部）导航项。
  final List<AppNavDestination> destinations;

  /// 次级分组（底部固定）导航项，如「设置」。
  ///
  /// 索引接在 [destinations] 之后，回调时直接传该索引。
  final List<AppNavDestination> bottomDestinations;

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return resolveAppUiStyle() == AppUiStyle.fluent
        ? _buildFluent(context)
        : _buildMaterial();
  }

  Widget _buildMaterial() {
    final all = [...destinations, ...bottomDestinations];
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      labelType: NavigationRailLabelType.all,
      destinations: [
        for (final d in all)
          NavigationRailDestination(
            icon: Icon(d.icon),
            label: Text(d.label),
          ),
      ],
    );
  }

  Widget _buildFluent(BuildContext context) {
    // 系统材质生效时侧栏完全透明，与内容共用材质底；
    // 无材质时用深色实底（白字体系下深底才可读）。
    final materialActive =
        Theme.of(context).scaffoldBackgroundColor == Colors.transparent;
    const paneColor = Color(0xFF202020);
    const dividerColor = Color(0x29FFFFFF);

    return Container(
      width: appNavBarWidth(),
      color: materialActive ? Colors.transparent : paneColor,
      foregroundDecoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: dividerColor, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 6),
          for (var i = 0; i < destinations.length; i++)
            _FluentNavItem(
              destination: destinations[i],
              selected: selectedIndex == i,
              onTap: () => onSelected(i),
            ),
          const Spacer(),
          for (var j = 0; j < bottomDestinations.length; j++)
            _FluentNavItem(
              destination: bottomDestinations[j],
              selected: selectedIndex == destinations.length + j,
              onTap: () => onSelected(destinations.length + j),
            ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

/// WinUI NavigationView 紧凑模式的单个导航项。
///
/// 结构：左侧 12px 指示条槽位 + 右侧圆角高亮块（图标在上、文字在下）。
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
    final accent = theme.colorScheme.primary;

    // 选中：高亮块 + 主色图标文字；悬停：更浅的高亮块
    final Color fill;
    if (widget.selected) {
      fill = p.rowHover;
    } else if (_hovering) {
      fill = p.rowPressed;
    } else {
      fill = Colors.transparent;
    }
    final fg = widget.selected ? accent : p.textSecondary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              // 选中指示条槽位：贴左边缘的 4×20 圆角竖条
              SizedBox(
                width: 12,
                child: Center(
                  child: AnimatedContainer(
                    duration: FluentMotion.hoverIn,
                    curve: FluentMotion.decelerate,
                    width: 4,
                    height: widget.selected ? 20 : 0,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              // 高亮块 + 图标/文字
              Expanded(
                child: AnimatedContainer(
                  duration: FluentMotion.hoverIn,
                  curve: FluentMotion.decelerate,
                  margin: const EdgeInsets.only(right: 6, top: 4, bottom: 4),
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.destination.icon, size: 24, color: fg),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text(
                          widget.destination.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 11,
                            color: fg,
                            fontWeight: widget.selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
