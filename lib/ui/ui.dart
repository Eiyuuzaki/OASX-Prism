/// 语义组件层：业务代码只依赖这里的组件，不直接使用平台专属 widget。
///
/// 设计目标：
/// - **语义优先**：用 `AppCard(variant: AppCardVariant.filled)` 表达"这是强调容器"，
///   而不是直接写 `Card.filled`（后者把 Material 实现泄露到业务层）
/// - **单点换肤**：各平台的呈现（Fluent / Material / Cupertino）在组件内部决定，
///   业务代码不判断平台
/// - **渐进迁移**：新代码直接用 App* 组件；老代码可逐个替换，不必一次性改完
///
/// 用法：
/// ```dart
/// import 'package:oasx/ui/ui.dart';
///
/// AppCard(
///   variant: AppCardVariant.filled,
///   padding: AppSpacing.cardPadding,
///   child: AppButton(
///     label: '保存',
///     icon: Icons.save_rounded,
///     variant: AppButtonVariant.primary,
///     onPressed: _save,
///   ),
/// )
/// ```
///
/// 平台映射（见 [resolveAppUiStyle]）：
/// - Windows → Fluent（WinUI 3）
/// - macOS / iOS → Cupertino
/// - Android / Linux / Web → Material 3
library;

export 'style.dart';

// 语义组件
export 'widgets/app_card.dart';
export 'widgets/app_button.dart';
export 'widgets/app_switch.dart';
export 'widgets/app_text_field.dart';
export 'widgets/app_dialog.dart';
export 'widgets/app_nav_bar.dart';
export 'widgets/app_dropdown.dart';
export 'widgets/app_icon_button.dart';
export 'widgets/app_page_header.dart';

// 平台实现的设计令牌（业务代码一般不需要直接用，
// 但自定义组件时需要，所以一并导出）
export 'impl/fluent/fluent_tokens.dart';
