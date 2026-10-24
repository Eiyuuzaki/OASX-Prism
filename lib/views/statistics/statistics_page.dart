import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/widgets/statistics_panel.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/ui/ui.dart';

/// 统计页。
///
/// 原来统计是工作台中栏的一个页签，现在拆成独立页面：
/// 页头说明这一页做什么，内容复用原有的 `ScriptStatisticsPanel`。
class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

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
