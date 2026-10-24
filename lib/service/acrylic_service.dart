import 'dart:ffi';
import 'dart:io' show Platform;

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:get/get.dart';

/// 窗口材质接入（flutter_acrylic + 少量 Win32 兜底）。
///
/// ## 材质优先级（实测结论）
///
/// 1. **Mica Alt（tabbed）**——DWM 托管，最小化/还原不丢，壁纸透出明显。
/// 2. **Mica**——更含蓄，后备。
/// 3. **Acrylic**——质感最强但最小化后会丢（Win11 已知问题，参数重设
///    无法唤醒），仅最后后备。
///
/// ## 为什么还要自己调 DwmExtendFrameIntoClientArea
///
/// flutter_acrylic 在设置 Mica/Tabbed 时会顺带设 `MARGINS{-1}` 让客户区
/// 透明，但实测（Win11 26200）DWM 属性设对了、视觉却仍是纯色——
/// 客户区被 Flutter 的不透明表面盖住。显式再设一次玻璃边距可让
/// 材质真正透出。
class AcrylicService {
  AcrylicService._();

  static bool _pluginReady = false;

  /// 材质是否已实际生效（供主题层判断要不要把背景设为透明）。
  static bool transparentBackground = false;

  /// 移动端是否需要透明 scaffold 底（供 `FrostedBars` 生效）。
  static bool get mobileFrostedBackground => _isMobile;

  /// 支持系统材质的平台。
  static bool get _supported =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS);

  /// 移动平台（Android/iOS）。
  static bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// 设备是否支持（不支持的平台不渲染相关 UI）。
  static bool get supported => _supported;

  /// 阶段一：插件初始化。**必须在 runApp 之前调用**。
  static Future<void> initializePlugin() async {
    if (!_supported) return;
    try {
      await Window.initialize();
      _pluginReady = true;
      debugPrint('AcrylicService: Window.initialize OK');
    } catch (e) {
      debugPrint('AcrylicService: Window.initialize failed: $e');
    }
  }

  /// 阶段二：应用材质。在窗口就绪之后调用。
  static Future<void> applyEffect({bool? dark}) async {
    if (!_supported || !_pluginReady) return;
    final useDark = dark ?? false;

    // 1) Mica Alt（tabbed）：DWM 托管 + 壁纸透出明显，首选。
    try {
      await Window.setEffect(effect: WindowEffect.tabbed, dark: useDark);
      transparentBackground = true;
      await _extendGlassIntoClientArea();
      debugPrint('AcrylicService: tabbed/mica-alt (dark=$useDark) OK');
      return;
    } catch (e) {
      debugPrint('AcrylicService: tabbed failed: $e');
    }

    // 2) Mica：更含蓄，后备。
    try {
      await Window.setEffect(effect: WindowEffect.mica, dark: useDark);
      transparentBackground = true;
      await _extendGlassIntoClientArea();
      debugPrint('AcrylicService: mica (dark=$useDark) OK');
      return;
    } catch (e) {
      debugPrint('AcrylicService: mica failed: $e');
    }

    // 3) Acrylic：质感最强但最小化后会丢，最后后备。
    final tint = useDark
        ? const Color(0xCC0A0A0C)
        : const Color(0x66FFFFFF);
    try {
      await Window.setEffect(effect: WindowEffect.acrylic, color: tint);
      transparentBackground = true;
      debugPrint('AcrylicService: acrylic tint=0x'
          '${tint.toARGB32().toRadixString(16)} (dark=$useDark) OK');
      return;
    } catch (e) {
      debugPrint('AcrylicService: acrylic failed: $e');
    }

    debugPrint('AcrylicService: all effects failed, keep opaque background');
    transparentBackground = false;
  }

  /// 显式设置 DWM 玻璃边距，让客户区真正透明。
  ///
  /// `MARGINS{-1,-1,-1,-1}` 是「sheet of glass」：整窗交给 DWM 合成，
  /// Flutter 画的内容叠在上面，未绘制处透出 DWM 背景（Mica/Tabbed）。
  ///
  /// 用 dart:ffi 直接调，因为 flutter_acrylic 在部分 Win11 构建上
  /// 这一步会被它自己的 ACCENT_DISABLED 前置调用抵消。
  static Future<void> _extendGlassIntoClientArea() async {
    if (!Platform.isWindows) return;
    try {
      final user32 = DynamicLibrary.open('user32.dll');
      final dwmapi = DynamicLibrary.open('dwmapi.dll');

      // 找本进程的 Flutter 窗口
      final findWindow = user32.lookupFunction<
          IntPtr Function(Pointer<Utf16>, Pointer<Utf16>),
          int Function(Pointer<Utf16>, Pointer<Utf16>)>('FindWindowW');
      final className = 'FLUTTER_RUNNER_WIN32_WINDOW'.toNativeUtf16();
      final hwnd = findWindow(className, nullptr);
      calloc.free(className);
      if (hwnd == 0) {
        debugPrint('AcrylicService: FindWindowW 未找到窗口');
        return;
      }

      final extendFrame = dwmapi.lookupFunction<
          Int32 Function(IntPtr, Pointer<MARGINS>),
          int Function(int, Pointer<MARGINS>)>('DwmExtendFrameIntoClientArea');
      final margins = calloc<MARGINS>();
      margins.ref.cxLeftWidth = -1;
      margins.ref.cxRightWidth = -1;
      margins.ref.cyTopHeight = -1;
      margins.ref.cyBottomHeight = -1;
      final hr = extendFrame(hwnd, margins);
      calloc.free(margins);
      debugPrint('AcrylicService: DwmExtendFrameIntoClientArea hr=0x'
          '${hr.toRadixString(16)}');
    } catch (e) {
      debugPrint('AcrylicService: extend glass failed: $e');
    }
  }

  /// 主题切换时重新应用材质（明暗分支变化）。
  static Future<void> refresh({bool dark = false}) async {
    if (!_supported || !_pluginReady) return;
    await applyEffect(dark: dark);
    Get.forceAppUpdate();
  }

  /// 仅重设 DWM 材质，不触发界面重建。
  static Future<void> reapply({bool dark = false}) async {
    if (!_supported || !_pluginReady) return;
    await applyEffect(dark: dark);
  }
}

/// Win32 `MARGINS` 结构。
final class MARGINS extends Struct {
  @Int32()
  external int cxLeftWidth;

  @Int32()
  external int cxRightWidth;

  @Int32()
  external int cyTopHeight;

  @Int32()
  external int cyBottomHeight;
}
