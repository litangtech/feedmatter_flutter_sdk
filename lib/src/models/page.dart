import 'package:json_annotation/json_annotation.dart';

part 'page.g.dart';

/// 分页响应
@JsonSerializable(genericArgumentFactories: true)
class Page<T> {
  /// 内容列表
  final List<T> content;

  /// 总元素数
  final int totalElements;

  /// 总页数
  final int totalPages;

  /// 每页大小
  final int size;

  /// 当前页码（从0开始）
  final int number;

  /// 是否是第一页
  final bool first;

  /// 是否是最后一页
  final bool last;

  /// 是否为空
  final bool empty;

  /// 当前页元素数量
  final int numberOfElements;

  const Page({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.size,
    required this.number,
    required this.first,
    required this.last,
    required this.empty,
    required this.numberOfElements,
  });

  factory Page.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$PageFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object Function(T value) toJsonT) =>
      _$PageToJson(this, toJsonT);
}

