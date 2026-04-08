// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main_comment_with_replies.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MainCommentWithReplies _$MainCommentWithRepliesFromJson(
        Map<String, dynamic> json) =>
    MainCommentWithReplies(
      id: json['id'] as String,
      content: json['content'] as String,
      author: Author.fromJson(json['author'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      mark: json['mark'] == null
          ? null
          : CommentMark.fromJson(json['mark'] as Map<String, dynamic>),
      status: json['status'] as String?,
      clientInfo: json['clientInfo'] == null
          ? null
          : ClientInfo.fromJson(json['clientInfo'] as Map<String, dynamic>),
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => Attachment.fromJson(e as Map<String, dynamic>))
          .toList(),
      replies: PagedReplies.fromJson(json['replies'] as Map<String, dynamic>),
      pinned: json['pinned'] as bool? ?? false,
    );

Map<String, dynamic> _$MainCommentWithRepliesToJson(
        MainCommentWithReplies instance) =>
    <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'author': instance.author,
      'createdAt': instance.createdAt.toIso8601String(),
      'mark': instance.mark,
      'status': instance.status,
      'clientInfo': instance.clientInfo,
      'attachments': instance.attachments,
      'replies': instance.replies,
      'pinned': instance.pinned,
    };
