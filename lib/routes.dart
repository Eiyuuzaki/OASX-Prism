import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:oasx/modules/common/widgets/primary_navigation_shell.dart';
import 'package:oasx/modules/home/home_binding.dart';
import 'package:oasx/modules/server/index.dart';

class Routes {
  static const initial = '/dashboard';

  static final routes = [
    GetPage(
      name: '/dashboard',
      page: () => _buildPrimaryPage('/dashboard'),
      binding: HomeBinding(),
    ),
    GetPage(
      name: '/workbench',
      page: () => _buildPrimaryPage('/workbench'),
      binding: HomeBinding(),
    ),
    GetPage(
      name: '/home',
      page: () => _buildPrimaryPage('/workbench'),
      binding: HomeBinding(),
    ),
    GetPage(
      name: '/statistics',
      page: () => _buildPrimaryPage('/statistics'),
      binding: HomeBinding(),
    ),
    GetPage(
      name: '/resource',
      page: () => _buildPrimaryPage('/resource'),
      binding: HomeBinding(),
    ),
    GetPage(
      name: '/log',
      page: () => _buildPrimaryPage('/log'),
      binding: HomeBinding(),
    ),
    GetPage(
      name: '/settings',
      page: () => _buildPrimaryPage('/settings'),
      binding: HomeBinding(),
    ),
    GetPage(
      name: '/server',
      page: () => const ServerView(),
      binding: BindingsBuilder(() {
        Get.put<ServerController>(ServerController());
      }),
    ),
  ];

  static Widget _buildPrimaryPage(String routePath) {
    // 一律走壳：壳自己按宽度决定「左侧导航栏」还是「底部导航栏」。
    //
    // 旧逻辑是宽窗口直接返回视图（绕过壳），结果是桌面端根本没有导航栏，
    // 只有全屏内容——这正是「看起来还是老界面」的根因。
    // 新的页面结构（主页/统计/资产/日志/设置）依赖常驻导航，
    // 必须始终经过壳，不能按宽度绕过。
    return PrimaryNavigationShell(initialRoutePath: routePath);
  }
}
