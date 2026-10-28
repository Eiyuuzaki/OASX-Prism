import 'package:flutter_nb_net/flutter_net.dart';

class UpdateInfoModel extends BaseNetModel {
  @override
  UpdateInfoModel fromJson(Map<String, dynamic> json) {
    return UpdateInfoModel.fromJson(json);
  }

  UpdateInfoModel({
    this.isUpdate,
    this.branch,
    this.currentCommit,
    this.latestCommit,
    this.commit,
  });
  UpdateInfoModel.fromJson(dynamic json) {
    // 后端在 updater 异常时会 `return None`（home_router），get_commit 拿不到
    // origin 分支时也会返回一串 None。这些情况都会让下面那句 `!` 抛
    // NoSuchMethodError/TypeError，整个更新弹窗直接报错。所以全部按空处理。
    if (json is! Map) {
      currentCommit = const [];
      latestCommit = const [];
      commit = const [];
      return;
    }
    isUpdate = json['is_update'];
    branch = json['branch'];
    currentCommit = _asStringList(json['current_commit']);
    latestCommit = _asStringList(json['latest_commit']);
    commit = _asRows(json['commit']);
  }

  static List<String> _asStringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) => e?.toString() ?? '').toList();
  }

  static List<List<String>> _asRows(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<List>()
        .map((row) => row.map((e) => e?.toString() ?? '').toList())
        .toList();
  }

  bool? isUpdate;
  String? branch;
  List<String>? currentCommit;
  List<String>? latestCommit;
  List<List<String>>? commit;
}
