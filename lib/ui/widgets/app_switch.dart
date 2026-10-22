import 'package:flutter/material.dart';

import 'package:oasx/ui/impl/fluent/fluent_tokens.dart';
import 'package:oasx/ui/style.dart';

/// 跨平台语义开关。
///
/// Windows 上渲染为 WinUI 的 ToggleSwitch，与 Material 的 Switch
/// 是**两种完全不同的形态**：
///
/// | | Material | WinUI |
/// |---|---|---|
/// | 轨道 | 52×32，较粗 | 40×20，细长 |
/// | 滑钮 | 大圆（20~24px） | 小圆（14px） |
/// | 关闭态 | 半透明灰底 | **透明底 + 1px 描边** |
/// | 开启态 | 轨道半透明填充 + 深色滑钮 | **纯强调色填充 + 白滑钮** |
///
/// 关闭态的"透明底 + 描边"是 WinUI 最显著的特征：它让关闭状态
/// 看起来是"空心的"，而 Material 是"实心的灰色"。
class AppSwitch extends StatelessWidget {
  /// 创建语义开关。
  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.stateLabel = false,
  });

  /// 当前值。
  final bool value;

  /// 变化回调；为 null 时禁用。
  final ValueChanged<bool>? onChanged;

  /// 是否在开关左侧显示「开/关」文字。
  ///
  /// WinUI 的 ToggleSwitch 支持这个文字（OnContent/OffContent），
  /// 但 Win11 设置应用里默认不显示，所以这里默认关闭。
  final bool stateLabel;

  @override
  Widget build(BuildContext context) {
    return switch (resolveAppUiStyle()) {
      AppUiStyle.fluent => _FluentToggle(
          value: value,
          onChanged: onChanged,
          stateLabel: stateLabel,
        ),
      _ => Switch(
          value: value,
          onChanged: onChanged,
        ),
    };
  }
}

/// WinUI ToggleSwitch。
class _FluentToggle extends StatefulWidget {
  const _FluentToggle({
    required this.value,
    required this.onChanged,
    required this.stateLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool stateLabel;

  @override
  State<_FluentToggle> createState() => _FluentToggleState();
}

class _FluentToggleState extends State<_FluentToggle> {
  bool _hovering = false;
  bool _pressing = false;

  // WinUI ToggleSwitch 的实际尺寸
  static const double _trackW = 40;
  static const double _trackH = 20;
  static const double _knobD = 14;
  static const double _knobInset = 3;

  @override
  Widget build(BuildContext context) {
    final p = FluentPalette.of(context);
    final enabled = widget.onChanged != null;
    final on = widget.value;

    // 轨道颜色
    final Color trackColor;
    final Color trackBorder;
    if (!enabled) {
      trackColor = on
          ? p.accent.withValues(alpha: 0.4)
          : Colors.transparent;
      trackBorder = p.stroke;
    } else if (on) {
      // 悬停时强调色略亮
      trackColor = _hovering
          ? Color.alphaBlend(const Color(0x0FFFFFFF), p.accent)
          : p.accent;
      trackBorder = trackColor;
    } else {
      trackColor = _hovering ? p.cardHover : Colors.transparent;
      trackBorder = p.stroke;
    }

    // 滑钮颜色：开启为白，关闭为中性灰
    final Color knobColor;
    if (!enabled) {
      knobColor = on ? Colors.white.withValues(alpha: 0.7) : p.textTertiary;
    } else {
      knobColor = on ? Colors.white : p.textSecondary;
    }

    final track = MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: enabled ? (_) => setState(() => _hovering = true) : null,
      onExit: enabled
          ? (_) => setState(() {
                _hovering = false;
                _pressing = false;
              })
          : null,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressing = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressing = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressing = false) : null,
        onTap: enabled ? () => widget.onChanged!(!widget.value) : null,
        child: AnimatedContainer(
          duration: FluentMotion.fast,
          curve: FluentMotion.standard,
          width: _trackW,
          height: _trackH,
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(_trackH / 2),
            border: Border.all(color: trackBorder, width: 1),
          ),
          child: AnimatedAlign(
            duration: FluentMotion.fast,
            curve: FluentMotion.standard,
            alignment: on ? Alignment.centerRight : Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: _knobInset),
              child: AnimatedContainer(
                duration: FluentMotion.fast,
                curve: FluentMotion.standard,
                width: _knobD,
                height: _knobD,
                decoration: BoxDecoration(
                  color: knobColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (!widget.stateLabel) return track;

    // 「开/关」文字在轨道左侧（WinUI 的排列方式）
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedOpacity(
          duration: FluentMotion.fast,
          opacity: _pressing ? 0.6 : 1,
          child: Text(
            on ? '开' : '关',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: enabled ? p.textPrimary : p.textTertiary,
                ),
          ),
        ),
        const SizedBox(width: 8),
        track,
      ],
    );
  }
}
