import 'dart:ffi';
import 'dart:io' as io show pid;
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

    await _applyEffectInternal(dark: useDark);

    // 窗口真正显示之后 DWM 才处理合成属性，补几轮覆盖启动期。
    for (final delay in const [120, 400, 900]) {
      Future.delayed(Duration(milliseconds: delay), () async {
        if (!_supported || !_pluginReady) return;
        if (!transparentBackground) return;
        await _applyDwmBackdrop(dark: useDark);
      });
    }
  }

  /// 应用材质。
  ///
  /// ## 正确顺序（实测踩坑记录）
  ///
  /// 1. **先 `SetWindowCompositionAttribute(ACCENT_DISABLED)`**——
  ///    这一步让 DWM 重置合成状态。跳过它直接设 SYSTEMBACKDROP，
  ///    属性查得到但不会重绘，表现为「完全没材质」。
  /// 2. `DwmExtendFrameIntoClientArea(MARGINS{-1})` —— 客户区交给 DWM
  /// 3. `DwmSetWindowAttribute(SYSTEMBACKDROP_TYPE, 4)`
  /// 4. `DwmSetWindowAttribute(USE_IMMERSIVE_DARK_MODE)`
  ///
  /// 前两步既是 flutter_acrylic 内部做的，也是它唯一不可替代的部分，
  /// 所以继续借它的 `setEffect`；后两步用 FFI 补（它在部分 Win11
  /// 构建上会漏掉或顺序颠倒）。
  static Future<void> _applyEffectInternal({required bool dark}) async {
    try {
      // 1) 借插件的 setEffect：内部会做 ACCENT_DISABLED 重置 + MARGINS + backdrop
      await Window.setEffect(effect: WindowEffect.tabbed, dark: dark);
      // 2) FFI 再补一遍 DWM 属性，确保落地
      final ok = await _applyDwmBackdrop(dark: dark);
      transparentBackground = ok;
      debugPrint('AcrylicService: tabbed/mica-alt applied (dark=$dark)');
    } catch (e) {
      debugPrint('AcrylicService: tabbed failed: $e → 尝试纯 DWM 路径');
      final ok = await _applyDwmBackdrop(dark: dark);
      transparentBackground = ok;
    }
  }

  /// 设置 DWM backdrop。返回是否成功。
  static Future<bool> _applyDwmBackdrop({required bool dark}) async {
    if (!Platform.isWindows) return false;
    try {
      final user32 = DynamicLibrary.open('user32.dll');
      final dwmapi = DynamicLibrary.open('dwmapi.dll');

      final hwnd = _findOwnWindow(user32);
      if (hwnd == 0) {
        debugPrint('AcrylicService: 未找到本进程窗口');
        return false;
      }

      // 1) 玻璃边距：整窗交给 DWM 合成，未绘制处透出材质
      final extendFrame = dwmapi.lookupFunction<
          Int32 Function(IntPtr, Pointer<MARGINS>),
          int Function(int, Pointer<MARGINS>)>('DwmExtendFrameIntoClientArea');
      final margins = calloc<MARGINS>();
      margins.ref.cxLeftWidth = -1;
      margins.ref.cxRightWidth = -1;
      margins.ref.cyTopHeight = -1;
      margins.ref.cyBottomHeight = -1;
      final hrFrame = extendFrame(hwnd, margins);
      calloc.free(margins);

      final setAttr = dwmapi.lookupFunction<
          Int32 Function(IntPtr, Uint32, Pointer<Int32>, Uint32),
          int Function(int, int, Pointer<Int32>, int)>('DwmSetWindowAttribute');

      // 2) SYSTEMBACKDROP_TYPE = 4（DWMSBT_TABBEDWINDOW，壁纸透出最明显）
      final backdrop = calloc<Int32>()..value = 4;
      final hrBackdrop = setAttr(hwnd, 38, backdrop, 4);
      calloc.free(backdrop);

      // 3) 明暗变体
      final darkMode = calloc<Int32>()..value = dark ? 1 : 0;
      final hrDark = setAttr(hwnd, 20, darkMode, 4);
      calloc.free(darkMode);

      debugPrint('AcrylicService: DWM backdrop hwnd=$hwnd '
          'frame=0x${hrFrame.toRadixString(16)} '
          'backdrop=0x${hrBackdrop.toRadixString(16)} '
          'dark=0x${hrDark.toRadixString(16)} (dark=$dark)');

      return hrFrame == 0 && hrBackdrop == 0;
    } catch (e) {
      debugPrint('AcrylicService: DWM backdrop failed: $e');
      return false;
    }
  }

  /// 按当前进程 ID 枚举顶层窗口，找类名为 Flutter runner 的那个。
  static int _findOwnWindow(DynamicLibrary user32) {
    final getWindowThreadProcessId = user32.lookupFunction<
        Uint32 Function(IntPtr, Pointer<Int32>),
        int Function(int, Pointer<Int32>)>('GetWindowThreadProcessId');
    final getClassName = user32.lookupFunction<
        Int32 Function(IntPtr, Pointer<Utf16>, Int32),
        int Function(int, Pointer<Utf16>, int)>('GetClassNameW');

    final ownPid = io.pid;
    int? found;

    // EnumWindows 的回调签名
    final enumWindows = user32.lookupFunction<
        Int32 Function(
            Pointer<NativeFunction<Int32 Function(IntPtr, IntPtr)>>, IntPtr),
        int Function(
            Pointer<NativeFunction<Int32 Function(IntPtr, IntPtr)>>,
            int)>('EnumWindows');

    final pidPtr = calloc<Int32>();
    final classBuf = calloc<Uint16>(256);

    final callback = NativeCallable<
        Int32 Function(IntPtr, IntPtr)>.isolateLocal(
      (int hwnd, int lParam) {
        pidPtr.value = 0;
        getWindowThreadProcessId(hwnd, pidPtr);
        if (pidPtr.value != ownPid) return 1; // 继续枚举

        // 不按 IsWindowVisible 过滤：applyEffect 可能在窗口 show 之前
        // 执行（initialize 之后立即调用），此时窗口尚不可见但已存在。
        // 只按类名 + 进程 ID 匹配即可。

        // 读取类名
        for (var i = 0; i < 256; i++) {
          classBuf[i] = 0;
        }
        final len = getClassName(hwnd, classBuf.cast<Utf16>(), 256);
        if (len <= 0) return 1;
        final name = classBuf.cast<Utf16>().toDartString();
        if (name == 'FLUTTER_RUNNER_WIN32_WINDOW') {
          found = hwnd;
          return 0; // 停止枚举
        }
        return 1;
      },
      // 回调返回值不是 void/Handle/Pointer，必须给"异常返回值"
      exceptionalReturn: 0,
    );

    try {
      enumWindows(callback.nativeFunction, 0);
    } finally {
      callback.close();
      calloc.free(pidPtr);
      calloc.free(classBuf);
    }
    return found ?? 0;
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
