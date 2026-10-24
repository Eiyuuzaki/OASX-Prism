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
    //
    // 只在**首次应用**时补（_retryDone 标记）：每次聚焦都重设会让
    // 窗口闪一下——setEffect 内部先 ACCENT_DISABLED 归零，再设回来，
    // 中间那一帧就是"闪一下另一种主题"的来源。
    if (!_settled) {
      _settled = true;
      for (final delay in const [150, 450]) {
        Future.delayed(Duration(milliseconds: delay), () async {
          if (!_supported || !_pluginReady) return;
          if (!transparentBackground) return;
          await _reapplySameEffect(dark: useDark);
        });
      }
    }
  }

  /// 首次启动是否已经补设过（避免每次聚焦重复补设导致闪烁）。
  static bool _settled = false;

  /// Acrylic 的染色。
  ///
  /// **浅色 0x8C（55% 白）**是三轮试出来的平衡点：
  /// - 0x66（40%）透是透，好看，但深色壁纸透上来后浅色主题的深色
  ///   文字可读性差
  /// - 0xBB（73%）可读性够了，但整窗发白、材质感明显变弱（"不好看"）
  /// - 0x8C 配卡片 48% 白：文字压得住，材质纹理也还看得见
  ///
  /// 深色保持 0xCC 不变——用户反馈深色模式本来就没问题，不该动。
  static Color _tintFor(bool dark) =>
      dark ? const Color(0xCC0A0A0C) : const Color(0x8CFFFFFF);

  /// 用当前效果重设一次，**不切换效果类型**（不闪）。
  ///
  /// 与 [_applyEffectInternal] 的区别：不先归零再设，直接重发当前
  /// setEffect，DWM 不会经历"无材质"的中间帧。
  ///
  /// 只补 `MARGINS`（让客户区透明），**不碰 SYSTEMBACKDROP_TYPE**：
  /// Acrylic 走 accent 策略，与 SYSTEMBACKDROP 抢同一层合成，
  /// 设 backdrop 会让窗口先渲染成 Mica 再被 accent 覆盖回来——
  /// 这正是"切回来先闪一下深色界面再闪回"的来源。
  static Future<void> _reapplySameEffect({required bool dark}) async {
    final tint = _tintFor(dark);
    try {
      await Window.setEffect(effect: WindowEffect.acrylic, color: tint, dark: dark);
      await _extendFrameOnly(dark: dark);
    } catch (_) {}
  }

  /// 只设玻璃边距（客户区交给 DWM）+ 明暗变体，不动 backdrop 类型。
  ///
  /// **必须显式设 `USE_IMMERSIVE_DARK_MODE`**：flutter_acrylic 的
  /// `setEffect(acrylic)` 只把 dark 用在 accent 颜色上，不设这个 DWM
  /// 属性；一旦之前有别的调用把它置成 1，浅色主题也会一直走深色变体
  /// （表现为窗口整体偏暗、与浅色 UI 不协调）。
  static Future<void> _extendFrameOnly({bool? dark}) async {
    if (!Platform.isWindows) return;
    try {
      final user32 = DynamicLibrary.open('user32.dll');
      final dwmapi = DynamicLibrary.open('dwmapi.dll');
      final hwnd = _findOwnWindow(user32);
      if (hwnd == 0) return;
      final extendFrame = dwmapi.lookupFunction<
          Int32 Function(IntPtr, Pointer<MARGINS>),
          int Function(int, Pointer<MARGINS>)>('DwmExtendFrameIntoClientArea');
      final margins = calloc<MARGINS>();
      margins.ref.cxLeftWidth = -1;
      margins.ref.cxRightWidth = -1;
      margins.ref.cyTopHeight = -1;
      margins.ref.cyBottomHeight = -1;
      extendFrame(hwnd, margins);
      calloc.free(margins);

      if (dark != null) {
        final setAttr = dwmapi.lookupFunction<
            Int32 Function(IntPtr, Uint32, Pointer<Int32>, Uint32),
            int Function(int, int, Pointer<Int32>, int)>('DwmSetWindowAttribute');
        final darkMode = calloc<Int32>()..value = dark ? 1 : 0;
        setAttr(hwnd, 20, darkMode, 4);
        calloc.free(darkMode);
      }
    } catch (_) {}
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
    // 用 Acrylic 而不是 Mica Alt：
    //
    // Mica 系（SYSTEMBACKDROP）只取壁纸的**平均色调**，深色壁纸配浅色
    // 变体会被提亮成一片中性灰（实测 238,238,238、蓝偏移 0），
    // 完全看不出材质纹理，用户会觉得"材质没了"。
    //
    // Acrylic 是实时模糊 + tint，能真正看到背景的明暗与色彩层次；
    // tint 用 35% 白把整体压回浅色，浅色主题下深色文字仍然可读。
    final tint = _tintFor(dark);
    try {
      await Window.setEffect(effect: WindowEffect.acrylic, color: tint, dark: dark);
      // 必须补 MARGINS：setEffect 内部只在 Mica/Tabbed 分支设玻璃边距，
      // Acrylic 分支只做 accent 策略。不补的话客户区仍是不透明的，
      // 模糊效果被自己盖住，表现为"整窗一片中性灰"。
      await _extendFrameOnly(dark: dark);
      transparentBackground = true;
      debugPrint('AcrylicService: acrylic tint=0x'
          '${tint.toARGB32().toRadixString(16)} (dark=$dark) OK');
    } catch (e) {
      debugPrint('AcrylicService: acrylic failed: $e → 回退 Mica Alt');
      try {
        await Window.setEffect(effect: WindowEffect.tabbed, dark: dark);
        final ok = await _applyDwmBackdrop(dark: dark);
        transparentBackground = ok;
      } catch (e2) {
        debugPrint('AcrylicService: tabbed failed: $e2');
        transparentBackground = false;
      }
    }
  }

  /// 设置 DWM 的一层合成属性。返回是否成功。
  ///
  /// [withBackdrop] 为 true 时把 `SYSTEMBACKDROP_TYPE` 设为 Mica Alt；
  /// **Acrylic 必须传 false**——Acrylic 走的是 accent 策略，与
  /// SYSTEMBACKDROP 互斥，强行设 backdrop 会覆盖掉 Acrylic，
  /// 表现为"先闪成另一种材质再闪回来"。
  static Future<bool> _applyDwmBackdrop({
    required bool dark,
    bool withBackdrop = true,
  }) async {
    if (!Platform.isWindows) return false;
    try {
      final user32 = DynamicLibrary.open('user32.dll');
      final dwmapi = DynamicLibrary.open('dwmapi.dll');

      final hwnd = _findOwnWindow(user32);
      if (hwnd == 0) {
        debugPrint('AcrylicService: 未找到本进程窗口');
        return false;
      }

      // 0) 去掉 WS_CAPTION —— DWM backdrop 能否绘制的硬前提。
      //
      // 窗口若仍带系统标题栏样式，DWM 会按「普通带边框窗口」合成，
      // SYSTEMBACKDROP_TYPE 设得再对也不画材质。实测：加上这一步之前，
      // 材质时有时无（属性查得到 =4、像素纯色）；加上之后稳定生效。
      //
      // **只去 WS_CAPTION，保留 WS_THICKFRAME**：后者是拖边拉伸的依据。
      // 由于窗口用 TitleBarStyle.normal，客户区等于窗口矩形，没有
      // 额外 8px 非客户区（白边的成因是 hidden 模式为拉伸热区缩进
      // 客户区，见 window_service 的说明），所以保留 THICKFRAME 也不会
      // 带回白边。比例由 windowManager.setAspectRatio 锁定，缩放等比。
      final getWindowLong = user32.lookupFunction<
          IntPtr Function(IntPtr, Int32),
          int Function(int, int)>('GetWindowLongPtrW');
      final setWindowLong = user32.lookupFunction<
          IntPtr Function(IntPtr, Int32, IntPtr),
          int Function(int, int, int)>('SetWindowLongPtrW');
      const gwlStyle = -16;
      const wsCaption = 0x00C00000;
      final style = getWindowLong(hwnd, gwlStyle);
      final newStyle = style & ~wsCaption;
      if (newStyle != style) {
        setWindowLong(hwnd, gwlStyle, newStyle);
        debugPrint('AcrylicService: 去掉 WS_CAPTION '
            '(0x${style.toRadixString(16)} → 0x${newStyle.toRadixString(16)})');
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
      //
      // Acrylic 模式下跳过：它用 accent 策略，与 SYSTEMBACKDROP 互斥。
      var hrBackdrop = 0;
      if (withBackdrop) {
        final backdrop = calloc<Int32>()..value = 4;
        hrBackdrop = setAttr(hwnd, 38, backdrop, 4);
        calloc.free(backdrop);
      }

      // 3) 明暗变体
      final darkMode = calloc<Int32>()..value = dark ? 1 : 0;
      final hrDark = setAttr(hwnd, 20, darkMode, 4);
      calloc.free(darkMode);

      debugPrint('AcrylicService: DWM hwnd=$hwnd '
          'frame=0x${hrFrame.toRadixString(16)} '
          'backdrop=${withBackdrop ? "0x${hrBackdrop.toRadixString(16)}" : "跳过(Acrylic)"} '
          'dark=0x${hrDark.toRadixString(16)} (dark=$dark)');

      return hrFrame == 0 && (withBackdrop ? hrBackdrop == 0 : true);
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
  /// 窗口状态变化（聚焦/还原/最大化）时补设材质。
  ///
  /// **走轻量路径**：直接重发当前效果，不先归零。
  /// 之前的实现是调 `applyEffect`（内部先 `setEffect(disabled)` 再设回来），
  /// 中间那一帧材质消失、窗口透出另一种底色 —— 用户看到的就是
  /// "切回来先闪一下深色界面再闪回"。
  static Future<void> reapply({bool? dark}) async {
    if (!_supported || !_pluginReady) return;
    await _reapplySameEffect(dark: dark ?? false);
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
