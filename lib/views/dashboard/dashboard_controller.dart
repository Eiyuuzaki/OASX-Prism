import 'dart:async';

import 'package:get/get.dart';

import 'package:oasx/api/api_client.dart';
import 'package:oasx/modules/home/models/config_model.dart';
import 'package:oasx/modules/home/models/script_statistics_models.dart';
import 'package:oasx/service/script_service.dart';

/// 仪表盘的数据聚合层。
///
/// 定位是**只读速览**：不承担任何配置/任务管理，只把「跑得怎么样、赚了多少」
/// 汇总到一屏。因此这里的职责很窄——从已有服务与 API 取数、格式化，不写任何
/// 后端状态。
///
/// 数据有三个来源，刷新节奏各不相同：
///
/// * **调度器**：`ScriptService` 里由 WebSocket 实时推送（`ScriptModel`
///   的 state/runningTask/pending/waiting），这里只做订阅，不额外轮询。
/// * **统计**：按日拉一次 `/stats/<脚本>?date=`，切配置或跨天时重取。
/// * **资产**：按日拉一次 `/resource/<脚本>`，同样低频。
///
/// 因此仪表盘自身只有一个低频定时器（用于跨天、以及避免 WS 断线后状态卡死），
/// 不打扰后端。
class DashboardOverviewController extends GetxController {
  DashboardOverviewController({
    required this.scriptName,
    ScriptService? scriptService,
  }) : _scriptService = scriptService ?? Get.find<ScriptService>();

  /// 当前正在查看的配置名。
  final String scriptName;

  final ScriptService _scriptService;

  /// 当日统计（null 表示还没加载到 / 今天没跑过）。
  final statistics = Rxn<ScriptStatisticsDay>();

  /// 当日资产。
  final resourceDay = Rxn<ResourceDayModel>();

  /// 拉取状态（用于骨架/重试态）。
  final loadingStats = false.obs;
  final loadingAssets = false.obs;

  /// 最近一次成功拉取的时间，用于「3 分钟前」这类提示。
  final statsUpdatedAt = Rxn<DateTime>();
  final assetsUpdatedAt = Rxn<DateTime>();

  /// 资产卡默认展示的重点项。
  ///
  /// 后端 `/resource` 会返回 190+ 项（大量已过期道具、往期活动代币，
  /// 数量为 0 的已经被后端滤掉），直接全列会淹没有用信息。这里先按名称
  /// 匹配常用的大额资产，剩余的再由「今日有增量」兜底补充。
  static const _priorityAssetNames = <String>[
    '体力',
    '勾玉',
    '金币',
    '神秘的符咒',
    '御札',
    '荣誉',
    '皮肤券',
    '金蛇皮',
  ];

  Timer? _refreshTimer;

  /// 当前配置的实时模型（WebSocket 推送）。可能在连接建立前为 null。
  ScriptModel? get scriptModel => _scriptService.findScriptModel(scriptName);

  /// 是否正在运行。
  bool get isRunning => scriptModel?.state.value == ScriptState.running;

  /// 正在运行的任务名（空表示空闲）。
  String get runningTaskName => scriptModel?.runningTask.value.taskName.value ?? '';

  /// 等待中的任务（含 pending + waiting，按时间合并）。
  List<ScriptTaskEntry> get scheduleEntries {
    final model = scriptModel;
    if (model == null) return const [];
    final entries = <ScriptTaskEntry>[];
    final running = model.runningTask.value;
    if (running.taskName.value.isNotEmpty) {
      entries.add(ScriptTaskEntry(
        name: running.taskName.value,
        nextRun: running.nextRun.value,
        running: true,
      ));
    }
    for (final item in model.pendingTaskList) {
      if (item.taskName.value.isEmpty) continue;
      entries.add(ScriptTaskEntry(
        name: item.taskName.value,
        nextRun: item.nextRun.value,
      ));
    }
    for (final item in model.waitingTaskList) {
      if (item.taskName.value.isEmpty) continue;
      entries.add(ScriptTaskEntry(
        name: item.taskName.value,
        nextRun: item.nextRun.value,
      ));
    }
    return entries;
  }

  /// 待执行任务数量（参考图里的「22 等待中」）。
  int get pendingCount =>
      (scriptModel?.pendingTaskList.length ?? 0) +
      (scriptModel?.waitingTaskList.length ?? 0);

  /// 资产卡要展示的条目：优先重点项，再补「今日有变动」的其余项。
  List<ResourceItemModel> get featuredAssets {
    final day = resourceDay.value;
    if (day == null) return const [];

    final byName = <String, ResourceItemModel>{};
    for (final item in day.items) {
      // 同名只留数量最大的那条（同名多 ID 的情况见资产页注释）
      final existing = byName[item.name];
      if (existing == null || item.count > existing.count) {
        byName[item.name] = item;
      }
    }

    final picked = <ResourceItemModel>[];
    final used = <String>{};
    for (final name in _priorityAssetNames) {
      final hit = byName[name];
      if (hit != null) {
        picked.add(hit);
        used.add(name);
      }
    }

    // 兜底：今日有增量的其他资产，按增量绝对值补到 8 个
    final rest = day.items
        .where((e) => !used.contains(e.name) && (e.delta ?? 0) != 0)
        .toList()
      ..sort((a, b) => (b.delta ?? 0).abs().compareTo((a.delta ?? 0).abs()));
    for (final item in rest) {
      if (picked.length >= 8) break;
      if (used.contains(item.name)) continue;
      picked.add(item);
      used.add(item.name);
    }
    return picked;
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(reload());
    // 低频兜底：主要为了跨天自动换日；顺带在被 WS 断线卡住时自愈。
    _refreshTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      unawaited(reload());
    });
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    super.onClose();
  }

  /// 拉取统计与资产。两个请求互不阻塞，各自维护 loading 态。
  ///
  /// 注意方法名不能叫 `refresh`：GetxController 自带同名成员。
  Future<void> reload() async {
    await Future.wait([
      _loadStats(),
      _loadAssets(),
    ]);
  }

  Future<void> _loadStats() async {
    if (loadingStats.value) return;
    loadingStats.value = true;
    try {
      final today = _todayKey();
      final day = await ApiClient().getScriptStatisticsDay(scriptName, today);
      statistics.value = day;
      statsUpdatedAt.value = DateTime.now();
    } catch (e) {
      // 今天没跑过时后端会返回空统计，属正常；这里只吞掉网络类错误，
      // 界面上靠「暂无数据」占位表达。
      printError(info: 'DashboardOverview stats: $e');
    } finally {
      loadingStats.value = false;
    }
  }

  Future<void> _loadAssets() async {
    if (loadingAssets.value) return;
    loadingAssets.value = true;
    try {
      final day = await ApiClient().getResourceDay(scriptName);
      resourceDay.value = day;
      assetsUpdatedAt.value = DateTime.now();
    } catch (e) {
      printError(info: 'DashboardOverview assets: $e');
    } finally {
      loadingAssets.value = false;
    }
  }

  static String _todayKey() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }
}

/// 调度器面板的一行。
class ScriptTaskEntry {
  const ScriptTaskEntry({
    required this.name,
    required this.nextRun,
    this.running = false,
  });

  final String name;

  /// 下次运行时间（后端给的原始文本，可能为空）。
  final String nextRun;

  /// 是否是"正在跑"的那一行。
  final bool running;
}
