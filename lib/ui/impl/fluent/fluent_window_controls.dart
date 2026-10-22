import 'package:flutter/material.dart';

import 'package:oasx/ui/impl/fluent/fluent_tokens.dart';

/// Win11 风格的窗口控制按钮组（最小化 / 最大化 / 关闭）。
///
/// 与系统标题栏按钮的区别在于**融入感**：
/// - 按钮不占满高度，垂直居中悬浮，四角留白
/// - 默认完全透明（不画任何底色），只有悬停才出现
/// - 关闭按钮悬停红底白图标（Windows 的强约定）
///
/// 这样窗口顶部看起来是"应用自己的头"，而不是一根系统横条。
class FluentWindowControls extends StatelessWidget {
  const FluentWindowControls({
    super.key,
    required this.isMaximized,
    required this.onMinimize,
    required this.onToggleMaximize,
    required this.onClose,
  });

  final bool isMaximized;
  final VoidCallback onMinimize;
  final VoidCallback onToggleMaximize;
  final VoidCallback onClose;

  /// 按钮尺寸：比系统略窄，避免在小窗口时挤压内容。
  static const double buttonWidth = 40;
  static const double buttonHeight = 28;

  @override
  Widget build(BuildContext context) {
    final p = FluentPalette.of(context);
    final hoverColor =
        p.isDark ? const Color(0xFF3A3A3A) : const Color(0xFFEDEDED);
    final pressedColor =
        p.isDark ? const Color(0xFF464646) : const Color(0xFFE0E0E0);

    return Padding(
      // 右侧与顶部留白，让按钮"浮"在头部区域里而不是贴着边缘
      padding: const EdgeInsets.only(right: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ControlButton(
            icon: _CaptionIcons.minimize,
            hoverColor: hoverColor,
            pressedColor: pressedColor,
            iconColor: p.textSecondary,
            onTap: onMinimize,
          ),
          const SizedBox(width: 2),
          _ControlButton(
            icon: isMaximized ? _CaptionIcons.restore : _CaptionIcons.maximize,
            hoverColor: hoverColor,
            pressedColor: pressedColor,
            iconColor: p.textSecondary,
            onTap: onToggleMaximize,
          ),
          const SizedBox(width: 2),
          _ControlButton(
            icon: _CaptionIcons.close,
            hoverColor: const Color(0xFFC42B1C),
            pressedColor: const Color(0xFFB02A1C),
            iconColor: p.textSecondary,
            hoverIconColor: const Color(0xFFFFFFFF),
            onTap: onClose,
          ),
        ],
      ),
    );
  }
}

/// 单个控制按钮：圆角小方块、悬停才显底色、无涟漪。
class _ControlButton extends StatefulWidget {
  const _ControlButton({
    required this.icon,
    required this.hoverColor,
    required this.pressedColor,
    required this.iconColor,
    required this.onTap,
    this.hoverIconColor,
  });

  final _CaptionIcons icon;
  final Color hoverColor;
  final Color pressedColor;
  final Color iconColor;
  final Color? hoverIconColor;
  final VoidCallback onTap;

  @override
  State<_ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<_ControlButton> {
  bool _hovering = false;
  bool _pressing = false;

  @override
  Widget build(BuildContext context) {
    final bg = _pressing
        ? widget.pressedColor
        : (_hovering ? widget.hoverColor : Colors.transparent);
    final fg = (_hovering && widget.hoverIconColor != null)
        ? widget.hoverIconColor!
        : widget.iconColor;

    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() {
        _hovering = false;
        _pressing = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressing = true),
        onTapUp: (_) => setState(() => _pressing = false),
        onTapCancel: () => setState(() => _pressing = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: FluentMotion.fast,
          curve: FluentMotion.standard,
          width: FluentWindowControls.buttonWidth,
          height: FluentWindowControls.buttonHeight,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: CustomPaint(
            size: const Size(10, 10),
            painter: _CaptionIconPainter(widget.icon, fg),
          ),
        ),
      ),
    );
  }
}

/// Win11 标题栏图标的几何描述。
///
/// 直接画路径而不是用字体图标：系统图标是 10×10 的细线，
/// Material 的图标偏圆润、线条也更粗，一眼就能看出不是原生的。
enum _CaptionIcons {
  minimize,
  maximize,
  restore,
  close,
}

class _CaptionIconPainter extends CustomPainter {
  _CaptionIconPainter(this.icon, this.color);

  final _CaptionIcons icon;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..isAntiAlias = true;

    // 以 10×10 为设计尺寸，按实际 size 缩放
    final s = size.width / 10.0;
    double x(double v) => v * s;
    // 半像素对齐，避免 1px 线发虚
    double y(double v) => v * s + 0.5;

    switch (icon) {
      case _CaptionIcons.minimize:
        canvas.drawLine(Offset(x(0), y(5)), Offset(x(10), y(5)), paint);
      case _CaptionIcons.maximize:
        canvas.drawRect(Rect.fromLTWH(x(0), y(0), x(10), x(10)), paint);
      case _CaptionIcons.restore:
        canvas.drawRect(Rect.fromLTWH(x(0), y(3), x(7), x(7)), paint);
        canvas.drawPath(
          Path()
            ..moveTo(x(3), y(3))
            ..lineTo(x(3), y(0))
            ..lineTo(x(10), y(0))
            ..lineTo(x(10), y(7))
            ..lineTo(x(7), y(7)),
          paint,
        );
      case _CaptionIcons.close:
        canvas.drawLine(Offset(x(0), y(0)), Offset(x(10), y(10)), paint);
        canvas.drawLine(Offset(x(10), y(0)), Offset(x(0), y(10)), paint);
    }
  }

  @override
  bool shouldRepaint(_CaptionIconPainter old) =>
      old.icon != icon || old.color != color;
}
