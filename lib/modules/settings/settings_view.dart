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
          final settingList = _buildSettingList(keyboardInset);

          // 单列布局：大标题 + 卡片列表（不再有左侧分区导航）。
          //
          // 设置只有三个分区，撑不起一个导航栏，反而制造了"三项菜单"
          // 和"滚到底高亮不跟手"的问题。分区标识回到卡片上方的分组
          // 标题（见 SettingCard.showTitle）。
          //
          // 左右内边距统一在这里给，保证所有卡片（含最后一张）左右
          // 严格对齐——之前卡片各自带 margin，出现过底部卡片偏移。
          final inset = fluent ? 24.0 : 8.0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (fluent) _buildPageTitle(),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    inset,
                    0,
                    inset,
                    fluent ? 16 : 0,
                  ),
                  child: settingList,
                ),
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
