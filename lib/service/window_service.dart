import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:get_storage/get_storage.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/api/backend_exit_client.dart';
import 'package:oasx/service/acrylic_service.dart';
import 'package:oasx/service/app_exit_service.dart';
import 'package:oasx/service/profile_service.dart';
import 'package:oasx/modules/common/models/storage_key.dart';
import 'package:oasx/modules/common/models/window_state.dart';
import 'package:oasx/service/system_tray_service.dart';
import 'package:oasx/service/theme_service.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/utils/platform_utils.dart';
import 'package:window_manager/window_manager.dart';
import 'package:oasx/ui/ui.dart';

const Size _defaultDesktopWindowSize = Size(1200, 800);
const Size _minimumWindowsWindowSize = Size(260, 420);

/// 桌面窗口的固定宽高比（3:2）。
///
/// 通过 `windowManager.setAspectRatio` 启用：window_manager 在
/// `WM_SIZING` 里按这个值锁定比例（横向拖按宽算高、纵向拖按高算宽），
/// 所以用户能拉伸但**不会变形**，界面布局始终按设计比例排版。
///
/// 3:2 与默认窗口 1200×800 一致；用户机器上实测 1800×1200 是同一比例
/// 在 1.5× DPI 下的结果。（不能写成 `width / height`——常量表达式里
/// 不允许访问 Size 的属性，所以直接写比值。）
const double _desktopAspectRatio = 3 / 2;

class WindowService extends GetxService with WindowListener {
  // ignore: unused_field
  final _storage = GetStorage();
  final Completer<void> _readyCompleter = Completer<void>();
  Future<void> get ready => _readyCompleter.future;

  bool _didInitDesktop = false;
  int _trayInitToken = 0;

  Timer? _debounceTimer;
  DateTime? _lastSaveTime;
  final enableWindowState = false.obs;
  final enableSystemTray = false.obs;
  final stopBackendOnExit = false.obs;

  late final AppExitService _exitService = AppExitService(
    minimizeToTray: () => enableSystemTray.value,
    trayAvailable: () =>
        Get.isRegistered<SystemTrayService>() &&
        Get.find<SystemTrayService>().isTrayVisible,
    stopBackendOnExit: () => stopBackendOnExit.value,
    backendAddress: () => ApiClient().address,
    hideWindow: _hideToTray,
    closeFrontend: _closeFrontend,
    stopBackend: (address) => BackendExitClient().stop(address),
    resolveStopFailure: _resolveStopFailure,
    preview: ProfileService.isPreview,
  );

