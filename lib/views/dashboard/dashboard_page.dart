import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/ui/ui.dart';
import 'package:oasx/views/dashboard/dashboard_controller.dart';

/// 仪表盘：**只读**的信息速览页。
///
/// 与工作台（`HomeView`）的分工：
///
/// * 工作台 = **管理**。选配置、改任务参数、拖拽分栏、看完整日志。
/// * 仪表盘 = **查看**。一屏回答"现在在跑什么、今天跑了多久、赚了多少"。
///
/// 因此这里刻意不放配置列表、任务参数、任何可编辑控件——只有顶部一个
/// 配置切换器（决定"看谁的"），其余全部是只读信息。
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  /// 当前查看的配置名。空表示还没选（首帧按激活脚本兜底）。
  String _scriptName = '';

  @override
  void initState() {
    super.initState();
    _scriptName = _resolveInitialScript();
    _ensureController();
  }

  String _resolveInitialScript() {
    final scriptService = Get.find<ScriptService>();
    final active = Get.isRegistered<HomeDashboardController>()
        ? Get.find<HomeDashboardController>().activeScriptName.value
        : '';
    if (active.isNotEmpty) return active;
    final names = scriptService.scriptOrderList;
    return names.isEmpty ? '' : names.first;
  }

  void _ensureController() {
    if (_scriptName.isEmpty) return;
    final tag = 'dashboard-$_scriptName';
    if (!Get.isRegistered<DashboardOverviewController>(tag: tag)) {
      Get.put(
        DashboardOverviewController(scriptName: _scriptName),
        tag: tag,
        permanent: false,
      );
    }
  }

  void _switchScript(String name) {
    if (name == _scriptName || name.isEmpty) return;
    // 销毁旧配置的控制器：它带 2 分钟兜底定时器，留着就是每切一次配置
    // 多一个永不停止的轮询（与资产页曾经的泄漏同类）。
    _disposeController(_scriptName);
    setState(() => _scriptName = name);
    _ensureController();
    // 记住选择，让其它页面（资产/统计）跟随，避免"仪表盘看 A、资产页看 B"
    if (Get.isRegistered<HomeDashboardController>()) {
      Get.find<HomeDashboardController>().setActiveScript(name);
    }
  }

  void _disposeController(String name) {
    if (name.isEmpty) return;
    final tag = 'dashboard-$name';
    if (Get.isRegistered<DashboardOverviewController>(tag: tag)) {
      Get.delete<DashboardOverviewController>(tag: tag, force: true);
    }
  }

  @override
  void dispose() {
    // 页面离开时释放当前配置的控制器（含其定时器）
    _disposeController(_scriptName);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scriptService = Get.find<ScriptService>();

    return Obx(() {
      final names = scriptService.scriptOrderList.toList();
      if (names.isEmpty) {
        return Center(
          child: Text(
            I18n.dashboard_no_config.tr,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        );
      }
      // 选中的配置可能被删除
      if (!names.contains(_scriptName)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _switchScript(names.first);
        });
      }

      if (!Get.isRegistered<DashboardOverviewController>(
        tag: 'dashboard-$_scriptName',
      )) {
        return const Center(child: AppProgressIndicator.circular());
      }
      final controller =
          Get.find<DashboardOverviewController>(tag: 'dashboard-$_scriptName');

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DashboardTopBar(
              names: names,
              selected: _scriptName,
              onChanged: _switchScript,
              controller: controller,
            ),
            const SizedBox(height: 14),
            // 调度器 + 今日概览：宽窗口并排，窄窗口堆叠
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 720;
                final schedule = _ScheduleCard(controller: controller);
                final today = _TodayCard(controller: controller);
                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: schedule),
                      const SizedBox(width: 12),
                      Expanded(child: today),
                    ],
                  );
                }
                return Column(children: [schedule, const SizedBox(height: 12), today]);
              },
            ),
            const SizedBox(height: 12),
            _AssetsCard(controller: controller),
            const SizedBox(height: 12),
            _LogTailCard(scriptName: _scriptName),
          ],
        ),
      );
    });
  }
}

/// 顶部条：配置切换 + 设备/角色摘要。
class _DashboardTopBar extends StatelessWidget {
  const _DashboardTopBar({
    required this.names,
    required this.selected,
    required this.onChanged,
    required this.controller,
  });

  final List<String> names;
  final String selected;
  final ValueChanged<String> onChanged;
  final DashboardOverviewController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = controller.resourceDay.value?.role ?? const {};
    final roleName = (role['name'] ?? '').toString();
    final level = role['level'];
    final serverName = (role['server_name'] ?? '').toString();

