import 'package:flutter/material.dart';

import 'package:oasx/ui/impl/fluent/fluent_tokens.dart';
import 'package:oasx/ui/style.dart';

/// 下拉项。
class AppDropdownItem<T> {
  const AppDropdownItem({required this.value, required this.label});

  final T value;
  final String label;
}

/// 跨平台语义下拉选择。
///
/// Windows 上是 WinUI 的 DropDownButton / ComboBox：
///
/// | | Material MenuAnchor + TextButton | WinUI ComboBox |
/// |---|---|---|
/// | 收起态 | 无边框文字按钮 | **控件底 + 1px 描边，圆角 4** |
/// | 展开态 | M3 菜单（大圆角 + tonal 底） | **卡片底 + 细描边，圆角 8** |
/// | 项高 | 48 | **32** |
/// | 选中项 | 右侧对勾（主色） | 左侧对勾 + 整项浅填充 |
///
/// 项高差异最明显：M3 的 48px 在 Windows 上显得非常松散。
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.icon,
    this.maxWidth = 200,
    this.dense = false,
    this.enabled = true,
    this.placeholder,
  });

  /// 当前选中值。
  final T value;

  /// 可选项；为空时整个组件不渲染（除非给了 [placeholder]）。
  final List<AppDropdownItem<T>> items;

  /// 选择回调。
  final ValueChanged<T> onChanged;

  /// 收起态的前置图标。
  final IconData? icon;

  /// 收起态文本的最大宽度（超出省略）。
  final double maxWidth;

  /// 紧凑模式（工具栏用）。
  final bool dense;

  /// 是否可用；false 时置灰且不可展开。
  final bool enabled;

  /// 当 [value] 不匹配任何项时显示的文案。
  ///
  /// 例如"角色未知"——此时并没有对应的下拉项，但仍要显示点东西。
  final String? placeholder;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && placeholder == null) return const SizedBox.shrink();

    final label = items
            .where((e) => e.value == value)
            .map((e) => e.label)
            .firstOrNull ??
        placeholder ??
        '';

    if (resolveAppUiStyle() != AppUiStyle.fluent) {
      return _buildMaterial(context, label);
    }
    return _buildFluent(context, label);
  }

  // ── Material：保持原来的 MenuAnchor + TextButton ──────────────
  Widget _buildMaterial(BuildContext context, String label) {
    final scheme = Theme.of(context).colorScheme;
    return MenuAnchor(
      menuChildren: [
        for (final item in items)
          MenuItemButton(
            onPressed: () => onChanged(item.value),
            child: Row(
              children: [
                Expanded(
                  child:
                      Text(item.label, overflow: TextOverflow.ellipsis),
                ),
                if (item.value == value) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.check_rounded, size: 18, color: scheme.primary),
                ],
              ],
            ),
          ),
      ],
      builder: (context, menu, _) {
        return TextButton.icon(
          onPressed: () => menu.isOpen ? menu.close() : menu.open(),
          icon: icon == null
              ? const SizedBox.shrink()
              : Icon(icon, size: 18),
          label: _collapsedLabel(context, label),
        );
      },
    );
  }

  // ── Fluent：WinUI ComboBox ────────────────────────────────────
  Widget _buildFluent(BuildContext context, String label) {
    final p = FluentPalette.of(context);
    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(p.card),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(8),
        shadowColor: WidgetStatePropertyAll(
          Colors.black.withValues(alpha: 0.18),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: 4),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: FluentRadius.cardRadius,
            side: BorderSide(color: p.stroke),
          ),
        ),
      ),
      menuChildren: [
        for (final item in items)
          _FluentMenuItem(
            label: item.label,
            selected: item.value == value,
            onTap: () => onChanged(item.value),
          ),
      ],
      builder: (context, menu, _) {
        return _FluentDropdownButton(
          icon: icon,
          dense: dense,
          open: menu.isOpen,
          enabled: enabled && items.isNotEmpty,
          onTap: () => menu.isOpen ? menu.close() : menu.open(),
          child: _collapsedLabel(context, label),
        );
      },
    );
  }

  Widget _collapsedLabel(BuildContext context, String label) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Fluent 的收起态按钮：控件底 + 1px 描边。
class _FluentDropdownButton extends StatefulWidget {
  const _FluentDropdownButton({
    required this.onTap,
    required this.child,
    this.icon,
    this.dense = false,
    this.open = false,
    this.enabled = true,
  });

  final VoidCallback onTap;
  final Widget child;
  final IconData? icon;
  final bool dense;
  final bool open;
  final bool enabled;

  @override
  State<_FluentDropdownButton> createState() => _FluentDropdownButtonState();
}

class _FluentDropdownButtonState extends State<_FluentDropdownButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = FluentPalette.of(context);
    final enabled = widget.enabled;
    final fg = enabled ? p.textPrimary : p.textTertiary;

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: enabled ? (_) => setState(() => _hovering = true) : null,
      onExit: enabled ? (_) => setState(() => _hovering = false) : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: FluentMotion.hoverIn,
          curve: FluentMotion.decelerate,
          height: widget.dense ? 28 : 32,
          padding: EdgeInsets.symmetric(
            horizontal: widget.dense ? 8 : 10,
          ),
          decoration: BoxDecoration(
            color: _hovering && enabled ? p.cardHover : p.card,
            borderRadius: FluentRadius.controlRadius,
            border: Border.all(color: p.stroke),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 14,
                  color: enabled ? p.textSecondary : p.textTertiary,
                ),
                const SizedBox(width: 6),
              ],
              DefaultTextStyle.merge(
                style: theme.textTheme.bodyMedium?.copyWith(color: fg),
                child: widget.child,
              ),
              const SizedBox(width: 6),
              // WinUI 的展开箭头是单独的小字形
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: enabled ? p.textSecondary : p.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fluent 的下拉项：32px 高，选中项左侧显示对勾并整项浅填充。
class _FluentMenuItem extends StatefulWidget {
  const _FluentMenuItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_FluentMenuItem> createState() => _FluentMenuItemState();
}

class _FluentMenuItemState extends State<_FluentMenuItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = FluentPalette.of(context);

    final Color fill;
    if (widget.selected) {
      fill = p.rowHover;
    } else if (_hovering) {
      fill = p.rowPressed;
    } else {
      fill = Colors.transparent;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          height: 32,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(FluentRadius.control),
          ),
          child: Row(
            children: [
              // 对勾在左侧留出固定位置，避免选中/未选中时文字跳动
              SizedBox(
                width: 20,
                child: widget.selected
                    ? Icon(Icons.check_rounded, size: 14, color: p.accent)
                    : null,
              ),
              Expanded(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: p.textPrimary,
                    fontWeight: widget.selected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
