import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/controllers/statistics_controller.dart';
import 'package:oasx/modules/home/widgets/statistics_panel.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/ui/ui.dart';

/// 统计页。
///
/// 原来统计是工作台中栏的一个页签，现在拆成独立页面：
/// 页头说明这一页做什么，内容复用原有的 `ScriptStatisticsPanel`。
///
/// **必须在进出时设置 `standalonePageVisible`**：统计控制器的绑定门控
/// 原本只看工作台页签是否选中 stats，独立页面永远满足不了这个条件，
/// 结果整页恒为"无数据"。
class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  HomeStatisticsController? _controller;

  @override
  void initState() {
    super.initState();
    // 放到首帧之后：initState 阶段往 GetX 里取控制器并触发异步绑定，
    // 可能在路由构建过程中引起重建。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!Get.isRegistered<HomeStatisticsController>()) return;
      final controller = Get.find<HomeStatisticsController>();
      _controller = controller;
      controller.setStandalonePageVisible(true);
    });
  }

  @override
  void dispose() {
    _controller?.setStandalonePageVisible(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = Get.find<HomeDashboardController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(
          () => AppPageHeader(
            title: I18n.homeStatsTab.tr,
            description: _describe(dashboard.activeScriptName.value),
          ),
        ),
        const Expanded(child: ScriptStatisticsPanel()),
      ],
    );
  }

  String _describe(String scriptName) {
    if (scriptName.isEmpty) {
      return '选择脚本后查看运行统计';
    }
    return '「$scriptName」的运行时长、战斗场次与历史趋势';
  }
}
