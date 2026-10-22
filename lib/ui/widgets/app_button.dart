import 'package:flutter/material.dart';

import 'package:oasx/ui/impl/fluent/fluent_tokens.dart';
import 'package:oasx/ui/style.dart';

/// 按钮的语义变体。
///
/// 用「表达什么意图」而不是「用哪个 widget」来定义，
/// 各平台自己决定怎么实现：
///
/// | 变体 | Material | Fluent |
/// |---|---|---|
/// | [primary] | FilledButton（主色填充） | Accent Button（强调色填充） |
/// | [secondary] | FilledButton.tonal（浅色填充） | Standard Button（卡片底 + 描边） |
/// | [outline] | OutlinedButton（描边） | Standard Button（描边） |
/// | [text] | TextButton（无底） | Subtle Button（悬停才显底） |
enum AppButtonVariant {
  /// 页面主操作（提交、保存、确认）。
  primary,

  /// 次要操作（取消、替换）。
  secondary,

  /// 中性操作，需要视觉边界但不要强调。
  outline,

  /// 最轻量，工具栏/行内操作。
  text,
}

/// 跨平台语义按钮。
///
/// 在 Windows 上渲染为 Fluent 风格（4px 圆角、悬停变色、无涟漪），
/// 其它平台沿用 Material（M3 圆角、水波纹）。
class AppButton extends StatelessWidget {
  /// 创建文本按钮。
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.secondary,
    this.icon,
    this.trailingIcon,
    this.dense = false,
    this.expand = false,
  });

  /// 按钮文字。
  final String label;

  /// 点击回调；为 null 时按钮禁用。
  final VoidCallback? onPressed;

  /// 语义变体。
  final AppButtonVariant variant;

  /// 前置图标。
  final IconData? icon;

  /// 后置图标。
  final IconData? trailingIcon;

  /// 紧凑模式（减小高度与内边距，用于工具栏）。
  final bool dense;

  /// 是否占满可用宽度。
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final style = resolveAppUiStyle();
    final child = _buildContent(context, style);

    final Widget button = switch (style) {
      AppUiStyle.fluent => _buildFluent(context, child),
      _ => _buildMaterial(context, child),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _buildContent(BuildContext context, AppUiStyle style) {
    final theme = Theme.of(context);
    final fluent = style == AppUiStyle.fluent ? FluentPalette.of(context) : null;
    final color = fluent == null ? null : _fluentForeground(fluent);
    final iconSize = dense ? 16.0 : 18.0;
    final textStyle = (dense
            ? theme.textTheme.labelMedium
            : theme.textTheme.labelLarge)
        ?.copyWith(color: color);

    return Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: iconSize, color: color),
          SizedBox(width: dense ? 4 : 8),
        ],
        Text(label, style: textStyle),
        if (trailingIcon != null) ...[
          SizedBox(width: dense ? 4 : 8),
          Icon(trailingIcon, size: iconSize, color: color),
        ],
      ],
    );
  }

  // ── Fluent 实现 ──────────────────────────────────────────────

  Color _fluentForeground(FluentPalette p) {
    return switch (variant) {
      AppButtonVariant.primary => p.onAccent,
      _ => p.textPrimary,
    };
  }

  Color _fluentBackground(FluentPalette p) {
    return switch (variant) {
      AppButtonVariant.primary => p.accent,
      AppButtonVariant.secondary => p.card,
      AppButtonVariant.outline => p.card,
      AppButtonVariant.text => const Color(0x00000000),
    };
  }

  Color _fluentHoverBackground(FluentPalette p) {
    return switch (variant) {
      // 强调色按钮悬停：略亮/略暗
      AppButtonVariant.primary => p.isDark
          ? Color.alphaBlend(const Color(0x14FFFFFF), p.accent)
          : Color.alphaBlend(const Color(0x0F000000), p.accent),
      AppButtonVariant.secondary => p.cardHover,
      AppButtonVariant.outline => p.cardHover,
      AppButtonVariant.text => p.subtleHover,
    };
  }

  Widget _buildFluent(BuildContext context, Widget child) {
    final p = FluentPalette.of(context);
    final disabled = onPressed == null;
    final baseBg = _fluentBackground(p);
    final fg = disabled ? p.textTertiary : _fluentForeground(p);
    final hasStroke = variant == AppButtonVariant.secondary ||
        variant == AppButtonVariant.outline;

    return _FluentButtonSurface(
      enabled: !disabled,
      baseColor: baseBg,
      hoverColor: _fluentHoverBackground(p),
      strokeColor: hasStroke ? p.stroke : Colors.transparent,
      radius: FluentRadius.controlRadius,
      minHeight: dense ? 28 : 32,
      horizontalPadding: dense ? 10 : 14,
      onPressed: onPressed,
      // Fluent 按钮的文字色也随禁用/悬停变化，由主题提供基色
      child: DefaultTextStyle.merge(
        style: TextStyle(color: fg),
        child: IconTheme.merge(
          data: IconThemeData(color: fg),
          child: child,
        ),
      ),
    );
  }

  // ── Material 实现（沿用现有观感）──────────────────────────────

  Widget _buildMaterial(BuildContext context, Widget child) {
    final padding = dense
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
        : const EdgeInsets.symmetric(horizontal: 20, vertical: 10);
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20));

    return switch (variant) {
      AppButtonVariant.primary => FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            padding: padding,
            shape: shape,
            minimumSize: Size(dense ? 0 : 64, dense ? 32 : 40),
          ),
          child: child,
        ),
      AppButtonVariant.secondary => FilledButton.tonal(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            padding: padding,
            shape: shape,
            minimumSize: Size(dense ? 0 : 64, dense ? 32 : 40),
          ),
          child: child,
        ),
      AppButtonVariant.outline => OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: padding,
            shape: shape,
            minimumSize: Size(dense ? 0 : 64, dense ? 32 : 40),
          ),
          child: child,
        ),
      AppButtonVariant.text => TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            padding: padding,
            shape: shape,
            minimumSize: Size(dense ? 0 : 64, dense ? 32 : 40),
          ),
          child: child,
        ),
    };
  }
}

