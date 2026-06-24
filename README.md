<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

# FeedMatter Flutter SDK

FeedMatter Flutter SDK 提供了与 FeedMatter API 交互的简单方式，用于收集和管理用户反馈。

## 功能特性

- 创建和管理反馈
- 评论功能
- 文件上传（支持图片和视频）
- 点赞功能
- 项目配置管理
- 常见问题（FAQ）列表和版本缓存

## 全局概览

FeedMatter Flutter SDK 主要负责 App 端反馈入口的接入：读取项目配置、展示常见问题、提交反馈、展示反馈列表、展示楼中楼评论、上传附件，并自动完成 API 鉴权签名。

### 支持平台

发布到 pub.dev 的默认版本支持 Android、iOS、macOS、Windows、Linux。HarmonyOS 端请使用 `harmony` 分支接入；由于 pub.dev 当前没有 HarmonyOS 平台标签，因此不会在 pub.dev 平台列表中单独展示 HarmonyOS。

### 能力一览

| 能力 | SDK 方法 | 对应 API | 典型用途 |
| --- | --- | --- | --- |
| 项目配置 | `getProjectConfig()` | `GET /api/v2/projects/config` | 控制反馈、评论、附件、游客权限等入口 |
| 创建反馈 | `createFeedback()` | `POST /api/v2/feedbacks` | 用户提交建议、问题、咨询等反馈 |
| 反馈列表 | `getFeedbacks()` | `GET /api/v2/feedbacks` | 展示全部反馈列表 |
| 我的反馈 | `getMyFeedbacks()` | `GET /api/v2/feedbacks/my` | 展示当前用户反馈 |
| 用户反馈 | `getUserFeedbacks()` | `GET /api/v2/feedbacks/user/{userId}` | 查看指定用户反馈 |
| 反馈详情 | `getFeedback()` | `GET /api/v2/feedbacks/{id}` | 进入反馈详情页 |
| 点赞反馈 | `toggleLike()` | `POST /api/v2/feedbacks/{id}/like` | 用户点赞 / 取消点赞 |
| 添加评论 | `createComment()` | `POST /api/v2/feedbacks/{id}/comments` | 发表评论或回复 |
| 楼中楼评论 | `getCommentsFloor()` | `GET /api/v2/feedbacks/{id}/comments/floor` | 展示主评论和首屏回复 |
| 更多回复 | `getCommentReplies()` | `GET /api/v2/feedbacks/comments/{mainCommentId}/replies` | 加载某条主评论下的更多回复 |
| 公开上传 | `uploadPublicFile()` | `POST /api/v2/upload/public` | 上传可直接访问的图片 / 视频 / 文件 |
| 私密上传 | `uploadPrivateFile()` | `POST /api/v2/upload/private` | 上传需要签名 URL 访问的文件 |
| 私密文件访问 | `getSignedUrl()` | `GET /api/v2/upload/private/{key}` | 获取私密文件临时访问 URL |
| FAQ 列表 | `getFaqList()` | `GET /api/v1/faq` | 获取常见问题内容，支持版本检查 |

### 推荐接入流程

1. 在 FeedMatter 后台创建项目，获取 `apiKey` 和 `apiSecret`。
2. 安装 SDK。普通 Flutter 使用 pub.dev 版本；鸿蒙 Flutter 使用 `harmony` 分支。
3. 应用启动时调用 `FeedMatterClient.instance.init(...)`，传入项目凭证、用户信息和渠道 `appMarket`。
4. 进入反馈入口前调用 `getProjectConfig()`，根据项目配置决定是否显示反馈、评论、附件入口。
5. 用户提交反馈时调用 `createFeedback()`；如有附件，先上传文件再把 `Attachment` 传入反馈。
6. 反馈详情页使用 `getCommentsFloor()` 展示楼中楼评论，用 `getCommentReplies()` 加载更多回复。
7. 如果业务服务端需要接收事件通知，在 FeedMatter 管理后台配置项目回调；Flutter 客户端无需直接处理回调。

### 客户端与服务端职责

| 模块 | 负责内容 |
| --- | --- |
| Flutter SDK | App 端 API 调用、请求签名、设备信息采集、附件上传、数据模型解析 |
| `feedmatter-api` | 面向 App 的反馈、评论、附件、项目配置和 FAQ API |
| `feedmatter-admin` | 后台管理、项目配置、回调配置、反馈处理和商店评论管理 |
| 项目回调 | FeedMatter 服务端向业务方服务端推送事件，客户端不直接接收 |

## 安装

将以下依赖添加到你的 `pubspec.yaml` 文件中：

```yaml
dependencies:
  feedmatter_flutter_sdk: ^1.0.5
```

然后运行：

```bash
flutter pub get
```

### 鸿蒙 HarmonyOS 接入注意

鸿蒙端使用的 Flutter 版本和插件生态比较特殊，**不要直接使用 pub.dev 上的默认版本**。鸿蒙项目请改用 `harmony` 分支：

```yaml
dependencies:
  feedmatter_flutter_sdk:
    git:
      url: https://github.com/litangtech/feedmatter_flutter_sdk.git
      ref: harmony
```

说明：

