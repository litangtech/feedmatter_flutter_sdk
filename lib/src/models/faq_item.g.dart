// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'faq_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FaqItem _$FaqItemFromJson(Map<String, dynamic> json) => FaqItem(
      id: json['id'] as String,
      title: json['title'] as String,
      answer: json['answer'] as String?,
      url: json['url'] as String?,
      keywords: json['keywords'] as String?,
      platforms: (json['platforms'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$FaqItemToJson(FaqItem instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'answer': instance.answer,
      'url': instance.url,
      'keywords': instance.keywords,
      'platforms': instance.platforms,
      'sortOrder': instance.sortOrder,
    };
