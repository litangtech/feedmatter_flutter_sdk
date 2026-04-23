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

## 安装

将以下依赖添加到你的 `pubspec.yaml` 文件中：

```yaml
dependencies:
  feedmatter_flutter_sdk: ^1.0.0
```

然后运行：

```bash
flutter pub get
```

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

### 2. 提交反馈

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

### 3. 反馈类型

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

### 4. 设备信息

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

### 5. 获取反馈列表

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

### 6. 评论功能

#### 6.1 添加评论

```dart
// 添加评论
final comment = await client.createComment(
  'feedback-id',    // 反馈 ID
  '这是一条评论',    // 评论内容
);

// 添加回复（回复某条评论）
final reply = await client.createComment(
  'feedback-id',          // 反馈 ID
  '回复内容',              // 评论内容
  parentCommentId: 'comment-id',  // 父评论 ID
);
```

#### 6.2 获取评论列表（楼中楼格式）

**推荐使用**楼中楼格式获取评论，这种方式将主评论和回复分开展示，支持独立翻页：

```dart
// 获取主评论列表（楼中楼格式）
final mainComments = await client.getCommentsFloor(
  'feedback-id',
  page: 0,
  size: 20,
  sort: 'created_asc',  // 排序方式：created_asc（默认）, created_desc, reply_desc
);

// 每个主评论包含：
// - 评论基本信息（内容、作者、时间等）
// - 回复的分页数据（前N条回复 + 分页信息）
for (var mainComment in mainComments) {
  print('主评论: ${mainComment.content}');
  print('回复数: ${mainComment.replies.totalElements}');
  
  // 首次加载时自动包含的回复
  for (var reply in mainComment.replies.content) {
    print('  回复: ${reply.content}');
  }
  
  // 检查是否还有更多回复
  if (mainComment.replies.hasNext) {
    // 加载更多回复
    final moreReplies = await client.getCommentReplies(
      mainComment.id,
      page: 1,
      size: 10,
    );
  }
}
```

#### 6.3 获取回复列表（分页）

当需要加载某个主评论的更多回复时：

```dart
// 获取某个主评论的回复（分页）
final pagedReplies = await client.getCommentReplies(
  'main-comment-id',
  page: 0,
  size: 10,
);

print('回复列表:');
for (var reply in pagedReplies.content) {
  print('- ${reply.author.username}: ${reply.content}');
}

print('总回复数: ${pagedReplies.totalElements}');
print('当前页: ${pagedReplies.currentPage}');
print('总页数: ${pagedReplies.totalPages}');
print('是否有下一页: ${pagedReplies.hasNext}');
```

#### 排序选项

楼中楼评论支持以下排序方式：

- `created_asc`: 按创建时间升序（默认，最早的在前）
- `created_desc`: 按创建时间降序（最新的在前）
- `reply_desc`: 按回复数降序（回复最多的在前）

注意：所有排序都会优先显示置顶评论

### 7. 项目配置

```dart
// 获取项目配置
try {
  final config = await client.getProjectConfig();
  print('反馈提示词: ${config.feedbackPrompt}');
  print('评论提示词: ${config.commentPrompt}');
  print('是否允许发布反馈: ${config.feedbackEnabled}');
  print('是否允许发布评论: ${config.commentEnabled}');
  print('反馈是否支持附件: ${config.feedbackAttachmentEnabled}');
  print('评论是否支持附件: ${config.commentAttachmentEnabled}');
  print('游客是否可以发布反馈: ${config.guestFeedbackEnabled}');
  print('游客是否可以发布评论: ${config.guestCommentEnabled}');
  print('反馈最大内容长度: ${config.feedbackMaxContentLength}');
  print('评论最大内容长度: ${config.commentMaxContentLength}');
  print('最大附件数量: ${config.maxAttachments}');
  print('最大文件大小: ${config.maxUploadFileSize}');
} catch (e) {
  print('获取配置失败: $e');
}
```

项目配置包含以下字段：

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
| maxUploadFileSize         | int     | 10MB   | 最大上传文件大小           |

使用示例：

```dart
// 获取项目配置
try {
  final config = await client.getProjectConfig();

  // 1. 检查是否允许发布反馈
  if (!config.feedbackEnabled) {
    showToast('该项目已关闭反馈功能');
    return;
  }

  // 2. 检查游客权限
  if (!config.guestFeedbackEnabled && !isUserLoggedIn) {
    showToast('未登录用户不能发布反馈');
    return;
  }

  // 3. 检查附件权限
  if (!config.feedbackAttachmentEnabled) {
    // 隐藏附件上传按钮
    attachmentButton.visible = false;
  }

  // 4. 设置提示词
  if (config.feedbackPrompt != null) {
    feedbackInput.hint = config.feedbackPrompt;
  }

  // 5. 检查反馈内容长度
  if (content.length > config.feedbackMaxContentLength) {
    showToast('反馈内容超出长度限制');
    return;
  }

  // 6. 检查附件数量
  if (attachments.length > config.maxAttachments) {
    showToast('附件数量超出限制');
    return;
  }

  // 7. 检查文件大小
  if (file.size > config.maxUploadFileSize) {
    showToast('文件大小超出限制');
    return;
  }
} catch (e) {
  print('获取配置失败: $e');
}
```

## 文件上传

SDK 提供了安全的文件上传功能，包括以下特性：

- 文件大小限制（默认最大 10MB）
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
  // 1. 上传文件，获取文件 key
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
- 上传私密文件：POST `/api/v2/upload/private`
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
| maxUploadFileSize         | int     | 10MB   | 最大上传文件大小           |

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

完整的示例项目请参考 [example](example) 目录。

## 许可证

MIT License

## ActionCard 链接

FeedMatter SDK 支持通过特殊的 URL Scheme 来展示富媒体卡片。格式如下：

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
