import 'package:json_annotation/json_annotation.dart';
import 'author.dart';
import 'attachment.dart';
import 'feedback_mark.dart';
import 'client_info.dart';
import '../enums/feedback_status.dart';
import '../enums/feedback_type.dart';

part 'feedback.g.dart';

@JsonSerializable()
class Feedback {
  final String id;
  final String content;
  @JsonKey(unknownEnumValue: FeedbackStatus.pending)
  final FeedbackStatus status;
  @JsonKey(unknownEnumValue: FeedbackType.other)
  final FeedbackType? type;
  final Author author;
  @JsonKey(name: 'pinned', defaultValue: false)
  final bool isPinned;
  @JsonKey(defaultValue: 0)
  final int readCount;
  @JsonKey(defaultValue: 0)
  final int commentCount;
  final int likeCount;
  @JsonKey(name: 'liked', defaultValue: false)
  final bool isLiked;
  @JsonKey(name: 'allowComment', defaultValue: true)
  final bool allowComment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ClientInfo? clientInfo;
  final Map<String, dynamic>? customInfo;
  final FeedbackMark? mark;
  final List<Attachment>? attachments;

  const Feedback({
    required this.id,
    required this.content,
    required this.status,
    this.type,
    required this.author,
    this.isPinned = false,
    this.readCount = 0,
    this.commentCount = 0,
    this.likeCount = 0,
    this.isLiked = false,
    this.allowComment = true,
    required this.createdAt,
    required this.updatedAt,
    this.clientInfo,
    this.customInfo,
    this.mark,
    this.attachments,
  });

  factory Feedback.fromJson(Map<String, dynamic> json) => _$FeedbackFromJson(json);
  Map<String, dynamic> toJson() => _$FeedbackToJson(this);

  Feedback copyWith({
    String? id,
    String? content,
    FeedbackStatus? status,
    FeedbackType? type,
    Author? author,
    bool? isPinned,
    int? readCount,
    int? commentCount,
    int? likeCount,
    bool? isLiked,
    bool? allowComment,
    DateTime? createdAt,
    DateTime? updatedAt,
    ClientInfo? clientInfo,
    Map<String, dynamic>? customInfo,
    FeedbackMark? mark,
    List<Attachment>? attachments,
  }) {
    return Feedback(
      id: id ?? this.id,
      content: content ?? this.content,
      status: status ?? this.status,
      type: type ?? this.type,
      author: author ?? this.author,
      isPinned: isPinned ?? this.isPinned,
      readCount: readCount ?? this.readCount,
      commentCount: commentCount ?? this.commentCount,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
      allowComment: allowComment ?? this.allowComment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      clientInfo: clientInfo ?? this.clientInfo,
      customInfo: customInfo ?? this.customInfo,
      mark: mark ?? this.mark,
      attachments: attachments ?? this.attachments,
    );
  }
}
