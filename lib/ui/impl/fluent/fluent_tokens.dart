import 'package:flutter/material.dart';

import 'package:oasx/ui/style.dart';

/// Fluent Design 的语义色板。
///
/// WinUI 3 的配色逻辑与 M3 不同：它不用"色调叠加"（tonal surface），
/// 而是分层（Layer）+ 极浅的中性色阶，配合 1px 细描边表现层级。
///
/// 参考 Windows 11 的实际取值（取自 Fluent Design System 公开文档）：
/// - 浅色：背景 #F3F3F3，卡片 #FFFFFF，描边 #E5E5E5
/// - 深色：背景 #202020，卡片 #2C2C2C，描边 #3D3D3D
class FluentPalette {
  const FluentPalette({
    required this.isDark,
    required this.accent,
    required this.onAccent,
    required this.layer,
    required this.layerAlt,
    required this.card,
    required this.cardHover,
    required this.cardPressed,
    required this.stroke,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.subtleHover,
    required this.subtlePressed,
  });

  /// 浅色 / 深色。
  final bool isDark;

  /// 强调色（Win11 默认蓝；这里从 App 主题的主色借用，保持品牌一致）。
  final Color accent;
  final Color onAccent;

  /// 窗口/页面底色。
  final Color layer;

  /// 次层底色（侧栏、分组）。
  final Color layerAlt;

  /// 卡片底色。
  final Color card;

  /// 卡片悬停 / 按下。
  final Color cardHover;
  final Color cardPressed;

  /// 1px 细描边。
  final Color stroke;

  /// 三级文字色。
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  /// 轻量按钮的悬停 / 按下底色。
  final Color subtleHover;
  final Color subtlePressed;

  /// 列表行的悬停 / 按下高亮（SubtleFill 系列）。
  ///
  /// WinUI 的规范里**按压比悬停更浅**（0.06 → 0.04），
  /// 不是"越按越深"。这样做是为了避免快速点击时出现
  /// "浅→深→浅"的明暗反复，那在视觉上就是闪烁。
  Color get rowHover => isDark
      ? const Color(0x0FFFFFFF)
      : const Color(0x0F000000);

  Color get rowPressed => isDark
      ? const Color(0x0AFFFFFF)
      : const Color(0x0A000000);

  /// 从 Flutter 主题推导一套 Fluent 色板。
  ///
  /// 强调色沿用 App 主题（`colorScheme.primary`），这样品牌色一致；
  /// 其余色阶用 Win11 的实际观感值，而不是 M3 的 tonal 体系——
  /// 后者的浅色底往往偏紫/偏白，不像 Windows 软件。
  factory FluentPalette.of(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // 用 theme.brightness 而不是 colorScheme.brightness：
    // 后者在只设了 `ThemeData(brightness: ...)` 而没显式给 colorScheme 时
    // 可能与实际主题不符。
    final dark = theme.brightness == Brightness.dark;
    final accent = scheme.primary;

    if (dark) {
      return FluentPalette(
        isDark: true,
        accent: accent,
        onAccent: _onColor(accent),
        layer: const Color(0xFF202020),
        layerAlt: const Color(0xFF272727),
        card: const Color(0xFF2C2C2C),
        cardHover: const Color(0xFF323232),
        cardPressed: const Color(0xFF383838),
        stroke: const Color(0xFF3D3D3D),
        textPrimary: const Color(0xFFFFFFFF),
        textSecondary: const Color(0xFFC8C8C8),
        textTertiary: const Color(0xFF9A9A9A),
        subtleHover: const Color(0x14FFFFFF),
        subtlePressed: const Color(0x0FFFFFFF),
      );
    }
    return FluentPalette(
      isDark: false,
      accent: accent,
      onAccent: _onColor(accent),
      layer: const Color(0xFFF3F3F3),
      layerAlt: const Color(0xFFEEEEEE),
      card: const Color(0xFFFFFFFF),
      cardHover: const Color(0xFFF9F9F9),
      cardPressed: const Color(0xFFF0F0F0),
      stroke: const Color(0xFFE5E5E5),
      textPrimary: const Color(0xFF1B1B1B),
      textSecondary: const Color(0xFF5D5D5D),
      textTertiary: const Color(0xFF8A8A8A),
      subtleHover: const Color(0x0A000000),
      subtlePressed: const Color(0x0F000000),
    );
  }

  /// 计算叠在 [bg] 上时该用白字还是黑字。
  static Color _onColor(Color bg) {
    // 相对亮度阈值，0.5 是常用分界
    return bg.computeLuminance() > 0.5
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);
  }

  /// 悬停层颜色插值（用于 AnimatedContainer）。
  Color hoverLerp(Color base, Color target, double t) {
    return Color.lerp(base, target, t) ?? base;
  }
}

/// Fluent 的圆角规格。
///
/// WinUI 3 比 M3 更"方"：4px 用于小控件、8px 用于卡片。
/// 之前统一用 [AppRadius] 的 8/12/16 在 Windows 上会显得过于圆润。
class FluentRadius {
  FluentRadius._();

  /// 小控件（按钮、输入框）。
  static const double control = 4;

  /// 中等容器（卡片、面板）。
  static const double card = 8;

  /// 大容器（对话框）。
  static const double dialog = 8;

  static BorderRadius get controlRadius => BorderRadius.circular(control);
  static BorderRadius get cardRadius => BorderRadius.circular(card);
  static BorderRadius get dialogRadius => BorderRadius.circular(dialog);
}

/// Fluent 的阴影规格。
///
/// WinUI 3 极其克制：默认卡片几乎无阴影，靠描边表达层级；
/// 只有弹出层（Flyout/Dialog）才有明显投影。
class FluentElevation {
  FluentElevation._();

  /// 无阴影（默认卡片）。
  static const List<BoxShadow> none = [];

  /// 轻微阴影（悬停状态）。
  static const List<BoxShadow> subtle = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  /// 弹出层阴影（对话框、菜单）。
  static const List<BoxShadow> flyout = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
}

/// Fluent 的动效曲线。
///
/// WinUI 用的是 FluentMotion，特点是从快到慢的强减速。
/// 对比 M3 的 easeOutCubic，Fluent 的曲线更"急"。
class FluentMotion {
  FluentMotion._();

  /// 标准曲线（WinUI 的 FastOutSlowIn）。
  static const Curve standard = Cubic(0.33, 0.0, 0.67, 1.0);

  /// 减速曲线（进入）。
  static const Curve decelerate = Cubic(0.1, 0.9, 0.2, 1.0);

  /// 悬停/按压反馈时长。
  static const Duration fast = Duration(milliseconds: 100);

  /// 悬停反馈时长。
  ///
  /// 比 [fast] 更短：交互反馈要"跟手"，100ms 在快速划过时
  /// 会感觉颜色追不上指针，读起来像卡顿。
  static const Duration hoverIn = Duration(milliseconds: 70);

  /// 展开/收起。
  static const Duration normal = Duration(milliseconds: 200);
}