- `harmony` 分支会适配鸿蒙 Flutter 环境及相关插件依赖。
- 普通 Android / iOS / macOS / Windows / Linux 项目可以继续使用发布到 pub.dev 的版本。
- 多端项目如果同时包含鸿蒙端，建议在鸿蒙工程的 `pubspec.yaml` 中单独指定 `harmony` 分支，避免与其他平台共用依赖锁定。

## 快速开始

### 1. 初始化 SDK

在使用 SDK 之前，需要先进行初始化。建议在应用启动时（比如在 `main.dart` 或首页的 `initState` 中）进行：

```dart
import 'package:feedmatter_flutter_sdk/feedmatter_flutter_sdk.dart' as feedmatter;

// 获取 SDK 实例
final client = feedmatter.FeedMatterClient.instance;

// 初始化配置
client.init(
  feedmatter.FeedMatterConfig(
    baseUrl: 'https://fmapi.litangkj.com',  // API 地址
    apiKey: 'your-api-key',                 // 项目 API Key
    apiSecret: 'your-api-secret',           // 项目 API Secret
    appMarket: 'appstore',                  // 应用渠道，如 appstore/googleplay/harmony
    timeout: 30,                            // 超时时间（秒）
    debug: true,                            // 是否开启调试模式
  ),
  feedmatter.FeedMatterUser(
    userId: 'user-id',                      // 用户 ID
    userName: 'User Name',                  // 用户名
    userAvatar: 'https://example.com/avatar.png',  // 用户头像（可选）
  ),
  onError: (error) {
    // 全局错误处理
    print('FeedMatter Error: $error');
  },
);
```

> **注意**：SDK 的初始化是一个轻量级操作，不会产生额外的网络请求或性能开销。只有在调用具体的 API 方法（如提交反馈、获取列表等）时，才会发起实际的网络请求。这意味着你可以在应用启动时就进行初始化，而不用担心影响应用的启动速度。

### 接入清单（参考钱迹 App）

第三方 App 接入时，建议按下面的顺序完成：

1. **准备项目凭证**：在 FeedMatter 后台创建项目，获取该项目的 `apiKey` 和 `apiSecret`。
2. **配置依赖**：普通 Flutter 使用 pub.dev 版本；鸿蒙 Flutter 使用 `harmony` 分支。
3. **应用启动时初始化**：建议在 `main()`、首页初始化或用户信息加载完成后调用 `FeedMatterClient.instance.init(...)`。
4. **先获取项目配置**：进入反馈入口前建议调用 `getProjectConfig()`，根据服务端配置决定是否展示“提交反馈”“评论”“附件”等入口。
5. **登录态变化时重新初始化**：如果用户登录、切换账号或退出登录，需要用新的 `FeedMatterUser` 重新调用 `init`，或退出时调用 `clearUser()`。
6. **设置渠道标识**：`appMarket` 建议传 App 的真实渠道，例如 `appstore`、`googleplay`、`harmony`、`xiaomi`、`huawei` 等，便于后台定位反馈来源。
7. **补充业务上下文**：提交反馈时可通过 `customInfo` 传入业务信息，例如包名、渠道、语言、会员状态、页面来源等。
8. **附件先上传再提交**：如果反馈带附件，先调用 `uploadPublicFile()` 或 `uploadPrivateFile()`，再把返回地址组装为 `Attachment` 随反馈提交。
9. **发布前关闭 debug**：生产环境建议 `debug: false`，避免输出请求参数、签名串和接口日志。

示例：

```dart
Future<void> initFeedMatter(AppUser? user) async {
  FeedMatterClient.instance.init(
    FeedMatterConfig(
      baseUrl: 'https://fmapi.litangkj.com',
      apiKey: 'your-api-key',
      apiSecret: 'your-api-secret',
      appMarket: detectAppMarket(), // 例如 appstore / harmony / xiaomi
      debug: false,
    ),
    FeedMatterUser(
      userId: user?.id ?? '',
      userName: user?.name ?? '',
      userAvatar: user?.avatar,
    ),
  );
}
```

提交反馈时附加业务上下文：

```dart
await FeedMatterClient.instance.createFeedback(
  content: content,
  type: FeedbackType.advice,
  customInfo: {
    'package': packageName,
    'market': appMarket,
    'locale': locale.toLanguageTag(),
    'source': 'settings_feedback',
  },
  attachments: attachments,
);
```

### 2. 获取项目配置并控制入口

项目配置是客户端接入时最重要的运行时开关，建议在展示反馈入口、进入反馈首页或进入提交页前优先获取。它决定当前项目是否允许发布反馈、是否允许评论、是否允许附件、游客是否可发布等行为。

```dart
final projectConfig = await FeedMatterClient.instance.getProjectConfig();

if (!projectConfig.feedbackEnabled) {
  // 隐藏“提交反馈”入口，或展示“反馈功能暂未开放”
}

if (!projectConfig.commentEnabled) {
  // 隐藏评论输入框
}

if (!projectConfig.feedbackAttachmentEnabled) {
  // 隐藏反馈附件上传入口
}

if (!projectConfig.commentAttachmentEnabled) {
  // 隐藏评论附件上传入口
}

if (!projectConfig.guestFeedbackEnabled && currentUser == null) {
  // 引导用户登录后再提交反馈
}

if (!projectConfig.guestCommentEnabled && currentUser == null) {
  // 引导用户登录后再发表评论
}
```

