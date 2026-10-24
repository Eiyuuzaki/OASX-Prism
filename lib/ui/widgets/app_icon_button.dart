import 'package:flutter/material.dart';

import 'package:oasx/ui/impl/fluent/fluent_tokens.dart';
import 'package:oasx/ui/style.dart';

/// 图标按钮的语义变体。
enum AppIconButtonVariant {
  /// 无底色，仅悬停时显示浅底（工具栏、标题栏最常用）。
  subtle,

  /// 常驻浅底（更像"已激活的开关"）。
  tonal,

  /// 描边（需要明确边界时）。
  outlined,
}

/// 跨平台语义图标按钮。
///
/// WinUI 的图标按钮与 Material 的主要差异：
/// - **36×36 而非 40×48**，圆角 4 而非圆形
/// - **无涟漪**，悬停整块浅填充
/// - 命中区是方形，不是圆
///
/// Material 的 `IconButton` 默认是圆形容器 + 水波纹，
/// 在 Windows 上会显得"软"，与系统的方形按钮观感不符。
class AppIconButton extends StatefulWidget {
  /// 创建图标按钮。
  ///
  /// [icon] 与 [child] 二选一：常规用 [icon]；需要在按钮里放
  /// 非图标内容（例如加载中的转圈）时用 [child] 覆盖。
  const AppIconButton({
    super.key,
    this.icon,
    this.child,
    this.onPressed,
    this.tooltip,
    this.variant = AppIconButtonVariant.subtle,
    this.dense = false,
    this.iconSize,
    this.color,
  }) : assert(icon != null || child != null,
            'AppIconButton 需要 icon 或 child');

  /// 图标。
  final IconData? icon;

  /// 自定义内容，优先级高于 [icon]。
  final Widget? child;

  /// 点击回调；为 null 时禁用。
  final VoidCallback? onPressed;

  /// 悬停提示。
  final String? tooltip;

  /// 语义变体。
  final AppIconButtonVariant variant;

  /// 紧凑模式（28×28，用于密集工具栏）。
  final bool dense;

  /// 覆盖图标尺寸。
  final double? iconSize;

  /// 覆盖图标颜色。
  final Color? color;

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  bool _hovering = false;
  bool _pressing = false;

  @override
  Widget build(BuildContext context) {
    final style = resolveAppUiStyle();
    if (style != AppUiStyle.fluent) return _buildMaterial(context);

    final p = FluentPalette.of(context);
    final enabled = widget.onPressed != null;
    final size = widget.dense ? 28.0 : 36.0;

    // 底色按变体决定；悬停/按压叠加 subtle-fill
    Color base;
    Color? border;
    switch (widget.variant) {
      case AppIconButtonVariant.subtle:
        base = Colors.transparent;
        border = null;
      case AppIconButtonVariant.tonal:
        base = p.card;
        border = null;
      case AppIconButtonVariant.outlined:
        base = p.card;
        border = p.stroke;
    }

    final Color fill;
    if (_pressing) {
      fill = Color.alphaBlend(p.rowPressed, base);
    } else if (_hovering) {
      fill = Color.alphaBlend(p.rowHover, base);
    } else {
      fill = base;
    }

    final fg = !enabled
        ? p.textTertiary
        : (widget.color ?? p.textSecondary);

    final button = MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: enabled ? (_) => setState(() => _hovering = true) : null,
      onExit: enabled
          ? (_) => setState(() {
                _hovering = false;
                _pressing = false;
              })
          : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _pressing = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressing = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressing = false) : null,
        onTap: widget.onPressed,
        // 按下缩放：与 AppButton 一致的 WinUI 手感
        child: AnimatedScale(
          duration: FluentMotion.fast,
          curve: FluentMotion.decelerate,
          scale: (_pressing && enabled) ? 0.90 : 1.0,
          child: AnimatedContainer(
          duration: FluentMotion.hoverIn,
          curve: FluentMotion.decelerate,
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: FluentRadius.controlRadius,
            border: border == null ? null : Border.all(color: border),
          ),
          child: widget.child ??
              Icon(
                widget.icon,
                size: widget.iconSize ?? (widget.dense ? 16 : 18),
                color: fg,
              ),
          ),
        ),
      ),
    );

    return widget.tooltip == null
        ? button
        : Tooltip(message: widget.tooltip!, child: button);
  }

  /// Material：沿用原来的 IconButton（保留涟漪，与其它 Material 界面一致）。
  Widget _buildMaterial(BuildContext context) {
    final style = switch (widget.variant) {
      AppIconButtonVariant.subtle => null,
      AppIconButtonVariant.tonal => IconButton.styleFrom(
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
      AppIconButtonVariant.outlined => IconButton.styleFrom(
          side: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
    };
    return IconButton(
      onPressed: widget.onPressed,
      tooltip: widget.tooltip,
      icon: widget.child ??
          Icon(widget.icon, size: widget.iconSize),
      color: widget.color,
      style: style,
      visualDensity: widget.dense ? VisualDensity.compact : null,
    );
  }
}
