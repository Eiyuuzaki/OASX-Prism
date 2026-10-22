part of resource;

/// 顶部工具条：Material 3 规范排列。
///
/// 结构（从上到下）：
/// ```
/// ┌──────────────────────────────────────┐
/// │ 行1: 角色下拉 ▾            (2)        │  ← MenuAnchor + DropdownMenuButton
/// │ 行2: [📅 10-19 ▾]      ● 未在采集     │  ← 日期(同一层级) + 状态圆点
/// │ 行3: 更新于 02:35:52        (⬇) (⟳)  │  ← 时间 + 圆形 IconButton
/// └──────────────────────────────────────┘
/// ```
///
/// 三行结构保留（演进史见 git）：任何窗口宽度都不溢出，
/// 行1 最坏 ≈ 角色名，行2 ≈ 230px，行3 时间可缩。
class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.controller});

  final ResourceController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dates = controller.dates;
    final current = controller.selectedDate.value;
    final updatedAt = controller.day.value.updatedAt;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- 行1：角色（MenuAnchor 下拉按钮，带箭头 + 悬停反馈）----
          _RoleSelector(controller: controller),
          const SizedBox(height: 8),
          // ---- 行2：日期 + 状态 ----
          Row(
            children: [
              Flexible(
                child: AppDropdown<String>(
                  icon: Icons.calendar_today_rounded,
                  dense: true,
                  maxWidth: 100,
                  value: current,
                  items: [
                    for (final d in dates)
                      AppDropdownItem(value: d, label: d),
                  ],
                  onChanged: controller.changeDate,
                ),
              ),
              const SizedBox(width: 12),
              _StatusChip(controller: controller),
            ],
          ),
          const SizedBox(height: 6),
          // ---- 行3：更新时间 + 操作按钮（同层级，圆形 IconButton）----
          Row(
            children: [
              Expanded(
                child: Text(
                  updatedAt.isEmpty
                      ? I18n.resource_updated_at.tr
                      : '${I18n.resource_updated_at.tr} $updatedAt',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 采集：进行中转圈、平时标准图标
              AppIconButton(
                tooltip: I18n.resource_collect_now.tr,
                onPressed: controller.collecting.value
                    ? null
                    : controller.collectNow,
                icon: Icons.download_rounded,
                iconSize: 20,
                child: controller.collecting.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : null,
              ),
              const SizedBox(width: 4),
              AppIconButton(
                tooltip: I18n.resource_refresh.tr,
                onPressed:
                    controller.loading.value ? null : controller.reload,
                icon: Icons.refresh_rounded,
                iconSize: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

