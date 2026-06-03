import 'package:json_annotation/json_annotation.dart';
import '../enums/file_type.dart';
import 'feedback.dart';

part 'attachment.g.dart';

@JsonSerializable()
class Attachment {
  final String fileName;
  final String? fileUrl;
  final FileType fileType;
  final String? referencedId;
  final Feedback? referencedFeedback;

  const Attachment({
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    this.referencedId,
    this.referencedFeedback,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) =>
      _$AttachmentFromJson(json);
  Map<String, dynamic> toJson() => _$AttachmentToJson(this);
}
