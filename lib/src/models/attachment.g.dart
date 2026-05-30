// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Attachment _$AttachmentFromJson(Map<String, dynamic> json) => Attachment(
      fileName: json['fileName'] as String,
      fileUrl: json['fileUrl'] as String?,
      fileType: $enumDecode(_$FileTypeEnumMap, json['fileType']),
      referencedId: json['referencedId'] as String?,
      referencedFeedback: json['referencedFeedback'] == null
          ? null
          : Feedback.fromJson(
              json['referencedFeedback'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AttachmentToJson(Attachment instance) =>
    <String, dynamic>{
      'fileName': instance.fileName,
      'fileUrl': instance.fileUrl,
      'fileType': _$FileTypeEnumMap[instance.fileType]!,
      'referencedId': instance.referencedId,
      'referencedFeedback': instance.referencedFeedback,
    };

const _$FileTypeEnumMap = {
  FileType.img: 'IMG',
  FileType.vid: 'VID',
  FileType.doc: 'DOC',
  FileType.txt: 'TXT',
  FileType.fref: 'FREF',
  FileType.cref: 'CREF',
};
