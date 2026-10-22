# OASX Prism

同 [OAS](https://github.com/runhey/OnmyojiAutoScript) 对接的全平台 GUI，**每个平台做自己该有的样子**。

> 前身 [OASX](https://github.com/Eiyuuzaki/OASX) 已归档。这个仓库从它的代码续写。

## 为什么重做

旧版本功能上是好用的，问题出在**外观**：

- 全平台只有一套 Material Design——Windows 上不像 Windows 软件，Apple 平台没有原生质感
- 移动端毛玻璃效果不明显：Material 的 blur 需要「下方有内容可糊」，而应用底色是纯色，白底糊白底等于没有
- 97 处硬编码颜色散落在业务代码里，主题系统没贯彻到底

重做的目标不是加功能，而是**让每个平台都像那个平台的原生应用**。就像光穿过棱镜会分成不同颜色，同一套逻辑在不同平台呈现不同形态——这是项目名 Prism 的由来。

## 设计原则

### 1. 业务逻辑与 UI 分离

旧版本 2.9 万行代码里，约 60%（1.7 万行）是纯业务逻辑——API 客户端、控制器、服务、数据模型。这部分经过实机验证，直接沿用。重做的只是 UI 层（约 54 个文件、1.1 万行）。

### 2. 语义组件层

业务代码不直接使用平台专属 widget，而是用语义组件表达意图：

```dart
// 不写这个：把 Material 实现泄露到业务层，换平台要改所有页面
Card.filled(child: ...)

// 写这个：表达「这是个强调容器」，由 AppCard 决定各平台怎么画
AppCard(variant: AppCardVariant.filled, child: ...)
```

### 3. 平台映射集中一处

| 平台 | 风格 | 依据 |
|---|---|---|
| Windows | Fluent / WinUI 3 | 系统原生范式 |
| Android | Material You | 系统原生范式 |
| macOS / iOS | Apple HIG | 系统原生范式 |
| Linux / Web | Material 3 | 无统一原生范式，沿用 M3 |

```dart
AppUiStyle resolveAppUiStyle() => switch (PlatformUtils.platfrom()) {
  PlatformType.windows => AppUiStyle.fluent,
  PlatformType.macOS || PlatformType.iOS => AppUiStyle.cupertino,
  _ => AppUiStyle.material,
};
```

## 目录结构

```
lib/
├── ui/                     UI 抽象层（本项目的重点）
│   ├── style.dart          风格枚举、圆角/间距/时长刻度
│   ├── ui.dart             统一导出
│   └── widgets/            语义组件（AppCard / AppButton / AppNavBar …）
├── api/                    API 客户端（沿用 OASX）
├── service/                服务层（沿用 OASX）
├── modules/                业务页面（沿用 OASX，改用语义组件）
└── views/                  独立视图（沿用 OASX）
```

## 进度

平台实施顺序：**Windows 优先**（本机测试最方便），再 Android，最后 Apple。

- [x] 语义组件层骨架（`AppCard` + 间距/圆角刻度）
- [ ] Windows Fluent 实现
- [ ] Android Material You 实现
- [ ] Apple Cupertino 实现
- [ ] 全页面迁移

## 与旧仓库的关系

| 项 | 说明 |
|---|---|
| 代码来源 | 从 [OASX](https://github.com/Eiyuuzaki/OASX) 克隆，保留完整提交历史 |
| Dart 包名 | 仍为 `oasx`（改名要动 300+ 处 import，收益为零） |
| Android ID | `com.oas.oasx.prism`（可与旧版共存安装，方便对比） |
| Windows 类名 | `oasx_prism`（两个版本可同时运行，窗口状态互不干扰） |

**旧仓库已停更**。OAS 后端即使新增 API，旧前端也不会跟进适配。

## 环境

```
Flutter 3.35.0 · Dart 3.9.0
```

> [!WARNING]
> Flutter 各版本接口有差异，版本必须对齐。

Android 构建需要 SDK 34，且 **Kotlin 插件 >= 2.1.0**
（`shared_preferences_android` 2.4.x 用到 Kotlin 2.x 的 `compilerOptions` DSL，
1.8.22 会报 `void ...compilerOptions(...)` 找不到方法）。

## 构建

```powershell
flutter pub get
flutter build windows --debug                                  # 桌面
flutter build apk --release --target-platform android-arm64    # Android，约 22MB
```

> 只构建 arm64，不要 `--split-per-abi`——v7a / x86_64 用不上。

## 配套后端

需要 OAS 后端挂载这些路由：

| 路由 | 用途 |
|---|---|
| `/resource/*` | 资产统计（Frida 读游戏内存） |
| `/stats/*` | 任务统计（解析日志 + SSE 推送） |
| `/device/*` | 安卓实例枚举与切换 |
| `/home/task_name_translate` | 任务名中文映射 |

后端地址默认 `127.0.0.1:22288`；Android 模拟器访问宿主机用 `10.0.2.2:22288`。

## 许可证

GNU General Public License v3.0

## 声明

本软件开源免费，仅供学习交流。使用本软件产生的任何问题与开发者无关。