建议：

- 项目配置可以在 App 启动后或反馈模块首次打开时获取，并做本地缓存。
- 进入提交页前应重新检查关键开关，避免后台关闭功能后客户端仍允许提交。
- `feedbackPrompt` / `commentPrompt` 可作为输入框提示文案。
- `feedbackMaxContentLength` / `commentMaxContentLength` 应用于输入长度限制。
- `maxAttachments` 和 `maxUploadFileSize` 应用于附件数量和大小限制。
- 即使客户端做了 UI 限制，服务端仍会再次校验；客户端需要处理相应错误并给出提示。

常见 UI 对应关系：

| 配置字段 | 建议控制的客户端 UI |
| --- | --- |
| `feedbackEnabled` | 是否显示提交反馈按钮 / 反馈提交页 |
| `commentEnabled` | 是否显示评论输入框 |
| `feedbackAttachmentEnabled` | 是否显示反馈附件上传入口 |
| `commentAttachmentEnabled` | 是否显示评论附件上传入口 |
| `guestFeedbackEnabled` | 未登录用户能否提交反馈 |
| `guestCommentEnabled` | 未登录用户能否发表评论 |
| `feedbackPrompt` | 反馈输入框提示文案 |
| `commentPrompt` | 评论输入框提示文案 |
| `feedbackMaxContentLength` | 反馈内容最大长度 |
| `commentMaxContentLength` | 评论内容最大长度 |
| `maxAttachments` | 最大附件数量 |
| `maxUploadFileSize` | 单个附件最大体积，默认 40MB |

### 3. 常见问题 FAQ

常见问题适合放在反馈入口的前置位置，用来减少重复反馈。后台维护 FAQ 内容后，客户端可以通过 `getFaqList()` 拉取并展示在“帮助与反馈”“提交反馈前”等页面。

`getFaqList()` 支持版本检查。客户端第一次请求传默认版本 `"0"`；后续可以缓存上一次返回的 `version`，再把该版本传给服务端。如果服务端 FAQ 没有更新，会返回相同 `version` 且 `items` 为空，客户端可以继续使用本地缓存。

```dart
final response = await FeedMatterClient.instance.getFaqList();

if (response.hasUpdate) {
  // 保存 response.version 和 response.items 到本地缓存
  setState(() {
    faqItems = response.items;
  });
}
```

带本地缓存的典型写法：

```dart
Future<List<FaqItem>> loadFaqs() async {
  final cachedVersion = await localStorage.getString('faq_version') ?? '0';
  final cachedItems = await loadCachedFaqItems();

  final response = await FeedMatterClient.instance.getFaqList(
    version: cachedVersion,
  );

  if (!response.hasUpdate) {
    return cachedItems;
  }

  await localStorage.setString('faq_version', response.version);
  await saveCachedFaqItems(response.items);
  return response.items;
}
```

展示时建议：

- 优先展示 `title`，点击后展开 `answer`。
- 如果 `url` 不为空，可以跳转到业务帮助文档或外部说明页面。
- `keywords` 可用于本地搜索。
- `platforms` 可用于按当前平台过滤，例如只展示 Android / iOS 相关问题。
- FAQ 不能替代反馈入口，建议在 FAQ 下方保留“没有解决？提交反馈”入口。

### 认证与签名

SDK 与 `feedmatter-api` 对接时会自动添加以下请求头：

- `X-API-Key`：项目 API Key。
- `X-User-Id`：业务侧用户唯一 ID。
- `X-User-Name`：URL 编码后的用户名。
- `X-User-Avatar`：URL 编码后的用户头像，可选。
- `X-Timestamp`：毫秒时间戳。
- `X-Signature`：使用 `apiSecret` 生成的 HMAC-SHA256 签名。

签名规则与 `feedmatter-api` 保持一致：

```text
METHOD + "\n" + PATH + "\n" + TIMESTAMP + "\n" + JSON_SORTED_PARAMS
```

说明：

- GET 请求使用 query 参数参与签名。
- JSON POST 请求使用请求体参数参与签名。
- 文件上传请求使用空对象 `{}` 参与签名。
- 生产环境不要开启 `debug`，避免在日志中输出请求详情。
- 如果 `FeedMatterUser.userId` 为空字符串，服务端会按游客/未登录用户处理；是否允许发布反馈或评论取决于项目配置中的游客开关。

### 4. 提交反馈

```dart
try {
  final feedback = await client.createFeedback(
    content: '这是一条反馈内容',
    type: FeedbackType.advice,    // 反馈类型（可选）
    customInfo: {
      'source': 'home_page',      // 自定义信息（可选）
    },
  );
  print('反馈已提交: ${feedback.id}');
} catch (e) {
  print('提交反馈失败: $e');
}
```

### 5. 反馈类型

SDK 支持以下反馈类型：

```dart
enum FeedbackType {
  advice,    // 建议
  error,     // 错误
  ask,       // 咨询
  help,      // 紧急求助
  notice,    // 公告（仅管理员可用）
  other      // 其他
}
```

注意：

- `notice` 类型仅限管理员使用
- 如果不指定类型，默认为 `other`
- 普通用户使用 `notice` 类型会收到错误响应

### 6. 设备信息

