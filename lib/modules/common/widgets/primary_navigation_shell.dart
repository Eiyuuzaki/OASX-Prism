import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/common/widgets/appbar.dart';
import 'package:oasx/modules/common/widgets/frosted_bars.dart';
import 'package:oasx/modules/home/index.dart';
import 'package:oasx/modules/home/models/home_workbench_layout.dart';
import 'package:oasx/modules/settings/index.dart';
import 'package:oasx/service/acrylic_service.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/ui/ui.dart';
import 'package:oasx/views/log/log_page.dart';
import 'package:oasx/views/resource/resource_page.dart';
import 'package:oasx/views/statistics/statistics_page.dart';

/// 页面顺序（决定导航项索引）。
///
/// 索引即数组下标，改顺序时导航项与内容栈会一起跟着变，
/// 不会出现"点了这项跳到那页"的错位。
const List<String> _kRouteOrder = [
  '/home',
  '/statistics',
  '/resource',
  '/log',
  '/settings',
];

class PrimaryNavigationShell extends StatefulWidget {
  const PrimaryNavigationShell({
    super.key,
    required this.initialRoutePath,
  });

  final String initialRoutePath;

  @override
  State<PrimaryNavigationShell> createState() => _PrimaryNavigationShellState();
}

class _PrimaryNavigationShellState extends State<PrimaryNavigationShell> {
  late String _routePath;
  late final Set<int> _builtIndexes;

  @override
  void initState() {
    super.initState();
    _routePath = _normalizeRoutePath(widget.initialRoutePath);
    _builtIndexes = <int>{_selectedIndexForRoute(_routePath)};
  }

  @override
  void didUpdateWidget(covariant PrimaryNavigationShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextRoutePath = _normalizeRoutePath(widget.initialRoutePath);
    if (nextRoutePath == _routePath) {
      return;
    }
    final previousRoutePath = _routePath;
    _routePath = nextRoutePath;
    _builtIndexes.add(_selectedIndexForRoute(nextRoutePath));
    _handleRouteExit(previousRoutePath, nextRoutePath);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final selectedIndex = _selectedIndexForRoute(_routePath);
        final showRail = _shouldShowRail(constraints.maxWidth);
        final content = _PrimaryNavigationContent(
          selectedIndex: selectedIndex,
          builtIndexes: _builtIndexes,
        );
        // 移动端 scaffold 底设为透明（让 FrostedBars 能糊到东西），
        // 但透明需要有"可被模糊的内容"托底，否则会露出黑色。
        // 这里铺一层主题渐变色作为模糊源：
        //   Scaffold(透明) → 渐变背景 → 内容 → 毛玻璃 AppBar/底栏
        final frosted = !showRail && AcrylicService.mobileFrostedBackground;
        return Scaffold(
          appBar: buildPlatformAppBar(context, routePath: _routePath),
          resizeToAvoidBottomInset: false,
          // 毛玻璃底栏/AppBar：body 延伸到栏后，内容滚动时透出模糊底色
          extendBody: showRail ? false : true,
          extendBodyBehindAppBar: !showRail,
          body: frosted
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.surface,
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                      ],
                    ),
                  ),
                  child: showRail
                      ? Row(
                          children: [
                            _PrimaryNavigationRail(
                              selectedIndex: selectedIndex,
                              onSelected: _handleDestinationSelected,
                            ),
                            const AppDivider(height: 1, vertical: true),
                            Expanded(child: content),
                          ],
                        )
                      : content,
                )
              : showRail
                  ? Row(
                      children: [
                        _PrimaryNavigationRail(
                          selectedIndex: selectedIndex,
                          onSelected: _handleDestinationSelected,
                        ),
                        const AppDivider(height: 1, vertical: true),
                        Expanded(child: content),
                      ],
                    )
                  : content,
          bottomNavigationBar: showRail
              ? null
              : FrostedBars.bottomBar(
                  context,
                  child: NavigationBar(
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (index) {
                      Haptics.selection();
                      _handleDestinationSelected(index);
                    },
                    // 关键：NavigationBar 的 M3 默认背景是不透明的
                    // surfaceContainer，会完全盖住 FrostedBars 的模糊层，
                    // 看起来就像完全没有毛玻璃。必须显式透明。
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    surfaceTintColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    destinations: _destinations(),
                  ),
                ),
        );
      },
    );
  }

  bool _shouldShowRail(double maxWidth) {
    // 用 appNavBarWidth() 而不是固定的 80：Windows 上 Fluent 导航栏是 200，
    // 沿用 80 会让判定过于乐观，窗口不够宽时挤坏两栏布局
    final twoPaneShellWidth = kHomeWorkbenchMinCollectionWidth +
        kHomeWorkbenchMinDetailsWidth +
        kHomeWorkbenchDividerWidth +
        appNavBarWidth();
    return maxWidth >= twoPaneShellWidth;
  }

  String _normalizeRoutePath(String value) {
    return _kRouteOrder.contains(value) ? value : _kRouteOrder.first;
  }

  int _selectedIndexForRoute(String value) {
    final i = _kRouteOrder.indexOf(value);
    return i < 0 ? 0 : i;
  }

  String _routePathForIndex(int index) {
    if (index < 0 || index >= _kRouteOrder.length) return _kRouteOrder.first;
    return _kRouteOrder[index];
  }

  void _handleDestinationSelected(int index) {
    final nextRoutePath = _routePathForIndex(index);
    if (nextRoutePath == _routePath) {
      return;
    }
    final previousRoutePath = _routePath;
    setState(() {
      _routePath = nextRoutePath;
      _builtIndexes.add(index);
    });
    _handleRouteExit(previousRoutePath, nextRoutePath);
  }

  void _handleRouteExit(String previousRoutePath, String nextRoutePath) {
    if (previousRoutePath == '/settings' && nextRoutePath != '/settings') {
      unawaited(handleSettingsLeaveEffect());
    }
  }

  List<Widget> _destinations() {
    return [
      NavigationDestination(
        icon: const Icon(Icons.home_rounded),
        label: I18n.home.tr,
      ),
      NavigationDestination(
        icon: const Icon(Icons.bar_chart_rounded),
        label: I18n.homeStatsTab.tr,
      ),
      NavigationDestination(
        icon: const Icon(Icons.diamond_outlined),
        label: '资产',
      ),
      NavigationDestination(
        icon: const Icon(Icons.article_outlined),
        label: I18n.log.tr,
      ),
      NavigationDestination(
        icon: const Icon(Icons.settings_rounded),
        label: I18n.setting.tr,
      ),
    ];
  }
}

