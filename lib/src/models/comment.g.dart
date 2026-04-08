// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Comment _$CommentFromJson(Map<String, dynamic> json) => Comment(
      id: json['id'] as String,
      content: json['content'] as String,
      author: Author.fromJson(json['author'] as Map<String, dynamic>),
      parentId: json['parentId'] as String?,
      parentUserName: json['parentUserName'] as String?,
      parentUserId: json['parentUserId'] as String?,
      pinned: json['pinned'] as bool? ?? false,
      replyCount: (json['replyCount'] as num?)?.toInt() ?? 0,
      totalReplyCount: (json['totalReplyCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      clientInfo: json['clientInfo'] == null
          ? null
          : ClientInfo.fromJson(json['clientInfo'] as Map<String, dynamic>),
      mark: json['mark'] == null
          ? null
          : CommentMark.fromJson(json['mark'] as Map<String, dynamic>),
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => Attachment.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: json['status'] as String?,
      feedbackId: json['feedbackId'] as String?,
    );

Map<String, dynamic> _$CommentToJson(Comment instance) => <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'author': instance.author,
      'parentId': instance.parentId,
      'parentUserName': instance.parentUserName,
      'parentUserId': instance.parentUserId,
      'pinned': instance.pinned,
      'replyCount': instance.replyCount,
      'totalReplyCount': instance.totalReplyCount,
      'createdAt': instance.createdAt.toIso8601String(),
      'clientInfo': instance.clientInfo,
      'mark': instance.mark,
      'attachments': instance.attachments,
      'status': instance.status,
      'feedbackId': instance.feedbackId,
    };
