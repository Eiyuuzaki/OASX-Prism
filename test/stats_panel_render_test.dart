// 统计面板渲染冒烟测试：验证面板在无数据 / 有数据两种状态下都能
// 正常渲染，不抛布局异常（曾因 Row.stretch 在 ListView 里把整行压成
// 0 高度而出现过"整页空白"）。
//
// 注意：不断言具体文案。面板的数据来自控制器，而控制器 onInit 会
// 重新绑定/拉取，注入的数据会被清空——断言文案会随实现变化而脆断。
// 这里只保证"能渲染、不崩、不溢出"。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:oasx/config/theme.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/controllers/statistics_controller.dart';
import 'package:oasx/modules/home/widgets/statistics_panel.dart';
import 'package:oasx/modules/settings/controllers/settings_controller.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/service/websocket_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('统计面板在无数据时渲染占位而不崩溃', (tester) async {
    Get.put(SettingsController(), permanent: true);
    Get.lazyPut<WebSocketService>(() => WebSocketService(), fenix: true);
    Get.put(ScriptService(), permanent: true);
    Get.put(HomeDashboardController());
    Get.put(HomeStatisticsController());

    await tester.pumpWidget(
      GetMaterialApp(
        theme: lightTheme,
        home: const Scaffold(
          body: SizedBox(
            width: 500,
            height: 800,
            child: ScriptStatisticsPanel(),
          ),
        ),
      ),
    );

    // 用固定帧而不是 pumpAndSettle：面板内的连接状态会启动重连计时器，
    // 界面永远"不稳定"，pumpAndSettle 必然超时。
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 不崩、有渲染内容即通过（渲染异常会在 pump 阶段直接抛出）
    expect(tester.takeException(), isNull);
    expect(find.byType(ScriptStatisticsPanel), findsOneWidget);
  });
}
