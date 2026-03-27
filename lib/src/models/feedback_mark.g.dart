// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback_mark.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FeedbackMark _$FeedbackMarkFromJson(Map<String, dynamic> json) => FeedbackMark(
      isAdmin: (json['isAdmin'] as num?)?.toInt(),
      isAdminReply: (json['isAdminReply'] as num?)?.toInt(),
    );

Map<String, dynamic> _$FeedbackMarkToJson(FeedbackMark instance) =>
    <String, dynamic>{
      'isAdmin': instance.isAdmin,
      'isAdminReply': instance.isAdminReply,
    };
