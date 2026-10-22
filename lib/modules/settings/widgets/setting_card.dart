import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';

import 'package:oasx/modules/settings/widgets/setting_item.dart';
import 'package:oasx/ui/ui.dart';

/// 设置分组卡片。
///
/// Windows 上改用 Win11 设置页的布局：
/// - **分组标题在卡片外面**（系统设置就是这样，标题是分区标签不是卡片内容）
/// - 卡片内是若干行，行与行之间有 1px 细分割线（左右内缩）
/// - 卡片本身用「卡片底 + 细描边」，不用阴影
///
/// 其它平台保持原来的 Material 观感（标题在卡片内、无分割线）。
class SettingCard extends StatelessWidget {
  final String title;
  final List<SettingItem> items;

  const SettingCard({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (resolveAppUiStyle() == AppUiStyle.fluent) {
      return _buildFluent(context);
    }
    return _buildMaterial(context);
  }

  Widget _buildMaterial(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: <Widget>[
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...items
              .map(
                (item) => item.padding(bottom: 5),
              )
              .toList(),
        ].toColumn(crossAxisAlignment: CrossAxisAlignment.start),
      ),
    );
  }

  Widget _buildFluent(BuildContext context) {
    final theme = Theme.of(context);
    final p = FluentPalette.of(context);

    // 行之间插 1px 细线（Win11 的分割方式，左右内缩 16）
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) {
        rows.add(Divider(
          height: 1,
          thickness: 1,
          indent: 16,
          endIndent: 16,
          color: p.stroke,
        ));
      }
      rows.add(items[i]);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 分组标题在卡片外，字号比 Material 的 titleMedium 小、
          // 用次级文字色——Win11 的分区标签是"弱强调"
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                color: p.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          AppCard(
            variant: AppCardVariant.elevated,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: rows,
            ),
          ),
        ],
      ),
    );
  }
}