/// Fluent 按钮的交互表面。
///
/// WinUI 的按钮反馈与 Material 有本质区别：
/// - **没有涟漪**，只有整块背景色过渡
/// - 悬停即变色（100ms 快速过渡）
/// - 按下时颜色更深
///
/// 这里用 `MouseRegion` + `GestureDetector` + `AnimatedContainer` 实现，
/// 而不是 `InkWell`——后者会带出 Material 的涟漪。
class _FluentButtonSurface extends StatefulWidget {
  const _FluentButtonSurface({
    required this.child,
    required this.enabled,
    required this.baseColor,
    required this.hoverColor,
    required this.strokeColor,
    required this.radius,
    required this.minHeight,
    required this.horizontalPadding,
    required this.onPressed,
  });

  final Widget child;
  final bool enabled;
  final Color baseColor;
  final Color hoverColor;
  final Color strokeColor;
  final BorderRadius radius;
  final double minHeight;
  final double horizontalPadding;
  final VoidCallback? onPressed;

  @override
  State<_FluentButtonSurface> createState() => _FluentButtonSurfaceState();
}

class _FluentButtonSurfaceState extends State<_FluentButtonSurface> {
  bool _hovering = false;
  bool _pressing = false;

  Color get _currentColor {
    if (!widget.enabled) return widget.baseColor;
    if (_pressing) {
      // 按下：在悬停色基础上再压深一点
      return Color.alphaBlend(const Color(0x0F000000), widget.hoverColor);
    }
    if (_hovering) return widget.hoverColor;
    return widget.baseColor;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: widget.enabled ? (_) => setState(() => _hovering = true) : null,
      onExit: widget.enabled
          ? (_) => setState(() {
                _hovering = false;
                _pressing = false;
              })
          : null,
      child: GestureDetector(
        onTapDown:
            widget.enabled ? (_) => setState(() => _pressing = true) : null,
        onTapUp: widget.enabled
            ? (_) => setState(() => _pressing = false)
            : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _pressing = false) : null,
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: FluentMotion.fast,
          curve: FluentMotion.standard,
          constraints: BoxConstraints(minHeight: widget.minHeight),
          padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
          decoration: BoxDecoration(
            color: _currentColor,
            borderRadius: widget.radius,
            border: Border.all(color: widget.strokeColor, width: 1),
          ),
          alignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );
  }
}
