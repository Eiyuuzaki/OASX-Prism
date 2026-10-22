import 'dart:async';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'package:oasx/modules/common/widgets/device_badge.dart';
import 'package:oasx/modules/common/widgets/title.dart';
import 'package:oasx/ui/impl/fluent/fluent_tokens.dart';
import 'package:oasx/ui/impl/fluent/fluent_window_controls.dart';

const double _compactActionBaseThreshold = 280;
const double _compactActionWidth = 48;

/// 应用头部高度。
///
/// 不用 Win11 系统的 32px——那是"系统标题栏"的比例，会显得单薄。
/// 48px 更接近现代应用（如 Watt Toolkit）的头部：足够容纳应用名 +
/// 常驻操作，同时不会像 Material AppBar 的 56px 那样厚重。
const double _captionBarHeight = 48;

class WindowsCaptionBar extends StatefulWidget implements PreferredSizeWidget {
  const WindowsCaptionBar({
    super.key,
    required this.brightness,
    this.onMenuPressed,
    this.routePath,
    this.trailingActions = const [],
  });

  final Brightness brightness;
  final VoidCallback? onMenuPressed;
  final String? routePath;
  final List<Widget> trailingActions;

  @override
  Size get preferredSize => const Size.fromHeight(_captionBarHeight);

  @override
  State<WindowsCaptionBar> createState() => _WindowsCaptionBarState();
}

class _WindowsCaptionBarState extends State<WindowsCaptionBar>
    with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    unawaited(_syncMaximizedState());
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() {
    if (!mounted || _isMaximized) {
      return;
    }
    setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    if (!mounted || !_isMaximized) {
      return;
    }
    setState(() => _isMaximized = false);
  }

  @override
  void onWindowRestore() {
    unawaited(_syncMaximizedState());
  }

  Future<void> _syncMaximizedState() async {
    final nextValue = await windowManager.isMaximized();
    if (!mounted || nextValue == _isMaximized) {
      return;
    }
    setState(() => _isMaximized = nextValue);
  }

  @override
  Widget build(BuildContext context) {
    // 不画独立背景色：与页面同色，避免视觉上出现"一根横条"。
    // 这是让它看起来像"应用头部"而不是"系统标题栏"的关键。
    // 不画独立背景色：与页面同色，避免视觉上出现"一根横条"。
    // 这是让它看起来像"应用头部"而不是"系统标题栏"的关键。
    return SizedBox(
      height: _captionBarHeight,
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final hideTrailingActions = _shouldHideTrailingActions(
                    constraints.maxWidth,
                  );
                  return Row(
                    children: [
                      if (widget.onMenuPressed != null) ...[
                        _CaptionIconButton(
                          icon: Icons.menu_rounded,
                          onTap: widget.onMenuPressed!,
                          tooltip: '菜单',
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: DragToMoveArea(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: getTitle(
                              context,
                              routePath: widget.routePath,
                            ),
                          ),
                        ),
                      ),
                      // 设备徽标：常驻显示当前连接的安卓实例，点击切换。
                      // 放在拖拽区之外保证可点击；窄窗口下自动退化为纯图标。
                      DeviceBadge(compact: hideTrailingActions),
                      if (!hideTrailingActions &&
                          widget.trailingActions.isNotEmpty)
                        const SizedBox(width: 4),
                      if (!hideTrailingActions) ...widget.trailingActions,
                      const SizedBox(width: 4),
                    ],
                  );
                },
              ),
            ),
          ),
          FluentWindowControls(
            isMaximized: _isMaximized,
            onMinimize: () => windowManager.minimize(),
            onToggleMaximize: () async {
              if (await windowManager.isMaximized()) {
                await windowManager.unmaximize();
              } else {
                await windowManager.maximize();
              }
            },
            onClose: () => windowManager.close(),
          ),
        ],
      ),
    );
  }

  bool _shouldHideTrailingActions(double maxWidth) {
    if (widget.trailingActions.isEmpty) {
      return false;
    }
    final threshold =
        _compactActionBaseThreshold +
        (widget.trailingActions.length * _compactActionWidth);
    return maxWidth <= threshold;
  }
}

/// 标题栏上的小型图标按钮（菜单等）。
///
/// 尺寸比 Material 的 IconButton 小（28×28），符合 32px 标题栏的留白比例；
/// 悬停时显示中性底色，无涟漪。
class _CaptionIconButton extends StatefulWidget {
  const _CaptionIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  State<_CaptionIconButton> createState() => _CaptionIconButtonState();
}

class _CaptionIconButtonState extends State<_CaptionIconButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final p = FluentPalette.of(context);
    final button = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: FluentMotion.fast,
          curve: FluentMotion.standard,
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _hovering ? p.subtleHover : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(widget.icon, size: 16, color: p.textSecondary),
        ),
      ),
    );
    final tip = widget.tooltip;
    return tip == null ? button : Tooltip(message: tip, child: button);
  }
}
