# FeedMatter Flutter SDK Example

这是 `feedmatter_flutter_sdk` 的完整示例 App，用于演示第三方 Flutter 应用如何接入 FeedMatter 反馈系统。

## 示例覆盖

- 初始化 `FeedMatterClient`。
- 通过 `feedmatter_flutter_ui` 展示帮助与反馈入口（`FeedMatterFeedbackEntry`）。
- 读取项目配置，并根据配置控制 FAQ、反馈、评论、附件等入口。
- 常见问题列表、搜索与版本缓存。
- 展示全部反馈 / 我的反馈列表。
- 搜索反馈。
- 提交反馈。
- 查看反馈详情。
- 发布评论和楼中楼回复。
- 加载更多回复。
- 点赞反馈。
- 项目配置调试面板（`showProjectConfigDebugPanel: true`）。

## 运行示例

先在 example 目录获取依赖：

```bash
flutter pub get
```

运行 Android：

```bash
flutter run -d android
```

运行 iOS、macOS、Windows：

```bash
flutter run -d ios
flutter run -d macos
flutter run -d windows
```

Linux 平台目录已提供，但需要在 Linux 环境中运行：

```bash
flutter run -d linux
```

## 配置说明

`lib/main.dart` 中的 `apiKey` 和 `apiSecret` 是 FeedMatter 测试项目的示例密钥，仅用于快速跑通 SDK 示例。接入你自己的项目时，请替换为后台项目配置中生成的正式值。

```dart
feedmatter.FeedMatterClient.instance.init(
  const feedmatter.FeedMatterConfig(
    baseUrl: 'https://fmapi.litangkj.com',
    apiKey: 'your-api-key',
    apiSecret: 'your-api-secret',
    appMarket: 'app-store',
  ),
  feedmatter.FeedMatterUser(
    userId: 'current-user-id',
    userName: 'Current User',
  ),
);
```

如果你的服务部署在自己的域名，请同步替换 `baseUrl`。

## 在业务项目中使用 UI 包

在 `pubspec.yaml` 中添加：

```yaml
dependencies:
  feedmatter_flutter_sdk: ^1.0.6
  feedmatter_flutter_ui: ^0.1.0
```

然后在 App 中挂载：

```dart
import 'package:feedmatter_flutter_ui/feedmatter_flutter_ui.dart';

FeedMatterFeedbackEntry(
  options: FeedMatterUiOptions(
    customInfo: {'source': 'my_app'},
    onPickAttachments: () async {
      // 接入文件选择器并调用 uploadPublicFile / uploadPrivateFile
      return [];
    },
  ),
)
```

附件上传通过 `FeedMatterUiOptions.onPickAttachments` 回调接入，上传完成后再把 `Attachment` 传给反馈接口。
