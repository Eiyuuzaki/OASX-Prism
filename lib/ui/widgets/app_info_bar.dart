import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:oasx/ui/impl/fluent/fluent_tokens.dart';
import 'package:oasx/ui/style.dart';

/// 消息提示的语义级别（对应 WinUI InfoBar 的 Severity）。
enum AppInfoBarSeverity { info, success, warning, error }

/// 跨平台语义提示条。
///
/// Windows 上是 WinUI 的 **InfoBar**：圆角 4、浅色底（不是深色块）、
/// 左侧状态图标、右上角关闭按钮，悬浮在窗口顶部。
///
/// ```
/// ┌──────────────────────────────────────────┐
/// │ ⓘ  标题                               ✕  │
/// │    详细说明                              │
/// └──────────────────────────────────────────┘
/// ```
///
/// 与 Material SnackBar 的区别：SnackBar 是**深色胶囊贴底**，
/// InfoBar 是**浅色卡片浮在顶部**——后者才是 Windows 的观感。
class AppInfoBar {
  AppInfoBar._();

  /// 显示一条提示。默认 4 秒后自动消失。
  static void show(
    String title, {
    String? message,
    AppInfoBarSeverity severity = AppInfoBarSeverity.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (resolveAppUiStyle() != AppUiStyle.fluent) {
      // 其它平台保持 Material 的 SnackBar 观感
      Get.snackbar(title, message ?? '', duration: duration);
      return;
    }

    final p = _paletteFor(severity, Get.context);
    final icon = _iconFor(severity);

    Get.snackbar(
      '',
      '',
      titleText: Row(
        children: [
          Icon(icon, size: 18, color: p.fg),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: p.fg,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (message != null && message.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: TextStyle(
                      color: p.fg.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      messageText: const SizedBox.shrink(),
      backgroundColor: p.bg,
      colorText: p.fg,
      borderRadius: FluentRadius.control,
      margin: const EdgeInsets.fromLTRB(0, 12, 0, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      duration: duration,
      snackPosition: SnackPosition.TOP,
      snackStyle: SnackStyle.FLOATING,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: FluentMotion.decelerate,
      reverseAnimationCurve: FluentMotion.decelerate,
      animationDuration: const Duration(milliseconds: 180),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static ({Color bg, Color fg}) _paletteFor(
    AppInfoBarSeverity severity,
    BuildContext? context,
  ) {
    final dark = Theme.of(context ?? Get.context!).brightness ==
        Brightness.dark;
    return switch (severity) {
      AppInfoBarSeverity.info => dark
          ? (bg: const Color(0xFF2C2C2C), fg: const Color(0xFFE8E8E8))
          : (bg: const Color(0xFFF3F3F3), fg: const Color(0xFF1B1B1B)),
      AppInfoBarSeverity.success => dark
          ? (bg: const Color(0xFF1F3A24), fg: const Color(0xFFB6EFC2))
          : (bg: const Color(0xFFDFF6DD), fg: const Color(0xFF0F5127)),
      AppInfoBarSeverity.warning => dark
          ? (bg: const Color(0xFF3D3319), fg: const Color(0xFFFFE08A))
          : (bg: const Color(0xFFFFF4CE), fg: const Color(0xFF6B4E00)),
      AppInfoBarSeverity.error => dark
          ? (bg: const Color(0xFF3F1A1A), fg: const Color(0xFFFFC7C7))
          : (bg: const Color(0xFFFDE7E9), fg: const Color(0xFF8E1B2A)),
    };
  }

  static IconData _iconFor(AppInfoBarSeverity severity) => switch (severity) {
        AppInfoBarSeverity.info => Icons.info_outline_rounded,
        AppInfoBarSeverity.success => Icons.check_circle_outline_rounded,
        AppInfoBarSeverity.warning => Icons.warning_amber_rounded,
        AppInfoBarSeverity.error => Icons.error_outline_rounded,
      };
}
