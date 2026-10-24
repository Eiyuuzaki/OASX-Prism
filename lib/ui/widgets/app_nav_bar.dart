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
/// WinUI 的 NavigationView **紧凑模式**：卡片 56 + 左右留白，约 64px。
/// 参考 Lenovo Legion Toolkit / Win11 设置应用的侧栏比例。
double appNavBarWidth() => resolveAppUiStyle() == AppUiStyle.fluent ? 64 : 80;

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
      foregroundDecoration: const BoxDecoration(
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
/// 结构（按用户要求调整过，与 LLT 原版有差异）：
///
/// ```
/// ┌──────────────────┐  ← 卡片接近正方形（76×72）
/// │ ▌                │  ← 指示条在**卡片内部**左侧
/// │       🏠         │
/// │      主页        │  ← 未选中：图标 + 文字
/// └──────────────────┘     选中：文字塌缩，图标居中
/// ```
///
/// ## 与 LLT 原版的差异
///
/// LLT 实测：卡片 94×85、指示条在卡片**外面**（x=0，与卡片相距 16px）。
/// 我们按用户要求改为「指示条进卡片内 + 卡片正方形」：
/// - 指示条放在卡片内部左边缘，视觉上是一个整体的高亮单元
/// - 卡片宽高比控制在 1.0 左右（76×72），不再是被拉长的矩形
///
/// ## 选中动画（照搬 LLT 规格）
///
/// 160ms：文字区高度塌缩 + 淡出（图标因此升到垂直居中），
/// 指示条与白色卡片底同时淡入。
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

  /// LLT 的动画时长：160ms。
  static const Duration _anim = Duration(milliseconds: 160);

  /// 卡片边长。正方形（宽高严格相等）。
  ///
  /// 从 72 缩到 56：72 时卡片显得笨重、占了侧栏一半宽度，
  /// 56 更接近 Win11 紧凑导航的密度。
  static const double _cardSize = 56;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = FluentPalette.of(context);
    final accent = theme.colorScheme.primary;
    final selected = widget.selected;

    // 选中底色：LLT 用**接近纯白的圆角块**（放大截图实测 RGB≈250），
    // 不是主色淡底——那个白色块让选中项像"浮起来的一张卡片"。
    final Color fill;
    if (selected) {
      fill = p.isDark ? const Color(0xFF2D2D2D) : const Color(0xFFFAFAFA);
    } else if (_hovering) {
      fill = p.rowPressed;
    } else {
      fill = Colors.transparent;
    }
    final fg = selected ? accent : p.textSecondary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Padding(
          // 卡片四周留白：缩小后 4px 足够，让卡片显得紧凑
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          child: Center(
            child: AnimatedContainer(
              duration: _anim,
              curve: Curves.easeOut,
              // 正方形卡片：56×56（宽高严格相等）
              width: _cardSize,
              height: _cardSize,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Stack(
                children: [
                  // 指示条：放在**卡片内部**左侧，垂直居中
                  Positioned(
                    left: 3,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: AnimatedOpacity(
                        duration: _anim,
                        opacity: selected ? 1 : 0,
                        child: Container(
                          width: 3,
                          height: 20,
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 图标 + 文字，整体居中
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(widget.destination.icon,
                            size: 22, color: fg),
                        // 文字区：选中时高度塌缩 + 淡出（图标因此居中）
                        AnimatedContainer(
                          duration: _anim,
                          curve: Curves.easeOut,
                          height: selected ? 0 : 13,
                          child: AnimatedOpacity(
                            duration: _anim,
                            opacity: selected ? 0 : 1,
                            child: Text(
                              widget.destination.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.labelSmall?.copyWith(
                                // LLT 用 FontSize 10
                                fontSize: 10,
                                color: fg,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