SDK 会自动收集以下设备信息：

```dart
class ClientInfo {
  String appVersionName;      // 应用版本名
  int appVersionCode;        // 应用版本号
  String appPackage;         // 应用包名
  String appType;           // 应用类型（ANDROID/IOS/MAC等）
  String? deviceModel;      // 设备型号
  String? deviceBrand;      // 设备品牌
  String? deviceSysVersion; // 系统版本名称
  String? deviceSysVersionInt; // 系统版本号
}
```

这些信息会在提交反馈时自动附加，你不需要手动设置。

### 7. 获取反馈列表

```dart
// 获取所有反馈
final feedbacks = await client.getFeedbacks(
  page: 0,    // 页码（从 0 开始）
  size: 20,   // 每页数量
);

// 获取用户自己的反馈
final myFeedbacks = await client.getMyFeedbacks(
  page: 0,
  size: 20,
);
```

### 8. 评论楼中楼

FeedMatter 推荐使用“楼中楼”模型展示评论，这是当前 SDK 的主推评论接入方式：

- 第一层是主评论列表，对应 `getCommentsFloor()`。
- 每条主评论包含一个独立的回复分页对象，对应 `mainComment.replies`。
- 当某条主评论还有更多回复时，再调用 `getCommentReplies(mainComment.id)` 单独加载该楼层的更多回复。
- 发送回复时，`parentCommentId` 建议传主评论 ID，让服务端把回复归到对应楼层。

#### 7.1 添加主评论和回复

```dart
// 添加主评论
final comment = await client.createComment(
  'feedback-id',
  '这是一条评论',
);

// 回复某条主评论
final reply = await client.createComment(
  'feedback-id',
  '回复内容',
  parentCommentId: 'main-comment-id',
);
```

#### 7.2 获取主评论列表

`getCommentsFloor()` 返回 `Page<MainCommentWithReplies>`，不是普通列表。`page.content` 是主评论列表，`page.totalElements` 是主评论总数。

```dart
final page = await client.getCommentsFloor(
  'feedback-id',
  page: 0,
  size: 20,
  sort: CommentSort.createdAsc,
);

print('主评论总数: ${page.totalElements}');
print('当前页: ${page.number}');
print('总页数: ${page.totalPages}');

for (final mainComment in page.content) {
  print('主评论: ${mainComment.content}');
  print('作者: ${mainComment.author.username}');
  print('该楼层回复总数: ${mainComment.replies.totalElements}');

  // 首屏会自带该主评论下的一页回复
  for (final reply in mainComment.replies.content) {
    print('  回复: ${reply.content}');
  }
}
```

#### 7.3 加载某条主评论的更多回复

每条主评论的回复页码需要独立维护，不要和主评论列表共用同一个 `page`。

```dart
final Map<String, int> replyPageByComment = {};

Future<void> loadMoreReplies(MainCommentWithReplies mainComment) async {
  final nextPage = (replyPageByComment[mainComment.id] ?? 0) + 1;

  final result = await client.getCommentReplies(
    mainComment.id,
    page: nextPage,
    size: 10,
  );

  replyPageByComment[mainComment.id] = result.currentPage;

  // 将 result.content 追加到该主评论的回复列表 UI 中
  // 如果 result.hasNext == false，隐藏“加载更多回复”按钮
}
```

`PagedReplies` 包含：

```dart
final replies = await client.getCommentReplies('main-comment-id');

print('回复列表: ${replies.content.length}');
print('回复总数: ${replies.totalElements}');
print('当前页: ${replies.currentPage}');
print('总页数: ${replies.totalPages}');
print('是否还有下一页: ${replies.hasNext}');
```

#### 7.4 排序选项

楼中楼评论支持以下排序方式：

- `CommentSort.createdAsc` / `created_asc`：按创建时间升序（默认，最早的在前）。
- `CommentSort.createdDesc` / `created_desc`：按创建时间降序（最新的在前）。
- `CommentSort.replyDesc` / `reply_desc`：按回复数降序（回复最多的在前）。

注意：所有排序都会优先显示置顶评论。

#### 7.5 接入建议

- 主评论列表和每条主评论的回复列表要分别维护分页状态。
- 下拉刷新主评论列表时，建议同时清空各主评论的回复分页缓存。
- 发送主评论成功后，可以刷新主评论列表，或把新评论插入当前列表。
- 发送回复成功后，建议刷新对应主评论的回复列表，或把新回复追加到该主评论楼层。
- 如果项目配置 `commentEnabled = false`，应隐藏评论输入框，但仍可展示已有评论。
- 如果项目配置 `commentAttachmentEnabled = false`，应隐藏评论附件入口。

## 文件上传

SDK 提供了安全的文件上传功能，包括以下特性：

- 文件大小限制（默认最大 40MB）
- 文件名安全处理
- 支持公开和私密两种上传方式
- RESTful API 路径：`/api/v2/upload`

### 上传公开文件

公开文件上传后可以直接通过返回的 URL 访问：

```dart
try {
  final url = await client.uploadPublicFile(File('path/to/file.jpg'));
  print('文件已上传：$url');
} on FeedMatterApiException catch (e) {
  if (e.code == 'FILE_TOO_LARGE') {
    print('文件太大：${e.originalError}');
  } else if (e.code == 'FILE_NOT_FOUND') {
    print('文件不存在');
  }
  print('上传失败：${e.message}');
}
```

