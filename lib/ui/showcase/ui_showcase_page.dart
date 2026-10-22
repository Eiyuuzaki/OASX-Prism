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
            title: '输入框 · TextBox',
            subtitle: style == AppUiStyle.fluent
                ? 'WinUI：聚焦时底部出现 2px 强调色下划线'
                : 'Material：圆角填充 + 聚焦描边',
            child: const _TextFieldDemo(),
          ),
          _Section(
            title: '导航栏 · NavigationView',
            subtitle: style == AppUiStyle.fluent
                ? 'WinUI：图标在左、文字在右；选中是左侧 3×16 圆角竖条'
                : 'Material：图标在上、文字在下；选中是胶囊高亮',
            child: const _NavBarDemo(),
          ),
          _Section(
            title: '对话框 · ContentDialog',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                AppButton(
                  label: '打开对话框',
                  icon: Icons.open_in_new_rounded,
                  variant: AppButtonVariant.primary,
                  onPressed: () => _showDemoDialog(context),
                ),
                AppButton(
                  label: '带输入的对话框',
                  onPressed: () => _showInputDialog(context),
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

/// 输入框演示：聚焦输入框即可看到 WinUI 的底部强调线。
class _TextFieldDemo extends StatefulWidget {
  const _TextFieldDemo();

  @override
  State<_TextFieldDemo> createState() => _TextFieldDemoState();
}

class _TextFieldDemoState extends State<_TextFieldDemo> {
  final _single = TextEditingController();
  final _multi = TextEditingController();

  @override
  void dispose() {
    _single.dispose();
    _multi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 420,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: _single,
            hintText: '单行输入（点这里聚焦）',
            prefixIcon: const Icon(Icons.search_rounded, size: 18),
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _multi,
            hintText: '多行输入',
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          const AppTextField(
            hintText: '禁用状态',
            enabled: false,
          ),
          const SizedBox(height: 16),
          const AppTextField(
            hintText: '带错误提示',
            errorText: '这个值不合法',
          ),
        ],
      ),
    );
  }
}

/// 导航栏演示：可点击切换选中项，观察指示条移动。
class _NavBarDemo extends StatefulWidget {
  const _NavBarDemo();

  @override
  State<_NavBarDemo> createState() => _NavBarDemoState();
}

class _NavBarDemoState extends State<_NavBarDemo> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 160,
            child: AppNavBar(
              selectedIndex: _index,
              onSelected: (i) => setState(() => _index = i),
              destinations: const [
                AppNavDestination(icon: Icons.home_rounded, label: '主页'),
                AppNavDestination(
                    icon: Icons.settings_rounded, label: '设置'),
                AppNavDestination(icon: Icons.tune_rounded, label: '参数'),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '点左侧各项，观察选中指示条（3×16 圆角竖条）与悬停填充。\n'
              '当前选中：$_index',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// 普通对话框演示。
void _showDemoDialog(BuildContext context) {
  showAppDialog(
    context: context,
    builder: (ctx) => AppDialog(
      title: const Text('确认操作'),
      content: const Text(
        '这是一个语义对话框。在 Windows 上会渲染成 WinUI 的 '
        'ContentDialog：8px 圆角、烟幕遮罩、右下角按钮。',
      ),
      actions: [
        AppButton(
          label: '取消',
          onPressed: () => Navigator.of(ctx).pop(),
        ),
        AppButton(
          label: '确定',
          variant: AppButtonVariant.primary,
          onPressed: () => Navigator.of(ctx).pop(),
        ),
      ],
    ),
  );
}

/// 带输入框的对话框演示。
void _showInputDialog(BuildContext context) {
  showAppDialog(
    context: context,
    builder: (ctx) => AppDialog(
      title: const Text('重命名'),
      content: const SizedBox(
        width: 320,
        child: AppTextField(hintText: '输入新名称'),
      ),
      actions: [
        AppButton(
          label: '取消',
          onPressed: () => Navigator.of(ctx).pop(),
        ),
        AppButton(
          label: '保存',
          variant: AppButtonVariant.primary,
          onPressed: () => Navigator.of(ctx).pop(),
        ),
      ],
    ),
  );
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
