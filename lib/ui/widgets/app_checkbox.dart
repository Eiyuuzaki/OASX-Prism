import 'package:flutter/material.dart';

import 'package:oasx/ui/impl/fluent/fluent_tokens.dart';
import 'package:oasx/ui/style.dart';

/// 跨平台语义复选框。
///
/// Windows 上是 WinUI 的 CheckBox：**14px 圆角方框**（圆角 2），
/// 选中时填充强调色并出现白色对勾，标签在右侧。
///
/// ```
/// 未选中          选中
/// ┌──┐            ┏━━┓
/// │  │   标签      ┃✓┃   标签
/// └──┘            ┗━━┛
/// ```
///
/// 其它平台沿用 Material 的 [Checkbox]。
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.tristate = false,
  });

  /// 当前值。`null` 表示三态的"不确定"状态。
  final bool? value;

  /// 变更回调。为 null 时禁用。
  final ValueChanged<bool?>? onChanged;

  /// 右侧标签。
  final String? label;

  /// 是否允许三态（不确定态）。
  final bool tristate;

  @override
  Widget build(BuildContext context) {
    if (resolveAppUiStyle() != AppUiStyle.fluent) {
      return Checkbox(
        value: value,
        onChanged: onChanged,
        tristate: tristate,
      );
    }

    final enabled = onChanged != null;
    return _FluentCheckbox(
      value: value,
      enabled: enabled,
      label: label,
      onTap: enabled
          ? () {
              if (tristate) {
                onChanged!(value == true ? null : true);
              } else {
                onChanged!(value != true);
              }
            }
          : null,
    );
  }
}

class _FluentCheckbox extends StatefulWidget {
  const _FluentCheckbox({
    required this.value,
    required this.enabled,
    required this.onTap,
    this.label,
  });

  final bool? value;
  final bool enabled;
  final VoidCallback? onTap;
  final String? label;

  @override
  State<_FluentCheckbox> createState() => _FluentCheckboxState();
}

class _FluentCheckboxState extends State<_FluentCheckbox> {
  bool _hovering = false;

  static const double _box = 16;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = FluentPalette.of(context);
    final checked = widget.value == true;
    final indeterminate = widget.value == null;

    final Color borderColor;
    final Color fillColor;
    if (!widget.enabled) {
      borderColor = p.textTertiary.withValues(alpha: 0.5);
      fillColor = checked ? p.textTertiary.withValues(alpha: 0.5) : Colors.transparent;
    } else if (checked || indeterminate) {
      borderColor = p.accent;
      fillColor = p.accent;
    } else if (_hovering) {
      borderColor = p.textSecondary;
      fillColor = Colors.transparent;
    } else {
      borderColor = p.textSecondary;
      fillColor = Colors.transparent;
    }

    final markColor = p.onAccent;

    final box = AnimatedContainer(
      duration: FluentMotion.hoverIn,
      curve: FluentMotion.decelerate,
      width: _box,
      height: _box,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: (checked || indeterminate)
          ? Icon(
              indeterminate ? Icons.remove_rounded : Icons.check_rounded,
              size: 12,
              color: markColor,
            )
          : null,
    );

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        box,
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
