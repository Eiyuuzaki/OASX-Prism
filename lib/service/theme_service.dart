import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:oasx/service/acrylic_service.dart';
import 'package:oasx/modules/common/models/storage_key.dart';

/// 三种主题模式：跟随系统 / 强制浅色 / 强制深色。
enum AppThemeMode { system, light, dark }

class ThemeService extends GetxService {
  final _storage = GetStorage();

  /// 当前主题模式（响应式）
  final mode = AppThemeMode.system.obs;

  /// 实际是否处于深色（跟随系统时由平台亮度决定）
  final _dark = false.obs;

  final _amoled = false.obs;

  bool get isDarkMode => _dark.value;

  /// AMOLED 纯黑深色：仅深色模式下有意义（OLED 省电 + 对比度拉满）
  bool get isAmoled => _amoled.value;

  /// 传给 GetMaterialApp.themeMode
  ThemeMode get themeMode => switch (mode.value) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      };

  @override
  void onInit() {
    // 兼容旧版本只存 bool 的情况
    final saved = _storage.read(StorageKey.dark.name);
    final savedMode = _storage.read('themeMode') as String?;
    if (savedMode != null) {
      mode.value = AppThemeMode.values.firstWhere(
        (m) => m.name == savedMode,
        orElse: () => AppThemeMode.system,
      );
    } else if (saved is bool) {
      // 没有新模式记录时，用旧的布尔值推断
      mode.value = saved ? AppThemeMode.dark : AppThemeMode.light;
    }

    _amoled.value = _storage.read('amoled') ?? false;
    _syncDark();
    super.onInit();
  }

  /// 根据模式与系统亮度计算"实际是否深色"
  void _syncDark() {
    switch (mode.value) {
      case AppThemeMode.light:
        _dark.value = false;
      case AppThemeMode.dark:
        _dark.value = true;
      case AppThemeMode.system:
        // **不要从 MediaQuery 取系统亮度**：`applyEffect` 在 `runApp` 之前
        // 就执行，那一刻 `Get.context` 还是 null，只能按浅色处理——结果是
        // "系统深色 + 跟随系统"启动时深色界面配浅色材质。
        // `platformDispatcher.platformBrightness` 不依赖 context，启动期和
        // 运行期都可用。
        final brightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        _dark.value = brightness == Brightness.dark;
    }
  }

  /// 设置主题模式并持久化
  void setMode(AppThemeMode value) {
    mode.value = value;
    _storage.write('themeMode', value.name);
    _storage.write(StorageKey.dark.name, value == AppThemeMode.dark);
    _syncDark();
    Get.changeThemeMode(themeMode);
    // 毛玻璃材质的明暗分支也跟着变（mica/acrylic 的 dark 参数）
    AcrylicService.refresh(dark: _dark.value);
    Get.forceAppUpdate();
  }

  /// 材质生效后重建主题。
  ///
  /// `lightTheme`/`darkTheme` 是顶层 getter，读取
  /// `AcrylicService.transparentBackground` 决定卡片与 scaffold 的
  /// 透明度。启动时材质晚于 `GetMaterialApp` 构建，那一刻该标志还是
  /// false，卡片会拿到 92% 不透明白（把材质完全盖住、表现为"整圈白边"）。
  ///
  /// 材质生效后标志变 true，但它不是 Rx，不会触发 Obx 重建，
  /// 所以这里强制刷一次，让新的透明卡片生效。
  void bumpForMaterial() {
    Get.forceAppUpdate();
  }

  /// 保留旧接口（图标按钮等地方可能还在用）：在浅色/深色间切换
  void switchTheme([bool? dark]) {
    final target = dark ?? !isDarkMode;
    setMode(target ? AppThemeMode.dark : AppThemeMode.light);
  }

  /// 切换 AMOLED 纯黑；仅在深色模式下实际改变观感
  void switchAmoled([bool? value]) {
    _amoled.value = value ?? !_amoled.value;
    _storage.write('amoled', _amoled.value);
    // darkTheme 实例需要重建，GetMaterialApp 整体刷新
    Get.forceAppUpdate();
  }

  /// 系统亮度变化时（跟随系统模式下）刷新
  void onPlatformBrightnessChanged() {
    if (mode.value == AppThemeMode.system) {
      _syncDark();
      Get.changeThemeMode(themeMode);
      Get.forceAppUpdate();
    }
  }
}
