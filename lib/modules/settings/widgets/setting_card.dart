import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';

import 'package:oasx/modules/settings/widgets/setting_item.dart';
import 'package:oasx/ui/ui.dart';

/// 设置分组。
///
/// Windows 上按 Legion Toolkit（WinUI 风格）的布局：
/// - 分区标题在卡片外（20px 粗体，页面级标签）
/// - **每一项各自一张独立卡片**，卡片间 8px 间隙，不用分割线
/// - 卡片用「卡片底 + 细描边」，不用阴影
///
/// 其它平台保持原来的 Material 观感（一张大卡片 + 分割线）。
class SettingCard extends StatelessWidget {
  final String title;
  final List<SettingItem> items;

  /// 是否在卡片上方显示分区标题。
  ///
  /// Windows 上**显示**：设置页已改成单列布局、去掉了左侧分区导航，
  /// 分区只能靠卡片上方的标题来标识（否则三组设置混在一起分不清）。
  /// 其它平台保持 Material 的原样（标题在卡片内）。
  final bool showTitle;

  const SettingCard({
    super.key,
    required this.title,
    required this.items,
    this.showTitle = true,
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 分区标题：默认隐藏（左侧导航已指示当前位置）。
          // 需要时打开 showTitle，20px 粗体、用 textPrimary——
          // 标题浮在材质上，灰色对比度不足。
          if (showTitle)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: p.textPrimary,
                ),
              ),
            ),
          // 每一项一张独立卡片（LLT 风格），卡片间 8px 间隙
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            AppCard(
              variant: AppCardVariant.elevated,
              child: items[i],
            ),
          ],
        ],
      ),
    );
  }
}
