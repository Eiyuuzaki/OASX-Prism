import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/widgets/log_center_panel.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/ui/ui.dart';

/// 日志页。
///
/// 原来日志是工作台右栏，现在拆成独立页面：
/// 侧栏只放全局导航，日志占满整个内容区，可读面积比原来大得多。
class LogPage extends StatelessWidget {
  const LogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboard = Get.find<HomeDashboardController>();

    return Obx(() {
      final scriptName = dashboard.activeScriptName.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPageHeader(
            title: I18n.log.tr,
            description: scriptName.isEmpty
                ? '选择脚本后查看运行日志'
                : '「$scriptName」的实时输出',
          ),
          Expanded(
            // 换脚本时重建面板，避免残留上一个脚本的日志缓冲
            child: LogCenterPanel(
              key: ValueKey('log-$scriptName'),
              scriptName: scriptName,
            ),
          ),
        ],
      );
    });
  }
}
