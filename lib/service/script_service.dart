import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/modules/common/controllers/progress_snackbar_controller.dart';
import 'package:oasx/modules/common/models/storage_key.dart';
import 'package:oasx/modules/home/models/config_model.dart';
import 'package:oasx/modules/home/models/taskitem_model.dart';
import 'package:oasx/service/websocket_service.dart';
import 'package:oasx/service/profile_service.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/utils/extension_utils.dart';
import 'package:oasx/utils/platform_utils.dart';
import 'package:oasx/utils/time_utils.dart';
import 'package:oasx/modules/log/script_log_controller.dart';
import 'package:oasx/ui/ui.dart';

part 'script_service_ws.dart';
part 'script_service_auto.dart';
part 'script_service_config.dart';

class ScriptService extends GetxService {
  // ignore: unused_field
  final _storage = GetStorage();
  final wsService = Get.find<WebSocketService>();
  final scriptModelMap = <String, ScriptModel>{}.obs;
  final scriptOrderList = <String>[].obs;
  final autoScriptList = <String>[].obs;
  bool _detached = false;
  int _backendGeneration = 0;
  Future<void>? _detachFuture;

  /// 每个脚本一条 WS 状态订阅。
  ///
  /// `connectScript` 每次启动脚本 / 同步配置都会重连一次，若不在这里
  /// 记住并取消旧订阅，监听会线性累积：WS 状态翻一次触发 N 次重复
  /// `update`，客户端关闭后闭包还攥着旧状态。
  final _statusSubscriptions = <String, StreamSubscription<dynamic>>{};

  bool get _shouldSkipBackendReload {
    return PlatformUtils.isWeb && !ApiClient().hasConfiguredBackendAddress;
  }

  @override
  Future<void> onInit() async {
    _loadAutoScriptListFromStorage();
    await reloadFromServer();
    super.onInit();
  }

  @override
  Future<void> onClose() async {
    await detach();
    super.onClose();
  }

  /// Closing the client only detaches observers; tasks belong to the backend.
  Future<void> detach() {
    _detached = true;
    // 断开所有脚本的状态订阅，避免闭包攥着已关闭客户端的旧状态
    for (final sub in _statusSubscriptions.values) {
      unawaited(sub.cancel());
    }
    _statusSubscriptions.clear();
    return _detachFuture ??= resetDashboardState();
  }

  void addScriptModel(dynamic sm) {
    if (_detached) return;
    if (sm is String) {
      sm = ScriptModel(sm);
    }
    if (scriptModelMap.containsKey(sm.name)) return;
    scriptModelMap[sm.name] = sm;
    if (!scriptOrderList.contains(sm.name)) {
      scriptOrderList.add(sm.name);
    }
  }

  void updateScriptModel(ScriptModel sm) {
    if (!scriptModelMap.containsKey(sm.name)) return;
    scriptModelMap[sm.name] = sm;
  }

  void addOrUpdateScriptModel(ScriptModel sm) {
    if (scriptModelMap.containsKey(sm.name)) {
      updateScriptModel(sm);
    } else {
      addScriptModel(sm);
    }
  }

  void deleteScriptModel(String name) {
    if (!scriptModelMap.containsKey(name)) return;
    scriptModelMap.remove(name);
    // 断开该脚本的状态订阅，避免 WS 关闭后仍有闭包持有已删除的模型
    unawaited(_cancelStatusSubscription(name));
    wsService.close(name);
    autoScriptList.removeWhere((e) => e == name);
    scriptOrderList.removeWhere((e) => e == name);
  }

  void syncScriptOrder(Iterable<String> scripts) {
    final normalized = scripts
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    scriptOrderList.value = normalized;
    for (final name in normalized) {
      if (!scriptModelMap.containsKey(name)) {
        addScriptModel(name);
      }
    }
    final validSet = normalized.toSet();
    final stale = scriptModelMap.keys
        .where((e) => !validSet.contains(e))
        .toList();
    for (final name in stale) {
      deleteScriptModel(name);
    }
  }

  ScriptModel? findScriptModel(String name) {
    return scriptModelMap[name];
  }

  bool isRunning(String scriptName) {
    return scriptModelMap.containsKey(scriptName) &&
        scriptModelMap[scriptName]!.state.value == ScriptState.running;
  }

  Future<bool> tryCloseScriptWithReason(String scriptName) async {
    try {
      final scriptModel = findScriptModel(scriptName);
      if (scriptModel != null &&
          scriptModel.state.value == ScriptState.running) {
        AppInfoBar.show(
          I18n.tip.tr,
          message: I18n.configUpdateTip.tr,
          duration: const Duration(milliseconds: 2000),
          );
        return false;
      }
      await wsService.close(scriptName);
      return true;
    } catch (e) {
      if (e.toString().contains('not found')) {
        return true;
      }
      return false;
    }
  }

  Future<void> refreshScriptsFromServer() async {
    if (_detached) return;
    final generation = _backendGeneration;
    if (_shouldSkipBackendReload) {
      await resetDashboardState();
      return;
    }
    final latest = await ApiClient().getScriptList();
    if (_detached || generation != _backendGeneration) return;
    syncScriptOrder(latest);
  }

  Future<void> reloadFromServer() async {
    if (_detached) return;
    final generation = _backendGeneration;
    if (_shouldSkipBackendReload) {
      await resetDashboardState();
      return;
    }
    final scriptList = await ApiClient().getScriptList();
    if (_detached || generation != _backendGeneration) return;
    syncScriptOrder(scriptList);
    if (scriptList.isEmpty) {
      return;
    }
    await Future.wait(scriptList.map((name) => connectScript(name)));
  }

  Future<void> resetDashboardState() async {
    ++_backendGeneration;
    final closing = wsService.closeAll();
    final names = scriptModelMap.keys.toList();
    for (final name in names) {
      if (Get.isRegistered<ScriptLogController>(tag: name)) {
        try {
          Get.delete<ScriptLogController>(tag: name, force: true);
        } catch (_) {}
      }
    }
    scriptModelMap.clear();
    scriptOrderList.clear();
    await closing;
  }
}