class _PrimaryNavigationContent extends StatelessWidget {
  const _PrimaryNavigationContent({
    required this.selectedIndex,
    required this.builtIndexes,
  });

  final int selectedIndex;
  final Set<int> builtIndexes;

  @override
  Widget build(BuildContext context) {
    // 按索引懒构建：只有访问过的页面才进树，未访问的留空
    return IndexedStack(
      index: selectedIndex,
      children: [
        _lazy(0, const HomeView(standalone: false)),
        _lazy(1, const StatisticsPage()),
        _lazy(2, const ResourcePage()),
        _lazy(3, const LogPage()),
        _lazy(4, const SettingsView(standalone: false)),
      ],
    );
  }

  Widget _lazy(int index, Widget child) {
    return builtIndexes.contains(index) ? child : const SizedBox.shrink();
  }
}

class _PrimaryNavigationRail extends StatelessWidget {
  const _PrimaryNavigationRail({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    // 语义导航栏：Windows 上渲染为 WinUI NavigationView 紧凑模式
    // （图标在上、文字在下；选中是左侧贴边竖条 + 圆角高亮块）。
    //
    // 「设置」放在 bottomDestinations —— 次级项固定底部，
    // 这是 Win11 设置/Legion Toolkit 的通用做法。
    // 索引仍接在主分组之后（4），与 _kRouteOrder 一致。
    return AppNavBar(
      selectedIndex: selectedIndex,
      onSelected: onSelected,
      destinations: [
        AppNavDestination(icon: Icons.home_rounded, label: I18n.home.tr),
        AppNavDestination(
            icon: Icons.bar_chart_rounded, label: I18n.homeStatsTab.tr),
        AppNavDestination(icon: Icons.diamond_outlined, label: '资产'),
        AppNavDestination(icon: Icons.article_outlined, label: I18n.log.tr),
      ],
      bottomDestinations: [
        AppNavDestination(icon: Icons.settings_rounded, label: I18n.setting.tr),
      ],
    );
  }
}
