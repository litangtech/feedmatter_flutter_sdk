## 1.0.3

* 📝 更新仓库地址为 `litangtech/feedmatter_flutter_sdk`。
* 🔒 加强 SDK debug 日志脱敏，避免输出敏感请求头。
* 📝 保持默认 API 地址指向当前线上服务域名。

## 1.0.2

* 📝 完善 SDK 接入文档，增加最佳实践清单和项目回调说明。
* 🐛 修复 `uploadPrivateFile` 方法解析私密文件 key 错误的 Bug。
* 🔒 脱敏 `FeedMatterConfig.toString()` 中的 `apiSecret` 输出。

## 1.0.1

* 🎉 新增楼中楼评论接口支持 (`getCommentsFloor`, `getCommentReplies`)。
* 📝 更新 `Comment` 模型，添加 `parentUserId`, `totalReplyCount` 等字段。

## 1.0.0

* 🚀 初始版本发布。
