import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:window_manager/window_manager.dart';

import 'package:oasx/config/theme.dart' show darkTheme, lightTheme;
import 'package:oasx/ui/showcase/ui_showcase_page.dart';

/// UI 组件预览的独立入口。
///
/// 不污染主应用：`flutter build windows --debug --target lib/main_showcase.dart`
/// 直接起这个，不需要改 `Routes.initial`，也就不会忘记还原。
///
/// 右上角可切换深浅色，方便对比 Fluent 色板在两种模式下的表现。
///
/// 注意：这里**不启动后端**，也不初始化完整服务层，
/// 只加载渲染组件所需的最小依赖。所以页面上的数据是占位的。
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // GetStorage 被 ApiClient / DeviceBadge 间接依赖。
  // 预览页不需要持久化，初始化失败也不该阻塞启动——
  // 某些环境下没有 Documents 写权限，直接跳过即可。
  try {
    await GetStorage.init();
  } catch (_) {
    // 忽略：徽标会静默降级为不显示
  }
  // WindowsCaptionBar 依赖 windowManager，预览页要用真实头部就得初始化它。
  //
  // 注意 titleBarStyle: hidden —— 不设的话原生系统标题栏会一直显示，
  // 盖在自绘头部上方，看到的效果就不是真实应用的样子（会被误判成
  // "还是系统标题栏"）。
  await windowManager.ensureInitialized();
  const options = WindowOptions(
    size: Size(1180, 820),
    center: true,
    backgroundColor: Colors.transparent,
    titleBarStyle: TitleBarStyle.hidden,
  );
  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  runApp(const ShowcaseApp());
}

class ShowcaseApp extends StatefulWidget {
  const ShowcaseApp({super.key});

  @override
  State<ShowcaseApp> createState() => _ShowcaseAppState();
}

class _ShowcaseAppState extends State<ShowcaseApp> {
  ThemeMode _mode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'OASX Prism · UI Showcase',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _mode,
      home: Stack(
        children: [
          const UiShowcasePage(),
          // 深浅色切换器放右下角：右上角是窗口控制按钮的位置，
          // 放那里会重叠（预览页才会遇到，真实应用没有这个切换器）
          Positioned(
            right: 20,
            bottom: 20,
            child: Material(
              elevation: 3,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_rounded, size: 16),
                      label: Text('浅色'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_rounded, size: 16),
                      label: Text('深色'),
                    ),
                  ],
                  selected: {_mode},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() => _mode = s.first),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
