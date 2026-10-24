import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';

import 'package:oasx/ui/ui.dart';

/// 设置项行：左边是图标/标题/说明，右边是控件。
///
/// Windows 上按 Win11 设置页（及 Legion Toolkit）的规格：
/// - 行高更大（最小 56），左右内缩 16，让内容有呼吸感
/// - 可选 **前置图标** 与**灰色说明文字**——这是 Win11 设置行
///   最有辨识度的结构：`[图标] 标题 / 说明 ........ [控件]`
/// - 整行可点击时悬停高亮（`onTap` 非空才启用）
/// - 不用涟漪（Fluent 的交互反馈是整块变色）
///
/// 其它平台保持原来的紧凑 Material 观感（忽略 icon/description）。
class SettingItem extends StatelessWidget {
  final Widget left;
  final Widget right;
  final VoidCallback? onTap;

  /// 可选前置图标（Fluent 下显示在标题左侧）。
  final IconData? icon;

  /// 可选说明文字（Fluent 下显示在标题下方，次级文字色）。
  final String? description;

  const SettingItem({
    super.key,
    required this.left,
    required this.right,
    this.onTap,
    this.icon,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    if (resolveAppUiStyle() == AppUiStyle.fluent) {
      return _buildFluent(context);
    }
    return _buildMaterial();
  }

  Widget _buildMaterial() {
    final row = <Widget>[
      left,
      const SizedBox(width: 8),
      right,
    ]
        .toRow(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
        )
        .padding(vertical: 4);
    return onTap == null
        ? row
        : InkWell(
            onTap: onTap,
            child: row,
          );
  }

  Widget _buildFluent(BuildContext context) {
    final theme = Theme.of(context);
    final p = FluentPalette.of(context);

    // 标题区：图标 +（标题 / 说明）
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        DefaultTextStyle.merge(
          style: theme.textTheme.bodyMedium?.copyWith(color: p.textPrimary),
          child: left,
        ),
        if (description != null) ...[
          const SizedBox(height: 2),
          Text(
            description!,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: p.textSecondary,
            ),
          ),
        ],
      ],
    );

    final labelArea = icon == null
        ? titleBlock
        : Row(
            crossAxisAlignment: description == null
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: description == null ? 0 : 2),
                child: Icon(icon, size: 20, color: p.textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(child: titleBlock),
            ],
          );

    final row = <Widget>[
      Expanded(child: labelArea),
      const SizedBox(width: 16),
      right,
    ].toRow(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
    );

    final padded = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Align(alignment: Alignment.centerLeft, child: row),
      ),
    );

    if (onTap == null) return padded;
    return _FluentRowTap(onTap: onTap!, child: padded);
  }
}

/// 整行悬停高亮（无涟漪）。
class _FluentRowTap extends StatefulWidget {
  const _FluentRowTap({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_FluentRowTap> createState() => _FluentRowTapState();
}

class _FluentRowTapState extends State<_FluentRowTap> {
  bool _hovering = false;
  bool _pressing = false;

  @override
  Widget build(BuildContext context) {
    final p = FluentPalette.of(context);
    // 用 decelerate 而不是 standard：后者的曲线是 easeInOut，
    // 开头一段几乎不动，悬停反馈会显得"卡一下才亮"。
    // decelerate（FastOutSlowIn）是立即响应、末端收慢，
    // 这才是 WinUI 悬停反馈该有的手感。
    final row = AnimatedContainer(
      duration: FluentMotion.hoverIn,
      curve: FluentMotion.decelerate,
      color: _pressing
          ? p.rowPressed
          : (_hovering ? p.rowHover : Colors.transparent),
      child: widget.child,
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() {
        _hovering = false;
        _pressing = false;
      }),
      child: GestureDetector(
        // opaque：整行都是热区，指针在文字空隙也能触发，
        // 避免"某些位置不响应"造成的断续感
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressing = true),
        onTapUp: (_) => setState(() => _pressing = false),
        onTapCancel: () => setState(() => _pressing = false),
        onTap: widget.onTap,
        child: row,
      ),
    );
  }
}