### 上传私密文件

私密文件需要通过签名 URL 访问：

```dart
try {
  // 1. 上传文件，获取私密文件 key
  final key = await client.uploadPrivateFile(File('path/to/private.pdf'));

  // 2. 使用 key 获取签名访问 URL
  final signedUrl = await client.getSignedUrl(key);
  print('文件访问链接：$signedUrl');
} catch (e) {
  print('操作失败：$e');
}
```

### API 端点

#### 文件上传
- 上传公开文件：POST `/api/v2/upload/public`
- 上传私密文件：POST `/api/v2/upload/private`。后端统一返回 `{ "url": "private-file-key" }`，SDK 会将其作为 key 返回。
- 获取签名 URL：GET `/api/v2/upload/private/{key}`

#### 项目配置
- 获取项目配置：GET `/api/v2/projects/config`

#### 反馈
- 创建反馈：POST `/api/v2/feedbacks`
- 获取反馈列表：GET `/api/v2/feedbacks`
- 获取反馈详情：GET `/api/v2/feedbacks/{id}`
- 切换点赞：POST `/api/v2/feedbacks/{id}/like`

#### 评论
- 获取评论列表（楼中楼）：GET `/api/v2/feedbacks/{id}/comments/floor`
- 获取回复列表（分页）：GET `/api/v2/feedbacks/comments/{mainCommentId}/replies`
- 添加评论/回复：POST `/api/v2/feedbacks/{id}/comments`

### 9. 项目回调

项目回调是 FeedMatter 服务端到业务方服务端的事件通知能力，**不是 Flutter SDK 在客户端直接接收回调**。Flutter SDK 提交反馈、评论、点赞等操作后，FeedMatter 服务端会根据项目回调配置，把对应事件推送到你配置的回调 URL。

典型用途：

- 新反馈创建后，同步到企业微信、飞书、Slack 或自研工单系统。
- 新评论或回复产生后，通知业务后台。
- 反馈状态变更、置顶、删除等后台操作后，同步到外部系统。

需要在 FeedMatter 管理后台为项目配置：

- 回调 URL：业务方用于接收事件的 HTTPS 接口。
- 签名密钥：用于校验回调来源和 payload 完整性。
- 启用事件：选择需要接收的事件类型。

常见事件：

| 事件 | 说明 |
| --- | --- |
| `feedback.created` | 用户创建反馈 |
| `feedback.updated` | 反馈内容或配置更新 |
| `feedback.status_changed` | 反馈状态变化 |
| `feedback.deleted` | 反馈删除 |
| `feedback.pinned` / `feedback.unpinned` | 反馈置顶 / 取消置顶 |
| `comment.created` | 用户创建评论或回复 |
| `comment.status_changed` | 评论状态变化 |
| `comment.deleted` | 评论删除 |
| `comment.pinned` / `comment.unpinned` | 评论置顶 / 取消置顶 |
| `system.test` | 管理后台测试回调 |

回调请求格式：

```http
POST {callback_url}
Content-Type: application/json
X-FeedMatter-Event: feedback.created
X-FeedMatter-Timestamp: 1710000000
X-FeedMatter-Signature: <base64-hmac-sha256>
```

payload 示例：

```json
{
  "eventId": "0f7d2b43-7c21-4b5d-9fd6-4a2b01f4b8e6",
  "projectId": "project-id",
  "eventType": "feedback.created",
  "timestamp": 1710000000,
  "data": {
    "id": "feedback-id",
    "feedbackDetailUrl": "https://your-admin-domain/feedback/feedback-id",
    "content": "这是一条反馈内容",
    "status": "PENDING",
    "type": "ADVICE",
    "username": "User Name",
    "commentCount": 0,
    "likeCount": 0
  }
}
```

签名校验：

```text
X-FeedMatter-Signature = Base64(HMAC_SHA256(raw_request_body, callback_secret))
```

接入建议：

- 回调接口应尽快返回 `2xx`，耗时处理建议异步执行。
- 如果签名校验失败，应返回 `401` 或 `403`。
- 回调可能因网络重试而重复投递，业务方应使用 `eventId` 做幂等处理。
- Flutter 客户端无需配置回调；客户端只需要正常调用 SDK API，事件通知由 FeedMatter 服务端负责。

## 错误处理

SDK 定义了以下几种异常类型：

1. `FeedMatterConfigException`: 配置错误

   - 未初始化 SDK
   - 配置信息不完整

2. `FeedMatterAuthException`: 认证错误

   - API Key 无效
   - 权限不足

3. `FeedMatterApiException`: API 调用错误
   - 网络错误
   - 服务器错误
   - 请求参数错误
   - 业务规则校验失败（如项目已关闭评论功能）

你可以通过以下两种方式处理错误：

1. 全局错误处理：

```dart
client.init(
  config,
  user,
  onError: (error) {
    if (error is FeedMatterAuthException) {
      // 处理认证错误
    } else if (error is FeedMatterApiException) {
      // 处理 API 错误
    }
  },
);
```

2. 局部错误处理：

