import 'package:flutter/material.dart';

import 'package:oasx/ui/impl/fluent/fluent_tokens.dart';
import 'package:oasx/ui/style.dart';

/// 跨平台语义单选按钮。
///
/// Windows 上是 WinUI 的 RadioButton：**16px 圆形**，选中时内圈填充
/// 强调色小圆点。
///
/// ```
/// 未选中          选中
///  ⭕   标签       ◉   标签
/// ```
class AppRadio<T> extends StatelessWidget {
  const AppRadio({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.label,
  });

  /// 本项代表的值。
  final T value;

  /// 当前选中值。
  final T? groupValue;

  /// 变更回调。为 null 时禁用。
  final ValueChanged<T?>? onChanged;

  /// 右侧标签。
  final String? label;

  bool get _selected => value == groupValue;

  @override
  Widget build(BuildContext context) {
    if (resolveAppUiStyle() != AppUiStyle.fluent) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<T>(
            value: value,
            groupValue: groupValue,
            onChanged: onChanged,
          ),
          if (label != null) Text(label!),
        ],
      );
    }

    return _FluentRadio(
      selected: _selected,
      enabled: onChanged != null,
      label: label,
      onTap: onChanged == null ? null : () => onChanged!(value),
    );
  }
}

class _FluentRadio extends StatefulWidget {
  const _FluentRadio({
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.label,
  });

  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;
  final String? label;

  @override
  State<_FluentRadio> createState() => _FluentRadioState();
}

class _FluentRadioState extends State<_FluentRadio> {
  bool _hovering = false;

  static const double _size = 16;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = FluentPalette.of(context);

    final Color borderColor;
    if (!widget.enabled) {
      borderColor = p.textTertiary.withValues(alpha: 0.5);
    } else if (widget.selected) {
      borderColor = p.accent;
    } else if (_hovering) {
      // 悬停时边框提亮，与复选框的悬停反馈一致
      borderColor = p.accent.withValues(alpha: 0.8);
    } else {
      borderColor = p.textSecondary;
    }

    final circle = AnimatedContainer(
      duration: FluentMotion.hoverIn,
      curve: FluentMotion.decelerate,
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.selected && widget.enabled ? p.accent : Colors.transparent,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: widget.selected
          ? Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.onAccent,
                ),
              ),
            )
          : null,
    );

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        circle,
        if (widget.label != null) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.label!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                color: widget.enabled ? p.textPrimary : p.textTertiary,
              ),
            ),
          ),
        ],
      ],
    );

    if (widget.onTap == null) return row;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: row,
      ),
    );
  }
}
