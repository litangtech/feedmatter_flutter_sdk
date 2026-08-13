# feedmatter_flutter_ui

基于 [`feedmatter_flutter_sdk`](../../) 的开箱即用 Flutter 反馈与 FAQ UI 组件库。提供完整页面、可复用组件与主题定制能力，业务方无需复制页面代码即可接入意见反馈模块。

## 功能特性

- 反馈列表（全部 / 我的）、关键词搜索、下拉刷新、点赞
- 提交反馈（类型选择、字数限制、附件）
- 反馈详情与楼中楼评论（发表、回复、加载更多）
- 常见问题（FAQ）列表、本地搜索、版本缓存
- 根据 `ProjectConfig` 自动控制 FAQ、评论、附件等入口开关
- 浅色 / 深色 / 跟随系统主题，支持 `seedColor` 与宿主 App 主色对齐
- 嵌套 `Navigator` 实现模块内主题隔离，切页不受宿主 `MaterialApp` 影响

## 安装

在 `pubspec.yaml` 中同时添加 SDK 与 UI 包：

```yaml
dependencies:
  feedmatter_flutter_sdk: ^3.0.0
  feedmatter_flutter_ui: ^0.1.0
```

同仓库本地开发可使用 path 依赖：

```yaml
dependencies:
  feedmatter_flutter_sdk:
    path: ../
  feedmatter_flutter_ui:
    path: ../packages/feedmatter_flutter_ui
```

然后运行 `flutter pub get`。