```dart
try {
  await client.createComment(feedbackId, '评论内容');
} on FeedMatterAuthException catch (e) {
  // 处理认证错误
  print('认证错误: ${e.message}, 错误码: ${e.code}');
} on FeedMatterApiException catch (e) {
  // 检查是否是业务规则校验失败（如项目已关闭评论功能）
  if (e.isBusinessRuleViolation) {
    print('业务规则校验失败: ${e.message}');
    // 向用户显示具体的错误信息，例如 "该项目已关闭评论功能"
    showErrorDialog(e.message);
  } else if (e.statusCode == 500) {
    // 处理服务器错误
    print('服务器错误: ${e.message}');
    // 可以查看更多详细信息
    print('错误堆栈: ${e.stackTrace}');
    print('原始响应: ${e.rawResponse}');
  } else {
    // 处理其他 API 错误
    print('API错误: ${e.message}, 状态码: ${e.statusCode}, 错误码: ${e.code}');
  }
}
```

### 常见业务错误与处理方式

SDK 会尝试解析服务器返回的错误信息，特别是对于业务规则校验失败的情况。以下是一些常见的业务错误和处理建议：

| 错误信息 | 原因 | 处理建议 |
|---------|------|---------|
| "该项目已关闭评论功能" | 项目配置中禁用了评论功能 | 隐藏评论输入框，向用户展示相应提示 |
| "未登录用户不能发布评论" | 项目不允许匿名评论 | 提示用户登录后再评论 |
| "该项目已关闭评论附件功能" | 项目禁用了评论附件 | 隐藏附件上传按钮 |
| "该反馈已关闭评论功能" | 特定反馈被关闭了评论 | 在此反馈下隐藏评论输入框 |
| "文件大小超过限制" | 上传的文件超出大小限制 | 提示用户压缩文件或选择更小的文件 |
| "附件数量超出限制" | 上传的附件数量超过限制 | 限制用户上传的附件数量 |

SDK 将这些业务规则校验错误统一标记为 `code: 'INVALID_STATE'`，状态码通常为 400，
可以通过 `isBusinessRuleViolation` 属性快速判断是否属于此类错误。

## 最佳实践

1. 初始化时机

   - 建议在应用启动时进行初始化
   - 确保在使用 SDK 功能前完成初始化

2. 错误处理

   - 建议设置全局错误处理函数
   - 对重要操作使用局部错误处理
   - 在 UI 层展示友好的错误提示

3. 用户信息

   - 在用户登录后更新用户信息
   - 在用户登出时调用 `clearUser()`

4. 调试模式

   - 开发时开启 debug 模式查看详细日志
   - 生产环境建议关闭 debug 模式

5. 设备信息

   - SDK 会自动收集设备信息
   - 无需手动设置设备信息
   - 设备信息字段为空时不会占用存储空间

6. 反馈类型
   - 根据实际场景选择合适的反馈类型
   - 避免使用 `notice` 类型（除非是管理员）
   - 不确定类型时使用 `other`

## API 参考

### FeedMatterConfig

| 参数      | 类型   | 必填 | 说明                         |
| --------- | ------ | ---- | ---------------------------- |
| baseUrl   | String | 是   | API 服务器地址               |
| apiKey    | String | 是   | 项目 API Key                 |
| apiSecret | String | 是   | 项目 API Secret              |
| appMarket | String | 是   | 应用渠道标识，会写入客户端信息 |
| timeout   | int    | 否   | 请求超时时间（秒），默认 30  |
| debug     | bool   | 否   | 是否开启调试模式，默认 false |

### FeedMatterUser

| 参数       | 类型   | 必填 | 说明         |
| ---------- | ------ | ---- | ------------ |
| userId     | String | 是   | 用户唯一标识 |
| userName   | String | 是   | 用户名称     |
| userAvatar | String | 否   | 用户头像 URL |

### ClientInfo

| 参数                | 类型   | 必填 | 说明         |
| ------------------- | ------ | ---- | ------------ |
| appVersionName      | String | 是   | 应用版本名   |
| appVersionCode      | int    | 是   | 应用版本号   |
| appPackage          | String | 是   | 应用包名     |
| appType             | String | 是   | 应用类型     |
| deviceModel         | String | 否   | 设备型号     |
| deviceBrand         | String | 否   | 设备品牌     |
| deviceSysVersion    | String | 否   | 系统版本名称 |
| deviceSysVersionInt | String | 否   | 系统版本号   |

### ProjectConfig

项目配置信息模型。

| 字段                      | 类型    | 默认值 | 说明                       |
| ------------------------- | ------- | ------ | -------------------------- |
| feedbackPrompt            | String? | null   | 添加反馈时的提示词         |
| commentPrompt             | String? | null   | 添加评论时的提示词         |
| feedbackEnabled           | bool    | true   | 是否允许发布反馈           |
| commentEnabled            | bool    | true   | 是否允许发布评论           |
| feedbackAttachmentEnabled | bool    | true   | 反馈是否支持附件           |
| commentAttachmentEnabled  | bool    | true   | 评论是否支持附件           |
| guestFeedbackEnabled      | bool    | false  | 未登录用户是否可以发布反馈 |
| guestCommentEnabled       | bool    | false  | 未登录用户是否可以发布评论 |
| feedbackMaxContentLength  | int     | 3000   | 反馈最大内容长度           |
| commentMaxContentLength   | int     | 3000   | 评论最大内容长度           |
| maxAttachments            | int     | 8      | 最大附件数量               |
| maxUploadFileSize         | int     | 40MB   | 最大上传文件大小           |

