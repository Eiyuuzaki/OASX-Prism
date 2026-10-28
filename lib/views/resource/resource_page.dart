import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/ui/ui.dart';
import 'package:oasx/views/resource/resource_view.dart';

/// 资产页。
///
/// 原来资产是工作台中栏的一个页签，现在拆成独立页面。
/// `ResourceView` 自身已经带了工具条与内容，这里只补统一的页头。
class ResourcePage extends StatelessWidget {
  const ResourcePage({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboard = Get.find<HomeDashboardController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(
          () => AppPageHeader(
            title: I18n.resource_title.tr,
            description: dashboard.activeScriptName.value.isEmpty
                ? '选择脚本后查看资产变化'
                : '「${dashboard.activeScriptName.value}」的资产快照与变动',
          ),
        ),
        // 必须跟着 activeScriptName 重建：用 Obx 订阅，并把脚本名作为 key，
        // 切脚本时拿到全新的 ResourceView 实例（否则 identical 短路，
        // 页面会一直停留在旧脚本的数据上）。
        Expanded(
          child: Obx(() {
            final name = dashboard.activeScriptName.value;
            return ResourceView(key: ValueKey('resource-$name'), scriptName: name);
          }),
        ),
      ],
    );
  }
}
