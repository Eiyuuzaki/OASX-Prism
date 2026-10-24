import 'package:flutter/material.dart';

import 'package:oasx/ui/impl/fluent/fluent_tokens.dart';
import 'package:oasx/ui/style.dart';

/// 页面头部：标题 + 可选描述 + 右侧主操作。
///
/// 这是 WinUI 页面结构的标准开头（设置、商店、Watt Toolkit 都是这个范式）：
///
/// ```
/// 页面标题                        [主操作]
/// 一句描述（可选）
/// ─────────────────────────────────────────
/// 内容卡片…
/// ```
///
/// 与 Material 的 AppBar 不同——标题属于**内容区**而不是顶部栏，
/// 会随内容一起滚动，顶部栏只放全局导航与窗口控制。
class AppPageHeader extends StatelessWidget {
  /// 创建页头。
  const AppPageHeader({
    super.key,
    required this.title,
    this.description,
    this.actions = const [],
  });

  /// 页面标题。
  final String title;

  /// 标题下的一句描述（说明这一页是做什么的）。
  final String? description;

  /// 右上角的操作按钮。
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fluent = resolveAppUiStyle() == AppUiStyle.fluent;
    final p = FluentPalette.of(context);

    final titleStyle = fluent
        // WinUI 的页面标题是 28px semibold，比 M3 的 headlineSmall 更紧凑
        ? theme.textTheme.headlineSmall?.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: p.textPrimary,
          )
        : theme.textTheme.headlineSmall;

    final descStyle = fluent
        ? theme.textTheme.bodyMedium?.copyWith(color: p.textSecondary)
        : theme.textTheme.bodyMedium
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                ),
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(width: 16),
                ...actions,
              ],
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: 4),
            Text(description!, style: descStyle),
          ],
        ],
      ),
    );
  }
}
