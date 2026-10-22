import 'package:flutter/material.dart';

import 'package:oasx/ui/impl/fluent/fluent_tokens.dart';
import 'package:oasx/ui/style.dart';

/// 跨平台语义对话框。
///
/// Windows 上是 WinUI 的 ContentDialog：
///
/// | | Material AlertDialog | WinUI ContentDialog |
/// |---|---|---|
/// | 宽度 | 跟随内容，最小 280 | **固定上限 548**，常用 320 |
/// | 圆角 | 28（M3 大圆角） | **8** |
/// | 标题 | titleLarge 24px | **20px semibold** |
/// | 内边距 | 24 | **24** |
/// | 按钮位置 | 右下 | 右下，**间距 8** |
/// | 遮罩 | `black54` | **`rgba(0,0,0,0.3)` 烟幕** |
///
/// M3 的 28px 大圆角在 Windows 上非常突兀，这是两者最容易辨认的差异。
class AppDialog extends StatelessWidget {
  /// 创建语义对话框。
  const AppDialog({
    super.key,
    this.title,
    this.content,
    this.actions = const [],
    this.maxWidth = 420,
  });

  /// 标题（可为空）。
  final Widget? title;

  /// 正文。
  final Widget? content;

  /// 底部操作按钮（通常最后一个是最主要的操作）。
  final List<Widget> actions;

  /// 最大宽度。WinUI 的 ContentDialog 上限是 548。
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return resolveAppUiStyle() == AppUiStyle.fluent
        ? _buildFluent(context)
        : _buildMaterial(context);
  }

  Widget _buildMaterial(BuildContext context) {
    return AlertDialog(
      title: title,
      content: content,
      actions: actions,
    );
  }

  Widget _buildFluent(BuildContext context) {
    final theme = Theme.of(context);
    final p = FluentPalette.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          decoration: BoxDecoration(
            color: p.isDark ? p.card : p.layer,
            borderRadius: FluentRadius.cardRadius,
            border: Border.all(color: p.stroke),
            boxShadow: FluentElevation.flyout,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title != null)
                      DefaultTextStyle.merge(
                        // WinUI ContentDialog 的标题是 20px semibold
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: p.textPrimary,
                        ),
                        child: title!,
                      ),
                    if (title != null && content != null)
                      const SizedBox(height: 12),
                    if (content != null)
                      DefaultTextStyle.merge(
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: p.textSecondary),
                        child: content!,
                      ),
                  ],
                ),
              ),
              if (actions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      for (var i = 0; i < actions.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        actions[i],
                      ],
                    ],
                  ),
                )
              else
                const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// 以 WinUI 的观感弹出对话框。
///
/// 与直接 `showDialog` 的区别：遮罩用 WinUI 的烟幕色
/// （`rgba(0,0,0,0.3)`，比 Material 的 `black54` 淡），
/// 淡入时长也更短。
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  final fluent = resolveAppUiStyle() == AppUiStyle.fluent;
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: fluent ? const Color(0x4D000000) : null,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    builder: builder,
  );
}
