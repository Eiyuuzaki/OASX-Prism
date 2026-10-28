import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:oasx/modules/server/index.dart';
import 'package:oasx/translation/i18n_content.dart';

Widget getTitle(BuildContext context, {String? routePath}) {
  final resolvedRoutePath = _resolveRoutePath(context, routePath: routePath);
  return switch (resolvedRoutePath) {
    '/settings' => const SettingTitle(),
    '/server' => const ServerTitle(),
    // 主页标题栏的文字按当前页变化：导航栏选中项会收起文字（WinUI 紧凑
    // 导航的既定行为），标题栏是用户唯一能确认"我在哪一页"的地方，
    // 写死「主页」会让仪表盘/工作台/统计等页面全都显示成主页。
    _ => HomeTitleBar(label: _pageLabelFor(resolvedRoutePath)),
  };
}

/// 路由 → 标题文字。
String _pageLabelFor(String routePath) {
  return switch (routePath) {
    '/dashboard' => I18n.dashboard.tr,
    '/workbench' || '/home' => I18n.workbench.tr,
    '/statistics' => I18n.homeStatsTab.tr,
    '/resource' => I18n.resource_title.tr,
    '/log' => I18n.log.tr,
    _ => I18n.home.tr,
  };
}

String _resolveRoutePath(BuildContext context, {String? routePath}) {
  final explicitRoute = routePath?.trim() ?? '';
  if (explicitRoute.isNotEmpty) {
    return explicitRoute;
  }

  final routingCurrent = Get.routing.current;
  if (routingCurrent.isNotEmpty) {
    return routingCurrent;
  }

  final routeName = ModalRoute.of(context)?.settings.name;
  if (routeName != null && routeName.isNotEmpty) {
    return routeName;
  }
  return Get.currentRoute;
}

class HomeTitleBar extends StatelessWidget {
  const HomeTitleBar({super.key, this.label});

  /// 标题文字；为空时回落到「主页」。
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/Icon-app.png', height: 30, width: 30),
          const SizedBox(width: 14),
          Flexible(
            child: _TitleLabel(
              text: 'OASX / ${label ?? I18n.home.tr}',
            ),
          ),
        ],
      ),
    );
  }
}

class SettingTitle extends StatelessWidget {
  const SettingTitle({super.key});

  @override
  Widget build(BuildContext context) {
    // 不放返回箭头：设置页在导航壳内是**状态切换**（IndexedStack），
    // 没有路由栈可返回——返回箭头是"设置曾经是压栈路由"时代的遗留，
    // 现在点它只会误弹初始路由。
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/Icon-app.png', height: 30, width: 30),
          const SizedBox(width: 14),
          Flexible(child: _TitleLabel(text: 'OASX / ${I18n.setting.tr}')),
        ],
      ),
    );
  }
}

class ServerTitle extends StatelessWidget {
  const ServerTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final backButton = switch (Theme.of(context).platform) {
      TargetPlatform.android => false,
      TargetPlatform.iOS => false,
      _ => true,
    };
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() {
            if (backButton &&
                !Get.find<ServerController>().isDeployLoading.value) {
              return const Row(
                mainAxisSize: MainAxisSize.min,
                children: [BackButton(), SizedBox(width: 8)],
              );
            }
            return const SizedBox.shrink();
          }),
          Image.asset('assets/images/Icon-app.png', height: 30, width: 30),
          const SizedBox(width: 14),
          const Flexible(child: _TitleLabel(text: 'OASX / Server')),
        ],
      ),
    );
  }
}

class _TitleLabel extends StatelessWidget {
  const _TitleLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
      style: Theme.of(context).textTheme.titleMedium,
    );
  }
}
