import 'package:flutter/material.dart';

import 'package:oasx/modules/common/widgets/appbar.dart';
import 'package:oasx/modules/settings/widgets/setting_card.dart';
import 'package:oasx/modules/settings/widgets/setting_item.dart';
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
                const AppButton(
                  label: '禁用',
                  variant: AppButtonVariant.primary,
                  onPressed: null,
                ),
                const AppButton(
                  label: '禁用描边',
                  variant: AppButtonVariant.outline,
                  onPressed: null,
                ),
              ],
            ),
          ),
          _Section(
            title: '开关 · ToggleSwitch',
            subtitle: style == AppUiStyle.fluent
                ? 'WinUI：40×20 细轨道、14px 小滑钮；关闭态是「透明底 + 1px 描边」'
                : 'Material：52×32 粗轨道、大滑钮；关闭态是实心灰底',
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 32,
                  runSpacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _SwitchDemo(label: '关闭', initial: false),
                    _SwitchDemo(label: '开启', initial: true),
                  ],
                ),
                SizedBox(height: 16),
                Wrap(
                  spacing: 32,
                  runSpacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _SwitchDemo(label: '带状态文字', initial: true, stateLabel: true),
                    _SwitchDemo(label: '带状态文字(关)', initial: false, stateLabel: true),
                  ],
                ),
                SizedBox(height: 16),
                Wrap(
                  spacing: 32,
                  runSpacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _SwitchDemo(label: '禁用(关)', initial: false, enabled: false),
                    _SwitchDemo(label: '禁用(开)', initial: true, enabled: false),
                  ],
                ),
              ],
            ),
          ),
          _Section(
            title: '设置分组 · 真实组件',
            subtitle: style == AppUiStyle.fluent
                ? 'WinUI：标题在卡片外、行高 48、行间 1px 细分割线'
                : 'Material：标题在卡片内、行紧凑、无分割线',
            child: const _SettingsCardDemo(),
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

/// 设置分组的实景演示。
///
/// 刻意复用**真实的** `SettingCard` / `SettingItem`，而不是仿制一份，
/// 这样预览页看到的就是设置页实际会渲染的样子。
class _SettingsCardDemo extends StatefulWidget {
  const _SettingsCardDemo();

  @override
  State<_SettingsCardDemo> createState() => _SettingsCardDemoState();
}

class _SettingsCardDemoState extends State<_SettingsCardDemo> {
  bool _a = true;
  bool _b = false;
  bool _c = true;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 560,
      child: SettingCard(
        title: '系统设置',
        items: [
          SettingItem(
            left: const Text('记住窗口位置与大小'),
            right: AppSwitch(
              value: _a,
              onChanged: (v) => setState(() => _a = v),
            ),
          ),
          SettingItem(
            left: const Text('最小化到系统托盘'),
            right: AppSwitch(
              value: _b,
              onChanged: (v) => setState(() => _b = v),
            ),
          ),
          SettingItem(
            left: const Text('开机自启动'),
            right: AppSwitch(
              value: _c,
              onChanged: (v) => setState(() => _c = v),
            ),
          ),
          // 可点击行：悬停时整行高亮
          SettingItem(
            left: const Text('保存路径（点整行可点击）'),
            right: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

/// 开关演示：带标题的独立状态，便于逐个切换观察。
class _SwitchDemo extends StatefulWidget {
  const _SwitchDemo({
    required this.label,
    required this.initial,
    this.enabled = true,
    this.stateLabel = false,
  });

  final String label;
  final bool initial;
  final bool enabled;
  final bool stateLabel;

  @override
  State<_SwitchDemo> createState() => _SwitchDemoState();
}

class _SwitchDemoState extends State<_SwitchDemo> {
  late bool _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            widget.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: FluentPalette.of(context).textTertiary,
            ),
          ),
        ),
        AppSwitch(
          value: _value,
          stateLabel: widget.stateLabel,
          onChanged: widget.enabled
              ? (v) => setState(() => _value = v)
              : null,
        ),
      ],
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
