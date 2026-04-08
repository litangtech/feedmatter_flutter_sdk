// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'faq_list_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FaqListResponse _$FaqListResponseFromJson(Map<String, dynamic> json) =>
    FaqListResponse(
      version: json['version'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => FaqItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$FaqListResponseToJson(FaqListResponse instance) =>
    <String, dynamic>{
      'version': instance.version,
      'items': instance.items,
    };
