import 'package:flutter/material.dart';

import 'package:oasx/ui/impl/fluent/fluent_tokens.dart';
import 'package:oasx/ui/style.dart';

/// 跨平台语义分割线。
///
/// **只调整深色主题**：深色下用 [FluentPalette.stroke]（white 15%，
/// 比底色亮一档），避免深色材质上出现黑线；浅色保持 Material 的
/// `outlineVariant` 不变（改它会让浅色观感发生用户没要求的变化）。
///
/// 其它平台一律走 Material 的 `outlineVariant`。
class AppDivider extends StatelessWidget {
  const AppDivider({
    super.key,
    this.height = 1,
    this.indent = 0,
    this.endIndent = 0,
    this.vertical = false,
  });

  /// 占位高度（水平）/ 宽度（竖直）。
  final double height;

  /// 左侧缩进。
  final double indent;

  /// 右侧缩进。
  final double endIndent;

  /// 是否竖直方向（用于侧栏与内容之间的分界）。
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isFluent = resolveAppUiStyle() == AppUiStyle.fluent;
    final Color color;
    if (isFluent && FluentPalette.of(context).isDark) {
      // 深色：白色半透明描边，在深色材质上是"比背景亮的分界线"
      color = FluentPalette.of(context).stroke;
    } else {
      // 浅色 / 非 Windows：保持原有观感
      color = scheme.outlineVariant;
    }

    if (vertical) {
      return VerticalDivider(
        width: height,
        thickness: 1,
        indent: indent,
        endIndent: endIndent,
        color: color,
      );
    }
    return Divider(
      height: height,
      thickness: 1,
      indent: indent,
      endIndent: endIndent,
      color: color,
    );
  }
}