    return Row(
      children: [
        // 只有一个配置时用静态徽标，多个时用下拉切换——
        // 两者不并排（否则同一个名字会显示两遍，看着像标签重复）
        if (names.length > 1)
          AppDropdown<String>(
            value: selected,
            items: [
              for (final name in names)
                AppDropdownItem<String>(value: name, label: name),
            ],
            onChanged: (v) => onChanged(v),
          )
        else
          AppChip(
            label: selected,
            icon: Icons.dashboard_customize_outlined,
            selected: true,
          ),
        const Spacer(),
        if (roleName.isNotEmpty)
          Text(
            [
              roleName,
              if (level != null) 'Lv$level',
              if (serverName.isNotEmpty) serverName,
            ].join(' · '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

/// 调度器面板：正在跑什么、接下来跑什么。
class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.controller});

  final DashboardOverviewController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final entries = controller.scheduleEntries;
      final running = controller.isRunning;

      return AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, size: 16),
                const SizedBox(width: 6),
                Text(I18n.dashboard_schedule.tr,
                    style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                AppChip(
                  label: running
                      ? I18n.dashboard_running.tr
                      : I18n.dashboard_idle.tr,
                  color: running
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  selected: running,
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  I18n.dashboard_no_task.tr,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else
              for (final entry in entries.take(8))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Icon(
                        entry.running
                            ? Icons.play_circle_fill
                            : Icons.pause_circle_outline,
                        size: 14,
                        color: entry.running
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        entry.nextRun,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      );
    });
  }
}

/// 今日概览：时长 / 战斗 / 任务次数。
class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.controller});

  final DashboardOverviewController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final day = controller.statistics.value;
      final theme = Theme.of(context);

      return AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.today, size: 16),
                const SizedBox(width: 6),
                Text(I18n.dashboard_today.tr,
                    style: theme.textTheme.titleSmall),
                const Spacer(),
                if (controller.loadingStats.value)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: AppProgressIndicator.circular(size: 14),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (day == null || day.totalTaskRunCount == 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(I18n.dashboard_today_empty.tr,
                    style: theme.textTheme.bodySmall),
              )
            else
              Row(
                children: [
                  _Metric(
                    label: I18n.dashboard_runtime.tr,
                    value: _formatDuration(day.totalRuntimeSeconds),
                  ),
                  _Metric(
                    label: I18n.dashboard_battles.tr,
                    value: '${day.totalBattleCount}',
                  ),
                  _Metric(
                    label: I18n.dashboard_task_runs.tr,
                    value: '${day.totalTaskRunCount}',
                  ),
                ],
              ),
          ],
        ),
      );
    });
  }

  static String _formatDuration(double seconds) {
    final total = seconds.round();
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    if (h > 0) return '$h小时$m分';
    if (m > 0) return '$m分钟';
    return '$total秒';
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// 资产概览：重点资产 + 今日增量。
class _AssetsCard extends StatelessWidget {
  const _AssetsCard({required this.controller});

  final DashboardOverviewController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = controller.featuredAssets;
      final theme = Theme.of(context);
      final updated = controller.assetsUpdatedAt.value;

      return AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.diamond_outlined, size: 16),
                const SizedBox(width: 6),
                Text(I18n.resource_title.tr, style: theme.textTheme.titleSmall),
                const Spacer(),
                if (updated != null)
                  Text(
                    '${I18n.resource_updated_at.tr} ${_hms(updated)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(I18n.dashboard_assets_empty.tr,
                    style: theme.textTheme.bodySmall),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  // 自适应列数：每格至少 118 宽，避免固定宽度在窄窗口下溢出。
                  const minTile = 118.0;
                  final perRow =
                      (constraints.maxWidth / minTile).floor().clamp(1, 8);
                  final tileWidth =
                      (constraints.maxWidth - (perRow - 1) * 10) / perRow;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 12,
                    children: [
                      for (final item in items)
                        SizedBox(
                          width: tileWidth,
                          child: _AssetTile(
                            name: item.name,
                            count: item.count,
                            delta: item.delta,
                            measuredVsToday: item.deltaFrom == 'today',
                          ),
                        ),
                    ],
                  );
                },
              ),
          ],
        ),
      );
    });
  }

  static String _hms(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

class _AssetTile extends StatelessWidget {
  const _AssetTile({
    required this.name,
    required this.count,
    required this.delta,
    required this.measuredVsToday,
  });

  final String name;
  final int count;
  final int? delta;
  final bool measuredVsToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final d = delta;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _formatCount(count),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (d != null && d != 0)
            Text(
              '${d > 0 ? '+' : ''}${_formatCount(d)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: d > 0
                    ? const Color(0xFF107C10)
                    : const Color(0xFFC50F1F),
              ),
            ),
      ],
    );
  }

  static String _formatCount(int value) {
    final abs = value.abs();
    final sign = value < 0 ? '-' : '';
    if (abs >= 100000000) {
      return '$sign${(abs / 100000000).toStringAsFixed(1)}亿';
    }
    if (abs >= 10000) {
      return '$sign${(abs / 10000).toStringAsFixed(1)}万';
    }
    return '$sign$abs';
  }
}

/// 日志尾巴：最近若干行，点击可跳日志页看全部。
class _LogTailCard extends StatelessWidget {
  const _LogTailCard({required this.scriptName});

  final String scriptName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.article_outlined, size: 16),
              const SizedBox(width: 6),
              Text(I18n.dashboard_log_tail.tr, style: theme.textTheme.titleSmall),
              const Spacer(),
              AppButton(
                label: I18n.dashboard_view_all.tr,
                variant: AppButtonVariant.text,
                onPressed: () => Get.toNamed('/log'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            I18n.dashboard_log_hint.tr,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
