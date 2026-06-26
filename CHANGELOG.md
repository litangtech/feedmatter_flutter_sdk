## 1.0.6

* 🧩 新增独立 UI 包 `feedmatter_flutter_ui`（`packages/feedmatter_flutter_ui`），提供反馈列表、提交、详情、FAQ 及组合入口 Widget。
* 📝 更新 README 与 example，改为依赖 UI 包接入，不再要求复制 `feedmatter_ui/` 目录。

## 1.0.5

* 📝 完善常见问题 FAQ 文档，补充 `getFaqList()` 用法、版本缓存建议和 FAQ 数据结构说明。
* 📝 更新 README 接入示例版本号，准备发布包含 FAQ 文档增强的新版 SDK。

## 1.0.4

* 📝 完善 `example` 示例项目，补齐 Android、iOS、macOS、Windows、Linux 多端工程。
* 🧩 新增可复制的反馈 UI 示例，覆盖反馈列表、提交反馈、反馈详情、评论、楼中楼回复和点赞流程。
* 📝 补充 example 接入文档，说明测试 `apiKey` / `apiSecret`、运行方式和业务项目复制接入步骤。
* 🔧 优化 example 平台配置，包括 Android 网络权限、macOS 网络权限、包名和应用显示名称。

## 1.0.3

* 📝 更新仓库地址为 `litangtech/feedmatter_flutter_sdk`。
* 🔒 加强 SDK debug 日志脱敏，避免输出敏感请求头。
* 📝 保持默认 API 地址指向当前线上服务域名。
* 📝 声明 pub.dev 支持 Android、iOS、macOS、Windows、Linux 平台。

## 1.0.2

* 📝 完善 SDK 接入文档，增加最佳实践清单和项目回调说明。
* 🐛 修复 `uploadPrivateFile` 方法解析私密文件 key 错误的 Bug。
* 🔒 脱敏 `FeedMatterConfig.toString()` 中的 `apiSecret` 输出。

## 1.0.1

* 🎉 新增楼中楼评论接口支持 (`getCommentsFloor`, `getCommentReplies`)。
* 📝 更新 `Comment` 模型，添加 `parentUserId`, `totalReplyCount` 等字段。

## 1.0.0

* 🚀 初始版本发布。