### FaqListResponse

常见问题列表响应模型，由 `getFaqList()` 返回。

| 字段      | 类型            | 说明                                                             |
| --------- | --------------- | ---------------------------------------------------------------- |
| version   | String          | 当前 FAQ 数据版本，客户端应缓存该值用于下次版本检查              |
| items     | List<FaqItem>   | FAQ 列表；如果服务端数据未更新，该列表为空                       |
| hasUpdate | bool            | 便捷 getter，`items` 非空时为 `true`，表示客户端应更新本地缓存    |

### FaqItem

单条常见问题模型。

| 字段      | 类型          | 说明                                           |
| --------- | ------------- | ---------------------------------------------- |
| id        | String        | FAQ ID                                         |
| title     | String        | 问题标题                                       |
| answer    | String?       | 问题答案，可直接用于展开展示                   |
| url       | String?       | 外部帮助文档链接，可用于跳转详情页             |
| keywords  | String?       | 搜索关键词，可用于客户端本地过滤               |
| platforms | List<String>? | 适用平台列表，例如 `android`、`ios`、`macos`   |
| sortOrder | int           | 排序值，服务端返回时通常已按该值排序           |

## 响应格式

FeedMatter API 使用统一的响应格式：

```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    // 实际的业务数据
  },
  "timestamp": "2023-05-01 12:34:56"
}
```

SDK 会自动处理这种响应格式，提取 `data` 字段的内容，并处理错误码。您不需要手动处理这些细节。

## 数据模型

### Feedback

反馈信息模型。

| 字段         | 类型                  | 说明                                                         |
| ------------ | --------------------- | ------------------------------------------------------------ |
| id           | String                | 反馈 ID                                                      |
| content      | String                | 反馈内容                                                     |
| status       | String                | 反馈状态（PENDING/IN_PROGRESS/RESOLVED/DELETED） |
| author       | Author                | 作者信息                                                     |
| attachments  | List<Attachment>?     | 附件列表                                                     |
| isPinned     | bool                  | 是否置顶                                                     |
| commentCount | int                   | 评论数量                                                     |
| readCount    | int                   | 阅读数量                                                     |
| createdAt    | DateTime              | 创建时间                                                     |
| updatedAt    | DateTime              | 更新时间                                                     |
| clientInfo   | Map<String, dynamic>? | 客户端信息（设备、系统、应用版本等）                         |
| customInfo   | Map<String, dynamic>? | 自定义信息（由开发者定义）                                   |
| mark         | FeedbackMark?         | 标记信息                                                     |

### Comment

评论信息模型。

| 字段            | 类型         | 说明                         |
| --------------- | ------------ | ---------------------------- |
| id              | String       | 评论 ID                      |
| content         | String       | 评论内容                     |
| author          | Author       | 作者信息                     |
| parentId        | String?      | 父评论 ID（用于回复）        |
| parentUserName  | String?      | 父评论作者用户名             |
| pinned          | bool         | 是否置顶                     |
| replyCount      | int          | 直接回复数量                 |
| totalReplyCount | int          | 总回复数（包括子孙回复）     |
| createdAt       | DateTime     | 创建时间                     |
| clientInfo      | ClientInfo?  | 客户端信息                   |
| mark            | CommentMark? | 标记信息                     |
| attachments     | List<Attachment>? | 附件列表                |
| status          | String?      | 评论状态                     |
| feedbackId      | String?      | 所属反馈 ID                  |

### MainCommentWithReplies

主评论及其回复（楼中楼模式）。

| 字段        | 类型               | 说明           |
| ----------- | ------------------ | -------------- |
| id          | String             | 评论 ID        |
| content     | String             | 评论内容       |
| author      | Author             | 作者信息       |
| createdAt   | DateTime           | 创建时间       |
| mark        | CommentMark?       | 标记信息       |
| status      | String?            | 评论状态       |
| clientInfo  | ClientInfo?        | 客户端信息     |
| attachments | List<Attachment>?  | 附件列表       |
| replies     | PagedReplies       | 分页回复       |
| pinned      | bool               | 是否置顶       |

### PagedReplies

分页回复响应。

| 字段          | 类型           | 说明                  |
| ------------- | -------------- | --------------------- |
| content       | List<Comment>  | 回复列表              |
| currentPage   | int            | 当前页码（从0开始）   |
| totalPages    | int            | 总页数                |
| totalElements | int            | 总元素数              |
| hasNext       | bool           | 是否有下一页          |
| hasPrevious   | bool           | 是否有上一页          |

### Author

用户信息模型。

| 字段     | 类型    | 说明     |
| -------- | ------- | -------- |
| id       | String  | 用户 ID  |
| username | String  | 用户名   |
| avatar   | String? | 头像 URL |

### Attachment

附件信息模型。

| 字段      | 类型     | 说明     |
| --------- | -------- | -------- |
| id        | String   | 附件 ID  |
| fileName  | String   | 文件名   |
| fileUrl   | String   | 文件 URL |
| fileType  | String   | 文件类型 |
| createdAt | DateTime | 创建时间 |

