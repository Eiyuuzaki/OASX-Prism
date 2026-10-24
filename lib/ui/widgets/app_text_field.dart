import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:oasx/ui/impl/fluent/fluent_tokens.dart';
import 'package:oasx/ui/style.dart';

/// 跨平台语义输入框。
///
/// Windows 上是 WinUI 的 TextBox，最显著的特征是**聚焦时底部出现
/// 2px 强调色下划线**（WinUI 的 focus underline）：
///
/// ```
/// 未聚焦                      聚焦
/// ┌──────────────┐           ┌──────────────┐
/// │ 输入内容      │           │ 输入内容      │
/// └──────────────┘           ┗━━━━━━━━━━━━━━┛  ← 2px 强调色
///   1px 深灰底线                1px 深灰底线被覆盖
/// ```
///
/// 其它平台沿用 Material 的圆角填充风格。
class AppTextField extends StatelessWidget {
  /// 创建语义输入框。
  const AppTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.enabled = true,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.scrollPadding,
    this.textInputAction,
    this.hintText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.fillColor,
    this.onTapOutside,
    this.onEditingComplete,
    this.onChanged,
    this.onTap,
    this.autofocus = false,
    this.obscureText = false,
    this.readOnly = false,
    this.validator,
    this.initialValue,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool enabled;
  final int? maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final EdgeInsets? scrollPadding;
  final TextInputAction? textInputAction;
  final String? hintText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  /// 覆盖填充色（毛玻璃场景需要半透明底）。
  final Color? fillColor;

  final TapRegionCallback? onTapOutside;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool autofocus;
  final bool obscureText;
  final bool readOnly;
  final FormFieldValidator<String>? validator;
  final String? initialValue;

  @override
  Widget build(BuildContext context) {
    final style = resolveAppUiStyle();
    final decoration = style == AppUiStyle.fluent
        ? _fluentDecoration(context)
        : _materialDecoration(context, fillColor);

    // initialValue 与 controller 互斥，TextFormField 会断言检查
    final field = TextFormField(
      controller: controller,
      focusNode: focusNode,
      initialValue: controller == null ? initialValue : null,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      scrollPadding: scrollPadding ??
          const EdgeInsets.only(left: 12, top: 12, right: 12, bottom: 24),
      textInputAction: textInputAction,
      obscureText: obscureText,
      autofocus: autofocus,
      readOnly: readOnly,
      onTap: onTap,
      onTapOutside: onTapOutside,
      onEditingComplete: onEditingComplete,
      onChanged: onChanged,
      validator: validator,
      style: _textStyle(context),
      decoration: decoration,
    );

    if (style != AppUiStyle.fluent) return field;

    // WinUI 的聚焦下划线**从中间向两边展开**（不是直接出现）。
    //
    // 实现：叠一条宽度 0 → 满宽的强调色线，用 TweenAnimationBuilder
    // 做 167ms 过渡。同时把 focusedBorder 的底部线设成透明（见
    // _fluentDecoration），避免两条线叠在一起。
    //
    // 聚焦状态来自 FocusNode——调用方传了就用它，没传则由本组件
    // 内部创建并负责释放（_AnimatedFocusUnderline 内部管理）。
    return _AnimatedFocusUnderline(
      focusNode: focusNode,
      child: field,
    );
  }

  TextStyle? _textStyle(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyMedium;
    if (resolveAppUiStyle() != AppUiStyle.fluent) return base;
    final p = FluentPalette.of(context);
    return base?.copyWith(color: p.textPrimary);
  }

  /// WinUI TextBox 的装饰。
  InputDecoration _fluentDecoration(BuildContext context) {
    final p = FluentPalette.of(context);
    final radius = BorderRadius.circular(FluentRadius.control);

    return InputDecoration(
      hintText: hintText,
      errorText: errorText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      isDense: true,
      // WinUI 的输入框填充很浅，几乎贴近背景
      fillColor: fillColor ?? (p.isDark ? p.layerAlt : p.card),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      prefixIconConstraints:
          const BoxConstraints(minWidth: 34, minHeight: 34),
      suffixIconConstraints:
          const BoxConstraints(minWidth: 34, minHeight: 34),
      hintStyle: TextStyle(color: p.textTertiary),
      // 未聚焦：四周 1px 浅描边 + 底部 1px 深线
      enabledBorder: _FluentInputBorder(
        borderRadius: radius,
        baseColor: p.stroke,
        bottomColor: p.isDark
            ? const Color(0x8AFFFFFF)
            : const Color(0x73000000),
      ),
      // 聚焦：底部线交给 _AnimatedFocusUnderline 画（从中间展开），
      focusedBorder: _FluentInputBorder(
        borderRadius: radius,
        baseColor: p.stroke,
        bottomColor: Colors.transparent,
        bottomWidth: 2,
      ),
      // 禁用 / 错误态
      disabledBorder: _FluentInputBorder(
        borderRadius: radius,
        baseColor: p.stroke,
        bottomColor: p.stroke,
      ),
      errorBorder: _FluentInputBorder(
        borderRadius: radius,
        baseColor: p.errorBorder,
        bottomColor: p.errorBorder,
      ),
      focusedErrorBorder: _FluentInputBorder(
        borderRadius: radius,
        baseColor: p.errorBorder,
        bottomColor: p.errorBorder,
        bottomWidth: 2,
      ),
      errorStyle: TextStyle(color: p.errorBorder, fontSize: 12),
    );
  }