> SDK 初始化、鉴权、匿名身份与 API 说明见根目录 [README 快速开始](../../README.md#快速开始)，以及 [客户端身份与匿名反馈合并](https://github.com/litangtech/FeedMatter/blob/main/docs/product/client-identity.md)。

## 快速开始

### 1. 初始化 SDK

在应用启动时初始化 `FeedMatterClient`（与 SDK 文档相同）。推荐使用 `initialize(...)`，未登录时可省略 `user`：

```dart
import 'package:feedmatter_flutter_sdk/feedmatter_flutter_sdk.dart';

await FeedMatterClient.instance.initialize(
  const FeedMatterConfig(
    baseUrl: 'https://your-api.example.com',
    apiKey: 'your-api-key',
    apiSecret: 'your-api-secret',
    appMarket: 'app-store',
  ),
  user: FeedMatterUser(userId: 'user-id', userName: 'User Name'),
  onError: (error) {
    // 全局错误处理
  },
);

// 登录 / 换号
FeedMatterClient.instance.setUser(
  FeedMatterUser(userId: account.id, userName: account.name),
);

// 退出登录（会轮换已合并的匿名 ID）
FeedMatterClient.instance.clearUser();
```

### 2. 打开反馈模块（推荐）

使用 `FeedMatterThemeScope.push` 从宿主 App **push 一次**即可进入完整反馈模块：

```dart
import 'package:feedmatter_flutter_ui/feedmatter_flutter_ui.dart';

FeedMatterThemeScope.push<void>(
  context,
  theme: const FeedMatterThemeOptions(
    mode: FeedMatterThemeMode.system,
    seedColor: Color(0xFF3B82F6), // 可选，不传则继承宿主 primary
  ),
  child: FeedMatterFeedbackEntry(
    options: FeedMatterUiOptions(
      theme: const FeedMatterThemeOptions(
        mode: FeedMatterThemeMode.system,
        seedColor: Color(0xFF3B82F6),
      ),
      customInfo: const {'source': 'my_app'},
    ),
  ),
);
```

完整可运行示例见仓库 [`example`](../../example) 目录。

## 推荐入口：FeedMatterFeedbackEntry

`FeedMatterFeedbackEntry` 是推荐的一站式入口，内部包含：

- **主题作用域**：自动应用 `FeedMatterUiOptions.theme`
- **嵌套 Navigator**：提交、详情、FAQ 等子页面在模块内切换，避免宿主浅色主题闪烁
- **项目配置**：自动拉取 `getProjectConfig()`，按 `faqEnabled` 等开关控制 UI

| `ProjectConfig` | 行为 |
| ---- | ---- |
| `faqEnabled: true` | 展示「意见反馈」壳层 + 常见问题入口 + 反馈列表 |
| `faqEnabled: false` | 仅展示反馈首页 |

`FeedMatterThemeScope.push` **仅用于宿主打开反馈模块**；模块内部导航由 `FeedMatterFeedbackEntry` 自行管理，无需再次调用。

## FeedMatterUiOptions

通过 `FeedMatterFeedbackEntry(options: ...)` 传入：

| 字段 | 说明 |
| ---- | ---- |
| `customInfo` | 提交反馈时写入的自定义字段 |
| `onPickAttachments` | 业务方文件选择器回调，返回 `Attachment` 列表 |
| `useDefaultAttachmentPicker` | 未提供 `onPickAttachments` 时，是否使用内置选择与上传，默认 `true` |
| `faqCache` | FAQ 版本与内容缓存（可接 SharedPreferences） |
| `showProjectConfigDebugPanel` | 是否展示项目配置调试面板（需 `FeedMatterConfig.debug: true`） |
| `platformFilter` | 按 `FaqItem.platforms` 过滤 FAQ |
| `onFaqUrlTap` | FAQ 外链点击回调（避免 UI 包强依赖 url_launcher） |
| `onHelpTap` | 列表页右上角帮助图标点击回调 |
| `onContentUrlTap` | 正文/评论内链接点击回调 |
| `theme` | UI 主题配置（见下文） |

## 主题定制

```dart
FeedMatterUiOptions(
  theme: FeedMatterThemeOptions(
    mode: FeedMatterThemeMode.system, // light | dark | system
    seedColor: Color(0xFF6750A4),     // 可选
  ),
)
```

| 字段 | 说明 |
| ---- | ---- |
| `mode` | `light` 浅色、`dark` 深色、`system` 跟随系统，默认 `system` |
| `seedColor` | 主题色种子；为 `null` 时继承宿主 `Theme.of(context).colorScheme.primary` |

也可在宿主 `MaterialApp` 上使用 `buildFeedMatterLightTheme()` / `buildFeedMatterDarkTheme()` 辅助构建主题，但**推荐**通过 `FeedMatterFeedbackEntry` + `FeedMatterThemeOptions` 接入，无需修改 `MaterialApp`。

若单独使用 `FeedMatterHomePage` 等页面（不经过 `FeedMatterFeedbackEntry`），请用 `FeedMatterThemeScope` 包裹；此时内部 `Navigator.push` 仍可能走宿主根 Navigator，切页时可能出现主题闪烁。

## 页面与组件

| 类型 | 类名 | 用途 |
| ---- | ---- | ---- |
| 入口 | `FeedMatterFeedbackEntry` | 推荐一站式入口（含嵌套 Navigator） |
| 页面 | `FeedMatterHomePage` | 反馈列表主页 |
| 页面 | `FeedMatterSubmitPage` | 提交反馈 |
| 页面 | `FeedMatterDetailPage` | 反馈详情与评论 |
| 页面 | `FeedMatterFaqPage` | 常见问题 |
| 组件 | `FeedMatterFeedbackCard` | 反馈列表卡片 |
| 组件 | `FeedMatterCommentFloorCard` | 楼中楼评论卡片 |
| 组件 | `FeedMatterCommentRow` | 评论行 |
| 组件 | `FeedMatterTag` | 标签 |
| 主题 | `FeedMatterThemeScope` | 主题作用域与宿主入口 `push` |
| 主题 | `FeedMatterUiTheme` | 设计 token（`ThemeExtension`） |
| 主题 | `buildFeedMatterLightTheme` / `buildFeedMatterDarkTheme` | 构建 `ThemeData` |

### 包目录结构

```text
lib/
  feedmatter_flutter_ui.dart       # 公共导出
  src/
    pages/                         # 完整页面
    widgets/                       # 可复用组件
    theme/                         # 主题与 ThemeScope
    faq/faq_cache.dart             # FAQ 缓存抽象
    feedmatter_ui_options.dart     # 行为配置
    feedmatter_theme_options.dart  # 主题配置
    attachment/                    # 默认附件选择器
```

## FAQ 缓存

实现 `FeedMatterFaqCache` 接口可持久化 FAQ 版本与内容，减少重复请求：

```dart
class MyFaqCache implements FeedMatterFaqCache {
  // getVersion / getItems / save ...
}

FeedMatterUiOptions(faqCache: MyFaqCache())
```

未提供时使用内置 `InMemoryFeedMatterFaqCache`（仅内存，进程重启后失效）。

## 附件

**方式一：自定义选择器**

```dart
FeedMatterUiOptions(
  onPickAttachments: () async {
    // 接入 file_picker 等，调用 uploadPublicFile / uploadPrivateFile
    return attachments;
  },
)
```

**方式二：内置选择器**（默认）

```dart
FeedMatterUiOptions(
  useDefaultAttachmentPicker: true, // 默认
)
```

内置逻辑见 `default_attachment_picker.dart`，受 `ProjectConfig` 附件开关与数量限制约束。

## 相关链接

- [FeedMatter Flutter SDK（API 文档）](../../README.md)
- [example 示例项目](../../example)
- [CHANGELOG](CHANGELOG.md)

## 许可证

MIT License（与主仓库一致）
