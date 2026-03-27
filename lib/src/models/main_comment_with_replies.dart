import 'package:json_annotation/json_annotation.dart';
import 'attachment.dart';
import 'author.dart';
import 'client_info.dart';
import 'comment_mark.dart';
import 'paged_replies.dart';

part 'main_comment_with_replies.g.dart';

/// 主评论及其回复（楼中楼模式）
@JsonSerializable()
class MainCommentWithReplies {
  /// 评论ID
  final String id;
  
  /// 评论内容
  final String content;
  
  /// 作者信息
  final Author author;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 评论标记
  final CommentMark? mark;
  
  /// 评论状态
  final String? status;
  
  /// 客户端信息
  final ClientInfo? clientInfo;
  
  /// 附件列表
  final List<Attachment>? attachments;
  
  /// 分页回复
  final PagedReplies replies;
  
  /// 是否置顶
  @JsonKey(defaultValue: false)
  final bool pinned;

  const MainCommentWithReplies({
    required this.id,
    required this.content,
    required this.author,
    required this.createdAt,
    this.mark,
    this.status,
    this.clientInfo,
    this.attachments,
    required this.replies,
    this.pinned = false,
  });

  factory MainCommentWithReplies.fromJson(Map<String, dynamic> json) =>
      _$MainCommentWithRepliesFromJson(json);
  
  Map<String, dynamic> toJson() => _$MainCommentWithRepliesToJson(this);
}

