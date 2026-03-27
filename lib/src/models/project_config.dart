import 'package:json_annotation/json_annotation.dart';

part 'project_config.g.dart';

@JsonSerializable()
class ProjectConfig {
  /// 反馈提示词
  final String? feedbackPrompt;

  /// 评论提示词
  final String? commentPrompt;

  /// 是否支持发布反馈
  final bool feedbackEnabled;

  /// 是否支持发布评论
  final bool commentEnabled;

  /// 反馈是否支持附件
  final bool feedbackAttachmentEnabled;

  /// 评论是否支持附件
  final bool commentAttachmentEnabled;

  /// 未登录用户是否可以发布反馈
  final bool guestFeedbackEnabled;

  /// 未登录用户是否可以发布评论
  final bool guestCommentEnabled;

  /// 反馈最大内容长度
  final int feedbackMaxContentLength;

  /// 评论最大内容长度
  final int commentMaxContentLength;

  /// 最大附件数量
  final int maxAttachments;

  /// 最大上传文件大小
  final int maxUploadFileSize;

  /// 创建时间
  final String? createdAt;

  /// 更新时间
  final String? updatedAt;

  const ProjectConfig({
    this.feedbackPrompt,
    this.commentPrompt,
    this.feedbackEnabled = true,
    this.commentEnabled = true,
    this.feedbackAttachmentEnabled = true,
    this.commentAttachmentEnabled = true,
    this.guestFeedbackEnabled = false,
    this.guestCommentEnabled = false,
    this.feedbackMaxContentLength = 3000,
    this.commentMaxContentLength = 3000,
    this.maxAttachments = 8,
    this.maxUploadFileSize = 10 * 1024 * 1024,
    this.createdAt,
    this.updatedAt,
  });

  factory ProjectConfig.fromJson(Map<String, dynamic> json) =>
      _$ProjectConfigFromJson(json);

  Map<String, dynamic> toJson() => _$ProjectConfigToJson(this);

  @override
  String toString() {
    return 'ProjectConfig('
        'feedbackPrompt: $feedbackPrompt, '
        'commentPrompt: $commentPrompt, '
        'feedbackEnabled: $feedbackEnabled, '
        'commentEnabled: $commentEnabled, '
        'feedbackAttachmentEnabled: $feedbackAttachmentEnabled, '
        'commentAttachmentEnabled: $commentAttachmentEnabled, '
        'guestFeedbackEnabled: $guestFeedbackEnabled, '
        'guestCommentEnabled: $guestCommentEnabled, '
        'feedbackMaxContentLength: $feedbackMaxContentLength, '
        'commentMaxContentLength: $commentMaxContentLength, '
        'maxAttachments: $maxAttachments, '
        'maxUploadFileSize: $maxUploadFileSize, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt)';
  }

  static ProjectConfig defaultConfig() {
    return const ProjectConfig(
      feedbackPrompt: "请描述您的问题或建议...",
      commentPrompt: "请输入评论...",
      feedbackEnabled: true,
      commentEnabled: true,
      feedbackAttachmentEnabled: true,
      commentAttachmentEnabled: true,
      guestFeedbackEnabled: false,
      guestCommentEnabled: false,

      /// 附件最大数量
      maxAttachments: 8,
      //目前写死，服务器限制了上传文件最大为10M
      maxUploadFileSize: 10 * 1024 * 1024,
    );
  }
}
