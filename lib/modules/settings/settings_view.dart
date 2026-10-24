import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';

import 'package:oasx/modules/common/widgets/appbar.dart';
import 'package:oasx/modules/settings/oas_card.dart';
import 'package:oasx/modules/settings/settings_leave_handler.dart';
import 'package:oasx/modules/settings/system_card.dart';
import 'package:oasx/modules/settings/user_card.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/ui/ui.dart';
import 'package:oasx/utils/platform_utils.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({
    super.key,
    this.standalone = true,
  });

  final bool standalone;

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  static const double _layoutSpacing = 8.0;
  static const double _wideLayoutBreakpoint = 960.0;
  static const double _navWidth = 220.0;
  static const double _topAlignmentTolerance = 12.0;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _scrollViewKey = GlobalKey();
  late final List<_SettingsSection> _sections = [
    _SettingsSection(
      key: GlobalKey(),
      navTitleBuilder: () => I18n.userSetting.tr,
      cardBuilder: () => const UserSettingsCard(),
    ),
    _SettingsSection(
      key: GlobalKey(),
      navTitleBuilder: () => 'OAS${I18n.setting.tr}',
      cardBuilder: () => const OasSettingsCard(),
    ),
    _SettingsSection(
      key: GlobalKey(),
      navTitleBuilder: () => I18n.systemSetting.tr,
      cardBuilder: () => const SystemSettingsCard(),
    ),
  ];

  int? _selectedSectionIndex;
  bool _isAutoScrolling = false;
  bool _lockSelectionToClickedNav = false;
  bool _hasHandledLeave = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _syncSelectedSectionByViewport();
    });
  }

  @override
  void dispose() {
    _handleLeaveSettings();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final fluent = resolveAppUiStyle() == AppUiStyle.fluent;
    final body = SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= _wideLayoutBreakpoint;
          final settingList = _buildSettingList(keyboardInset);

          if (!isWide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (fluent) _buildPageTitle(),
                Expanded(child: settingList.paddingOnly(left: 8, right: 8)),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 页面大标题（LLT/Win11 的 Settings 标题），占满整行宽度
              if (fluent) _buildPageTitle(),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPrimaryNav(),
                    const SizedBox(width: 16),
                    Expanded(child: settingList),
                  ],
                ).paddingOnly(left: 24, right: 24, bottom: 16),
              ),
            ],
          );
        },
      ),
    );
    if (!widget.standalone) {
      return body;
    }
    return Scaffold(
      appBar: buildPlatformAppBar(context, routePath: '/settings'),
      body: body,
    );
  }

  void _handleLeaveSettings() {
    if (_hasHandledLeave) {
      return;
    }
    _hasHandledLeave = true;
    unawaited(handleSettingsLeaveEffect());
  }

  void _handleScroll() {
    if (_isAutoScrolling || _lockSelectionToClickedNav || !mounted) {
      return;
    }
    _syncSelectedSectionByViewport();
  }

  void _syncSelectedSectionByViewport() {
    final sectionIndex = _findCurrentSectionIndex();
    if (sectionIndex == _selectedSectionIndex) {
      return;
    }
    setState(() => _selectedSectionIndex = sectionIndex);
  }

  int? _findCurrentSectionIndex() {
    final viewportContext = _scrollViewKey.currentContext;
    if (viewportContext == null) {
      return _selectedSectionIndex;
    }

    final viewportRenderObject = viewportContext.findRenderObject();
    if (viewportRenderObject is! RenderBox || !viewportRenderObject.hasSize) {
      return _selectedSectionIndex;
    }

    final viewportTop = viewportRenderObject.localToGlobal(Offset.zero).dy;
    int? passedTopSectionIndex;
    int? upcomingSectionIndex;
    var nearestUpcomingTop = double.infinity;

    for (var index = 0; index < _sections.length; index++) {
      final sectionContext = _sections[index].key.currentContext;
      if (sectionContext == null) {
        continue;
      }
      final sectionRenderObject = sectionContext.findRenderObject();
      if (sectionRenderObject is! RenderBox || !sectionRenderObject.hasSize) {
        continue;
      }

      final sectionTop =
          sectionRenderObject.localToGlobal(Offset.zero).dy - viewportTop;
      if (sectionTop <= _topAlignmentTolerance) {
        passedTopSectionIndex = index;
        continue;
      }
      if (sectionTop < nearestUpcomingTop) {
        nearestUpcomingTop = sectionTop;
        upcomingSectionIndex = index;
      }
    }

    return passedTopSectionIndex ??
        upcomingSectionIndex ??
        _selectedSectionIndex;
  }

  Future<void> _scrollToSection(int index) async {
    if (index < 0 || index >= _sections.length) {
      return;
    }

    final targetContext = _sections[index].key.currentContext;
    if (targetContext == null) {
      return;
    }

    setState(() {
      _selectedSectionIndex = index;
      _lockSelectionToClickedNav = true;
    });

    _isAutoScrolling = true;
    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOutCubic,
      alignment: 0,
    );
    _isAutoScrolling = false;
  }

  Widget _buildSettingList(double keyboardInset) {
    return Scrollbar(
      controller: _scrollController,
      child: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (_isAutoScrolling || !mounted) {
            return false;
          }
          if (notification.direction != ScrollDirection.idle &&
              _lockSelectionToClickedNav) {
            setState(() => _lockSelectionToClickedNav = false);
          }
          return false;
        },
        child: SingleChildScrollView(
          key: _scrollViewKey,
          controller: _scrollController,
          keyboardDismissBehavior: PlatformUtils.isWeb
              ? ScrollViewKeyboardDismissBehavior.manual
              : ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(
            bottom: keyboardInset > 0 ? keyboardInset + 24 : 0,
          ),
          child: Column(
            children: _sections
                .map(
                  (section) => Container(
                    key: section.key,
                    margin: const EdgeInsets.only(bottom: _layoutSpacing),
                    child: section.cardBuilder(),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  /// 页面大标题：28px 粗体，占满内容区宽度（LLT 的 "Settings"）。
  Widget _buildPageTitle() {
    final theme = Theme.of(context);
    final p = FluentPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Text(
        I18n.setting.tr,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: p.textPrimary,
        ),
      ),
    );
  }

  /// 左侧分区导航：**单个容器**装所有分区项（LLT 风格）。
  ///
  /// 选中项是「左侧 3×20 蓝条 + 圆角高亮块」，与顶部导航栏的选中态一致。
  Widget _buildPrimaryNav() {
    final theme = Theme.of(context);
    final p = FluentPalette.of(context);
    final accent = theme.colorScheme.primary;

    return SizedBox(
      width: _navWidth,
      child: AppCard(
        variant: AppCardVariant.elevated,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_sections.length, (index) {
            final isSelected = index == _selectedSectionIndex;
            return _SectionNavItem(
              label: _sections[index].navTitleBuilder(),
              selected: isSelected,
              accent: accent,
              textColor: isSelected ? p.textPrimary : p.textSecondary,
              fill: isSelected ? p.rowHover : Colors.transparent,
              onTap: () => _scrollToSection(index),
            );
          }),
        ),
      ),
    );
  }
}

