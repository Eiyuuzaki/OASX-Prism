import 'package:flutter/material.dart';

import 'package:oasx/ui/impl/fluent/fluent_tokens.dart';
import 'package:oasx/ui/style.dart';

/// 跨平台语义标签（Chip）。
///
/// Windows 上是 WinUI 的 Pill / Tag：**圆角胶囊**，浅底 + 细描边，
/// 可选前置图标。
///
/// ```
/// ╭──────────╮   ╭────────╮
/// │ ⚡ 百鬼棋局 │   │ 已启用  │
/// ╰──────────╯   ╰────────╯
/// ```
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.onTap,
    this.selected = false,
  });

  final String label;

  /// 可选前置图标。
  final IconData? icon;

  /// 强调色（默认用主题的次级文字色）。
  final Color? color;

  final VoidCallback? onTap;

  /// 是否处于选中态（加强调色底）。
  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (resolveAppUiStyle() != AppUiStyle.fluent) {
      // 不能把点击语义塞进 `onDeleted`：那会在 chip 上渲染一个 ✕ 删除
      // 图标，点它执行的却是 onTap——视觉（"可删除"）与行为（"切换"）
      // 对不上。可点击就用 ActionChip，不可点击才用纯展示的 Chip。
      if (onTap == null) {
        return Chip(
          label: Text(label),
          avatar: icon == null ? null : Icon(icon, size: 16),
        );
      }
      return ActionChip(
        label: Text(label),
        avatar: icon == null ? null : Icon(icon, size: 16),
        onPressed: onTap,
      );
    }

    return _FluentChip(
      label: label,
      icon: icon,
      tint: color,
      selected: selected,
      onTap: onTap,
    );
  }
}

class _FluentChip extends StatefulWidget {
  const _FluentChip({
    required this.label,
    required this.selected,
    this.icon,
    this.tint,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final Color? tint;
  final bool selected;
  final VoidCallback? onTap;

  @override
  State<_FluentChip> createState() => _FluentChipState();
}

class _FluentChipState extends State<_FluentChip> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = FluentPalette.of(context);

    final tint = widget.tint ?? p.textSecondary;
    final Color bg;
    final Color fg;
    if (widget.selected) {
      bg = tint.withValues(alpha: 0.16);
      fg = tint;
    } else if (_hovering && widget.onTap != null) {
      bg = p.subtleHover;
      fg = p.textPrimary;
    } else {
      bg = p.isDark ? const Color(0x14FFFFFF) : const Color(0x0A000000);
      fg = p.textSecondary;
    }

    return MouseRegion(
      cursor: widget.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: FluentMotion.hoverIn,
          curve: FluentMotion.decelerate,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 12, color: fg),
                const SizedBox(width: 4),
              ],
              Text(
                widget.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  color: fg,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
