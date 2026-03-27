import 'package:json_annotation/json_annotation.dart';

part 'comment_mark.g.dart';

@JsonSerializable()
class CommentMark {
  @JsonKey(name: 'isAdmin')
  final int? _isAdmin; //是否管理员发布的评论
  
  @JsonKey(name: 'isAdminReply')
  final int? _isAdminReply; //是否管理员回复的评论

  const CommentMark({
    int? isAdmin,
    int? isAdminReply,
  }) : _isAdmin = isAdmin,
       _isAdminReply = isAdminReply;

  // 计算属性：将 int? 转换为 bool
  bool get isAdmin => _isAdmin == 1;
  bool get isAdminReply => _isAdminReply == 1;

  factory CommentMark.fromJson(Map<String, dynamic> json) =>
      _$CommentMarkFromJson(json);

  Map<String, dynamic> toJson() => _$CommentMarkToJson(this);
}
