import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';

import 'package:oasx/ui/ui.dart';

/// 设置项行：左边是标题/说明，右边是控件。
///
/// Windows 上按 Win11 设置页的规格：
/// - 行高更大（最小 48），左右内缩 16，让内容有呼吸感
/// - 整行可点击时悬停高亮（`onTap` 非空才启用）
/// - 不用涟漪（Fluent 的交互反馈是整块变色）
///
/// 其它平台保持原来的紧凑 Material 观感。
class SettingItem extends StatelessWidget {
  final Widget left;
  final Widget right;
  final VoidCallback? onTap;

  const SettingItem({
    super.key,
    required this.left,
    required this.right,
    this.onTap,
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
    final row = <Widget>[
      Expanded(child: left),
      const SizedBox(width: 16),
      right,
    ].toRow(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
    );

    final padded = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
