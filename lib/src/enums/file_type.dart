// ignore_for_file: constant_identifier_names

import 'package:json_annotation/json_annotation.dart';

/// 文件类型
@JsonEnum(valueField: 'value')
enum FileType {
  /// 图片
  IMG('IMG'),

  /// 视频
  VID('VID'),

  /// 文档
  DOC('DOC'),

  /// 文本
  TXT('TXT'),

  /// 反馈引用
  FREF('FREF'),

  /// 评论引用
  CREF('CREF');

  final String value;
  const FileType(this.value);
}