  @override
  Future<void> onInit() async {
    try {
      await _initDesktopIfNeeded();
    } catch (e) {
      printError(info: 'window init failed: $e');
    } finally {
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.complete();
      }
    }
    super.onInit();
  }

  Future<void> _initDesktopIfNeeded() async {
    if (_didInitDesktop || !PlatformUtils.isDesktop) return;
    _didInitDesktop = true;

    await windowManager.ensureInitialized();

    enableWindowState.value =
        _storage.read(StorageKey.enableWindowState.name) ?? false;
    enableSystemTray.value =
        _storage.read(StorageKey.enableSystemTray.name) ?? false;
    stopBackendOnExit.value =
        _storage.read(StorageKey.stopBackendOnExit.name) ?? false;

    // WM_CLOSE must already be intercepted when the window becomes visible.
    // Tray readiness only changes hide-vs-exit, never close interception.
    windowManager.addListener(this);
    await windowManager.setPreventClose(true);

    final lastState = await initWindowState();

    await windowManager.waitUntilReadyToShow(buildWindowOptions(lastState));

    // 固定宽高比：允许拉伸，但不允许拉成任意比例。
    //
    // window_manager 在 WM_SIZING 里按这个值锁定比例——横向拖按宽算高、
    // 纵向拖按高算宽，所以拖任意方向都只做等比缩放。布局按设计比例
    // 排版，不会因为用户拉成细长窗口而错乱。
    if (PlatformUtils.isWindows) {
      await windowManager.setAspectRatio(_desktopAspectRatio);
    }

    _kickoffSystemTrayInit();
  }

  void _kickoffSystemTrayInit() {
    if (!PlatformUtils.isDesktop) return;

    if (!enableSystemTray.value) return;

    final token = ++_trayInitToken;
    unawaited(_ensureSystemTrayReady(token));
  }

  Future<void> _ensureSystemTrayReady(int token) async {
    const maxAttempts = 30;
    const retryDelay = Duration(seconds: 1);

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      if (!PlatformUtils.isDesktop) return;
      if (!enableSystemTray.value) return;
      if (token != _trayInitToken) return;
      if (!Get.isRegistered<SystemTrayService>()) return;

      final ok = await Get.find<SystemTrayService>().showTray();
      if (token != _trayInitToken || !enableSystemTray.value) {
        if (!enableSystemTray.value) {
          await Get.find<SystemTrayService>().hideTray();
        }
        return;
      }
      if (ok) {
        return;
      }

      await Future.delayed(retryDelay);
    }

    printInfo(info: 'system tray init failed, close will exit the app.');
  }

  WindowOptions buildWindowOptions(WindowStateModel? lastState) {
    final minimumSize = PlatformUtils.isWindows
        ? _minimumWindowsWindowSize
        : null;
    final initialSize = _resolveInitialWindowSize(
      lastState,
      minimumSize: minimumSize,
    );
    return WindowOptions(
      // 标题跟随实际后端地址，不再硬编码端口（曾经写死 22289，
      // 而真实默认是 22288，标题与实际连接对不上，容易误导排查）
      title: _buildWindowTitle(),
      size: initialSize,
      center: lastState == null,
      minimumSize: minimumSize,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      // 用 hidden：系统标题栏不画，自绘标题栏接管。
      //
      // 千万不要改成 normal——那样原生标题栏会重新出现（实测客户区
      // 比窗口矮 56px，多出来的正是系统标题栏），而且它会覆盖掉
      // AcrylicService 对 WS_CAPTION 的清理。
      //
      // hidden 的代价是 window_manager 在 WM_NCCALCSIZE 里为拖边
      // 热区把客户区左右各缩进 8px（issue #483），表现为窗口右侧
      // 一条浅色窄带。这是已知取舍：要自绘标题栏就必须接受它，
      // 或者自己子类化窗口过程（复杂且风险高）。
      titleBarStyle: TitleBarStyle.hidden,
    );
  }

  /// 生成窗口标题：`OASX · <host:port>`。
  ///
  /// 预览模式显示 Preview 标记；否则取 ApiClient 当前地址
  /// （启动时已由 setAddress 按用户配置初始化）。
  static String _buildWindowTitle() {
    if (ProfileService.isPreview) {
      return 'OASX · Preview';
    }
    String address = '';
    try {
      address = ApiClient().address;
    } catch (_) {
      // 取不到就不显示地址
    }
    // 去掉协议前缀，标题更简洁
    final display = address.replaceFirst(RegExp(r'^https?://'), '').trim();
    return display.isEmpty ? 'OASX' : 'OASX · $display';
  }

  Size _resolveInitialWindowSize(
    WindowStateModel? lastState, {
    Size? minimumSize,
  }) {
    if (lastState == null) {
      return _defaultDesktopWindowSize;
    }
    if (minimumSize == null) {
      return Size(lastState.width, lastState.height);
    }
    return Size(
      lastState.width < minimumSize.width ? minimumSize.width : lastState.width,
      lastState.height < minimumSize.height
          ? minimumSize.height
          : lastState.height,
    );
  }

  Future<WindowStateModel?> initWindowState() async {
    if (!enableWindowState.value) return null;
    final jsonStr = _storage.read(StorageKey.windowState.name);
    if (jsonStr == null) return null;
    WindowStateModel? lastState = WindowStateModel.fromJson(
      json.decode(jsonStr) as Map<String, dynamic>,
    );
    await windowManager.setBounds(
      Rect.fromLTWH(
        lastState.x,
        lastState.y,
        lastState.width,
        lastState.height,
      ),
    );
    return lastState;
  }

  Future<void> _saveWindowState() async {
    if (!PlatformUtils.isDesktop || !enableWindowState.value) return;
    final size = await windowManager.getSize();
    final pos = await windowManager.getPosition();
    final state = WindowStateModel(
      x: pos.dx,
      y: pos.dy,
      width: size.width,
      height: size.height,
    );
    _storage.write(StorageKey.windowState.name, json.encode(state.toJson()));
    printInfo(info: 'save window state:${state.toJson()}');
  }

  void _scheduleSave() {
    if (!PlatformUtils.isDesktop || !enableWindowState.value) return;
    final now = DateTime.now();
    if (_lastSaveTime == null ||
        now.difference(_lastSaveTime!) > const Duration(seconds: 2)) {
      _lastSaveTime = now;
      _saveWindowState();
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      _lastSaveTime = DateTime.now();
      await _saveWindowState();
    });
  }

  @override
  void onWindowMove() => _scheduleSave();
  @override
  void onWindowResize() => _scheduleSave();

  // ── 窗口状态变化后补回 DWM 材质 ──────────────────────────────
  //
  // Windows 在最小化/还原、最大化切换、从托盘恢复等时机可能重建
  // 窗口合成层，把 SYSTEMBACKDROP_TYPE 重置掉，表现为 Mica 突然消失。
  // 这里在 WindowService 全局监听（不依赖 UI 组件是否挂载），
  // 状态变化后重设一次材质，代价极小且幂等。

  @override
  void onWindowRestore() => _rebuildMaterial();
  @override
  void onWindowMaximize() => _rebuildMaterial();
  @override
  void onWindowUnmaximize() => _rebuildMaterial();

  /// 最小化前主动摘掉 Acrylic（见 AcrylicService.prepareForMinimize）。
  @override
  void onWindowMinimize() {
    if (!PlatformUtils.isDesktop) return;
    unawaited(AcrylicService.prepareForMinimize());
  }

  /// 窗口获得焦点时轻量补设材质。
  ///
  /// 普通聚焦切换不会销毁 DWM 的 backdrop 合成，轻量重发（不归零）
  /// 就够，且不会闪。**注意它对最小化→还原无效**：最小化时 DWM 真正
  /// 销毁了合成，必须走 [_rebuildMaterial] 的完整重建才能唤醒。
  @override
  void onWindowFocus() => _reapplyMaterial();

  /// 还原 / 最大化后**完整重建**材质。
  ///
  /// 这些状态变化会让 DWM 销毁并重建合成层，轻量重发会被忽略
  /// （实测：SYSTEMBACKDROP_TYPE=3 属性还在、画面却是纯灰）。
  /// 走完整 `applyEffect`（内部先 ACCENT_DISABLED 归零再设）才能唤醒；
  /// 还原/最大化本身带系统动画，归零瞬间不会构成可见闪烁。
  ///
  /// 动画期间下发的状态可能被丢弃，间隔补两轮。
  void _rebuildMaterial() {
    if (!PlatformUtils.isDesktop) return;
    final dark = Get.isRegistered<ThemeService>()
        ? Get.find<ThemeService>().isDarkMode
        : false;
    unawaited(_rebuildWithRetry(dark));
  }

  Future<void> _rebuildWithRetry(bool dark) async {
    for (final delay in const [0, 400, 900]) {
      if (delay > 0) {
        await Future.delayed(Duration(milliseconds: delay));
      }
      await AcrylicService.applyEffect(dark: dark);
    }
  }

  void _reapplyMaterial() {
    if (!PlatformUtils.isDesktop) return;
    // **必须传当前主题的明暗**：`reapply({bool? dark})` 内部是
    // `dark ?? false`，不传就按浅色重发 tint（0x8CFFFFFF）并把 DWM 的
    // USE_IMMERSIVE_DARK_MODE 置 0——深色主题下每次窗口获得焦点（启动
    // 首次聚焦、alt+tab 切回）材质就被刷成浅色，表现为深色 UI 配亮白材质。
    // 托盘那条路径（SystemTrayService._reapplyMaterial）一直传对了，这里漏了。
    final dark = Get.isRegistered<ThemeService>()
        ? Get.find<ThemeService>().isDarkMode
        : false;
    unawaited(AcrylicService.reapply(dark: dark));
  }

  @override
  void onWindowClose() {
    unawaited(
      requestExit().catchError((Object error) {
        printError(info: 'window exit failed: $error');
        return AppExitResult.keptOpen;
      }),
    );
  }

  Future<AppExitResult> requestExit({bool fromTray = false}) =>
      _exitService.requestExit(fromTray: fromTray);

  Future<void> _hideToTray() async {
    _debounceTimer?.cancel();
    await _saveWindowState();
    await windowManager.hide();
  }

  Future<void> _closeFrontend() async {
    _debounceTimer?.cancel();
    try {
      await _saveWindowState();
      await _storage.save();
      if (Get.isRegistered<SystemTrayService>()) {
        await Get.find<SystemTrayService>().hideTray();
      }
    } catch (error) {
      printError(info: 'window exit cleanup failed: $error');
    }
    await windowManager.setPreventClose(false);
    await windowManager.close();
  }

  Future<ExitFailureChoice> _resolveStopFailure(
    String address,
    Object error,
  ) async {
    // A tray-menu exit may start with a hidden window. Always expose its
    // failure choice instead of leaving an invisible modal behind the tray.
    await windowManager.show();
    await windowManager.focus();
    if (Get.overlayContext == null) return ExitFailureChoice.keepOpen;
    final uri = Uri.tryParse(address);
    final displayAddress = uri == null
        ? address
        : uri.replace(userInfo: '', query: '', fragment: '').toString();
    final result = await Get.dialog<ExitFailureChoice>(
      AlertDialog(
        title: Text(I18n.exitBackendStopFailed.tr),
        content: Text(
          I18n.exitBackendStopFailedHelp.trParams({'address': displayAddress}),
        ),
        actions: [
          AppButton(
  label: I18n.exitKeepOpen.tr,
  variant: AppButtonVariant.text,
  onPressed: () => Get.back(result: ExitFailureChoice.keepOpen),
),
          AppButton(
  label: I18n.exitFrontendOnly.tr,
  variant: AppButtonVariant.text,
  onPressed: () =>
                Get.back(result: ExitFailureChoice.exitFrontendOnly),
),
        ],
      ),
      barrierDismissible: false,
    );
    return result ?? ExitFailureChoice.keepOpen;
  }

  @override
  void onClose() {
    if (PlatformUtils.isDesktop) {
      windowManager.removeListener(this);
    }
    _debounceTimer?.cancel();
    super.onClose();
  }

  void updateWindowStateEnable(bool newVal) {
    enableWindowState.value = newVal;
    _storage.write(StorageKey.enableWindowState.name, newVal);
  }

  void updateStopBackendOnExit(bool newVal) {
    stopBackendOnExit.value = newVal;
    _storage.write(StorageKey.stopBackendOnExit.name, newVal);
  }

  Future<void> updateSystemTrayEnable(bool newVal) async {
    enableSystemTray.value = newVal;
    _storage.write(StorageKey.enableSystemTray.name, newVal);

    if (!PlatformUtils.isDesktop) return;

    if (newVal) {
      _kickoffSystemTrayInit();
      return;
    }

    _trayInitToken++;
    if (!Get.isRegistered<SystemTrayService>()) {
      return;
    }
    await Get.find<SystemTrayService>().hideTray();
  }
}
