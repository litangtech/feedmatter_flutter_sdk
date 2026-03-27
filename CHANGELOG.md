## 1.1.1

### 改进

* 📝 更新 `Comment` 模型，添加新字段：
  * `parentUserId`: 通过 UUID 精确标识被回复的用户
  * 向后兼容，保留原有的 `parentUserName` 字段

## 1.1.0

### 新功能

* 🎉 新增楼中楼评论接口支持
  * 添加 `getCommentsFloor()` 方法：获取楼中楼格式的评论列表
  * 添加 `getCommentReplies()` 方法：获取主评论的分页回复
  * 新增 `MainCommentWithReplies` 模型：主评论及其回复的数据结构
  * 新增 `PagedReplies` 模型：分页回复的数据结构

### 改进

* 📝 更新 `Comment` 模型，添加以下字段：
  * `totalReplyCount`: 总回复数（包括子孙回复）
  * `status`: 评论状态
  * `feedbackId`: 所属反馈 ID
* 📚 完善文档，添加楼中楼评论的详细使用说明和示例

### API 变更

* ✨ 新增接口：
  * `GET /api/v2/feedbacks/{id}/comments/floor` - 获取楼中楼格式评论列表
  * `GET /api/v2/feedbacks/comments/{mainCommentId}/replies` - 获取主评论的回复（分页）
* ❌ 移除接口：
  * `getComments()` - 已移除，请使用 `getCommentsFloor()` 代替
  * `GET /api/v2/feedbacks/{id}/comments/nested` - 已移除，请使用楼中楼接口

## 0.0.1

* 初始版本发布
