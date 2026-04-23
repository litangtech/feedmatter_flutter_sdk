import 'package:json_annotation/json_annotation.dart';

part 'feedback_mark.g.dart';


@JsonSerializable()
class FeedbackMark {
  @JsonKey(name: 'isAdmin')
  final int? _isAdmin; //是否管理员发布的评论
  
  @JsonKey(name: 'isAdminReply')
  final int? _isAdminReply; //是否管理员回复的评论

  const FeedbackMark({
    int? isAdmin,
    int? isAdminReply,
  }) : _isAdmin = isAdmin,
       _isAdminReply = isAdminReply;

  // 计算属性：将 int? 转换为 bool
  bool get isAdmin => _isAdmin == 1;
  bool get isAdminReply => _isAdminReply == 1;

  factory FeedbackMark.fromJson(Map<String, dynamic> json) =>
      _$FeedbackMarkFromJson(json);

  Map<String, dynamic> toJson() => _$FeedbackMarkToJson(this);
}
