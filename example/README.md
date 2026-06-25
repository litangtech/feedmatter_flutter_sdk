# FeedMatter Flutter SDK Example

这是 `feedmatter_flutter_sdk` 的完整示例 App，用于演示第三方 Flutter 应用如何接入 FeedMatter 反馈系统。

## 示例覆盖

- 初始化 `FeedMatterClient`。
- 读取项目配置，并根据配置控制反馈、评论、附件等入口。
- 展示全部反馈 / 我的反馈列表。
- 搜索反馈。
- 提交反馈。
- 查看反馈详情。
- 发布评论和楼中楼回复。
- 加载更多回复。
- 点赞反馈。
- 预留附件上传入口。

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

## 复制到业务项目

如果你想快速在业务 App 中复用 UI，可以复制：

```text
lib/feedmatter_ui/
```

然后在业务 App 启动或用户信息加载完成后，参考 `lib/main.dart` 初始化 `FeedMatterClient`。

附件上传按钮目前只做了入口预留。业务项目接入文件选择器后，可以调用 `uploadPublicFile()`，上传完成后再把附件 URL 传给反馈或评论接口。
