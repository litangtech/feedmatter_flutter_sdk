// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProjectConfig _$ProjectConfigFromJson(Map<String, dynamic> json) =>
    ProjectConfig(
      feedbackPrompt: json['feedbackPrompt'] as String?,
      commentPrompt: json['commentPrompt'] as String?,
      feedbackEnabled: json['feedbackEnabled'] as bool? ?? true,
      commentEnabled: json['commentEnabled'] as bool? ?? true,
      feedbackAttachmentEnabled:
          json['feedbackAttachmentEnabled'] as bool? ?? true,
      commentAttachmentEnabled:
          json['commentAttachmentEnabled'] as bool? ?? true,
      guestFeedbackEnabled: json['guestFeedbackEnabled'] as bool? ?? false,
      guestCommentEnabled: json['guestCommentEnabled'] as bool? ?? false,
      feedbackMaxContentLength:
          (json['feedbackMaxContentLength'] as num?)?.toInt() ?? 3000,
      commentMaxContentLength:
          (json['commentMaxContentLength'] as num?)?.toInt() ?? 3000,
      maxAttachments: (json['maxAttachments'] as num?)?.toInt() ?? 8,
      maxUploadFileSize:
          (json['maxUploadFileSize'] as num?)?.toInt() ?? 10 * 1024 * 1024,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );

Map<String, dynamic> _$ProjectConfigToJson(ProjectConfig instance) =>
    <String, dynamic>{
      'feedbackPrompt': instance.feedbackPrompt,
      'commentPrompt': instance.commentPrompt,
      'feedbackEnabled': instance.feedbackEnabled,
      'commentEnabled': instance.commentEnabled,
      'feedbackAttachmentEnabled': instance.feedbackAttachmentEnabled,
      'commentAttachmentEnabled': instance.commentAttachmentEnabled,
      'guestFeedbackEnabled': instance.guestFeedbackEnabled,
      'guestCommentEnabled': instance.guestCommentEnabled,
      'feedbackMaxContentLength': instance.feedbackMaxContentLength,
      'commentMaxContentLength': instance.commentMaxContentLength,
      'maxAttachments': instance.maxAttachments,
      'maxUploadFileSize': instance.maxUploadFileSize,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };
