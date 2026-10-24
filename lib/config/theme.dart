import 'dart:io' show Platform, Process;

import 'package:flutter/material.dart';
import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:oasx/service/acrylic_service.dart';

/// scaffold 是否让出透明底。
///
/// 两种情况需要透明：
/// 1. 桌面：系统窗口材质（Mica）已生效，Flutter 实色会盖住它
/// 2. 移动端：没有系统材质，但 `FrostedBars` 的 BackdropFilter 只能模糊
///    "下方已绘制的内容"；scaffold 若为实色，底栏/AppBar 下无物可糊，
///    毛玻璃在视觉上等于不存在
bool get _usesTransparentScaffold =>
    AcrylicService.transparentBackground ||
    AcrylicService.mobileFrostedBackground;

/// 系统强调色缓存（Win11 原生应用的标准行为：跟随用户在系统设置里
/// 选的强调色）。启动时由 [initSystemAccentColor] 读一次注册表。
Color? _systemAccent;

/// Windows 默认强调色（读不到注册表时的回退值）。
const Color _fallbackAccent = Color(0xFF0078D4);

/// 读取系统强调色（`HKCU\...\DWM\ColorizationColor`，0xAARRGGBB）。
///
/// 必须在 runApp 之前 await——主题 getter 是同步的，强调色要提前就位。
Future<void> initSystemAccentColor() async {
  if (!Platform.isWindows) {
    _systemAccent = _fallbackAccent;
    return;
  }
  try {
    final result = await Process.run('reg', [
      'query',
      r'HKCU\Software\Microsoft\Windows\DWM',
      '/v',
      'ColorizationColor',
    ]);
    final match = RegExp(
      r'0x([0-9a-fA-F]+)',
    ).firstMatch(result.stdout.toString().trim());
    if (match == null) {
      _systemAccent = _fallbackAccent;
      return;
    }
    // DWORD 是 0xAARRGGBB；实际存储的 alpha 常为 00，强制不透明
    final value = int.parse(match.group(1)!, radix: 16);
    _systemAccent = Color(value | 0xFF000000);
  } catch (_) {
    _systemAccent = _fallbackAccent;
  }
}

/// 当前强调色（系统色，回退 Windows 默认蓝）。
Color get accentColor => _systemAccent ?? _fallbackAccent;

/// 深浅底上该配的文字色（亮度判定，与 FluentTokens._onColor 同逻辑）。
Color _onColorFor(Color bg) =>
    bg.computeLuminance() > 0.5 ? const Color(0xFF1B1B1B) : Colors.white;

/// 浅色主题。
///
/// **必须是 getter**：`scaffoldBackgroundColor` 依赖
/// `AcrylicService.transparentBackground`，而后者会在运行时
/// 随毛玻璃开关变化。写成顶层变量的话只在启动时求值一次，
/// 关闭毛玻璃后主题仍停留在旧值，界面会变成黑灰。
ThemeData get lightTheme => ThemeData(
  colorScheme: _lightScheme(accentColor),
  useMaterial3: true,
  brightness: Brightness.light,
  textTheme: const TextTheme(
    bodyLarge: TextStyle(),
    bodyMedium: TextStyle(),
    bodySmall: TextStyle(),
    labelLarge: TextStyle(),
    labelMedium: TextStyle(),
    labelSmall: TextStyle(),
    titleLarge: TextStyle(),
    titleMedium: TextStyle(),
    // titleMedium: TextStyle(fontWeight: FontWeight.w600),
    titleSmall: TextStyle(),
  ).apply(fontFamily: 'LatoLato').useSystemChineseFont(Brightness.light),
  // 桌面材质生效时完全透明（让系统 Mica 透出）；
  // 移动端同样透明——那里没有系统材质，但 FrostedBars 的 BackdropFilter
  // 只能模糊"下方已绘制的内容"，scaffold 若是实色则底栏/AppBar 下无物可糊。
  scaffoldBackgroundColor: _usesTransparentScaffold
      ? Colors.transparent
      : const Color(0xFFFBF9FF),
  navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Color.fromRGBO(255, 251, 255, 1)),
  // 卡片统一观感：16px 圆角 + 细描边 + 极低阴影（移动端柔和现代）
  // Glassmorphism：半透明玻璃卡片，让底层 Acrylic 自然晕染
  cardTheme: CardThemeData(
    // 轻微抬升，配合 shadowColor 产生弥散阴影（玻璃"浮"起来）
    elevation: 2,
    shadowColor: Colors.black.withValues(alpha: 0.05),
    // 材质生效时用半透明白；否则回退到接近实色的浅白。
    //
    // 0.48 是观感与可读性的平衡点：
    // - 0.35 太透，深色壁纸透上来后深色文字对比度不足
    // - 0.68 可读性够但整窗发白，材质感明显变弱（用户反馈"不好看"）
    color: AcrylicService.transparentBackground
        ? Colors.white.withValues(alpha: 0.48)
        : Colors.white.withValues(alpha: 0.92),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      // 玻璃高光边框：边缘一圈半透明白，制造"厚度感"
      side: BorderSide(
        color: Colors.white.withValues(alpha: 0.5),
        width: 1,
      ),
    ),
    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  ),

  // 弹出菜单（PopupMenuButton / DropdownButton 的浮层）。
  //
  // WinUI 的 MenuFlyout：圆角 8、浅色卡片底、1px 描边、无重阴影。
  // Material 默认是直角 + 深阴影 + 44 行高，观感差别明显。
  popupMenuTheme: PopupMenuThemeData(
    color: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 8,
    shadowColor: Colors.black.withValues(alpha: 0.14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
    ),
    textStyle: const TextStyle(fontSize: 13, color: Color(0xFF1B1B1B)),
  ),
  dropdownMenuTheme: DropdownMenuThemeData(
    menuStyle: MenuStyle(
      backgroundColor: const WidgetStatePropertyAll(Colors.white),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      elevation: const WidgetStatePropertyAll(8),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
      ),
    ),
  ),

  // FAB（服务器页的部署按钮）：强调色圆钮。WinUI 没有对应物，
  // 取「强调色 + 圆形」的精神与整体观感保持一致；底色由主题 seedColor 决定。
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    elevation: 4,
    focusElevation: 4,
    hoverElevation: 6,
    highlightElevation: 8,
    shape: const CircleBorder(),
  ),
);

// AMOLED 纯黑深色主题：设置页可切换（OLED 省电 + 对比度拉满）
ThemeData get amoledDarkTheme => darkTheme.copyWith(
  scaffoldBackgroundColor: _usesTransparentScaffold
      ? Colors.transparent
      : Colors.black,
  navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Colors.black),
  cardTheme: darkTheme.cardTheme.copyWith(
    color: const Color(0xFF121212),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
    ),
  ),

  // FAB：同浅色，深色下由 Material 自动取 seedColor 的深色变体。
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    elevation: 4,
    focusElevation: 4,
    hoverElevation: 6,
    highlightElevation: 8,
    shape: const CircleBorder(),
  ),
);

ThemeData get darkTheme => ThemeData(
  useMaterial3: true,
  colorScheme: _darkScheme(accentColor),
  brightness: Brightness.dark,
  textTheme: const TextTheme(
    bodyLarge: TextStyle(),
    bodyMedium: TextStyle(),
    bodySmall: TextStyle(),
    labelLarge: TextStyle(),
    labelMedium: TextStyle(),
    labelSmall: TextStyle(),
    titleLarge: TextStyle(),
    titleMedium: TextStyle(),
    titleSmall: TextStyle(),
  ).apply(fontFamily: 'LatoLato').useSystemChineseFont(Brightness.dark),
  scaffoldBackgroundColor: _usesTransparentScaffold
      ? Colors.transparent
      : const Color.fromRGBO(49, 48, 51, 1),
  navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Color.fromRGBO(49, 48, 51, 1)),
  // Glassmorphism（深色）：半透明黑 + 白色高光边框
  cardTheme: CardThemeData(
    elevation: 2,
    shadowColor: Colors.black.withValues(alpha: 0.18),
    // 深色下卡片要比浅色更实（0.30 → 0.55）：
    // acrylic 会把壁纸的亮色透上来，卡片太透会让白字失去对比度
    color: AcrylicService.transparentBackground
        ? Colors.black.withValues(alpha: 0.55)
        : const Color(0xFF2A2A2E),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.18), width: 1),
    ),
    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  ),

  // 深色菜单：比页面底亮一档 + 白色半透明描边（与 AppCard 一致）
  popupMenuTheme: PopupMenuThemeData(
    color: const Color(0xFF2C2C2C),
    surfaceTintColor: Colors.transparent,
    elevation: 8,
    shadowColor: Colors.black.withValues(alpha: 0.30),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: Color(0x26FFFFFF), width: 1),
    ),
    textStyle: const TextStyle(fontSize: 13, color: Color(0xFFFFFFFF)),
  ),
  dropdownMenuTheme: DropdownMenuThemeData(
    menuStyle: MenuStyle(
      backgroundColor: const WidgetStatePropertyAll(Color(0xFF2C2C2C)),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      elevation: const WidgetStatePropertyAll(8),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0x26FFFFFF), width: 1),
        ),
      ),
    ),
  ),
);


