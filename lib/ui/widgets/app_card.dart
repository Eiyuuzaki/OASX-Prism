import 'package:flutter/material.dart';

import 'package:oasx/ui/impl/fluent/fluent_tokens.dart';
import 'package:oasx/ui/style.dart';

/// 语义化卡片：跨平台统一入口。
///
/// 业务代码用 [AppCard] 而不是裸 `Card`，由这里决定各平台的具体呈现：
///
/// | 风格 | 呈现 |
/// |---|---|
/// | fluent | 细描边 + 极浅填充（WinUI 的 Layer 卡片），无阴影 |
/// | material | M3 的 `Card.filled` / `Card.outlined` / 默认 elevation |
/// | cupertino | 无阴影纯色块 + iOS 分组分隔线风格 |
///
/// 三种形态覆盖了原来 `Card` / `Card.filled` / `Card.outlined` 的全部用法，
/// 语义上用 [AppCardVariant] 表达"想表达什么"，而不是"用什么组件"。
enum AppCardVariant {
  /// 常规容器：有轻微层级感（原 `Card`）。
  elevated,

  /// 强调容器：用色调底表达分组（原 `Card.filled`）。
  filled,

  /// 弱强调容器：只有描边，用于嵌套或次要信息（原 `Card.outlined`）。
  outlined,
}

/// 跨平台语义卡片。
class AppCard extends StatelessWidget {
  /// 创建语义卡片。
  const AppCard({
    super.key,
    required this.child,
    this.variant = AppCardVariant.elevated,
    this.padding,
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.borderRadius,
  });

  /// 卡片内容。
  final Widget child;

  /// 语义变体，决定各平台的呈现。
  final AppCardVariant variant;

  /// 内边距；为空时不加额外 padding（由内容自己控制）。
  final EdgeInsetsGeometry? padding;

  /// 外边距。
  final EdgeInsetsGeometry margin;

  /// 点击回调；非空时整张卡片可点击并带涟漪/悬停反馈。
  final VoidCallback? onTap;

  /// 自定义圆角；为空时用 [AppRadius.medium]。
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final style = resolveAppUiStyle();

    // 圆角按平台取：Fluent 比 M3 更"方"（卡片 8 vs 12）
    final radius = borderRadius ??
        (style == AppUiStyle.fluent
            ? FluentRadius.cardRadius
            : AppRadius.mediumRadius);
    final shape = RoundedRectangleBorder(borderRadius: radius);

    if (style == AppUiStyle.fluent) {
      return _buildFluent(context, radius, shape);
    }

    final content = padding == null
        ? child
        : Padding(padding: padding!, child: child);

    // 可点击时包一层 InkWell，保证 ripple 与 hover 反馈
    final tappable = onTap == null
        ? content
        : InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: content,
          );

    return Padding(
      padding: margin,
      child: switch (variant) {
        AppCardVariant.elevated => Card(
            elevation: 1,
            margin: EdgeInsets.zero,
            shape: shape,
            clipBehavior: Clip.antiAlias,
            child: tappable,
          ),
        AppCardVariant.filled => Card.filled(
            margin: EdgeInsets.zero,
            shape: shape,
            clipBehavior: Clip.antiAlias,
            color: scheme.surfaceContainerLow,
            child: tappable,
          ),
        AppCardVariant.outlined => Card.outlined(
            margin: EdgeInsets.zero,
            shape: shape,
            clipBehavior: Clip.antiAlias,
            child: tappable,
          ),
      },
    );
  }

  /// Windows 实现：WinUI 的卡片用「卡片底色 + 1px 细描边」表达层级，不用阴影。
  ///
  /// 三种变体在 Fluent 下的差异比 M3 小（WinUI 本身就不靠色调区分层级）：
  /// - elevated：卡片底 + 描边（WinUI 的"Layer"卡片）
  /// - filled：比页面底略亮的层，无描边
  /// - outlined：页面底（透明）+ 描边
  Widget _buildFluent(
    BuildContext context,
    BorderRadius radius,
    RoundedRectangleBorder shape,
  ) {
    final p = FluentPalette.of(context);

    final (Color bg, Color border) = switch (variant) {
      AppCardVariant.elevated => (p.card, p.stroke),
      AppCardVariant.filled => (p.card, Colors.transparent),
      AppCardVariant.outlined => (Colors.transparent, p.stroke),
    };

    Widget content = padding == null
        ? child
        : Padding(padding: padding!, child: child);

    if (onTap != null) {
      // Fluent 不用涟漪：整块底色过渡
      content = _FluentCardTap(
        radius: radius,
        onTap: onTap!,
        child: content,
      );
    }

    return Padding(
      padding: margin,
      child: AnimatedContainer(
        duration: FluentMotion.fast,
        curve: FluentMotion.standard,
        decoration: BoxDecoration(
          color: onTap == null ? bg : Colors.transparent,
          borderRadius: radius,
          border: Border.all(color: border, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: content,
      ),
    );
  }
}

/// 可点击 Fluent 卡片的表面：悬停/按下整块变色，无涟漪。
class _FluentCardTap extends StatefulWidget {
  const _FluentCardTap({
    required this.child,
    required this.radius,
    required this.onTap,
  });

  final Widget child;
  final BorderRadius radius;
  final VoidCallback onTap;

  @override
  State<_FluentCardTap> createState() => _FluentCardTapState();
}

class _FluentCardTapState extends State<_FluentCardTap> {
  bool _hovering = false;
  bool _pressing = false;

  @override
  Widget build(BuildContext context) {
    final p = FluentPalette.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() {
        _hovering = false;
        _pressing = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressing = true),
        onTapUp: (_) => setState(() => _pressing = false),
        onTapCancel: () => setState(() => _pressing = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          // decelerate 而非 standard：反馈要立即响应，
          // easeInOut 的开头延迟会让悬停显得"卡一下才亮"
          duration: FluentMotion.hoverIn,
          curve: FluentMotion.decelerate,
          decoration: BoxDecoration(
            // WinUI 的按压比悬停更浅，避免明暗反复造成闪烁
            color: _pressing
                ? p.rowPressed
                : (_hovering ? p.rowHover : Colors.transparent),
            borderRadius: widget.radius,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
