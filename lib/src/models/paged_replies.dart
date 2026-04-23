import 'package:json_annotation/json_annotation.dart';
import 'comment.dart';

part 'paged_replies.g.dart';

/// 分页回复响应
@JsonSerializable()
class PagedReplies {
  /// 回复列表
  final List<Comment> content;
  
  /// 当前页码（从0开始）
  final int currentPage;
  
  /// 总页数
  final int totalPages;
  
  /// 总元素数
  final int totalElements;
  
  /// 是否有下一页
  final bool hasNext;
  
  /// 是否有上一页
  final bool hasPrevious;

  const PagedReplies({
    required this.content,
    required this.currentPage,
    required this.totalPages,
    required this.totalElements,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory PagedReplies.fromJson(Map<String, dynamic> json) =>
      _$PagedRepliesFromJson(json);
  
  Map<String, dynamic> toJson() => _$PagedRepliesToJson(this);
}

