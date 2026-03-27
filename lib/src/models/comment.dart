import 'package:feedmatter_flutter_sdk/src/models/attachment.dart';
import 'package:json_annotation/json_annotation.dart';

import 'author.dart';
import 'client_info.dart';
import 'comment_mark.dart';

part 'comment.g.dart';

@JsonSerializable()
class Comment {
  final String id;
  final String content;
  final Author author;
  final String? parentId;
  final String? parentUserName;
  final String? parentUserId;
  @JsonKey(name: 'pinned', defaultValue: false)
  final bool pinned;
  @JsonKey(defaultValue: 0)
  final int replyCount;
  @JsonKey(defaultValue: 0)
  final int totalReplyCount;
  final DateTime createdAt;
  final ClientInfo? clientInfo;
  final CommentMark? mark;
  final List<Attachment>? attachments;
  final String? status;
  final String? feedbackId;

  @JsonKey(includeFromJson: false, includeToJson: false)
  bool hasMoreSubComment = false;

  @JsonKey(includeFromJson: false, includeToJson: false)
  int _subCommentCount = 0;

  @JsonKey(includeFromJson: false, includeToJson: false)
  String? rootCommentId;

  @JsonKey(includeFromJson: false, includeToJson: false)
  bool isLastSubComment = false;

  Comment({
    required this.id,
    required this.content,
    required this.author,
    this.parentId,
    this.parentUserName,
    this.parentUserId,
    this.pinned = false,
    this.replyCount = 0,
    this.totalReplyCount = 0,
    required this.createdAt,
    this.clientInfo,
    this.mark,
    this.attachments,
    this.status,
    this.feedbackId,
  });

  factory Comment.fromJson(Map<String, dynamic> json) => _$CommentFromJson(json);
  Map<String, dynamic> toJson() => _$CommentToJson(this);

  void setSubCommentProps(String? rootCommentId, bool isLastSubComment) {
    this.rootCommentId = rootCommentId;
    this.isLastSubComment = isLastSubComment;
  }

  void setMainCommentProps(bool hasMoreSubComment, int subCommentCount) {
    this.hasMoreSubComment = hasMoreSubComment;
    _subCommentCount = subCommentCount;
  }

  int getSubCommentCount() => _subCommentCount;

  bool isMainComment() => parentId == null || parentId!.isEmpty;
}