  /// Material 装饰：沿用原来的观感，只把填充色参数化。
  InputDecoration _materialDecoration(BuildContext context, Color? fill) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hintText,
      errorText: errorText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: fill ??
          scheme.surfaceContainerHighest.withValues(alpha: 0.6),
    );
  }
}

/// WinUI 的输入框边框：圆角矩形描边 + 一条更明显的底线。
///
/// Flutter 内置的 `UnderlineInputBorder` 只有底线、`OutlineInputBorder`
/// 只有等宽描边，都表达不出 WinUI「盒 + 强调底线」的组合，所以自绘。
class _FluentInputBorder extends InputBorder {
  const _FluentInputBorder({
    required this.borderRadius,
    required this.baseColor,
    required this.bottomColor,
    this.bottomWidth = 1,
    this.baseWidth = 1,
  });

  final BorderRadius borderRadius;
  final Color baseColor;
  final Color bottomColor;
  final double bottomWidth;
  final double baseWidth;

  @override
  bool get isOutline => true;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.only(bottom: bottomWidth);

  @override
  _FluentInputBorder copyWith({
    BorderSide? borderSide,
    BorderRadius? borderRadius,
    Color? baseColor,
    Color? bottomColor,
    double? bottomWidth,
    double? baseWidth,
  }) {
    return _FluentInputBorder(
      borderRadius: borderRadius ?? this.borderRadius,
      baseColor: baseColor ?? this.baseColor,
      bottomColor: bottomColor ?? this.bottomColor,
      bottomWidth: bottomWidth ?? this.bottomWidth,
      baseWidth: baseWidth ?? this.baseWidth,
    );
  }

  @override
  ShapeBorder scale(double t) =>
      copyWith(bottomWidth: bottomWidth * t, baseWidth: baseWidth * t);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(borderRadius.resolve(textDirection).toRRect(rect));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(borderRadius.resolve(textDirection).toRRect(rect));

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0,
    double gapPercentage = 0,
    TextDirection? textDirection,
  }) {
    // 底线画在边框内侧，避免被裁掉半个像素
    final inner = rect.deflate(baseWidth / 2);

    // 圆角矩形描边
    if (baseWidth > 0) {
      canvas.drawRRect(
        borderRadius.resolve(textDirection).toRRect(inner),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = baseWidth
          ..color = baseColor
          ..isAntiAlias = true,
      );
    }

    // 底部强调线：两端内缩圆角半径，避免突出圆角外
    if (bottomWidth > 0) {
      final r = borderRadius.resolve(textDirection);
      final inset = r.topLeft.x.clamp(0.0, inner.width / 2);
      final y = inner.bottom - bottomWidth / 2;
      canvas.drawLine(
        Offset(inner.left + inset, y),
        Offset(inner.right - inset, y),
        Paint()
          ..strokeWidth = bottomWidth
          ..color = bottomColor
          ..isAntiAlias = true,
      );
    }
  }
}

/// 聚焦时从中间展开的强调色下划线（WinUI TextBox 的 focus underline）。
///
/// [focusNode] 为空时内部自建一个并负责释放——这样调用方无需为了
/// 拿到动画而额外传 focusNode。
class _AnimatedFocusUnderline extends StatefulWidget {
  const _AnimatedFocusUnderline({required this.child, this.focusNode});

  final Widget child;
  final FocusNode? focusNode;

  @override
  State<_AnimatedFocusUnderline> createState() =>
      _AnimatedFocusUnderlineState();
}

class _AnimatedFocusUnderlineState extends State<_AnimatedFocusUnderline> {
  FocusNode? _owned;

  FocusNode get _node => widget.focusNode ?? (_owned ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(_AnimatedFocusUnderline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocus);
      _owned?.dispose();
      _owned = null;
      _node.addListener(_onFocus);
    }
  }

  void _onFocus() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _node.removeListener(_onFocus);
    _owned?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _node.hasFocus;
    return Stack(
      children: [
        widget.child,
        if (focused)
          Positioned(
            left: 1,
            right: 1,
            bottom: 1,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 167),
              curve: FluentMotion.decelerate,
              builder: (context, t, _) => FractionallySizedBox(
                widthFactor: t,
                alignment: Alignment.center,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: FluentPalette.of(context).accent,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