### FeedbackMark

反馈标记信息模型。

| 字段    | 类型 | 说明                 |
| ------- | ---- | -------------------- |
| isAdmin | bool | 是否管理员发布的反馈 |

### CommentMark

评论标记信息模型。

| 字段         | 类型 | 说明           |
| ------------ | ---- | -------------- |
| isAdminReply | bool | 是否管理员回复 |

## 状态码说明

### 反馈状态（FeedbackStatus）

| 状态        | 说明   |
| ----------- | ------ |
| PENDING     | 审核中 |
| IN_PROGRESS | 处理中 |
| RESOLVED    | 已解决 |
| DELETED     | 已删除 |

### 错误码

| 错误码              | 说明         |
| ------------------- | ------------ |
| CONFIG_NOT_SET      | 配置未设置   |
| INVALID_API_KEY     | API Key 无效 |
| FORBIDDEN           | 没有权限     |
| NOT_FOUND           | 资源不存在   |
| NETWORK_ERROR       | 网络错误     |
| SERVER_ERROR        | 服务器错误   |
| BAD_REQUEST         | 请求参数错误 |
| RATE_LIMIT_EXCEEDED | 请求频率超限 |

## 示例项目

完整的示例项目请参考 [example](example) 目录。示例项目内置了一套可复制的反馈 UI，方便第三方 App 直接拷贝后按自己的设计规范调整。

### 可复制 UI 目录

```text
example/lib/
  main.dart
  feedmatter_ui/
    feedback_home_page.dart
    feedback_submit_page.dart
    feedback_detail_page.dart
    feedmatter_ui_helpers.dart
    widgets/
      feedback_card.dart
      comment_floor_card.dart
```

这套 UI 覆盖：

- SDK 初始化和全局错误处理。
- 进入反馈模块后读取 `getProjectConfig()`。
- 根据项目配置展示反馈、评论、附件、游客权限等开关状态。
- 反馈列表、关键词搜索、全部反馈 / 我的反馈切换。
- 提交反馈，支持反馈类型选择、字数限制和附件入口预留。
- 反馈详情展示。
- 楼中楼评论展示、发表评论、回复主评论、加载更多回复。
- 点赞反馈和下拉刷新。

接入建议：

1. 复制 `example/lib/feedmatter_ui/` 到你的业务项目。
2. 在业务 App 启动或用户信息加载完成后，参考 `example/lib/main.dart` 初始化 `FeedMatterClient`。
3. 替换 `apiKey`、`apiSecret`、`appMarket` 和 `FeedMatterUser`。
4. 根据你的设计系统修改 `feedback_card.dart`、`comment_floor_card.dart` 和页面样式。
5. 如果需要附件上传，把你的文件选择器接到 `feedback_submit_page.dart` 中预留的按钮，然后调用 `uploadPublicFile()` 或 `uploadPrivateFile()`。

## ActionCard 链接

> **状态说明**：ActionCard 是预留能力，当前 Flutter SDK 和 `feedmatter-api` 尚未正式启用该功能。下面内容仅用于说明计划中的 URL 约定，请不要在生产接入中依赖该能力。

FeedMatter 后续计划支持通过特殊的 URL Scheme 来展示富媒体卡片。格式如下：

```

actioncard://fm.com/?logo=LOGO_URL&appname=APP_NAME&title=TITLE&desc=DESCRIPTION&image=IMAGE_URL

```

### 参数说明

| 参数    | 必填 | 说明              |
| ------- | ---- | ----------------- |
| logo    | 否   | 应用/平台图标 URL |
| appname | 否   | 应用/平台名称     |
| title   | 是   | 卡片标题          |
| desc    | 否   | 卡片描述文本      |
| image   | 否   | 预览图 URL        |

### 示例

```dart
// 小红书用户主页
final url = 'actioncard://fm.com/?'
    'logo=https://ci.xiaohongshu.com/fe-platform-service/f190e97a-cf88-4512-9bea-c5f6158bd85b&'
    'appname=小红书&'
    'title=用户主页&'
    'desc=点击查看详情';

// 微信公众号文章
final url = 'actioncard://fm.com/?'
    'logo=https://res.wx.qq.com/a/wx_fed/assets/res/OTE0YTAw.png&'
    'appname=微信公众号&'
    'title=这是一篇公众号文章&'
    'desc=点击阅读全文&'
    'image=https://example.com/preview.jpg';
```

### 卡片展示效果

卡片包含以下元素：

1. 左侧显示应用图标（logo），如果未提供则显示默认图标
2. 中间显示应用名称（appname）和标题（title），以及可选的描述文本（desc）
3. 右侧显示可选的预览图（image）
4. 点击卡片会触发链接跳转

### 使用场景

ActionCard 适用于以下场景：

1. 展示第三方平台的内容预览
2. 统一不同平台的链接展示样式
3. 提供更丰富的视觉信息和交互体验

### 注意事项

1. URL 中的所有参数值需要进行 URL 编码
2. 图片资源（logo 和 image）建议使用 HTTPS 链接
3. 建议 logo 使用正方形图片，image 使用 16:9 或 4:3 的图片
4. 标题和描述文本过长时会自动截断

## 许可证

MIT License