/// 浅色 ColorScheme：WinUI 实际观感值，不走 M3 tonal 调色。
///
/// M3 的 tonal 浅色底偏紫/偏灰白，不像 Windows 软件；这里 primary 用
/// 系统强调色，surface/outline/error 用 Fluent 体系的值。
ColorScheme _lightScheme(Color accent) {
  final onAccent = _onColorFor(accent);
  final onAccentSoft = Color.alphaBlend(
    accent.withValues(alpha: 0.60),
    Colors.black,
  );
  return ColorScheme(
    brightness: Brightness.light,
    primary: accent,
    onPrimary: onAccent,
    primaryContainer: Color.alphaBlend(
      accent.withValues(alpha: 0.20),
      Colors.white,
    ),
    onPrimaryContainer: onAccentSoft,
    secondary: accent,
    onSecondary: onAccent,
    secondaryContainer: Color.alphaBlend(
      accent.withValues(alpha: 0.14),
      Colors.white,
    ),
    onSecondaryContainer: onAccentSoft,
    tertiary: accent,
    onTertiary: onAccent,
    surface: const Color(0xFFF3F3F3),
    onSurface: const Color(0xFF1B1B1B),
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: const Color(0xFFFAFAFA),
    surfaceContainer: const Color(0xFFF3F3F3),
    surfaceContainerHigh: const Color(0xFFEEEEEE),
    surfaceContainerHighest: const Color(0xFFE5E5E5),
    onSurfaceVariant: const Color(0xFF5D5D5D),
    outline: const Color(0xFFC8C8C8),
    outlineVariant: const Color(0xFFE5E5E5),
    error: const Color(0xFFC50F1F),
    onError: Colors.white,
    errorContainer: const Color(0xFFFDE7E9),
    onErrorContainer: const Color(0xFF8E1B2A),
    inverseSurface: const Color(0xFF202020),
    onInverseSurface: const Color(0xFFFFFFFF),
    inversePrimary: accent,
    scrim: Colors.black,
  );
}

/// 深色 ColorScheme：比页面底亮一档的层级色 + 白系描边。
ColorScheme _darkScheme(Color accent) {
  final onAccent = _onColorFor(accent);
  final base = const Color(0xFF202020);
  return ColorScheme(
    brightness: Brightness.dark,
    primary: accent,
    onPrimary: onAccent,
    primaryContainer: Color.alphaBlend(
      accent.withValues(alpha: 0.35),
      base,
    ),
    onPrimaryContainer: Color.alphaBlend(
      accent.withValues(alpha: 0.55),
      Colors.white,
    ),
    secondary: accent,
    onSecondary: onAccent,
    secondaryContainer: Color.alphaBlend(
      accent.withValues(alpha: 0.25),
      base,
    ),
    onSecondaryContainer: const Color(0xFFE8E8E8),
    tertiary: accent,
    onTertiary: onAccent,
    surface: base,
    onSurface: const Color(0xFFFFFFFF),
    surfaceContainerLowest: const Color(0xFF1A1A1A),
    surfaceContainerLow: base,
    surfaceContainer: const Color(0xFF272727),
    surfaceContainerHigh: const Color(0xFF2C2C2C),
    surfaceContainerHighest: const Color(0xFF323232),
    onSurfaceVariant: const Color(0xFFC8C8C8),
    outline: const Color(0x66FFFFFF),
    outlineVariant: const Color(0x26FFFFFF),
    error: const Color(0xFFFF99A4),
    onError: const Color(0xFF390C13),
    errorContainer: const Color(0xFF3F1A1A),
    onErrorContainer: const Color(0xFFFFC7C7),
    inverseSurface: const Color(0xFFF3F3F3),
    onInverseSurface: const Color(0xFF1B1B1B),
    inversePrimary: accent,
    scrim: Colors.black,
  );
}