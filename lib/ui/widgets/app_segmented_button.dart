import 'package:flutter/material.dart';

import 'package:oasx/ui/impl/fluent/fluent_tokens.dart';
import 'package:oasx/ui/style.dart';

/// 分段控件的一个选项。
class AppSegment<T> {
  const AppSegment({required this.value, required this.label, this.icon});

  final T value;

  /// 文字标签。与 [icon] 同时给出时，图标在左、文字在右。
  final String label;

  /// 可选图标（纯图标分段控件用它代替文字）。
  final IconData? icon;
}

/// 跨平台语义分段控件（WinUI 的 SegmentedControl）。
///
/// ## Windows 观感
///
/// 外框是一个圆角容器，选中项是**内部浮起的圆角块**（不是 Material
/// 那种整块描边的 ToggleButtons）：
///
/// ```
/// ┌──────────────────────┐
/// │ ▓浅色▓ │ 深色 │ 系统 │   ← 选中的"浅色"是内部白块
/// └──────────────────────┘     外框 1px 描边、圆角 4
/// ```
///
/// - 外框：1px `stroke` 描边 + 圆角 4，无填充
/// - 选中块：`card` 底色 + 圆角 3 + 轻微阴影，手指按下时变 `cardPressed`
/// - 未选中：文字用 `textSecondary`，悬停时文字变 `textPrimary`
/// - 动画：`FluentMotion.hoverIn`（70ms），与其它控件一致
///
/// 其它平台退回 Material 的 [SegmentedButton]。
class AppSegmentedButton<T> extends StatelessWidget {
  const AppSegmentedButton({
    super.key,
    required this.segments,
    required this.selected,
    required this.onSelected,
  }) : assert(segments.length > 0);

  final List<AppSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    if (resolveAppUiStyle() != AppUiStyle.fluent) {
      return SegmentedButton<T>(
        segments: [
          for (final s in segments)
            ButtonSegment<T>(
              value: s.value,
              icon: s.icon == null ? null : Icon(s.icon, size: 18),
              label: s.label.isEmpty ? null : Text(s.label),
            ),
        ],
        selected: {selected},
        showSelectedIcon: false,
        onSelectionChanged: (values) {
          if (values.isNotEmpty) onSelected(values.first);
        },
      );
    }

    final p = FluentPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: p.stroke, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final s in segments)
            _FluentSegment(
              label: s.label,
              icon: s.icon,
              selected: s.value == selected,
              onTap: () => onSelected(s.value),
            ),
        ],
      ),
    );
  }
}

class _FluentSegment extends StatefulWidget {
  const _FluentSegment({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_FluentSegment> createState() => _FluentSegmentState();
}

class _FluentSegmentState extends State<_FluentSegment> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = FluentPalette.of(context);

    final Color bg;
    if (widget.selected) {
      bg = p.card;
    } else {
      bg = Colors.transparent;
    }

    final Color fg;
    if (widget.selected) {
      fg = p.textPrimary;
    } else if (_hovering) {
      fg = p.textPrimary;
    } else {
      fg = p.textSecondary;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: FluentMotion.hoverIn,
          curve: FluentMotion.decelerate,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(3),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 18, color: fg),
                if (widget.label.isNotEmpty) const SizedBox(width: 6),
              ],
              if (widget.label.isNotEmpty)
                Text(
                  widget.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    color: fg,
                    fontWeight:
                        widget.selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
