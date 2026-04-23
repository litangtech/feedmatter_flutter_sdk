import 'package:json_annotation/json_annotation.dart';

/// 文件类型
@JsonEnum(valueField: 'value')
enum FileType {
  /// 图片
  img('IMG'),

  /// 视频
  vid('VID'),

  /// 文档
  doc('DOC'),

  /// 文本
  txt('TXT'),

  /// 反馈引用
  fref('FREF'),

  /// 评论引用
  cref('CREF');

  final String value;
  const FileType(this.value);
}
