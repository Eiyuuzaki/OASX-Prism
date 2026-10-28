// 仪表盘渲染冒烟测试。
//
// 目的：验证仪表盘在**窄窗口 / 标准窗口**下都不会布局溢出。
//
// 背景：仪表盘的资产卡用 Wrap + 自适应列数排布，若固定宽度或列数算错，
// 1200 宽的窗口里右侧会被裁掉（真机上表现为"资产卡超出窗口"）。
// Flutter 把 overflow 记成异常，用 widget 测试能稳定捕获，不依赖截图。
//
// 这里只实例化仪表盘自己需要的两个服务（WebSocketService / ScriptService），
// 不引入 SettingsController 等无关依赖——它们会走 path_provider 之类的
// 平台插件，在测试环境里没有实现。
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:oasx/config/theme.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/service/websocket_service.dart';
import 'package:oasx/views/dashboard/dashboard_controller.dart';
import 'package:oasx/views/dashboard/dashboard_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // GetStorage 依赖 path_provider；测试环境没有平台实现，给它一个临时目录。
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => Directory.systemTemp.path,
    );
  });

  setUp(() {
    Get.reset();
    // 构造期依赖链：HomeDashboardController → ScriptService → WebSocketService。
    // 必须用 put（lazyPut 要等被 find 时才创建，这里会踩空）。
    Get.put(WebSocketService(), permanent: true);
    Get.put(ScriptService(), permanent: true);
    Get.put(HomeDashboardController());
  });

  Future<void> pumpDashboard(WidgetTester tester, Size size,
      {bool withConfig = false}) async {
    if (withConfig) {
      Get.find<ScriptService>().addScriptModel('demo');
    }
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: lightTheme,
        home: const Scaffold(body: DashboardPage()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 核心断言：没有布局溢出等异常
    expect(tester.takeException(), isNull);

    // 清理：仪表盘控制器带 2 分钟兜底定时器，不销毁会让下一个用例报
    // "A Timer is still pending"。
    for (final name in ['demo', '']) {
      final tag = 'dashboard-$name';
      if (Get.isRegistered<DashboardOverviewController>(tag: tag)) {
        Get.delete<DashboardOverviewController>(tag: tag, force: true);
      }
    }
  }

  testWidgets('无配置时渲染提示而不崩溃', (tester) async {
    await pumpDashboard(tester, const Size(1200, 800));
  });

  testWidgets('窄窗口 700 宽不溢出', (tester) async {
    await pumpDashboard(tester, const Size(700, 800), withConfig: true);
  });

  testWidgets('标准窗口 1200 宽不溢出', (tester) async {
    await pumpDashboard(tester, const Size(1200, 800), withConfig: true);
  });
}
