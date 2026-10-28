import 'package:flutter/material.dart';

import 'package:oasx/ui/impl/fluent/fluent_tokens.dart';
import 'package:oasx/ui/style.dart';
import 'package:oasx/ui/ui.dart';

/// 跨平台语义进度指示器。
///
/// Windows 上是 WinUI 的 ProgressRing / ProgressBar：
///
/// - **环形**：细环（2.5px 描边），强调色，带缓动旋转
/// - **线性**：细条（3px），圆角端点，强调色
///
/// 与 Material 的区别：WinUI 的指示器**更细、更克制**，没有 Material
/// 那种粗壮感；不确定态用一段循环滑动的短弧而不是整圈跳动。
class AppProgressIndicator extends StatelessWidget {
  const AppProgressIndicator._({
    this.value,
    this.size = 20,
    this.strokeWidth,
    this.linear = false,
  });

  /// 环形进度指示器。[value] 为 null 表示不确定进度（转圈）。
  const AppProgressIndicator.circular({
    Key? key,
    double? value,
    double size = 20,
    double? strokeWidth,
  }) : this._(value: value, size: size, strokeWidth: strokeWidth)
       ;

  /// 线性进度条。[value] 为 null 表示不确定进度（循环滑动）。
  const AppProgressIndicator.linear({
    Key? key,
    double? value,
  }) : this._(value: value, linear: true);

  final double? value;
  final double size;
  final double? strokeWidth;
  final bool linear;

  @override
  Widget build(BuildContext context) {
    if (resolveAppUiStyle() != AppUiStyle.fluent) {
      // 非 Fluent 平台直接用 Material 原生控件。
      //
      // **不要返回 `AppProgressIndicator.linear(...)`**：构造出来的仍是
      // linear 实例，build 会再次进入这个分支，无限递归到栈溢出
      // （Android / Web / Linux 上渲染线性进度条即崩溃）。
      return linear
          ? LinearProgressIndicator(value: value)
          : SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: strokeWidth ?? 2.5,
              ),
            );
    }

    final p = FluentPalette.of(context);
    return linear
        ? _FluentLinearProgress(value: value, color: p.accent)
        : SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: strokeWidth ?? 2.5,
              color: p.accent,
              backgroundColor: p.stroke,
              strokeCap: StrokeCap.round,
            ),
          );
  }
}

/// WinUI 的线性进度条：细、圆角端点。
class _FluentLinearProgress extends StatelessWidget {
  const _FluentLinearProgress({required this.value, required this.color});

  final double? value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (value != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(1.5),
        child: LinearProgressIndicator(
          value: value,
          minHeight: 3,
          color: color,
          backgroundColor:
              FluentPalette.of(context).stroke,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(1.5),
      child: LinearProgressIndicator(
        minHeight: 3,
        color: color,
        backgroundColor: FluentPalette.of(context).stroke,
      ),
    );
  }
}
