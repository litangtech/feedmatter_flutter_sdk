// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paged_replies.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PagedReplies _$PagedRepliesFromJson(Map<String, dynamic> json) => PagedReplies(
      content: (json['content'] as List<dynamic>)
          .map((e) => Comment.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: (json['currentPage'] as num).toInt(),
      totalPages: (json['totalPages'] as num).toInt(),
      totalElements: (json['totalElements'] as num).toInt(),
      hasNext: json['hasNext'] as bool,
      hasPrevious: json['hasPrevious'] as bool,
    );

Map<String, dynamic> _$PagedRepliesToJson(PagedReplies instance) =>
    <String, dynamic>{
      'content': instance.content,
      'currentPage': instance.currentPage,
      'totalPages': instance.totalPages,
      'totalElements': instance.totalElements,
      'hasNext': instance.hasNext,
      'hasPrevious': instance.hasPrevious,
    };
