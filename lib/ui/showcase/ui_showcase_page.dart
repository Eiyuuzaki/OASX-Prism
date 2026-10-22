import 'package:flutter/material.dart';

import 'package:oasx/modules/common/widgets/appbar.dart';
import 'package:oasx/ui/ui.dart';

/// 语义组件预览页。
///
/// 开发工具：把当前平台下所有语义组件的实际渲染效果集中展示，
/// 方便肉眼验收「这个平台看起来像不像那个平台」。
///
/// **头部使用真实的 `buildPlatformAppBar`**，而不是普通的 `MaterialAppBar`，
/// 否则看不到 Windows 上自绘的 Fluent 头部效果。
///
/// 用法：`flutter run -t lib/main_showcase.dart`，或从设置里进入。
class UiShowcasePage extends StatelessWidget {
  const UiShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    final style = resolveAppUiStyle();
    final theme = Theme.of(context);
    final p = FluentPalette.of(context);

    return Scaffold(
      backgroundColor: style == AppUiStyle.fluent ? p.layer : null,
      // 真实的应用头部：Windows 上会渲染成 Fluent 自绘标题栏
      appBar: buildPlatformAppBar(
        context,
        routePath: '/home',
        trailingActions: [
          IconButton(
            tooltip: '设置',
            onPressed: () {},
            icon: const Icon(Icons.settings_rounded, size: 20),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _Section(
            title: '按钮 · 变体',
            subtitle: style == AppUiStyle.fluent
                ? 'WinUI：4px 圆角、无涟漪、悬停整块变色'
                : 'Material：圆角胶囊 + 水波纹',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                AppButton(
                  label: '主要操作',
                  variant: AppButtonVariant.primary,
                  onPressed: () {},
                ),
                AppButton(
                  label: '次要操作',
                  variant: AppButtonVariant.secondary,
                  onPressed: () {},
                ),
                AppButton(
                  label: '描边按钮',
                  variant: AppButtonVariant.outline,
                  onPressed: () {},
                ),
                AppButton(
                  label: '文字按钮',
                  variant: AppButtonVariant.text,
                  onPressed: () {},
                ),
              ],
            ),
          ),
          _Section(
            title: '按钮 · 带图标',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                AppButton(
                  label: '保存',
                  icon: Icons.save_rounded,
                  variant: AppButtonVariant.primary,
                  onPressed: () {},
                ),
                AppButton(
                  label: '刷新',
                  icon: Icons.refresh_rounded,
                  onPressed: () {},
                ),
                AppButton(
                  label: '下一步',
                  trailingIcon: Icons.arrow_forward_rounded,
                  variant: AppButtonVariant.outline,
                  onPressed: () {},
                ),
              ],
            ),
          ),
          _Section(
            title: '按钮 · 尺寸与状态',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                AppButton(
                  label: '紧凑',
                  dense: true,
                  onPressed: () {},
                ),
                AppButton(
                  label: '禁用',
                  variant: AppButtonVariant.primary,
                  onPressed: null,
                ),
                AppButton(
                  label: '禁用描边',
                  variant: AppButtonVariant.outline,
                  onPressed: null,
                ),
              ],
            ),
          ),
          _Section(
            title: '卡片 · 三种变体',
            child: Column(
              children: [
                AppCard(
                  variant: AppCardVariant.elevated,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.layers_rounded, size: 20),
                      const SizedBox(width: 12),
                      Text('elevated · 常规容器',
                          style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  variant: AppCardVariant.filled,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.style_rounded, size: 20),
                      const SizedBox(width: 12),
                      Text('filled · 强调容器',
                          style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  variant: AppCardVariant.outlined,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.crop_square_rounded, size: 20),
                      const SizedBox(width: 12),
                      Text('outlined · 弱强调容器',
                          style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (style == AppUiStyle.fluent) ...[
            _Section(
              title: 'Fluent 色板',
              subtitle: 'WinUI 3 分层逻辑：layer / card / stroke',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Swatch('layer', p.layer),
                  _Swatch('layerAlt', p.layerAlt),
                  _Swatch('card', p.card),
                  _Swatch('cardHover', p.cardHover),
                  _Swatch('cardPressed', p.cardPressed),
                  _Swatch('stroke', p.stroke),
                  _Swatch('accent', p.accent),
                ],
              ),
            ),
            _Section(
              title: 'Fluent 文字色阶',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('textPrimary · 主要文字',
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: p.textPrimary)),
                  const SizedBox(height: 6),
                  Text('textSecondary · 次要文字',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: p.textSecondary)),
                  const SizedBox(height: 6),
                  Text('textTertiary · 三级文字',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: p.textTertiary)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 40),
          Center(
            child: Text(
              '当前平台解析为：${_styleLabel(style)}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: p.textTertiary),
            ),
          ),
        ],
      ),
    );
  }

  String _styleLabel(AppUiStyle style) {
    return switch (style) {
      AppUiStyle.fluent => 'Fluent (WinUI 3)',
      AppUiStyle.material => 'Material 3',
      AppUiStyle.cupertino => 'Cupertino',
    };
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = resolveAppUiStyle();
    final p = FluentPalette.of(context);
    final titleColor =
        style == AppUiStyle.fluent ? p.textPrimary : null;
    final subColor =
        style == AppUiStyle.fluent ? p.textTertiary : theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600, color: titleColor),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(color: subColor),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 96,
          height: 56,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
              width: 1,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}
