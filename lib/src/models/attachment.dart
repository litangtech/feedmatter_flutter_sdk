import 'package:json_annotation/json_annotation.dart';
import '../enums/file_type.dart';

part 'attachment.g.dart';

@JsonSerializable()
class Attachment {
  final String fileName;
  final String fileUrl;
  final FileType fileType;

  const Attachment({
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) => _$AttachmentFromJson(json);
  Map<String, dynamic> toJson() => _$AttachmentToJson(this);
} 