// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_mark.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommentMark _$CommentMarkFromJson(Map<String, dynamic> json) => CommentMark(
      isAdmin: (json['isAdmin'] as num?)?.toInt(),
      isAdminReply: (json['isAdminReply'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CommentMarkToJson(CommentMark instance) =>
    <String, dynamic>{
      'isAdmin': instance.isAdmin,
      'isAdminReply': instance.isAdminReply,
    };