/// 分区导航项：左侧蓝条 + 圆角高亮块（与顶部导航栏同款选中态）。
class _SectionNavItem extends StatefulWidget {
  const _SectionNavItem({
    required this.label,
    required this.selected,
    required this.accent,
    required this.textColor,
    required this.fill,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final Color textColor;
  final Color fill;
  final VoidCallback onTap;

  @override
  State<_SectionNavItem> createState() => _SectionNavItemState();
}

class _SectionNavItemState extends State<_SectionNavItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = FluentPalette.of(context);
    const anim = Duration(milliseconds: 160);

    final fill = widget.selected
        ? widget.fill
        : (_hovering ? p.rowPressed : Colors.transparent);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              // 左侧 3×20 蓝条
              SizedBox(
                width: 8,
                child: AnimatedOpacity(
                  duration: anim,
                  opacity: widget.selected ? 1 : 0,
                  child: Center(
                    child: Container(
                      width: 3,
                      height: 20,
                      decoration: BoxDecoration(
                        color: widget.accent,
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: AnimatedContainer(
                  duration: anim,
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: widget.textColor,
                          fontWeight: widget.selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSection {
  _SettingsSection({
    required this.key,
    required this.navTitleBuilder,
    required this.cardBuilder,
  });

  final GlobalKey key;
  final String Function() navTitleBuilder;
  final Widget Function() cardBuilder;
}
